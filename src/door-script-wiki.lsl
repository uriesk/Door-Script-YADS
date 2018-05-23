//### door-script-wiki.lsl
 
float openingTime=3.0;      // in seconds
float openingAngle=90.0;    // in degrees
float autocloseTime=15.0;   // in seconds
integer steps=4;            // number of internal rotation steps
integer world=FALSE;         // align to world or root prim rotation
 
string soundOpen="door_open";
string soundClose="door_close";
string soundClosing="door_closing";
 
float omega=0.0;
 
vector axis;
rotation closedRot;
rotation openRot;
 
integer swinging;
integer open;
 
sound(string name)
{
    if(llGetInventoryType(name)==INVENTORY_SOUND)
        llTriggerSound(name,1.0);
}
 
openDoor(integer yes)
{
    if(yes)
        sound(soundOpen);
    else
        sound(soundClosing);
 
    vector useAxis=axis;
    open=yes;
 
    if(!yes)
        useAxis=-axis;
 
    llSetTimerEvent(openingTime/(float) steps);
    llTargetOmega(useAxis,omega,1.0);
}
 
go()
{
    if(swinging==0)
    {
        if(!open)
        {
            axis=<0.0,0.0,1.0>/llGetRootRotation();
 
            closedRot=llGetLocalRot();
 
            if(world)
                openRot=llGetRot()*llEuler2Rot(<0.0,0.0,openingAngle>*DEG_TO_RAD)/llGetRootRotation();
            else
                openRot=closedRot*llEuler2Rot(<0.0,0.0,openingAngle>*DEG_TO_RAD);
        }
        swinging=steps;
        openDoor(!open);
    }
}
 
rotation slerp(rotation source,rotation target,float amount)
{
   return llAxisAngle2Rot(llRot2Axis(target/source),amount*llRot2Angle(target))*source;
}
 
default
{
    state_entry()
    {
        swinging=0;
        open=FALSE;
        omega=TWO_PI/360*openingAngle/openingTime;
        llTargetOmega(ZERO_VECTOR,1.0,1.0);
    }
 
    touch_start(integer dummy)
    {
        go();
    }
 
    collision_start(integer dummy)
    {
        go();
    }
 
    timer()
    {
        if(swinging>0)
        {
            swinging--;
            if(swinging!=0)
            {
                float amount=(float) swinging/(float) steps;
                if(open)
                    amount=1.0-amount;
                llSetLinkPrimitiveParamsFast(LINK_THIS,[PRIM_ROT_LOCAL,slerp(closedRot,openRot,amount)]);
                return;
            }
 
            llTargetOmega(axis,0.0,0.0);
            if(open)
            {
                llSetLinkPrimitiveParamsFast(LINK_THIS,[PRIM_ROT_LOCAL,openRot]);
                llSetTimerEvent(autocloseTime);
            }
            else
            {
                llSetLinkPrimitiveParamsFast(LINK_THIS,[PRIM_ROT_LOCAL,closedRot]);
                sound(soundClose);
                llSetTimerEvent(0.0);
            }
        }
        else // autoclose time reached
        {
            llSetTimerEvent(0.0);
            openDoor(!open);
            swinging=steps;
        }
    }
}
