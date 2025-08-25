// FIRST, SET YOUR DAMAGE.
// THIS CAN EITHER BE AN INTEGER, (WHOLE NUMBER), OR A FLOAT (PERCENTAGE)
// "DAMAGE" DELIVERS INSTANT AT DAMAGE, AND CAN BE USED TO REPAIR.
// To set the arguments damage, follow it with a new section of the list, or (arg):(dmg)
// ie - ["damage","1"] - or ["damage:1"] - Either will cause 1 daamge.
// WE ARE USING *THIS* PARTICULAR SYSTEM TO ALLOW FOR A EXTENSIBLE API, FOR FURTHER UPDATES AND DAMAGE TYPES IF PEOPLE WANT TO HAVE THEM.
integer dmg = 25; // INTEGER or PERCENTAGE
key hit;
detonate(integer die)
{
    llSetLinkAlpha(-1, 0, ALL_SIDES);
    vector pos = llGetPos();
    vector start = pos + <-1.5, 0, 0> * llGetRot();
    vector end =   pos + <+1.5, 0, 0> * llGetRot();
    list r = llCastRay(start, end, []);
    if(llList2Integer(r, -1) > 0)
    {
        vector hit_pos = llList2Vector(r, 1);
        llRezObjectWithParams("[Fragmentation Explosion]", [REZ_POS, hit_pos, REZ_PARAM, 1])
    }
    else
    {
        llRezObjectWithParams("[Fragmentation Explosion]", [REZ_POS, start, REZ_PARAM, 1])
    }
    llTriggerSound("471e245c-b9d7-0d59-287b-ef89c9843ab3", 1);
    llTriggerSound("471e245c-b9d7-0d59-287b-ef89c9843ab3", 1);
    if(die == TRUE) llDie();
}
default
{
    state_entry()
    {

        llSetStatus(14, FALSE); // No rotating
        llCollisionSound("", 0);
    }
    land_collision_start(vector p)
    {
        llSetStatus(STATUS_PHYSICS, 0);
        llSetStatus(STATUS_PHANTOM, 1);
        detonate(TRUE);
    }
    collision_start(integer p)
    {
        llSetStatus(STATUS_PHYSICS, 0);
        llSetStatus(STATUS_PHANTOM, 1);
        integer type = llDetectedType(0);
        integer avatar = (type & AGENT);
        integer physical = (type & ACTIVE);
        integer scripted = (type & SCRIPTED);
        if(avatar)
        {
            detonate(TRUE);
        }
        else if(physical || scripted)
        {
            detonate(FALSE);
            hit = llDetectedKey(0);
            string desc = llList2String(llGetObjectDetails(hit, [OBJECT_DESC]), 0);
            integer has_desc = (desc != "");
            integer lba1 = (llGetSubString(desc,0,1) == "v.");
            integer lba2 = (llGetSubString(desc,0,5) == "LBA.v.");
            if(has_desc && (lba1 || lba2))
            {
                if(lba2)
                {
                    integer hex = (integer)("0x" + llGetSubString(llMD5String((string)hit, 0), 0, 3));
                    llRegionSayTo(hit, hex, llList2CSV([hit, dmg]));
                }
                else
                {
                    llRegionSayTo(hit, -500, llList2CSV([hit, "damage", dmg]));
                }
                llOwnerSay("/me : Delivering " + (string)dmg + " AT to - " + llKey2Name(hit));
                llSleep(1);
                llDie();
            }
            else
            {
                llRezObjectWithParams("[L_AT]", [REZ_POS, llGetPos(), REZ_PARAM, dmg / 5]);
                llOwnerSay("/me : Delivering " + (string)dmg + " AT to - " + llKey2Name(hit));
            }
        }
    }
    object_rez(key id)
    {
        if(llKey2Name(id) == "[L_AT]")
        {
            llRegionSayTo(id, -867, hit);
            llSleep(1);
            llDie();
        }
    }
}
