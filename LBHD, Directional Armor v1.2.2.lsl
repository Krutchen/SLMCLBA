/*[IMPORTANT] This requires vehicles/deployables to be aligned properly down the X-axis in order to function properly. Objects which require a rotational offset to function will need to be adjusted.
The publically issued copy of this code has the following settings disabled:
- Object healing
- Collision Damage
- Line-of-Sight Requirement
- Blocking of micro-LBA.


These settings may make the system incompatible with certain rulesets and equipment. However, notes and code for switching these features on and off is present for those who wish to use them.

Do [not] use this as your default LBA parser as it would not be optimized for use in equipment that has no intention of benefitting from directional damage resistances. Use a standard LBA core or a different LBA parser instead.

[CREDITS]
datbot Resident/Criss Ixtar - For the initial proof of concept and idea.
Dread Hudson - Establishing the standard LBA format.
Secondary Lionheart - Method and integration

Note: This should be considered an extention of LBA Slim and possesses limited to no anti-grief.
*/
integer mhp=100;//Maximum HP
integer hp=mhp;//Current HP
//Positive Numbers Deal Damage
//Negative Numbers Restore Health
//Damage Multipliers: 0 = Invulnerable, 1.0 = 100% Damage, High numbers = Higher Damage
integer atcap=50;
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
float height_threshold=1.5;//How far up/down the Z axis should the source be to registered a top or bottom hit. Should be roughly half the vehicle's height.
integer lbapos(float dmg,vector pos, vector targetPos)
{
    //We'll use numbers greater than -20.0 but less than 20.0 as our forward direction. This means that numbers less -160.0 and greater than 160.0 are our rear. This will need to be changed based on vehicle size and shape. This will not work on Rho because she's too fat.
    if(targetPos)
    {
        float dist=llVecDist(pos,targetPos);
        if(dist<1.0)return llFloor(dmg*middle);//This catches explosions which rezzes AT in the object's root position.
        else
        {
            float mod=targetPos.z-pos.z;
            if(llFabs(mod)>=height_threshold)//Determines top/bottom hits
            {
                if(mod>0.0)mod=top;//Top check
                else mod=bottom;//Bottom check
            }
            else mod=1.0;//Else reset it to 1.0
            rotation targetRot=llRotBetween(<1.0,0.0,0.0>*llGetRot(),llVecNorm(<targetPos.x,targetPos.y,pos.z>-pos));
            vector targetRotVec=llRot2Euler(targetRot)*RAD_TO_DEG;
            //You can optimize this further by doing angles in radians as opposed to degrees. This is written in degrees so its easier to read/follow
            //For those who care to do so, here's the formulas: [Degrees = (Radians*180.0)/PI] or [Radians = (Degrees*PI)/180.0]
            //Degrees should be returned in values between -180.0 and 180.0
            //llSay(0,"Angle: "+(string)trotvec.z+"| Pos offset: "+(string)(tpos-pos)+" | RotBetween: "+(string)trot);//Debug output
            //Now we use the Z-Axis to calculate the horizonal directions.
            //Note that vertical direction isn't factored, only the horizonal angle. This the vehicle is sliced up like a pie and damage will be based on how far and which direction from the center the projectile strikes when it hits the top or bottom.
            if(targetRotVec.z>-front_threshold&&targetRotVec.z<front_threshold)//Front
                return llFloor((dmg*front)*mod);
            else if(targetRotVec.z<-back_threshold||targetRotVec.z>back_threshold)//Back
                return llFloor((dmg*back)*mod);
            else //If it didn't hit any previous angles, the only thing left to hit is the sides.
                return llFloor((dmg*side)*mod);
        }
    }
    else return 0;//If a no vector is returned, do not process damage.
}
//Damage Processor
damage(integer amt, key id,vector pos, vector targetPos)
{
    /*if(amt<0)//Allows the object to be healed/repaired
    {
        if(llGetTime()>1.0)//Optional healing cooldown
        {
            if(amt>hp*0.1)amt=hp*0.1;//Optional healing cap
            hp-=amt;
            llResetTime();
        }
        //Be sure to update the listen event code block to allow negative damage values through.
    }*/
    /*else if(amt<6)return; //Blocks micro-LBA
    else*/
    {
        integer directional_amt=lbapos(amt,pos,targetPos);
        if(directional_amt)hp-=directional_amt;
        else
        {
            //llRegionSayTo(llGetOwnerKey(id),0,"/me Armor deflected the damage!");//cheeki breeki
            return;
        }
        //llSay(0,"/me took "+(string)amt+" LBA/LBB damage!");//Used to debug output.
    }
    if(hp<1)die();
    else
    {
        if(hp>mhp)hp=mhp;//Used to prevent overhealing
        update();
    }
}
//Line-of-Sight Check
integer los(vector start, vector target)
{
    list ray=llCastRay(target,start,[RC_REJECT_TYPES,RC_REJECT_AGENTS,RC_DATA_FLAGS,RC_GET_ROOT_KEY,RC_MAX_HITS,1]);
    key hit=llList2Key(ray,0);//Debug
    if(llKey2Name(hit))
    {
        //llSay(0,llKey2Name(hit));//Debug
        if(hit==me)return 1;
        else return 0;//Object in way
    }
    else
    {
        if(llList2Vector(ray,1)==ZERO_VECTOR)return 1;
        else return 0;//Land in way
    }
}
string modifierstring;//This is visible so moderators can confirm vehicle attributes are within regulation.
update()//SetText
{
    llSetLinkPrimitiveParamsFast(-4,[PRIM_TEXT,"[LBHD]\n "+(string)hp+" / "+(string)mhp+" HP",<0.0,0.75,1.0>,1.0,
        PRIM_DESC,"LBA.v.LBHD"+(string)hp+","+(string)mhp+","+(string)atcap+",999"+modifierstring]);
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
            vector pos=llGetPos();
            vector targetPos=tar(id);
            //if(los(pos,tpos))//Enforces LBA line-of-sight
            {
                float amt=llList2Float(parse,-1);
                //if(llFabs(amt)<666.0)damage((integer)amt,id,pos,tpos);//Use this code to allow object healing, Blocks overflow attempts
                if(amt>0)damage((integer)amt,id,pos,targetPos);//Use this code if you do not wish to support healing
            }
            //else llRegionSayTo(llGetOwnerKey(id),0,"/me Armor deflected the damage!");//cheeki breeki
        }
    }
    /*collision_start(integer c)//Enable this block if you want to support legacy collisions.
    {
        if(llVecMag(llDetectedVel(0))>40.0)
        {
            hp-=c;
            if(hp<1)die();//llDie();
            else update();
        }
    }*/
    timer()//Auto-deleter. Will kill object if avatar leaves the region or spawning object is removed.
    {
        if(tar(gen))return;
        llDie();
    }
}
