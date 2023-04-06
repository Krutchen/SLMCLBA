//A slim and simplified version of the LBA parser.
integer mhp=100;//Maximum HP
integer hp=mhp;//Current HP
//Positive Numbers Deal Damage
//Negative Numbers Restore Health
integer atcap=50;
//Damage Processor
damage(integer amt, key id)
{
    if(amt>atcap)amt=atcap;
    if(amt<0)//Allows the object to be healed/repaired
    {
        if(llGetTime()>1.0)//Optional healing cooldown
        {
            amt*=-1;
            if(amt>(float)hp*0.1)amt=llRound((float)hp*0.1);//Optional healing cap
            hp+=amt;
            if(hp>mhp)hp=mhp;//Used to prevent overhealing
            llResetTime();
        }
        //Be sure to update the listen event code block to allow negative damage values through.
    }
    /*else if(amt<6)return; //Blocks micro-LBA*/
    else if(amt)
    {
        if(amt>atcap)amt=atcap;
        hp-=amt;
    }
    else return;
    if(hp<1)die();
    else update();
}

update()//SetText
{
    llSetLinkPrimitiveParamsFast(-4,[PRIM_TEXT,"[LBHS]\n "+(string)hp+" / "+(string)mhp+" HP",<1.0,1.0,1.0>,1.0,
        PRIM_DESC,"LBA.v.HS,"+(string)hp+","+(string)mhp+","+(string)atcap+",666"]);
        //In order: Current HP, Max HP, Max AT accepted, Max healing accepted (Not implemented)
}
die()
{
    //Add extra shit here
    //llResetScript();//Debug
    llDie();//Otherwise, use this
}
vector tar(key id)
{
    vector av=(vector)((string)llGetObjectDetails(id,[OBJECT_POS]));
    return av;
}
key user;
key gen;//Object rezzer
key me;
integer hear;
boot()
{
    user=llGetOwner();
    me=llGetKey();
    gen=(string)llGetObjectDetails(me,[OBJECT_REZZER_KEY]);
    if(hear)llListenRemove(hear);
    integer hex=(integer)("0x" + llGetSubString(llMD5String((string)me,0), 0, 3));
    hear=llListen(hex,"","","");
    llSetTimerEvent(5.0);//Used for auto-delete.
    update();
}
default
{
    state_entry()
    {
        boot();
    }
    on_rez(integer p)
    {
        if(p>1)//Allows HUD/Objects to set HP value when rezzed with a param, otherwise uses default
        {
            mhp=p;
            hp=p;
        }
        boot();
    }
    listen(integer chan, string name, key id, string message)
    {
        //[ALWAYS] USE llRegionSayTo(). Do not flood the channel with useless garbage that'll poll every object in listening range.
        list parse=llParseString2List(message,[","],[" "]);
        if(llList2Key(parse,0)==me)//targetcheck
        {
            float amt=llList2Float(parse,-1);
            if(llFabs(amt)<666.0)damage((integer)amt,id);//Use this code to allow object healing, Blocks overflow attempts
            //if(amt>0)damage((integer)amt,id);//Use this code if you do not wish to support healing
        }
    }
    collision_start(integer c)//Enable this block if you want to support legacy collisions.
    {
        if(llVecMag(llDetectedVel(0))>40.0)
        {
            hp-=c;
            if(hp<1)die();//llDie();
            else update();
        }
    }
    timer()//Auto-deleter. Will kill object if avatar leaves the region or spawning object is removed.
    {
        if(tar(gen))return;
        llDie();
    }
}
