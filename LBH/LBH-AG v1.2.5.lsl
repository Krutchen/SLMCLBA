//AG Variant includes a built-in anti-grief and blacklisting system. See line 49+ for details.
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
    llSetLinkPrimitiveParamsFast(-4,[PRIM_TEXT,"[LBH-AG]\n "+(string)hp+" / "+(string)mhp+" HP",<1.0,1.0,1.0>,1.0,
        PRIM_DESC,"LBA.v.HAG,"+(string)hp+","+(string)mhp+","+(string)atcap+",666"]);
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
//Anti-Grief
float interval=2.0;//How many seconds before the threshold is cleared. Recommended 2 seconds.
integer banthresh=80;//How much HP within the interval is considered ban worth, this affects single-hits as well as ATCAP is used only during damage calculations. Note that exceeding the ATCAP will still count against the user as the difference is not factored with the tracker.
//With a 2s interval at 80 damage, it will require a single owner to deal more than 40 DPS in order to get blacklisted.
list banlist;
//Tracker stores information like so: OWNER_UUID,DMG_TRACKED
list tracker;
integer checkdmg(string source, key owner, integer amt)//0 = Do not take damage, 1 = Take damage
{
    if(llListFindList(banlist,[owner])>-1)return 0;//Checks for previously banned source
    else
    {
        integer param=llListFindList(banlist,[owner]);
        if(param>-1)//Owner damage is already in tracker.
        {
            integer totalamt=llList2Integer(tracker,param+1);
            if(totalamt<banthresh)//Check ban threshold
            {
                tracker=llListReplaceList(tracker,[totalamt],param+1,param+1);//Update damage dealt thus far
                return 1;
            }
            else //Ban them instead if it fails
            {
                tracker=llDeleteSubList(tracker,param,param+1);
                banlist+=owner;
                llOwnerSay("Banned "+llKey2Name(owner)+" for dealing "+(string)totalamt+" damage
                    Last source: ["+source+"] for "+(string)amt+" damage");
                llRegionSayTo(owner,0,"Blacklisted for dealing too much damage too quickly");
                hp+=llList2Integer(tracker,param+1); //Refund the damage they already did.
                if(hp>mhp)hp=mhp;
                return 0;
            }
        }
        else
        {
            if(amt>banthresh)
            {
                banlist+=owner;
                llOwnerSay("Banned "+llKey2Name(owner)+" for dealing "+(string)amt+" damage
                    Last source: ["+source+"] for "+(string)amt+" damage");
                llRegionSayTo(owner,0,"Blacklisted for dealing too much damage too quickly");
                return 0;
                //No need to refund damage since they were not already in tracker
            }
            else
            {
                tracker+=[owner,amt];
                return 1;
            }
        }
    }
}
//
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
    llSetTimerEvent(interval);
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
            integer amt=llList2Integer(parse,-1);
            if(llFabs(amt)<666.0)//Overflow check
            {
                if(amt>0.0)
                {
                    if(checkdmg(name,llGetOwnerKey(id),amt))
                    {
                        llSetTimerEvent(interval);//Reset interval on new damage update
                        damage(amt,id);
                    }
                }
                else damage(amt,id);
            }
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
    timer()
    {
        tracker=[];//Clear tracker
        //Auto-Deleter
        if(tar(gen))return;
        llDie();
    }
}
