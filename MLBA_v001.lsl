/*
Module LBA v001 by Shaxei(datbot)

In order to use this armour system your physbase should 
listen on channel -255  for messages from the physbase
Death commands start with "die," followed by a number 
representing the cause of death which may be sent to 
the wreckage to induce different sets of effects.
the cause being '2' means ammo explosion, 
'1' means the fuel/engine burning down.
Upon recieving the command "crewdie" the sitbase should eject and kill 
the user, since this means the crew of the vehicle has been killed.
The physbase's core script should also send this script a link message 
with the text 'newcrew' when a new user sits on the vehicle, to reset 
the crew's health pool lest they die on the next hit.

If you wish to see particle effects for engine damage and ammo cookoff then
your physbase should include two upright prims where the engine is
located called 'enginefx' and 'enginefx2' for engine fire/smoke particles
and one where an ammo fire would erupt from (commander's hatch) called 'ammofx'

If your vehicle re-rezzes its physbase or wants to rez it with specific health values
then it should first set its own description as follows:

"LBA.v.,"+(string)enginehealth+","+(string)transhealth+","+(string)crewhealth+","+(string)ammohealth
e.g.
LBA.v.,50,40,30,30

This system was designed to be used in vehicles that retain their physbases
when the user disembarks (or is ejected) so that they can continue to burn
and have armour. If you don't plan on having your vehicles work this way,
it's recommended to have your vehicle continue to burn down after de-rezzing
its physbase if the engine's health is below half or the ammo's health is 
below 20%.


Adjust everything below to match your vehicle. 
Note that this should be set to your EFFECTIVE armour thicknesses 
since in the hit angle calculations you are always represented as a cuboid. 
(aka 100mm of armour angled at 45 degrees should be written below as 200mm of armour)
*/
float frontarmour=0.5; //Effective armour thicknesses in metres (0.5=500mm)
float sidearmour=0.2;
float reararmour=0.06;
float toparmour=0.06;
float bottomarmour=0.07;

vector enginepos=<-2,0,0>; //the engine's position relative to the root
float enginehealthmax=70; 
/*Keep in mind when setting the above that the engine catches fire and essentially 
dooms the vehicle to burning down unless repaired when it drops below half its max*/
vector transpos=<-2.5,0,0>;
float transhealthmax=20;

vector ammopos=<-0.5,0,0>;
float ammohealthmax=30;

vector crewpos=<1,0,0>;
float crewhealthmax=50;

//Add your own particle effects for engine smoke, engine fire, and ammo cook-off in here 
//(optional, only use if you have the particle emitter prims set up)
enginesmoke()
{
        llLinkParticleSystem(enginefx,[]);
        llLinkParticleSystem(enginefx2,[]);
}

enginefire()
{
        llLinkParticleSystem(enginefx,[]);
        llLinkParticleSystem(enginefx2,[]);
}

ammofire()
{
    llLinkParticleSystem(ammofx,[]);
}

//NO TOUCHING ANYTHING BELOW HERE FAM (unless it specifically says you can uncomment it for features/debugging)

vector siz;
float hitangl;
vector lochit;
vector lochitN;
rotation rothit;
vector hn;
float anglehitat;
float armour;
list recents;
integer i;
key sitbase;
float pen;
string mesg;
string hitface;
float mofs;

integer ammofx;
integer enginefx;
integer enginefx2;

float crewhealth;
float transhealth;
float enginehealth;
float ammohealth;

ref()
{
    llSetObjectDesc("LBA.v.MLBA,"+(string)enginehealth+","+(string)transhealth+","+(string)crewhealth+","+(string)ammohealth);
    llSetText(
    "E: "+(string)(llRound(enginehealth)%90000)+"/"+(string)llRound(enginehealthmax)+" T: "+(string)(llRound(transhealth)%90000)+"/"+(string)llRound(transhealthmax)+
    "\nC: "+(string)(llRound(crewhealth)%90000)+"/"+(string)llRound(crewhealthmax)+" A: "+(string)(llRound(ammohealth)%90000)+"/"+(string)llRound(ammohealthmax),<1,1,1>,1);
    //I'll clean all of this shit up later
    if(enginehealth<0 || ammohealth<0){
        llLinkParticleSystem(-1,[]);
        llSetText("",<0,0,0>,0);
        if(ammohealth<0){
            llRegionSayTo(sitbase,-255,"die,2");
        }else{
            llRegionSayTo(sitbase,-255,"die,1");
        }
        llSleep(.2);llDie();
    }else if(crewhealth<0){
        llRegionSayTo(sitbase,-255,"crewdie");
    }
    if(enginehealth<enginehealthmax*.5||ammohealth<ammohealthmax*.2){
        if(enginehealth<enginehealthmax*.5){
            enginefire();
            llTriggerSound("ce357b58-03aa-1526-58e5-2bb81b8f8d81",1);
        }else{
            llLinkParticleSystem(enginefx,[]);
            llLinkParticleSystem(enginefx2,[]);
        }
        if(ammohealth<ammohealthmax*.2){
            ammofire();
            llTriggerSound("ce357b58-03aa-1526-58e5-2bb81b8f8d81",1);
        }else{
            llLinkParticleSystem(ammofx,[]);
        }
        llSetTimerEvent(3);
    }else{
        if(enginehealth<enginehealthmax*.7){
            llTriggerSound("69f8d03b-9c1f-7014-2a8e-c75c0022232a",1);
            enginesmoke();
        }else{
            llLinkParticleSystem(enginefx,[]);
            llLinkParticleSystem(enginefx2,[]);
        }
        llLinkParticleSystem(ammofx,[]);
        llSetTimerEvent(0);
    }
}

integer hcd;
default
{
    touch_start(integer ndtt)
    {
        if(llGetUnixTime()-hcd>5){
            hcd=llGetUnixTime();
            llRegionSayTo(llDetectedKey(0),0,
                "This is an LBA-based armour system that simulates effective armour thickness and module damage
                Effective penetration of a projectile = damage*0.012*(1-(angle-of-attack/90))
                e.g. 50LBA rocket hitting at 45 degrees = 300mm, hitting at 0 degrees = 600mm
                If penetration>armour of the side it hit then damage is delivered to the crew, ammo, engine, and transmission within a 5m radius
                the closer to the hit position, the more damage done to each module up to a maximum of the round's full damage
                If the crew dies, the tank's user is ejected and killed. If the ammo is destroyed, the tank cooks and explodes.
                If the engine is destroyed, the tank burns down and is destroyed. If the transmission is destroyed, the tank cannot move.");
                llRegionSayTo(llDetectedKey(0),0,"
                Specifics for this tank:
                Front armour:"+(string)llRound(frontarmour*1000)+"mm
                Side armour: "+(string)llRound(sidearmour*1000)+"mm
                Rear armour: "+(string)llRound(reararmour*1000)+"mm
                Top armour: "+(string)llRound(toparmour*1000)+"mm
                Bottom armour: "+(string)llRound(bottomarmour*1000)+"mm
                Engine position: "+(string)enginepos+"m
                Engine maxhealth: "+(string)llRound(enginehealthmax)+"LBA
                Trans position: "+(string)transpos+"m
                Trans maxhealth: "+(string)llRound(transhealthmax)+"LBA
                Ammo position: "+(string)ammopos+"m
                Ammo maxhealth: "+(string)llRound(ammohealthmax)+"LBA
                Crew position: "+(string)crewpos+"m
                Crew maxhealth: "+(string)llRound(crewhealthmax)+"LBA"
            );
        }
    }
    link_message(integer sndr,integer val,string txt,key idd)
    {
        if(txt=="newcrew"){crewhealth=crewhealthmax;ref();}
    }
    on_rez(integer rz)
    {
        sitbase=llList2Key(llGetObjectDetails(llGetKey(),[OBJECT_REZZER_KEY]),0);
        string d=llList2String(llGetObjectDetails(sitbase,[OBJECT_DESC]),0);
        if(llGetListLength(llCSV2List(d))==5){ //if my sitbase's description stored the last physbase's values then take and use them
            enginehealth=llList2Float(llCSV2List(d),1);
            transhealth=llList2Float(llCSV2List(d),2);
            crewhealth=llList2Float(llCSV2List(d),3);
            ammohealth=llList2Float(llCSV2List(d),4);
        }
        list bb=llGetBoundingBox(llGetKey());
        siz=llList2Vector(bb,1)-llList2Vector(bb,0);
        siz*=.5;
        llListen((integer)("0x" + llGetSubString(llMD5String((string)llGetKey(),0), 0, 3)), "","","");
        ref();
        if(transhealth<=0){llMessageLinked(LINK_THIS,0,"immobile","");} //if I was rezzed with no transmission health then be immobile
    }
    state_entry()
    {
        enginehealth=enginehealthmax;
        transhealth=transhealthmax;
        ammohealth=ammohealthmax;
        crewhealth=crewhealthmax;
        for(i=1;i<llGetNumberOfPrims()+1;i++){
            if(llGetLinkName(i)=="enginefx"){enginefx=i;}
            if(llGetLinkName(i)=="enginefx2"){enginefx2=i;}
            if(llGetLinkName(i)=="ammofx"){ammofx=i;}
        }
    }
    collision_start(integer ndt)
    {
        for(i=0;i<ndt;i++){
            if(llVecMag(llDetectedVel(i))>50){
                lochit=(llDetectedPos(i)-llGetPos())/llGetRot();
                rothit=llRotBetween(<1,0,0>,llDetectedVel(i))/llGetRot();
                recents=[llDetectedKey(i),lochit,rothit]+llListReplaceList(recents,[],9,11);
            }
        }
    }
    listen(integer i, string s, key k, string m)
    {
        list l = llCSV2List(m);
        string target = llList2String(l,0);
        integer dmg = (integer)llList2String(l,1);
        if(target == (string)llGetKey())
        {
            if(dmg>0){
                llResetTime();
                key rzr=llList2Key(llGetObjectDetails(k,[OBJECT_REZZER_KEY]),0);
                if(llListFindList(recents,[k])!=-1){
                    lochit=llList2Vector(recents,llListFindList(recents,[k])+1);
                    rothit=llList2Rot(recents,llListFindList(recents,[k])+2);
                }else if(llListFindList(recents,[rzr])!=-1){
                    lochit=llList2Vector(recents,llListFindList(recents,[rzr])+1);
                    rothit=llList2Rot(recents,llListFindList(recents,[rzr])+2);
                }else{
                    lochit=llVecNorm( (llList2Vector(llGetObjectDetails(k,[OBJECT_POS]),0)-llGetPos())/llGetRot() );
                    //rothit=llRotBetween(<-1,0,0>,lochit);
                    rothit=ZERO_ROTATION;
                }
                
                lochitN=<lochit.x/siz.x,lochit.y/siz.y,lochit.z/siz.z>;
                if(llFabs(lochitN.x)>llFabs(lochitN.y)&&llFabs(lochitN.x)>llFabs(lochitN.z)){
                    if(lochitN.x>0){hn=<1,0,0>;armour=frontarmour;hitface="F";lochit.x=siz.x;}else{hn=<-1,0,0>;armour=reararmour;hitface="B";lochit.x=-siz.x;}
                }else if(llFabs(lochitN.y)>llFabs(lochitN.z)){
                    armour=sidearmour;
                    if(lochitN.y>0){hn=<0,1,0>;hitface="L";lochit.y=siz.y;}else{hn=<0,-1,0>;hitface="R";lochit.y=-siz.y;}
                }else{
                    if(lochitN.z>0){hn=<0,0,1>;armour=toparmour;hitface="T";lochit.z=siz.z;}else{hn=<0,0,-1>;armour=bottomarmour;hitface="U";lochit.z=-siz.z;}
                }
                
                if(rothit!=ZERO_ROTATION){
                    anglehitat=llAngleBetween(ZERO_ROTATION,llRotBetween(hn,<-1,0,0>*rothit))/DEG_TO_RAD;
                    pen=(dmg*0.012*(1-(anglehitat*.011)))-armour;
                }else{
                    pen=(dmg*0.012)-armour;
                }
                
                if(pen>0){
                    mesg+=(string)dmg+" basedmg: Penetrated "+hitface+" side ("+(string)llRound(dmg*12)+"mm*"+(string)llRound(anglehitat)+"°="+(string)llRound(pen*1000)+"mm>"+(string)llRound(armour*1000)+"mm)";
                    
                    //mofs=llVecDist(<1,0,0>*rothit,llVecNorm(enginepos-lochit))*1.5;
                    mofs=llVecDist(lochit+<1,0,0>*rothit,enginepos)*.2;
                    if(mofs<1){
                        enginehealth-=dmg*(1-mofs);
                        if(enginehealth<0 && enginehealth>-9000){mesg+="Engine:destroyed ";enginehealth=-90000;
                        }else{mesg+="Engine:"+(string)llRound(enginehealth)+"/"+(string)llRound(enginehealthmax)+"hp(-"+(string)llRound(dmg*(1-mofs))+") ";}
                    }
                    mofs=llVecDist(lochit+<1,0,0>*rothit,transpos)*.2;
                    if(mofs<1){
                        transhealth-=dmg*(1-mofs);
                        if(transhealth<0 && transhealth>-9000){mesg+="Trans:destroyed ";transhealth=-90000;llTriggerSound("e9b5b4a7-bcb7-58ff-e831-47e9ceeda248",1);llMessageLinked(LINK_THIS,0,"immobile","");
                        }else if(transhealth>-9000){mesg+="Trans:"+(string)llRound(transhealth)+"/"+(string)llRound(transhealthmax)+"hp(-"+(string)llRound(dmg*(1-mofs))+") ";}
                    }
                    mofs=llVecDist(lochit+<2,0,0>*rothit,ammopos)*.2;
                    if(mofs<1){
                        ammohealth-=dmg*(1-mofs);
                        if(ammohealth<0 && ammohealth>-9000){mesg+="Ammo:destroyed ";ammohealth=-90000;
                        }else if(ammohealth>-9000){mesg+="Ammo:"+(string)llRound(ammohealth)+"/"+(string)llRound(ammohealthmax)+"hp(-"+(string)llRound(dmg*(1-mofs))+") ";}
                    }
                    mofs=llVecDist(lochit+<2,0,0>*rothit,crewpos)*.2;
                    if(mofs<1){
                        crewhealth-=dmg*(1-mofs);
                        if(crewhealth<0 && crewhealth>-9000){mesg+="Crew:killed ";crewhealth=-90000;
                        }else if(crewhealth>-9000){mesg+="Crew:"+(string)llRound(crewhealth)+"/"+(string)llRound(crewhealthmax)+"hp(-"+(string)llRound(dmg*(1-mofs))+") ";}
                    }
                    
                    //llOwnerSay("Succ Proc time: "+(string)llGetTime()); //debugging message, tell me how long we took to process this damage
                    llRegionSayTo(llGetOwnerKey(k),0,mesg);
                    llWhisper(0,"damage recieved:\n"+mesg);
                    //llRegionSayTo(sitbase,-255,"dmg,"+(string)lochitN+",0"); //Uncomment to send the relative hit position to the sitbase, for damage decals
                    llTriggerSound(llList2String(["32036145-8205-d4a4-8518-3d7f9f5de0d5","b0820b49-3ea6-b7b7-5a27-cfaff169427c","3977dd91-ad56-6b8e-e5cb-75fb817aaba1"],llFloor(llFrand(3))),1);
                }else{
                    mesg+=(string)dmg+" basedmg: Didn't penetrate "+hitface+" side ("+(string)llRound(dmg*12)+"mm*"+(string)llRound(anglehitat)+"°="+(string)llRound(pen*1000)+"mm<"+(string)llRound(armour*1000)+"mm)";
                    llRegionSayTo(llGetOwnerKey(k),0,"\n"+mesg);
                    //llWhisper(0,"damage recieved:\n"+mesg);
                    if(dmg>4){
                        //llRegionSayTo(sitbase,-255,"dmg,"+(string)lochitN+",1"); //Uncomment to send the relative hit position to the sitbase, for damage decals
                        llTriggerSound(llList2String(["513bf948-b2b8-fe36-0064-fc5a7f58fd52","60bda7e2-56e2-7031-6a8a-a945ee1e1c6b","72711778-7eb3-4608-3d86-9bc1aee2f54a"],llFloor(llFrand(3))),1);
                    }else{
                        llTriggerSound("34b809cf-a833-d433-911d-b0d914d82260",1);
                    }
                }
            }else{
                ammohealth-=dmg/3;
                if(ammohealth>ammohealthmax){ammohealth=ammohealthmax;}
                enginehealth-=dmg/3;
                if(enginehealth>enginehealthmax){enginehealth=enginehealthmax;}
                if(transhealth<0){transhealth=0;}
                transhealth-=dmg/3;
                if(transhealth>transhealthmax){transhealth=transhealthmax;llMessageLinked(LINK_THIS,0,"mobile","");} //Mobilize on the transmission being fully repaired
            }
            ref();
        }
    }
    timer()
    {
        if(enginehealth<enginehealthmax*.5){
            enginehealth-=1;
            if(llVecDist(enginepos,ammopos)<10){ammohealth-=(10-llVecDist(enginepos,ammopos))*.1;}
            if(llVecDist(enginepos,crewpos)<10){crewhealth-=(10-llVecDist(enginepos,crewpos))*.1;}
            enginefire();
            llTriggerSound("ce357b58-03aa-1526-58e5-2bb81b8f8d81",1);
        }else{
            llLinkParticleSystem(enginefx,[]);llLinkParticleSystem(enginefx2,[]);
        }
        if(ammohealth<ammohealthmax*.2){
            ammohealth-=1;
            if(llVecDist(enginepos,ammopos)<10){enginehealth-=(10-llVecDist(enginepos,ammopos))*.1;}
            if(llVecDist(crewpos,ammopos)<10){crewhealth-=(10-llVecDist(enginepos,crewpos))*.1;}
            ammofire();
            llTriggerSound("ce357b58-03aa-1526-58e5-2bb81b8f8d81",1);
        }else{
            llLinkParticleSystem(ammofx,[]);
        }
        llSetObjectDesc("LBA.v.,"+(string)enginehealth+","+(string)transhealth+","+(string)crewhealth+","+(string)ammohealth);
        llSetText(
        "E: "+(string)(llRound(enginehealth)%90000)+"/"+(string)llRound(enginehealthmax)+" T: "+(string)(llRound(transhealth)%90000)+"/"+(string)llRound(transhealthmax)+
        "\nC: "+(string)(llRound(crewhealth)%90000)+"/"+(string)llRound(crewhealthmax)+" A: "+(string)(llRound(ammohealth)%90000)+"/"+(string)llRound(ammohealthmax),<1,1,1>,1);
        if(enginehealth>enginehealthmax*.5&&ammohealth>ammohealthmax*.2){
            llSetTimerEvent(0);llLinkParticleSystem(-1,[]);
        }else if(enginehealth<=0 || ammohealth<=0){
            llLinkParticleSystem(-1,[]);
            llSetText("",<0,0,0>,0);
            if(ammohealth<=0){
                llRegionSayTo(sitbase,-255,"die,2");
            }else{
                llRegionSayTo(sitbase,-255,"die,1");
            }
            llSleep(.2);llDie();
        }else if(crewhealth<0){
            llRegionSayTo(sitbase,-255,"crewdie");
        }
    }
}
