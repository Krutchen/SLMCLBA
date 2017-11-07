//FIRST, SET YOUR DAMAGE. 
//THIS CAN EITHER BE AN INTEGER, (WHOLE NUMBER), OR A FLOAT (PERCENTAGE)
//"DAMAGE" DELIVERS INSTANT AT DAMAGE, AND CAN BE USED TO REPAIR.
//To set the arguments damage, follow it with a new section of the list, or (arg):(dmg)
//ie - ["damage","1"] - or ["damage:1"] - Either will cause 1 daamge.
//WE ARE USING *THIS* PARTICULAR SYSTEM TO ALLOW FOR A EXTENSIBLE API, FOR FURTHER UPDATES AND DAMAGE TYPES IF PEOPLE WANT TO HAVE THEM.
integer dmg=25; //INTEGER or PERCENTAGE
key hit;
det(integer i)
{
    llSetLinkAlpha(-1,0,ALL_SIDES);
    list r=llCastRay(llGetPos()+<-1.5,0,0>*llGetRot(),llGetPos()+<1.5,0,0>*llGetRot(),[RC_MAX_HITS,1]);
    if(llList2Integer(r,-1)>0)llRezObject("[Fragmentation Explosion]",llList2Vector(r,1),ZERO_VECTOR,ZERO_ROTATION,1);
    else llRezObject("[Fragmentation Explosion]",llGetPos()+<1.5,0,0>*llGetRot(),ZERO_VECTOR,ZERO_ROTATION,1);
    llTriggerSound("471e245c-b9d7-0d59-287b-ef89c9843ab3",1);
    llTriggerSound("471e245c-b9d7-0d59-287b-ef89c9843ab3",1);
    if(i==0)llDie();
}
default
{
    state_entry()
    {
        llSetStatus(STATUS_ROTATE_X|STATUS_ROTATE_Y|STATUS_ROTATE_Z,FALSE);
        llCollisionSound("",1);
    }
    land_collision_start(vector p)
    {
        llSetStatus(STATUS_PHYSICS,0);
        llSetStatus(STATUS_PHANTOM,1);
        det(0);
    }
    collision_start(integer p)
    {
        llSetStatus(STATUS_PHYSICS,0);
        llSetStatus(STATUS_PHANTOM,1);
        integer type=llDetectedType(0);
        if(~type&0x1&&(type&0x2||type&0x8))
        {
            det(1);
            hit=llDetectedKey(0);
            string desc=llList2String(llGetObjectDetails(hit,[OBJECT_DESC]),0);
            if(desc!=""&&(llGetSubString(desc,0,1)=="v."||llGetSubString(desc,0,5)=="LBA.v."))
            {
                if(llGetSubString(desc,0,5)=="LBA.v.")
                {
                    integer hex=(integer)("0x" + llGetSubString(llMD5String((string)hit,0), 0, 3));
                    llRegionSayTo(hit,hex,(string)hit+","+(string)dmg);
                }
                else
                {
                    llRegionSayTo(hit,-500,(string)hit+",damage,"+(string)dmg);
                }
                llOwnerSay("/me : Delivering "+(string)dmg+" AT to - "+llKey2Name(hit));
                llSleep(1);
                llDie();
            }
            else
            {
                llRezObject("[L_AT]",llGetPos(),ZERO_VECTOR,ZERO_ROTATION,dmg/5);
                llOwnerSay("/me : Delivering "+(string)dmg+" AT to - "+llKey2Name(hit));
            }
        }
        else det(0);
    }
    object_rez(key id)
    {
        if(llKey2Name(id)=="[L_AT]")
        {
            llRegionSayTo(id,-867,hit);
            llSleep(1);
            llDie();
        }
    }
}
