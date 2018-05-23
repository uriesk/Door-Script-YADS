//### door-script.lsl
//
// SWING A HINGED DOOR.  NO NEED FOR A SECOND PRIM.
// Works on stand-alone prim doors, a door of several linked parts,
// Or even a door that's a linked child of a larger house.  If the door
// is the root, all the links will swing.  If the door is just a linked,
// child then only the door will swing.
//
// ****************************************************************
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
// This software was originally written by KyleFlynn Resident.
// Mr. Flynn can be reached at kyleflynnresident@gmail.com.
// However, I don't often check that email.  You'd do better
// to catch me online, which I often am.
// ****************************************************************
// ****************************************************************
// ****************************************************************
//
//
// A FEW USER DEFINED PARAMETERS FOLLOW.  THEY CAN BE CUSTOMIZED FOR SPECIFIC DOORS:
//
//
// The following must be either 1 or -1.
// It simply specifies which side of the door the hinges are on.
// If they're on the wrong side, just change it.
integer giHingeSide = 1;
// The following also must be 1 or -1.
// It just specifies which direction the door opens.
integer giSwingDirection = 1;
// The following can be any number but something around 90, 
// or maybe up 140 makes sense.
integer giDegreesToOpenDoor = 90;
// The following basically specifies how fast the door opens.
// It's how many degrees the door opens on each loop step.
// To make it just "pop" open, set it to the same as giDegreesToOpenDoor.
// Ideally, it should be an even divisor of giDegreesToOpenDoor, 
// but it doesn't really matter.  The pause is also just another
// way to slow the door down, but set giDegreesPerStep=1 before using pause.
integer giDegreesPerStep = 9;
float   gfSecondsPausePerStep = 0.1;
// Do we wish for the door to automatically close after some interval?
integer gbCloseAfterTimeExpires = FALSE;
float   gfSecondToLeaveOpen = 5.0; // Does nothing unless above is TRUE.
//
// Do we wish to have chat commands that open/close the doors?
// This leaves a listener open if you do this.
integer gbListenToOpenChatForOpenClose = TRUE; // Following are ignored if this is FALSE.
integer giListenChannel = 0;            // 0 is open chat.
string gsOpenCommand = "OpenDoor";      // Not case sensitive.
string gsCloseCommand = "CloseDoor";    // Not case sensitive.
//
//
// NOTHING FROM HERE DOWN SHOULD BE TAMPERED WITH, UNLESS YOU'RE A SCRIPTER.
//
//
integer    gbDoorIsClosed = TRUE;
vector     gvClosedDoorPos;
rotation gqClosedDoorRot;
//
integer    giListenHandle;
//

SwingTheDoor()
{
    // This can be thought of as quite similar to the problem of 
    // one prim orbiting another while continuing to face it, just
    // like the Moon does to the Earth.  The hinged "edge" of the
    // door stays facing the spot on which it is hinged, while
    // the center of the door orbits this point with a radius of
    // half the door width.
    vector     vDoorPos;
    rotation qDoorRot;
    vector     vDoorScale;
    vector     vHingePos;
    vector     vOrigRadiusVector;
    //
    integer    iStepCount;
    rotation qHingeOrbitStep;
    rotation qHingeOrbitAngle;
    //
    vector     vNewRadiusVector;
    vector     vNewPos;
    rotation qNewRot;
    //
    integer    iSwingDir;
    //
    // Figure out whether we're opening or closing.
    iSwingDir = giSwingDirection;
    if (gbDoorIsClosed)
    {
        // These are used to prevent the closed door from moving due to rounding errors.
        gvClosedDoorPos = llGetLocalPos();
        gqClosedDoorRot = llGetLocalRot();
        //
        llMessageLinked(LINK_THIS, 0, "MakeOpenDoorSound", "");
    }
    else
    {
        iSwingDir = iSwingDir * -1;
    }
    // Initial parameters.
    vDoorPos = llGetLocalPos(); 
    qDoorRot = llGetLocalRot();
    vDoorScale = llGetScale();
    vOrigRadiusVector = <0.0, 0.0, 0.0>; 
    //
    // Figure out center-to-side distance of door.
    // Notice that giHingeSide is also considered.
    if (vDoorScale.x > vDoorScale.y) vOrigRadiusVector.x = vOrigRadiusVector.x + giHingeSide * vDoorScale.x / 2;
    else                             vOrigRadiusVector.y = vOrigRadiusVector.y + giHingeSide * vDoorScale.y / 2;
    // Rotate the radius vector for any initial rotation of the door.
    // This gives us both length and direction for the radius vector.
    vOrigRadiusVector = vOrigRadiusVector * qDoorRot; 
    // Now that we have the radius vector, we can subtract it from the door's position to get the hinge's position.
    vHingePos = vDoorPos - vOrigRadiusVector;
    //
    // The door orbits its hinges in the Z axis (XY plane).
    // Also, we account for swing direction here.
    qHingeOrbitStep = llEuler2Rot(<0.0, 0.0, giDegreesPerStep * DEG_TO_RAD * iSwingDir>);
    // Start an increment loop to slowly open the door.
    for(iStepCount = 1; iStepCount * giDegreesPerStep <= giDegreesToOpenDoor; iStepCount++)
    {
        // Figure out the angle to orbit on this step (from the beginning so no errors accumulate).
        qHingeOrbitAngle = llAxisAngle2Rot(llRot2Axis(qHingeOrbitStep), iStepCount * llRot2Angle(qHingeOrbitStep));
        // Multiply the original radius vector by the amount to orbit to get new radius vector.
        vNewRadiusVector = vOrigRadiusVector * qHingeOrbitAngle;
        // Add the hinge position to the new radius vector to pull the door to the correct spot on the sim.
        vNewPos = vHingePos + vNewRadiusVector;
        // We must also re-orient the door so that its side is facing the hinges.
        // We simply add our new angle to the door's starting orientation.
        qNewRot = qDoorRot * qHingeOrbitAngle;
        // Set them both at once so there's minimal visual lag.
        llSetLinkPrimitiveParamsFast(llGetLinkNumber(), [PRIM_POS_LOCAL, vNewPos, PRIM_ROT_LOCAL, qNewRot]);
        if (gfSecondsPausePerStep) llSleep(gfSecondsPausePerStep);
    }
    // Toggle opened/closed to new state.
    gbDoorIsClosed = !gbDoorIsClosed;
    if (gbDoorIsClosed)
    {
        // If it's now closed, make sure it's where it started.  
        // In other words, correct any rounding errors from opening and closing it.
        llSetLinkPrimitiveParams(llGetLinkNumber(), [PRIM_POS_LOCAL, gvClosedDoorPos, PRIM_ROT_LOCAL, gqClosedDoorRot]);
        //
        llMessageLinked(LINK_THIS, 0, "MakeCloseDoorSound", "");
    }
    else
    {
        // Make sure it's open to specified degrees.  See above for notes on what the math means.
        qHingeOrbitAngle = llEuler2Rot(<0.0, 0.0, giDegreesToOpenDoor * DEG_TO_RAD * iSwingDir>);
        vNewRadiusVector = vOrigRadiusVector * qHingeOrbitAngle;
        vNewPos = vHingePos + vNewRadiusVector;
        qNewRot = qDoorRot * qHingeOrbitAngle;
        llSetLinkPrimitiveParams(llGetLinkNumber(), [PRIM_POS_LOCAL, vNewPos, PRIM_ROT_LOCAL, qNewRot]);
        // If auto-close, set timer.
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
        if (gbListenToOpenChatForOpenClose) giListenHandle = llListen(giListenChannel, "", "", "");
    }
    listen(integer iChannel, string sSenderPrimOrAviLegacyName, key kSenderKey, string sMsg)
    {
        if (llToUpper(sMsg) == llToUpper(gsOpenCommand))  if (gbDoorIsClosed == TRUE)  SwingTheDoor();
        if (llToUpper(sMsg) == llToUpper(gsCloseCommand)) if (gbDoorIsClosed == FALSE) SwingTheDoor();
    }
    touch(integer iNumDetected) 
    {
        if (llGetTime() < 1.0) return; // Prevent double-clicks and LSL bug.
        //
        llResetTime();
        SwingTheDoor();
    }
    timer() 
    {
        llSetTimerEvent(0.0);
        if (!gbDoorIsClosed) SwingTheDoor();
    }
}



