//### door-script.lsl
// Version 1.01
//
// DOOR SCRIPT FOR SWINGING, ROTATING AND SLIDING DOORS.
// Works on stand-alone prim doors, a door of several linked parts,
// Or even a door that's a linked child of a larger house.  If the door
// is the root, all the links will move.  If the door is a linked
// child, then only the door will move.
// FOR FAST USE, THIS SCRIPT IS SUPPOSED TO BE CONFIGURED IN THE 
// DESCRIPTION FIELD OF THE DOOR.
// YOU SHOULD HAVE GOOTEN A NOTECARD AND IMAGES WITH IT, THAT LIST
// ALL POSSIBLE CONFIGURATION OPTIONS. IF YOU DID NOT RECEIVE THEM
// GET THEM at https://github.com/uriesk/Door-Script-YASM
//
// ****************************************************************
// ****************************************************************
// This program is free software: you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// version 3 as published my the Free Software Foundation:
// http://www.gnu.org/licenses/gpl.html
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// The part about hinged swining doors of this  software was 
// originally written by KyleFlynn Resident. 
// Mr. Flynn can be reached at kyleflynnresident@gmail.com.
// However, I don't often check that email.  You'd do better
// to catch me online, which I often am.
//
// The whole rest of this script got written by unregi Resident. 
// ****************************************************************
// ****************************************************************
//
//
// A FEW DEFAULT PARAMETERS FOLLOW, THOSE ARE THE VALUES THE SCRIPT USES IF
// THERE ARE NO CONFIGURATION VALUES IN THE DESCRIPTION FIELD
//
//
// Following is the type of the door, it can be "ROTATE", "HINGED" or "SLIDE"
string gsDoorType = "ROTATE";
// The following is the rotation / sliding axes, usually, doors rotate around z.
// and slide around x or y
// It can be uppercase X, Y or Z
string gsMovementAxes = "Z";
// The following must be either 1 or -1.
// It simply specifies which side of the door the hinges are on.
// If they're on the wrong side, just change it.
integer giHingeSide = 1;
// The following must be 1 or -1.
// It just specifies which direction the door opens.
integer giOpenDirection = 1;
// The following can be any number but something around 90, 
// or maybe up 140 makes sense. It is the Degrees for rotate and hinged,
// and percent for sliding
integer giUnitsToOpenDoor = 90;
// The following basically specifies how fast the door opens.
// It's how many units (degrees with rotate and hinged, percentage with sliding)
// the door opens on each loop step.
// To make it just "pop" open, set it to the same as giUnitsToOpenDoor.
// Ideally, it should be an even divisor of giUnitsToOpenDoor, 
// but it doesn't really matter.  The pause is also just another
// way to slow the door down, but set giUnitsPerStep=1 before using pause.
// Since llSleep is a potential risk of lag on OpenSim, it is advised
// to open the door fast, by either setting gfSecondsPausePerStep very low
// or giUnitsPerStep high.
integer giUnitsPerStep = 2;
float   gfSecondsPausePerStep = 0.004;
// Do we wish for the door to automatically close after some interval?
integer gbCloseAfterTimeExpires = FALSE;
float   gfSecondToLeaveOpen = 5.0; // Does nothing unless above is TRUE.
// Do we play sounds on open doors?
// If so, place the sound files into the object inventory
integer giPlaySound = FALSE;
string gsOpeningSound = "open";
string gsClosingSound = "close";
string gsClosedSound = "closed";
// Should the door get set to none physics shape when open?
// (this means that avatars can walk through it and wont get stuck or pushed)
integer giOpenPhantom = FALSE;
// set if the door should be able to be locked by link message
integer gbDoorIsLockable = FALSE;
string gsUnlockMessage = "unlock";
string gsLockMessage = "lock";
// set if the door is paired with another door and its link number
// use this if you have a paire of doors that needs to open/close together
integer gbDoorIsPaired = FALSE;
integer giLinkOfPaired = 10;
// set if the door should open on collision (when Avatar is bumping into it)
integer gbBumpOpen = FALSE;
//
//
// NOTHING FROM HERE DOWN SHOULD BE TAMPERED WITH, UNLESS YOU'RE A SCRIPTER.
//
//
string     gsDescription;
integer    gbDoorIsClosed = TRUE;
integer    gbDoorIsLocked = FALSE;
vector     gvClosedDoorPos;
rotation   gqClosedDoorRot;
integer    giClosedDoorPhysics;
//

PlaySound(string name)
{
    if(llGetInventoryType(name) == INVENTORY_SOUND && giPlaySound)
        llTriggerSound(name,1.0);
}

LoadConfig()
{
    string desc = llGetObjectDesc();
    if (desc == gsDescription) return;
    gsDescription = desc;
    list lKeys = llParseString2List(gsDescription, [" "], [""]);
    integer iLength = llGetListLength(lKeys);
    if (iLength <= 1) return;
    if (llToUpper(llList2String(lKeys, 0)) != "DOOR") return;
    integer iCnt = 1;
    do {
        string sKey = llToUpper(llList2String(lKeys, iCnt));
        if (sKey == "X" || sKey == "Y" || sKey == "Z") gsMovementAxes = sKey;
        else if (sKey == "ROTATE" || sKey == "HINGED" || sKey == "SLIDE") gsDoorType = sKey;
        else if (sKey == "CCW" || sKey == "LEFT" || sKey == "DOWN") giOpenDirection = 1;
        else if (sKey == "CW" || sKey == "RIGHT" || sKey == "UP") giOpenDirection = -1;
        else if (sKey == "SOUND" || sKey == "SND") giPlaySound = TRUE;
        else if (sKey == "PHANTOM" || sKey == "PH") giOpenPhantom = TRUE;
        else if (sKey == "LOCKABLE" || sKey == "LCK") gbDoorIsLockable = TRUE;
        else if (sKey == "BUMP" || sKey == "BO") gbBumpOpen = TRUE;
        else if (sKey == "LI") {
            giHingeSide = 1;
            giOpenDirection = 1;
        }
        else if (sKey == "LO") {
            giHingeSide = 1;
            giOpenDirection = -1;
        }
        else if (sKey == "RI") {
            giHingeSide = -1;
            giOpenDirection = -1;
        }
        else if (sKey == "RO") {
            giHingeSide = -1;
            giOpenDirection = 1;
        }
        else if (llGetSubString(sKey, -1, -1) == "%") {
            giUnitsToOpenDoor = (integer)(llGetSubString(sKey, 0, -2));
        }
        else if (sKey == "PAIRED" || sKey == "PRD") {
            gbDoorIsPaired = TRUE;
            giLinkOfPaired = llList2Integer(lKeys, ++iCnt);
        }
        else if (sKey == "AUTOCLOSE" || sKey == "AC") {
            gbCloseAfterTimeExpires = TRUE;
            gfSecondToLeaveOpen = llList2Float(lKeys, ++iCnt);
        }
        else if (llSubStringIndex(sKey, "/") != -1) {
            integer spacer = llSubStringIndex(sKey, "/");
            giUnitsPerStep = (integer)(llGetSubString(sKey, 0, spacer - 1));
            gfSecondsPausePerStep = (float)(llGetSubString(sKey, spacer + 1, -1));
        }
    } while (++iCnt < iLength);

}

TriggerTheDoor()
{
    if (llGetTime() < 0.8) return;
    llResetTime();
    integer iDirection;
    LoadConfig();
    //
    iDirection = giOpenDirection;
    if (gbDoorIsClosed)
    {

        list lDoorParams = llGetLinkPrimitiveParams(LINK_THIS, [PRIM_POS_LOCAL, PRIM_ROT_LOCAL, PRIM_PHYSICS_SHAPE_NONE]);
        gvClosedDoorPos = llList2Vector(lDoorParams, 0);
        gqClosedDoorRot = llList2Rot(lDoorParams, 1);
        giClosedDoorPhysics = llList2Integer(lDoorParams, 2);
        PlaySound(gsOpeningSound);
        if (giOpenPhantom) llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_PHYSICS_SHAPE_TYPE, PRIM_PHYSICS_SHAPE_NONE]);
        if (gbDoorIsPaired) llMessageLinked(giLinkOfPaired, 0, "opendoor", NULL_KEY);
    }
    else
    {
        iDirection = iDirection * -1;
        PlaySound(gsClosingSound);
        if (gbDoorIsPaired) llMessageLinked(giLinkOfPaired, 0, "closedoor", NULL_KEY);
    }
    //
    if (gsDoorType == "ROTATE") RotateTheDoor(iDirection);
    if (gsDoorType == "HINGED") SwingTheDoor(iDirection);
    if (gsDoorType == "SLIDE") SlideTheDoor(iDirection);
}

RotateTheDoor(integer iSwingDir)
{
    rotation   qDoorRot;
    integer    iStepCount;
    rotation   qHingeOrbitAngle;
    rotation   qNewRot;
    vector     vRotAxes;
    //
    qDoorRot = llGetLocalRot();
    vRotAxes = <0.0, 0.0, 0.0>;
    if (gsMovementAxes == "X") vRotAxes.x = 1.0;
    else if (gsMovementAxes == "Y") vRotAxes.y = 1.0;
    else if (gsMovementAxes == "Z") vRotAxes.z = 1.0;
    // Start an increment loop to slowly open the door.
    for(iStepCount = 1; iStepCount * giUnitsPerStep <= giUnitsToOpenDoor; iStepCount++)
    {
        qHingeOrbitAngle = llEuler2Rot(vRotAxes * iStepCount * giUnitsPerStep * DEG_TO_RAD * iSwingDir);
        qNewRot = qHingeOrbitAngle * qDoorRot;
        llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_ROT_LOCAL, qNewRot]);
        if (gfSecondsPausePerStep) llSleep(gfSecondsPausePerStep);
    }
    gbDoorIsClosed = !gbDoorIsClosed;
    //make sure that it is in the wanted position (adjust for rounding errors)
    if (gbDoorIsClosed)
    {
        llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_ROT_LOCAL, gqClosedDoorRot]);
        PlaySound(gsClosedSound);
        if (giOpenPhantom) llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_PHYSICS_SHAPE_TYPE, giClosedDoorPhysics]);
    }
    else
    {
        qHingeOrbitAngle = llEuler2Rot(vRotAxes * giUnitsToOpenDoor * DEG_TO_RAD * iSwingDir);
        qNewRot = qHingeOrbitAngle * qDoorRot;
        llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_ROT_LOCAL, qNewRot]);
        if (gbCloseAfterTimeExpires) llSetTimerEvent(gfSecondToLeaveOpen);
    }
}

SwingTheDoor(integer iSwingDir)
{
    // This can be thought of as quite similar to the problem of 
    // one prim orbiting another while continuing to face it, just
    // like the Moon does to the Earth.  The hinged "edge" of the
    // door stays facing the spot on which it is hinged, while
    // the center of the door orbits this point with a radius of
    // half the door width.
    vector     vDoorPos;
    rotation   qDoorRot;
    vector     vDoorScale;
    vector     vHingePos;
    vector     vOrigRadiusVector;
    integer    iStepCount;
    rotation   qHingeOrbitAngle;
    vector     vNewRadiusVector;
    vector     vNewPos;
    rotation   qNewRot;
    vector     vRotAxes;
    //
    vDoorPos = llGetLocalPos(); 
    qDoorRot = llGetLocalRot();
    vDoorScale = llGetScale();
    vOrigRadiusVector = <0.0, 0.0, 0.0>; 
    vRotAxes = <0.0, 0.0, 0.0>;
    // Figure out center-to-side distance of door, according to the longer side of the none-rotation axis.
    if (gsMovementAxes == "Z") {
        vRotAxes.z = 1.0; 
        if (vDoorScale.x > vDoorScale.y) vOrigRadiusVector.x = vOrigRadiusVector.x + giHingeSide * vDoorScale.x / 2;
        else                             vOrigRadiusVector.y = vOrigRadiusVector.y + giHingeSide * vDoorScale.y / 2;
    }
    else if (gsMovementAxes == "Y") {
        vRotAxes.y = 1.0; 
        if (vDoorScale.x > vDoorScale.z) vOrigRadiusVector.x = vOrigRadiusVector.x + giHingeSide * vDoorScale.x / 2;
        else                             vOrigRadiusVector.z = vOrigRadiusVector.z + giHingeSide * vDoorScale.z / 2;
    }
    else if (gsMovementAxes == "X") {
        vRotAxes.x = 1.0; 
        if (vDoorScale.y > vDoorScale.z) vOrigRadiusVector.y = vOrigRadiusVector.y + giHingeSide * vDoorScale.y / 2;
        else                             vOrigRadiusVector.z = vOrigRadiusVector.z + giHingeSide * vDoorScale.z / 2;
    }
      // Now that we have the radius vector, we can rotate it to its initial position and subtract it from the door's position to get the hinge's position.
    vHingePos = vDoorPos - vOrigRadiusVector * qDoorRot;
    // Start an increment loop to slowly open the door.
    for(iStepCount = 1; iStepCount * giUnitsPerStep <= giUnitsToOpenDoor; iStepCount++)
    {
        qHingeOrbitAngle = llEuler2Rot(vRotAxes * iStepCount * giUnitsPerStep * DEG_TO_RAD * iSwingDir);
        vNewRadiusVector = vOrigRadiusVector * qHingeOrbitAngle * qDoorRot;
        vNewPos = vHingePos + vNewRadiusVector;
        qNewRot = qHingeOrbitAngle * qDoorRot;
        llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_POS_LOCAL, vNewPos, PRIM_ROT_LOCAL, qNewRot]);
        if (gfSecondsPausePerStep) llSleep(gfSecondsPausePerStep);
    }
    gbDoorIsClosed = !gbDoorIsClosed;
    //make sure that it is in the wanted position (adjust for rounding errors)
    if (gbDoorIsClosed)
    {
        llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_POS_LOCAL, gvClosedDoorPos, PRIM_ROT_LOCAL, gqClosedDoorRot]);
        PlaySound(gsClosedSound);
        if (giOpenPhantom) llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_PHYSICS_SHAPE_TYPE, giClosedDoorPhysics]);
    }
    else
    {
        qHingeOrbitAngle = llEuler2Rot(vRotAxes * giUnitsToOpenDoor * DEG_TO_RAD * iSwingDir);
        vNewRadiusVector = vOrigRadiusVector * qHingeOrbitAngle * qDoorRot;
        vNewPos = vHingePos + vNewRadiusVector;
        qNewRot = qHingeOrbitAngle * qDoorRot;
        llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_POS_LOCAL, vNewPos, PRIM_ROT_LOCAL, qNewRot]);
        if (gbCloseAfterTimeExpires) llSetTimerEvent(gfSecondToLeaveOpen);
    }
}

SlideTheDoor(integer iSlideDir)
{
    vector     vDoorPos;
    rotation   qDoorRot;
    vector     vDoorScale;
    integer    iStepCount;
    vector     vNewPos;
    vector     vOpenVector;
    float      fDoorWidth;
    vector     vMoveDirection;
    //
    iSlideDir = iSlideDir * -1;
    vDoorPos = llGetLocalPos(); 
    qDoorRot = llGetLocalRot();
    vDoorScale = llGetScale();
    vMoveDirection = <0.0, 0.0, 0.0>;
    if (gsMovementAxes == "X") {
        vMoveDirection.x = 1.0;
        fDoorWidth = vDoorScale.x;
    }
    else if (gsMovementAxes == "Y") {
        vMoveDirection.y = 1.0;
        fDoorWidth = vDoorScale.y;
    }
    else if (gsMovementAxes == "Z") {
        vMoveDirection.z = 1.0;
        fDoorWidth = vDoorScale.z;
    }
    // Start an increment loop to slowly open the door.
    for(iStepCount = 1; iStepCount * giUnitsPerStep <= giUnitsToOpenDoor; iStepCount++)
    {
        vOpenVector = ( vMoveDirection * giUnitsPerStep * iStepCount * fDoorWidth / 100 * iSlideDir) * qDoorRot;
        vNewPos = vDoorPos + vOpenVector;
        llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_POS_LOCAL, vNewPos]);
        if (gfSecondsPausePerStep) llSleep(gfSecondsPausePerStep);
    }
    gbDoorIsClosed = !gbDoorIsClosed;
    //make sure that it is in the wanted position (adjust for rounding errors)
    if (gbDoorIsClosed)
    {
        llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_POS_LOCAL, gvClosedDoorPos, PRIM_ROT_LOCAL, gqClosedDoorRot]);
        PlaySound(gsClosedSound);
        if (giOpenPhantom) llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_PHYSICS_SHAPE_TYPE, giClosedDoorPhysics]);
    }
    else
    {
        vOpenVector = ( vMoveDirection * giUnitsToOpenDoor * fDoorWidth / 100 * iSlideDir) * qDoorRot;
        vNewPos = vDoorPos + vOpenVector;
        llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_POS_LOCAL, vNewPos]);
        if (gbCloseAfterTimeExpires) llSetTimerEvent(gfSecondToLeaveOpen);
    }
}


default
{
    on_rez(integer iParam) 
    {
        llResetScript();
    }
    state_entry()
    {
        LoadConfig();
    }
    touch_start(integer iNumDetected) 
    {
        if (gbDoorIsLocked && gbDoorIsClosed) {
            llWhisper(0, "This door is locked.");
            return;
        }
        TriggerTheDoor();
    }
    collision_start(integer iNumDetected) {
        if (!gbBumpOpen || !gbDoorIsClosed || gbDoorIsLocked) return;
        TriggerTheDoor();
    }
    timer() 
    {
        llSetTimerEvent(0.0);
        if (!gbDoorIsClosed) TriggerTheDoor();
    }
    link_message(integer link_num, integer num, string msg, key id)
    {
        if (!gbDoorIsLockable && (!gbDoorIsPaired || link_num != giLinkOfPaired)) return;
        if (msg == gsUnlockMessage) gbDoorIsLocked = FALSE;
        else if (msg == gsLockMessage) gbDoorIsLocked = TRUE;
        else if ( (msg == "opendoor" && !gbDoorIsLocked && gbDoorIsClosed && link_num == giLinkOfPaired) || (msg == "closedoor" && !gbDoorIsClosed && link_num == giLinkOfPaired) ) TriggerTheDoor();
    }
}

