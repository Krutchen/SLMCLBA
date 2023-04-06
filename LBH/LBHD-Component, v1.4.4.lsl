//MBTLBA was a stupid name
string ver="DHCv1.4.4";//LBA Version
//efx
integer burning;//burning flag
integer repair;//repair timer
integer detrack;//detrack flah
integer layer;//detrack layers
integer ml;//Mouselook tracker
integer emk;//em kit
//
integer mhp=250;//Maximum HP
integer hp=mhp;//Current HP
//Positive Numbers Deal Damage
//Negative Numbers Restore Health
//Damage Multipliers: 0 = Invulnerable, 1.0 = 100% Damage, High numbers = Higher Damage
integer atcap=500;
float front=0.5;
float side=1.0;
float back=1.5;
float middle=0.1;
//Note that following modifiers multiply the final damage. So it stacks multiplicatively with the previous modifiers
float top=1.2;
float bottom=1.2;
//Directional Processor
float front_threshold=20.0;//Use positive floats, determines forward range
float back_threshold=160.0;//Use positive floats, determines backward range
float top_threshold=0.75;//How far up the Z axis should the source be to registered a top. (Positive Number)
float bottom_threshold=-0.75;//How far down the Z axis should the source be to registered a bottom hit. (Negative Number)
vector collisionmod(vector pos, vector targetPos)
{
    if(targetPos)
    {
        float trak;
        float dist=llVecDist(pos,targetPos);
        if(dist<1.0)return <0.01,0.0,0.0>;//This catches explosions which rezzes AT in the object's root position.
        else
        {
            vector fpos=(targetPos-pos)/llGetRot();
            float mod=fpos.z;
            if(mod>=top_threshold)mod=top;//Top check
            else if(mod<=bottom_threshold)
            {
                ++trak;//Chance to detrack
                mod=bottom;//Bottom check
            }
            else mod=1.0;//Else reset it to 1.0
            vector angle=<1.0,0.0,0.0>*llGetRot();
            angle.z=0.0;
            rotation targetRot=llRotBetween(llVecNorm(angle),llVecNorm(<targetPos.x,targetPos.y,pos.z>-pos));
            vector targetRotVec=llRot2Euler(targetRot)*RAD_TO_DEG;
            if(targetRotVec.z>-front_threshold&&targetRotVec.z<front_threshold)return <front*mod,trak,0.0>;
            else if(targetRotVec.z<-back_threshold||targetRotVec.z>back_threshold)return <back*mod,trak,1.0>;//chance to burn
            else return <side*mod,trak,0.0>;
        }
    }
    else return ZERO_VECTOR;
}
//Damage Processor
damage(integer amt, key id,vector pos, vector targetPos,vector tmod,string name)
{
    //Tmod Dump: Damage modifier, Did I detrack?, Did I burn?
    if(amt>atcap)amt=atcap;
    if(amt<0)//Allows the object to be healed/repaired
    {
        if(llGetTime()>1.0)//Optional healing cooldown
        {
            if(burning||detrack)
            {
                burning=0;
                detrack=0;
                llMessageLinked(-4,1,"","");
                llOwnerSay("Status Repaired");
            }
            amt*=-1.0;
            if(amt>(float)hp*0.1)amt=llRound(hp*0.1);//Optional healing cap
            hp+=amt;
            if(hp>mhp)hp=mhp;//Used to prevent overhealing
            llResetTime();
        }
        //Be sure to update the listen event code block to allow negative damage values through.
    }
    else if(amt<6)
    {
        llRegionSayTo(llGetOwnerKey(id),0,"*plink*");
        return; //Blocks micro-LBA, stop that shit
    }
    else
    {
        key oid=llGetOwnerKey(id);
        integer directional_amt;
        if(tmod==ZERO_VECTOR)tmod=collisionmod(pos,targetPos);
        directional_amt=llFloor(tmod.x*(float)amt);
        if(tmod.y>0.0&&!detrack)
        {
            if(llFrand(100.0)-amt<0.0)//roll for detrack
            {
                if(layer>1)
                {
                    llTriggerSound("9213b540-c8de-c7a6-a228-fa3569c5c6ae",1.0);
                    llOwnerSay("Tracks hit!");
                    layer=0;
                }
                else
                {
                    ++detrack;
                    list sounds=["af44ee43-b6c8-130a-161d-19282010a84e","d6190a72-9221-3b24-4d0a-a206923f63f1"];
                    llTriggerSound(llList2String(sounds,llRound(llFrand(1.0))),1.0);
                    llOwnerSay("De-tracked!");
                    if(!burning)llMessageLinked(-4,0,"","");
                    repair=0;
                }
            }
        }
        if(tmod.z>0.0&&!burning)
        {
            if(llFrand(100.0)-amt<0.0)//roll for burn
            {
                ++burning;
                list sounds=["f288bc4f-62bd-9ca1-501e-3afb42d23ef5","2caf350b-ecae-2bc4-1c27-8e7c16ab9e11"];
                llTriggerSound(llList2String(sounds,llRound(llFrand(1.0))),1.0);
                llMessageLinked(-4,2,"","");
                repair=0;
            }
        }
        if(directional_amt>1.0)
        {
            list sounds=["a6c864a1-015a-83d1-bc63-d4b2d5df8482","fd462a07-c691-585c-1c2b-63554c0a71eb","91e2c1a7-238d-b7a7-43b2-00a7fe8f371e"];
            llTriggerSound(llList2String(sounds,llRound(llFrand(2.0))),1.0);
            hp-=directional_amt;
        }
        else //Failed to do damage
        {
            llOwnerSay("Damage Blocked by Armor");
            llRegionSayTo(llGetOwnerKey(id),0,"Attack was stopped by armor.");
            return;
        }
        llOwnerSay("/me took "+(string)directional_amt+" ("+(string)amt+") damage from "+name+" by "+llKey2Name(oid));//Used to debug output.
        llRegionSayTo(oid,0,"/me took "+(string)directional_amt+" ("+(string)amt+") damage");
    }
    if(hp<1)die();
    else update();
}
string modifierstring;//This is visible so moderators can confirm vehicle attributes are within regulation.
update()//SetText
{
    string mod="\n";
    if(burning||detrack)
    {
        if(burning)mod+="[Burning] ";
        if(detrack)mod+="[Detracked]";
        if(!ml)mod+="\n Repair-in-Progress \n"+(string)((integer)repair*10)+"/100";
    }
    llSetLinkPrimitiveParamsFast(-4,[PRIM_TEXT,"[LBHD]\n "+(string)hp+" / "+(string)mhp+" HP"+mod,<0.0,0.75,1.0>,1.0,
        PRIM_DESC,"LBA.v."+ver+","+(string)hp+","+(string)mhp+","+(string)atcap+",666"+modifierstring]);
        //In order: Current HP, Max HP, Max AT accepted, Max healing accepted (Not implemented)
}
die()
{
    llRezObject("Explosion",llGetPos(),ZERO_VECTOR,ZERO_ROTATION,1);
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
boot(integer entry)
{
    modifierstring=",F-"+llGetSubString((string)front,0,2)+//Frontal modifier
        ",S-"+llGetSubString((string)side,0,2)+//Side modifier
        ",R-"+llGetSubString((string)back,0,2)+//Rear modifier
        ",T-"+llGetSubString((string)top,0,2)+//Top modifier
        ",B-"+llGetSubString((string)bottom,0,2)+//Bottom modifier
        ",M-"+llGetSubString((string)middle,0,2);//Middle Modifier
    user=llGetOwner();
    me=llGetKey();
    gen=(string)llGetObjectDetails(me,[OBJECT_REZZER_KEY]);
    if(hear)llListenRemove(hear);
    integer hex=(integer)("0x" + llGetSubString(llMD5String((string)me,0), 0, 3));
    hear=llListen(hex,"","","");
    llSetTimerEvent(1.0);//Used for auto-delete.
    update();
    if(entry)return;
    emk=(integer)("0x" + llGetSubString(llMD5String(user,0), 1, 4));
    llListen(emk,"","","emk");
}
list tracker;
default
{
    state_entry()
    {
        boot(1);
    }
    on_rez(integer p)
    {
        boot(0);
    }
    listen(integer chan, string name, key id, string message)
    {
        //[ALWAYS] USE llRegionSayTo(). Do not flood the channel with useless garbage that'll poll every object in listening range.
        if(chan==emk)
        {
            if(llGetOwnerKey(id)!=user)return;
            if(detrack)
            {
                list sounds=["62fafb58-f350-632c-c16d-8928514d52d8","47c80392-832f-8212-a42e-00437fa7ff01"];
                llTriggerSound(llList2String(sounds,llRound(llFrand(1.0))),1.0);
                detrack=0;
                if(!burning)llMessageLinked(-4,1,"","");
            }
            else
            {
                if(layer<1)++layer;
                llOwnerSay("Protected "+(string)layer+" track(s)");
            }
        }
        else
        {
            list parse=llParseString2List(message,[","],[" "]);
            if(llList2Key(parse,0)==me)//targetcheck
            {
                list data=llGetObjectDetails(id,[OBJECT_POS,OBJECT_ATTACHED_POINT,OBJECT_ROT,OBJECT_REZZER_KEY]);
                vector pos=llGetPos();
                vector targetPos=llList2Vector(data,0);
                vector tmod;
                integer f=llListFindList(tracker,[name]);
                if(f>-1)tmod=llList2Vector(tracker,f+1);
                else //Rezzer rezzer's rezzer rezzer
                {
                    f=llListFindList(tracker,[llList2Key(data,4)]);
                    if(f>-1)tmod=llList2Vector(tracker,f+1);
                }
                float amt=llList2Float(parse,-1);
                if(llFabs(amt)<666.0)
                {
                    if(llList2Integer(data,1))
                    {
                        float dist=llVecDist(targetPos,pos)-1.25;//Backtrack so we don't end up triggering the middle filter.
                        vector posfix=targetPos+<dist,0.0,0.0>*llList2Rot(data,2);//Do math
                        if(llVecDist(pos,posfix)<5.0)damage((integer)amt,id,pos,posfix,ZERO_VECTOR,name);
                            //Check offset to prevent camera-related oofs.
                            //This technically drops damage but w/e, not a huge issue.
                    }
                    else
                    {
                        if(tmod)damage((integer)amt,id,pos,targetPos,tmod,name);
                        else damage((integer)amt,id,pos,targetPos,ZERO_VECTOR,name);
                    }
                }
            }
        }
    }
    collision_start(integer c)
    {
        if(llVecMag(llDetectedVel(0))>40.0)
        {
            vector gpos=llGetPos();
            if(tracker==[])llSetTimerEvent(1.0);
            string name=llDetectedName(0);
            integer f=llListFindList(tracker,[name]);
            if(f>-1)tracker=llListReplaceList(tracker,[collisionmod(gpos,llDetectedPos(0))],f+1,f+1);
            else
            {
                if(llGetListLength(tracker)>10)tracker=llDeleteSubList(tracker,0,1);//Delete eldest entry to prevent stack-heap
                vector cmod=collisionmod(gpos,llDetectedPos(0));
                if(cmod)tracker+=[name,cmod];
            }
            //Stores data as follows: OBJECT_NAME,OBJECT_MODIFIER
            //Updates objects of the same name to the most recent.
        }
    }
    timer()
    {
        if(burning||detrack)
        {
            ml=llGetAgentInfo(user)&AGENT_MOUSELOOK;
            if(ml)repair=0;
            else if(++repair>9)
            {
                if(burning)
                {
                    list sounds=["ada6486e-81ef-667b-0a92-17f20184a7eb","fa2f0288-f012-6741-948c-da30f5cfff68","c13344d6-a9b1-3541-5f40-f0703ce97b8d","2a4d1e97-24ec-250b-ac1c-8e2e9134be26","f0fc1dc6-b4b3-f7bf-a3ce-6961845afbad"];
                    llTriggerSound(llList2String(sounds,llRound(llFrand(4.0))),1.0);
                    burning=0;
                    if(!detrack)llMessageLinked(-4,1,"","");
                    llOwnerSay("Fire is out");
                }
                else if(detrack)
                {
                    list sounds=["62fafb58-f350-632c-c16d-8928514d52d8","47c80392-832f-8212-a42e-00437fa7ff01"];
                    llTriggerSound(llList2String(sounds,llRound(llFrand(1.0))),1.0);
                    detrack=0;
                    llMessageLinked(-4,1,"","");
                    llOwnerSay("Tracks repaired");
                }
                repair=0;
                update();
            }
            if(burning)
            {
                hp-=5;
                if(hp>0)update();
                else die();
            }
        }
        if(tar(gen))return;
        llDie();
    }
}
