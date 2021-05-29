integer hp;             // Current hp
integer hpmax = 25;     // My default HP value, LBA Slim is great for values less than 50
integer cap = 0;        // Maximum damage taken per hit, leave this at 0 if you dont want to use the cap
integer link = 0;       // Text display link number
integer hex;            // My channel
key me;                 // My key
list buffer;
integer die = TRUE;     // Does this script kill the object -OR- sends a message to a core script
                        // for plug and play LBA

updateHP()
{
    if(hp <= 0)
    {
        if(buffer != []) llOwnerSay(llDumpList2String(buffer, " | "));
        llSleep(0.1);
        if(!die) llMessageLinked(LINK_THIS, 1, "dead", NULL_KEY);
        else llDie();
    }
    else
    {
        llSetLinkPrimitiveParamsFast(link,[
        PRIM_TEXT,"[LBA-Slim]\n[" + (string)(hp) + "/" +(string)(hpmax) + "]",<0.0,1.0,0.0>,1.0,
        PRIM_LINK_TARGET, LINK_THIS,
        PRIM_DESC,"LBA.v.L.2.22," + (string)hp + "," + (string)hpmax + "," + (string)cap
        ]);
    }
}

init(integer s)
{
    if(s <= hpmax && s > 0) hp = s;
    else hp = hpmax;
    if(!cap) cap = hpmax;
    me = llGetKey();
    hex = (integer)("0x" + llGetSubString(llMD5String((string)me,0), 0, 3));
    llListen(hex, "","","");
    updateHP();
}

default
{
    state_entry()
    {
        llSetLinkPrimitiveParams(LINK_SET, [PRIM_TEXT,"", <1,1,1>,1]);
        init(hpmax);
    }
    on_rez(integer sp)
    {
        init(sp);
    }
    collision_start(integer n)
    {
        while(n--)
        {
            if(llVecMag(llDetectedVel(n)) > 25 && llDetectedType(n) != 3) --hp;
        }
        updateHP();
    }
    listen(integer c, string n, key id, string m)
    {
        list l = llParseString2List(m,[","],[]);
        string target = llList2String(l,0);
        integer dmg = (integer)llList2String(l,1);
        if (cap) // use cap to limit repairs
        {
            if (dmg < -cap) dmg = -cap;
        }
        else if (dmg < -hpmax) dmg = -hpmax; // use maxhp to limit repairs
        if(c == hex)
        {
            if(target == (string)me)
            {
                string name = llKey2Name(llGetOwnerKey(id));
                if(dmg > cap) hp -= cap;
                else hp -= dmg;
                if(hp > hpmax) hp = hpmax;
                integer index = llListFindList(buffer, [name]);
                if(index < 0) buffer += [name,dmg];
                else
                {
                    dmg = llList2Integer(buffer,index+1) + dmg;
                    buffer = llListReplaceList(buffer, [name,dmg], index, index+1);
                }
                updateHP();
                llSetTimerEvent(2);
            }
        }       
    }
    
    timer()
    {
        llOwnerSay(llDumpList2String(buffer, " | "));
        buffer = [];
        llSetTimerEvent(0);
    }
}
