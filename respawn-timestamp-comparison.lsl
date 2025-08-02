string daystamp;
string endstamp;
getend()
{
    string stamp=llGetTimestamp();
    daystamp=llGetSubString(stamp,8,9)+":"+llGetSubString(stamp,11,-9);
    list newtime=llParseString2List(daystamp,[":"],[]);
    integer day=(integer)llList2String(newtime,0);
    integer hour=(integer)llList2String(newtime,1);
    integer minute=(integer)llList2String(newtime,2);
    integer sec=(integer)llList2String(newtime,3);
    integer newmin=delay/60;
    integer new=delay;
    if(newmin)
    {
        minute+=newmin;
        new=delay-(60*newmin);
        sec+=new;
    }
    else sec+=delay;
    if(sec>60)
    {
        sec-=60;
        minute++;
    }
    if(minute>60)
    {
        integer howm=minute/60;
        minute-=(60*howm);
        hour+=howm;
    }
    if(hour>24)
    {
        integer howm=hour/24;
        hour-=(24*howm);
        day+=howm;
    }
    endstamp=(string)day+":";
    if(hour<10)endstamp+="0";
    endstamp+=(string)hour+":";
    if(minute<10)endstamp+="0";
    endstamp+=(string)minute+":";
    if(sec<10)endstamp+="0";
    endstamp+=(string)sec;
    llSetLinkPrimitiveParamsFast(body,[PRIM_DESC,endstamp]);
}
integer compare()//This is a little big lengthy and rough, feel free to make it more efficient if need be but the basic functions should be roughly 2kb, lsl is 16kb mono is 64kb so we have plenty of space
{
    string stamp=llGetTimestamp();
    daystamp=llGetSubString(stamp,8,9)+":"+llGetSubString(stamp,11,-9);
    list newtime=llParseString2List(daystamp,[":"],[]);
    integer day=(integer)llList2String(newtime,0);
    integer hour=(integer)llList2String(newtime,1);
    integer minute=(integer)llList2String(newtime,2);
    integer sec=(integer)llList2String(newtime,3);
    newtime=llParseString2List(endstamp,[":"],[]);
    integer eday=(integer)llList2String(newtime,0);
    integer ehour=(integer)llList2String(newtime,1);
    integer eminute=(integer)llList2String(newtime,2);
    integer esec=(integer)llList2String(newtime,3);
    integer valid=1;
    if(sec<esec)
    {
        valid=0;
        if(minute>eminute)valid=1;
    }
    if(minute<eminute)
    {
        valid=0;
        if(hour>ehour)valid=1;
    }
    if(hour<ehour)
    {
        valid=0;
        if(day>eday)valid=1;
    }
    if(day<eday)
    {
        valid=0;
        if(llAbs(eday-day)>0)valid=1;
    }
    if(valid)
    {
        endstamp="";
        llSetLinkPrimitiveParamsFast(body,[PRIM_DESC,endstamp]);
        return 1;
    }
    else return 0;
}
integer respawndelay=1;//Is respawn delay active?
integer delay=4;//If active how long does this take?
//Link set numbers
integer body;
//Listen channel numbers
integer targetchannel;
key target;//this is my hitbox
default
{
    state_entry()
    {
      
        integer num=llGetNumberOfPrims()+1;
        while(num)
        {
            string name=llToLower(llGetLinkName(num));
            if(name=="*body")body=num;
            --num;
        }
        endstamp=(string)llGetLinkPrimitiveParams(body,[PRIM_DESC]);
    }
    listen(integer c, string n, key id, string m)
    {
        if(llGetOwnerKey(id)==llGetOwner())
        {
            if(c==1)
            {
                if(m=="menu")menu();
                if(target=="")
                {
                    m=llToLower(m);
                    if(m=="rez")
                    {
                        if(endstamp!=""&&compare()==0&&respawndelay==1)
                        {
                            llOwnerSay("Cannot respawn until "+endstamp+", it is currently "+daystamp);
                            return;
                        }
                        rotation rot=llGetRot();
                        target=llRezObjectWithParams("vehicle hitbox name",[REZ_POS,llGetPos()+<0,0,.5>,0,0,REZ_ROT,<0,0,rot.z,rot.s>,0,
REZ_PARAM,75,REZ_PARAM_STRING,"respawndelay:"+(string)respawndelay]);
targetchannel=(integer)("0x" + llGetSubString(llMD5String((string)target,0), 0, 3))+101;
                    }
                }
                if(m=="respawndelay"||m=="respawn delay")
                {
                    //if((vector)((string)llGetObjectDetails(oichud,[OBJECT_POS]))==ZERO_VECTOR)oichud="";
                    //if(oichud=="") // Chaos has an OIC hud that can remotely set this, that should give you other guys an idea too lol
                    //{
                        if(respawndelay==0)
                        {
                            llOwnerSay("Enabling vehicle respawn delay");
                            respawndelay=1;
                        }
                        else
                        {
                            llOwnerSay("Disabling vehicle respawn delay");
                            respawndelay=0;
                            endstamp="";
                            llSetLinkPrimitiveParamsFast(body,[PRIM_DESC,endstamp]);
                        }
                        if(target!="")llRegionSayTo(target,targetchannel,"respawndelay:"+(string)respawndelay);
                    //}
                }
            }
        }
    }
}
