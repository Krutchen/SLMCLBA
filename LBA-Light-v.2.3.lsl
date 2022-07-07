//      LBA v.2.3
//  These are your configurable values. You don't really need to change anything under this except for your style of death in the die() command
integer link=LINK_THIS;//WHERE YOUR HP TEXT WILL BE DISPLAYED! DON'T FUCK UP!
integer hp;//This is your HP. It is affected by rez params, but on startup it turns 
integer maxhp=1000;//Max HP of your hitbox, yo.
integer antigrief=1;//Whether or not Antigrief is active - auto-disables if you're on a sim chain because damage source finding won't work across borders.
die()
{
    llSleep(1);
    //PUT ALL EXPLODEY SHIT AND SITBASE KILLING HOOKS IN HERE!!!!!
    //llDie();
    hp=maxhp;
    handlehp();
}
handlehp()//Updates your HP text. The only thing you should really dick with is the text display in case you want fancy text colours.
{
    if(hp<0)hp=0;
    integer t=10;
    string display="[";
    while(t)
    {
        if(hp>((10-t)*maxhp/10))display+="█";
        else display+="-";
        --t;
    }
    display+="]";
    string info="LBA.v.L."+llGetSubString((string)rev,0,3)+","+(string)hp+","+(string)maxhp;
    llSetLinkPrimitiveParamsFast(link,[PRIM_TEXT,"[LBA Light] \n ["+(string)((integer)hp)+"/"+(string)((integer)maxhp)+"] \n "+display,<1.-(float)hp/maxhp,(float)hp/maxhp,0.>,1,PRIM_LINK_TARGET,LINK_THIS,PRIM_DESC,info]);
    if(hp==0&&proc==[])die();
}
//
//
//DON'T TOUCH ANY OF THE SHIT BELOW THIS - REMEMBER, SAVE THIS IN MONO.
float rev=2.3;//Current revision number, for just making sure people know you're on version X Y Z.
list proc=[];//Damage events being processed into the buffer
list buffer=[];//This builds the message for the ownersay when you get damaged, don't touch me either
list recent=[];//List of things that have already hurt you.
list totals=[];//The combined damage from munitions, don't touch me either you fuckboy. Processed damage gets pushed into this
list blacklist=[];//List of keys that are a bunch of cock monglers, don't touch me, for one, and also this will be overwritten on blacklist communication.
integer lh;//Don't touch me
integer events=0;//How many events are happening in your processing event. 
open()
{
    llSetLinkPrimitiveParamsFast(-1,[PRIM_TEXT,"",<1,1,1>,1]);
    integer hex=(integer)("0x" + llGetSubString(llMD5String((string)myKey,0), 0, 3));//My key hex
    llListenRemove(lh);
    lh=llListen(hex,"","","");
}
key myKey;//My key! Duh!
default
{
    state_entry()
    {
        myKey = llGetKey();
        hp=maxhp;
        open();
        handlehp();
    }
    on_rez(integer n)
    {
        if(n)
        {
            myKey = llGetKey();
            llListenRemove(lh);
            open();
            hp=n;
            handlehp();
        }
    }
    changed(integer c)
    {
        if(c&CHANGED_REGION)
        {
            open();
            handlehp();
        }
    }
    listen(integer c, string n, key id, string m)
    {
        list ownerinfo=llGetObjectDetails(id,[OBJECT_OWNER,OBJECT_ATTACHED_POINT,OBJECT_REZZER_KEY,OBJECT_DESC,OBJECT_POS,OBJECT_REZ_TIME]);
        if(llList2String(ownerinfo,0)=="")return;//Munition needs to stay around for a moment so that you can gather Owner & Creator details, otherwise fuck off.
        list mes=llParseString2List(m,[","],[" "]);
        if(llList2Key(mes,0)==myKey)//First things first, am I the target?
        {
            integer no=0;
            if((key)n)no=1;
            if((string)((float)n)==n||(string)((integer)n)==n)no=1;
            if(no==1&&antigrief==0)return;
            key owner=llList2Key(ownerinfo,0);//Gets the owner key from Ownerinfo
            integer dmg=(integer)llList2Integer(mes,-1);//This is the damage, fuck you.
            if(dmg>300)dmg=300;//Basic AT cap, the 4s check should be better for catching spam attempts, allows for heavier slower hits, but we still don't want 1000 AT being done to people.
            if(dmg<-20)dmg=-20;//Flat limit on repairs to 20 per event. This should cockblock all overflow attempts as well. If you ever need more than this much per event you're being a dipshit.
            key src=id;
            integer sit=-1;
            key osrc=src;
            if(antigrief==1)//If you don't want to run this, either delete this section or set antigrief to 0
            {
                if(llListFindList(blacklist,[(string)owner])!=-1)return;
                if(no==1)
                {
                    key owner=llList2Key(ownerinfo,0);
    llOwnerSay("/me :: secondlife:///app/agent/"+(string)owner+"/about is being blacklisted for Keygen projectile usage");
    llRegionSayTo(owner,0,"/me :: You are being blacklisted for Keygen projectile usage");
                    blacklist+=(string)owner;
                    return;
                }
                integer att=llList2Integer(ownerinfo,1);
                sit=0;//Sit 0 for standing, sit 1 for seated av, sit 2 for deployable, sit 3 for close range weapon (attached & within 15m)
                string desc=llList2String(ownerinfo,3);
                integer tries=3;//We'll see if we can do 3 chains, that's pretty liberal because usually 1 or 2 will do it.
                list dl=llCSV2List(desc);
                if(att)
                {
                    if(llVecDist(llGetPos(),llList2Vector(ownerinfo,4))<=15)sit=3;
                    if(llGetAgentInfo(owner)&AGENT_ON_OBJECT)sit=1;
                }
                else
                {
                    if(llGetSubString(desc,0,5)=="LBA.v."&&llGetListLength(dl)>=3&&llList2Integer(dl,2)>0&&(integer)((string)llGetObjectDetails(id,[OBJECT_RUNNING_SCRIPT_COUNT]))>1)
                    {
                        src=id;//Is this a delpoyable?
                        sit=2;
                    }
                    else 
                    {
                        if(llGetSubString(desc,0,5)=="LBA.v."&&(integer)((string)llGetObjectDetails(id,[OBJECT_TOTAL_INVENTORY_COUNT]))>(integer)((string)llGetObjectDetails(id,[OBJECT_TOTAL_SCRIPT_COUNT])))//Kind of messy but this checks 'is direct damager a landmine'. Check if it has a LBA flag
                        {
                            list bb=llGetBoundingBox(src);//Get size, is it under 1x1x1 like a LANDMINE?
                            vector tsize=llList2Vector(bb,1)-llList2Vector(bb,0);
                            if(tsize.x<1&&tsize.y<1&&tsize.z<1)
                            {
                                string time=(string)llParseString2List(llGetSubString(llList2String(ownerinfo,5),11,-8),[":","."],[]);
                                string comp=(string)llParseString2List(llGetSubString(llGetTimestamp(),11,-8),[":","."],[]);
                                if((integer)comp-(integer)time>5)//Does it have t:####?
                                {
                                    tries=0;
                                    n+=" @"+time;
                                    desc="";
                                }
                            }
                        }
                        if(tries)
                        {
                            @srcfind;//Jumps back here for iterations if the check didn't get a valid source
                            key src2=llList2Key(ownerinfo,2);//Src2 is the last rezzer key
                            integer shortcut=llListFindList(recent,[src2]);
                            if(shortcut==-1)
                            {
                                ownerinfo=llGetObjectDetails(src2,[OBJECT_DESC,OBJECT_ATTACHED_POINT,OBJECT_REZZER_KEY,OBJECT_POS,OBJECT_RUNNING_SCRIPT_COUNT,OBJECT_SIT_COUNT,OBJECT_ROOT,OBJECT_REZ_TIME]);
                                if(llList2Key(ownerinfo,6)!=src2)
                                {
                                    ownerinfo=llListReplaceList(ownerinfo,[llList2Key(ownerinfo,6)],3,3);
                                    jump srcfind;
                                }
                                if(llList2Vector(ownerinfo,3)==ZERO_VECTOR)src=src2;
                                desc=llList2String(ownerinfo,0);
                                if(llGetSubString(desc,0,5)=="LBA.v."&&(integer)((string)llGetObjectDetails(src2,[OBJECT_TOTAL_INVENTORY_COUNT]))>(integer)((string)llGetObjectDetails(src2,[OBJECT_TOTAL_SCRIPT_COUNT])))//Kind of messy but this checks 'is direct damager a landmine'. Check if it has a LBA flag
                                {
                                    list bb=llGetBoundingBox(src2);//Get size, is it under 1x1x1 like a LANDMINE?
                                    vector tsize=llList2Vector(bb,1)-llList2Vector(bb,0);
                                    if(tsize.x<1&&tsize.y<1&&tsize.z<1)
                                    {
                                        string time=(string)llParseString2List(llGetSubString(llList2String(ownerinfo,7),11,-8),[":","."],[]);
                                        string comp=(string)llParseString2List(llGetSubString(llGetTimestamp(),11,-8),[":","."],[]);
                                        if((integer)comp-(integer)time>5)//Does it have t:####?
                                        {
                                            tries=0;
                                            n+=" @"+time;
                                            desc="";
                                        }
                                    }
                                }
                                if(src!=src2)
                                {
                                    att=llList2Integer(ownerinfo,1);//Is the rezzer attached? If so that's your source
                                    if(!att)//Otherwise check their info
                                    {
                                        //Does this have a valid LBA description and more than one script? Then it's a deployable and you can decide that's your source.
                                        list dl=llCSV2List(desc);
                                        if(llGetSubString(desc,0,5)=="LBA.v."&&llGetListLength(dl)>=3&&llList2Integer(dl,2)>0&&llList2Integer(ownerinfo,4)>1)
                                        {
                                            src=src2;
                                            sit=2;
                                        }
                                        else desc="";
                                    }
                                    else 
                                    {
                                        if(llGetAgentInfo(owner)&AGENT_ON_OBJECT)sit=1;
                                        src=src2;
                                        desc="";
                                    }
                                    if(llList2Vector(ownerinfo,3)==ZERO_VECTOR)tries=0;
                                    if(llList2Integer(ownerinfo,5)>0)
                                    {
                                        if(sit!=2)sit=1;
                                        src=src2;
                                        tries=0;
                                    }
                                    if(src!=src2&&tries-->0)jump srcfind;
                                }
                            }
                            else src=llList2Key(recent,shortcut);
                        }
                    }
                }
            }
            string srcn=llKey2Name(src);
            integer tf=llListFindList(totals,[owner]);
            if(tf==-1)totals+=[owner,dmg];
            else totals=llListReplaceList(totals,[llList2Integer(totals,tf+1)+dmg],tf+1,tf+1);
            integer rf=llListFindList(recent,[owner,src]);
            if(rf==-1)recent+=[owner,src,n,dmg,llGetTime(),sit];
            else 
            {
                integer new=llList2Integer(recent,rf+3)+dmg;
                recent=llListReplaceList(recent,[new],rf+3,rf+3);
                if(antigrief)
                {
                    integer val=150;
                    integer nsit=llList2Integer(recent,rf+5);
                    if(sit!=nsit&&nsit==0)
                    {
                        nsit=sit;
                        recent=llListReplaceList(recent,[sit],rf+5,rf+5);
                    }
                    sit=nsit;
                    if(nsit>0)val=300;
                    if(new>val)
                    {
                        if(tf==-1)tf=llListFindList(totals,[owner]);
                        integer tdamage=llList2Integer(totals,tf+1);
                        llOwnerSay("/me :: secondlife:///app/agent/"+(string)owner+"/about has exceeded "+(string)val+" AT / 4s using "+llKey2Name(src)+" with "+(string)new+" total damage.
    This avatar has sourced "+(string)tdamage+" before being blacklisted.");
                        llRegionSayTo(owner,0,"/me :: You have exceeded "+(string)val+" / 4s using "+llKey2Name(src)+" with "+(string)new+" total damage.
    You avatar has sourced "+(string)tdamage+" before being blacklisted.");
                        blacklist+=(string)owner;
                        hp+=tdamage;
                        if(hp<=0)hp=0;
                        if(hp>=maxhp)hp=maxhp;
                        handlehp();
                        llListReplaceList(recent,[],rf,rf+5);
                        integer pf=llListFindList(proc,[owner,llKey2Name(src)]);
                        proc=llListReplaceList(proc,[],pf,pf+5);
                        return;
                    }
                }
            }
            if(hp<=0)return;
            integer pf=llListFindList(proc,[owner,srcn,n]);
            if(pf==-1)proc+=[owner,srcn,n,dmg,1,sit];
            else
            {
                integer tdmg=llList2Integer(proc,pf+3)+dmg;
                integer hits=llList2Integer(proc,pf+4)+1;
                proc=llListReplaceList(proc,[tdmg,hits],pf+3,pf+4);
            }
            ++events;//Adds to events
            if(events==1)llSetTimerEvent(1);//On the first event, the processing countdown/timer gets started.
            hp-=dmg;
            if(hp>=maxhp)hp=maxhp;
            handlehp();
        }
    }
    timer()
    {
        events=0;
        if(proc)
        {
            integer buffers=(llGetListLength(proc)+1)/6;
            while(buffers)
            {
                key owner=llList2Key(proc,0);
                string own="secondlife:///app/agent/"+(string)owner+"/about";
                string srcn=llList2Key(proc,1);
                string objn=llList2String(proc,2);
                integer dmg=llList2Integer(proc,3);
                integer hits=llList2Integer(proc,4);
                integer sit=llList2Integer(proc,5);
                proc=llListReplaceList(proc,[],0,5);
                if(dmg>0)
                {
                    string st;//Sit 0 for standing, sit 1 for seated av, sit 2 for deployable, sit 3 for close range weapon (attached & within 15m)
                    if(sit==1)st="vehicle weapon";
                    if(sit==2)st="deployable";
                    if(sit==3)st="cqc weapon";
                    buffer+="Hit by "+(string)own+" with ";
                    if(srcn!=""&&srcn!=objn&&srcn!=llKey2Name(owner))buffer+="'"+objn+"' from "+st+" '"+srcn+"'";
                    else buffer+=st+" '"+objn+"'";
                    if(hits>1)buffer+=" "+(string)hits+" times";
                    buffer+=" for "+(string)dmg+" damage";
                }
                else if(dmg<0)
                {
                    if(hits==1)buffer+="Repaired by "+(string)own+" with '"+objn+"' for "+(string)dmg+" damage";
                    else buffer+="Repaired by "+(string)own+" with '"+objn+"' "+(string)hits+" times for "+(string)dmg+" damage";
                }
                buffers--;
                if(buffers>0)buffer+=" \n";
            }
            if(buffer)llOwnerSay("\n"+(string)buffer);
            buffer=[];
            handlehp();
        }
        if(recent)
        {
            integer buffers=(llGetListLength(recent)+1)/5;
            integer i=0;
            while(i<buffers)
            {
                integer plus=i*6;
                float time=llList2Float(recent,plus+4);
                if(llGetTime()-time>=4)recent=llListReplaceList(recent,[],0,5);
                ++i;
            }
        }
        if(proc==[]&&recent==[])llSetTimerEvent(0);
    }
    collision_start(integer n)
    {
        while(n--)
        {
            integer type=llDetectedType(n);
            if(type&0x2&&~type&0x1&&llVecMag(llDetectedVel(n))>10)--hp;
        }
        handlehp();
    }
}
//CHANGELOG ----
//2.06 - Release
//2.06 -> 2.07 - 
//+Added integer neghex1, neghex2 so the script won't have to constantly recalculate reghex*-1/-2
//+Added key myOwner, myKey so it won't have to keep looking for llGetOwner/llGetKey on events
//@ 135,- Fixed first channel check in listener to be == instead of =
//@ 121 - Fixed HP display being lost on region crossing, only showing back up when damage taken.
//2.07 -> 2.1
//+Added list recent, float cleanup
//+Updated collision handling, handlehp(); after all collisions are processed, fors switched to whiles
//2.1 -> 2.2
//+Checks to see if whats damaging it has damaged it before, if the damage is over 1 and not attached
//+If attached, checks if the owner is actually aiming at the hitbox with a 2m margin of error.
//2.1 -> 2.21
//+I FUCKED UP, THE 2M MARGIN OF ERROR DIDN'T TAKE ROTATIONS INTO ACCOUNT LOL
//+This has that fixed, I blame tired scripting and 50 hour work weeks :(
//+Thank jakobbischerk for finding this by trying to repair my barbed wire of all things
//2.21 -> 2.22
//+Negative integer overflow bug fixed, now clamps your repair cap so people can't instakill your shit.
//2.22 -> 2.3
//+Removed Blackbox support, very ancient code, will be redone sometime in the future.
//+Reworked anti-grief, recent list no longer flat out rejects damage for things found, instead used in anti-grief
//  Anti-Grief will now collect data over several seconds instead of just in that specific event
//  Rezzer Key chaining will now be used to get the rezzer
//  Rezzers that have a complete LBA description of (LBA.v.,hp,maxhp) and more than 1 script will be considered to be a valid rezzer
//  Recents list will now be cleaned per entry by first time damage was applied. recent+=[owner,src,n,dmg,llGetTime(),sit]; & total+=[owner,damage], time for cleaning recent is 4s
//  Blacklisting now triggers on 150 AT(Infantry)/4s 300 AT(Seated)/4s
//  Totals list will track an avatars TOTAL DAMAGE over the lifetime of the vehicle.
//  For the sake of the antigrief functioning, PROC has to be cleared before it can die. But other than that, damage is now processed when you recieve it and not with a 1s proc delay.
//  Also has lazy namespace dropping, if it's just a key or a float/integer it gets dropped because that's baby grief, if antigrief = 1 it blacklists
//  if((key)n)return;
//  if ((string)((float)n)==n||(string)((integer)n)==n)return;
