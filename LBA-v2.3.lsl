//      LBA v.2.23
//  These are your configurable values. You don't really need to change anything under this except for your style of death in the die() command
integer link=LINK_THIS;//WHERE YOUR HP TEXT WILL BE DISPLAYED! DON'T FUCK UP!
integer hp;//This is your HP. It is affected by rez params, but on startup it turns 
integer maxhp=1000;//Max HP of your hitbox, yo.
integer setupmessage=1;//This will enable state_entry AT cap help text.
integer antigrief=1;//Whether or not Antigrief is active
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
    integer t=10;
    string display="[";
    while(t)
    {
        if(hp>((10-t)*maxhp/10))display+="█";
        else display+="-";
        --t;
    }
    display+="]";
    string info="LBA.v."+llGetSubString((string)rev,0,3)+","+(string)hp+","+(string)maxhp;
    llSetLinkPrimitiveParamsFast(link,[PRIM_TEXT,"[LBA] \n ["+(string)((integer)hp)+"/"+(string)((integer)maxhp)+"] \n "+display,<1.-(float)hp/maxhp,(float)hp/maxhp,0.>,1,PRIM_LINK_TARGET,LINK_THIS,PRIM_DESC,info]);
    if(hp==0&&proc==[])die();
}
//
//
//DON'T TOUCH ANY OF THE SHIT BELOW THIS - REMEMBER, SAVE THIS IN MONO.
float rev=2.3;//Current revision number, for just making sure people know you're on version X Y Z.
list proc=[];//Damage events being processed into the buffer
list buffer=[];//This builds the message for the ownersay when you get damaged, don't touch me either
list recent=[];//List of things that have already hurt you. Ignores multiple messages if they are not sourced from an attachment and over one damage.
list totals=[];//The combined damage from munitions, don't touch me either you fuckboy. Processed damage gets pushed into this
list blacklist=[];//List of keys that are a bunch of cock monglers, don't touch me, for one, and also this will be overwritten on blacklist communication.
integer lh;//Don't touch me
integer lh2;//For cleaning up listens on the reghex channel from regions you've left, Don't touch me please.
integer events=0;//How many events are happening in your processing event. 
vector min;
vector max;
//Bounding box values for checking against raycast rifles.
open()
{
    llSetLinkPrimitiveParamsFast(-1,[PRIM_TEXT,"",<1,1,1>,1]);
    list bb=llGetBoundingBox(llGetKey());
    min=llList2Vector(bb,0)-<2,2,2>;
    max=llList2Vector(bb,1)+<2,2,2>;
    float t;//Temp float for correcting janky hitbox stuff
    if(min.x>max.x)
    {
        t=min.x;
        min.x=max.x;
        max.x=t;
    }
    if(min.y>max.y)
    {
        t=min.z;
        min.z=max.z;
        max.z=t;
    }
    if(min.z>max.z)
    {
        t=min.z;
        min.z=max.z;
        max.z=t;
    }
    integer hex=(integer)("0x" + llGetSubString(llMD5String((string)myKey,0), 0, 3));//My key hex
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
        if(setupmessage==1)
        {
//First time setup for vehicles, this will feed back your max damage you can do without worrying about triggering the AT cap antigrief.
//Recent list that handles the AT cap clears 4 seconds after dealing damage
            integer atcap=85;//Default AT cap for **Vehicles**
            list bb=llGetBoundingBox(llGetKey());
            vector tsize=llList2Vector(bb,1)-llList2Vector(bb,0);
            float tvol=tsize.x*tsize.y*tsize.z;
            llOwnerSay("/me :: Your hitbox size is "+(string)tsize+" :: with a volume of "+(string)tvol);
            integer mult=(integer)tvol/40;
            llOwnerSay("Your Multiplier (Tvol/40) is "+(string)mult);
            atcap+=mult*10;
            llOwnerSay("Your total AT cap is - "+(string)atcap+" (85 + "+(string)mult+" * 10)");
        }
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
        if(hp<=0)return;
        list ownerinfo=llGetObjectDetails(id,[OBJECT_OWNER,OBJECT_CREATOR,OBJECT_ATTACHED_POINT,OBJECT_REZZER_KEY,OBJECT_DESC]);
        if(llList2String(ownerinfo,0)=="")return;//Munition needs to stay around for a moment so that you can gather Owner & Creator details, otherwise fuck off.
        if(llStringLength(m)>36)
        {
            key target=llGetSubString(m,0,35);//Gets the target key from the first 36 (The length of a key) characters in the message
            if(target==myKey)//First things first, am I the target?
            {
                if((key)n)return;
                if ((string)((float)n)==n||(string)((integer)n)==n)return;
                key owner=llList2Key(ownerinfo,0);//Gets the owner key from Ownerinfo
                integer dmg=(integer)llGetSubString(m,37,-1);//This is the damage, fuck you.
                key src=id;
                key osrc=src;
                if(antigrief==1)//If you don't want to run this, either delete this section or set antigrief to 0
                {
                    key creator=llList2Key(ownerinfo,1);//Gets the creator key from Ownerinfo
                    if(llListFindList(blacklist,[(string)owner])!=-1&&llListFindList(blacklist,[(string)creator])!=-1)return;
                    integer att=llList2Integer(ownerinfo,2);
                    string desc=llList2String(ownerinfo,4);
                    integer rm=1;//Range multiplier
                    integer sit=llGetAgentInfo(owner)&AGENT_ON_OBJECT;
                    if(att)//If attachment, do the CAM VECTOR check, to see if they're actually aiming at me. If it's an attachment it's either a melee or a raycast weapon.
                    {
                        list tdl=llGetObjectDetails(owner,[OBJECT_POS,OBJECT_ROT]);//target data list
                        vector csize=llGetAgentSize(owner);//Gets hitbox size for camera position adjustment
                        vector tpos=llList2Vector(tdl,0)+<0,0,csize.z/2>;//Their pos
                        rotation trot=llList2Rot(tdl,1);//Their rot
                        vector camvec=tpos+<1,0,0>*trot*llVecDist(tpos,llGetPos());
                        if(llVecDist(tpos,llGetPos())<10)rm=2;//If they're up close they get a double multiplier on their AT cap, to avoid unnecessarily punishing melee weapons.
                        camvec=(camvec-llGetPos())/llGetRot();
                        integer bc=0;
                        if (camvec.x>min.x&&camvec.y>min.y&&camvec.z>min.z&&
                        camvec.x<max.x&&camvec.y<max.y&&camvec.z<max.z)bc=1;
                        if(!bc)return;
                        if(!sit)att=0;//Are they sitting? If not you've found the source, no need to fuck with getting bound size, this is just an attached weapon.
                    }
                    else//If not an attachment, can we do rezzer key chaining?
                    {
                        integer tries=3;//We'll see if we can do 3 chains, that's pretty liberal because usually 1 or 2 will do it.
                        if(llGetSubString(desc,0,5)=="LBA.v."&&llGetListLength(llCSV2List(desc))>=3&&(integer)((string)llGetObjectDetails(id,[OBJECT_RUNNING_SCRIPT_COUNT]))>1)src=id;//Is this a delpoyable?
                        else 
                        {
                            if(llGetSubString(desc,0,5)=="LBA.v.")//Kind of messy but this checks 'is direct damager a landmine'. Check if it has a LBA flag
                            {
                                string tod=llList2String(llCSV2List(desc),1);//Get the part where "time of day" would be
                                if(llGetSubString(tod,0,1)=="t:"&&((float)llGetSubString(tod,2,-1))!=0)//Does it have t:####?
                                {
                                    list bb=llGetBoundingBox(src);//Get size, is it under 1x1x1 like a LANDMINE?
                                    vector tsize=llList2Vector(bb,1)-llList2Vector(bb,0);
                                    if(tsize.x<1&&tsize.y<1&&tsize.z<1)
                                    {
                                        tries=0;
                                        n+=" "+llGetSubString(tod,2,-1);
                                        desc="";
                                    }
                                }
                            }
                            if(tries)
                            {
                                @srcfind;//Jumps back here for iterations if the check didn't get a valid source
                                key src2=llList2Key(ownerinfo,3);//Src2 is the last rezzer key 
                                ownerinfo=llGetObjectDetails(src2,[OBJECT_DESC,OBJECT_ATTACHED_POINT,OBJECT_POS,OBJECT_REZZER_KEY,OBJECT_RUNNING_SCRIPT_COUNT,OBJECT_SIT_COUNT,OBJECT_NAME]);
                                desc=llList2String(ownerinfo,0);
                                if(llGetSubString(desc,0,5)=="LBA.v.")//Kind of messy but this checks 'is direct damager a landmine'. Check if it has a LBA flag
                                {
                                    string tod=llList2String(llCSV2List(desc),1);//Get the part where "time of day" would be
                                    if(llGetSubString(tod,0,1)=="t:"&&((float)llGetSubString(tod,2,-1))!=0)//Does it have t:####?
                                    {
                                        list bb=llGetBoundingBox(src2);//Get size, is it under 1x1x1 like a LANDMINE?
                                        vector tsize=llList2Vector(bb,1)-llList2Vector(bb,0);
                                        if(tsize.x<1&&tsize.y<1&&tsize.z<1)
                                        {
                                            src=src2;
                                            n=llList2String(ownerinfo,6)+" "+llGetSubString(tod,2,-1);
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
                                        if(llGetSubString(desc,0,5)=="LBA.v."&&llGetListLength(llCSV2List(desc))>=3&&llList2Integer(ownerinfo,4)>1)src=src2;
                                        else desc="";
                                    }
                                    else 
                                    {
                                        src=src2;
                                        desc="";
                                    }
                                    if(llList2Vector(ownerinfo,2)==ZERO_VECTOR)tries=0;
                                    if(llList2Integer(ownerinfo,5)>0)
                                    {
                                        sit=1;
                                        att=1;
                                        tries=0;
                                    }
                                    if(src!=src2&&tries-->0)jump srcfind;
                                }
                            }
                        }
                    }
                    integer atcap=75;
                    osrc=src;
                    integer buffers=(llGetListLength(recent)+1)/6;
                    integer i=0;
                    while(i<buffers)
                    {
                        integer plus=i*6;
                        key oc=llList2Key(recent,plus+0);
                        key os=llList2Key(recent,plus+1);
                        key on=llList2String(recent,plus+2);
                        ++i;
                        if(owner==oc&&os!=osrc&&on==n)
                        {
                            osrc=os;
                            i=buffers;
                        }
                    }
                    integer rf=llListFindList(recent,[owner,osrc]);//Have I already generated an AT cap from this hitbox?
                    if(att&&rf==-1)//If the rezzer is attached, from either rezzer sourcing to an attached object OR the message came from an attachment from a sitter, check for a hitbox size
                    {
                        if(sit)
                        {
                            key root=(string)llGetObjectDetails(owner,[OBJECT_ROOT]);
                            vector rp=(vector)((string)llGetObjectDetails(root,[OBJECT_POS]));
                            list rcfind=llCastRay(rp-<0,0,2>,rp+<0,0,2>,[RC_MAX_HITS,5,RC_REJECT_TYPES,RC_REJECT_AGENTS|RC_REJECT_LAND]);
                            integer hits=llList2Integer(rcfind,-1);
                            while(hits--)
                            {
                                key rck=llList2Key(rcfind,0);
                                list info=llGetObjectDetails(rck,[OBJECT_DESC,OBJECT_RUNNING_SCRIPT_COUNT,OBJECT_OWNER]);
                                desc=llList2String(info,0);
                                if(llGetSubString(desc,0,5)=="LBA.v."&&llGetListLength(llCSV2List(desc))>=3&&llList2Integer(info,1)>1&&llList2Key(info,2)==owner)
                                {
                                    //Do I have a valid LBA description, more than 1 script, and the same owner as the source? If so we can assume this is the hitbox.
                                    src=rck;
                                    hits=0;
                                }
                                else 
                                {
                                    //Otherwise clear that iteration and keep on checking.
                                    rcfind=llListReplaceList(rcfind,[],0,1);
                                    desc="";
                                }
                            }
                        }
                    }
                    if(desc)//Okay, do I have a description and all that? Will be passed down from attach & sit checking and etc
                    {
                        //integer rf=llListFindList(recent,[osrc]);//Have I already generated an AT cap from this hitbox?
                        if(rf!=-1)atcap=llList2Integer(recent,rf+3);
                        else
                        {
                            if(llGetSubString(desc,0,5)=="LBA.v."&&llGetListLength(llCSV2List(desc))>=3)//Checks validity of description
                            {
                                atcap=85;//Because this is a valid source, bump up the default AT cap to 85 instead of 75
                                list bb=llGetBoundingBox(src);//Get size
                                vector tsize=llList2Vector(bb,1)-llList2Vector(bb,0);
                                float tvol=tsize.x*tsize.y*tsize.z;//Get volume
                                integer mult=(integer)tvol/40;
                                atcap+=mult*10;//Generate new AT cap. The larger the vehicle the higher the cap before blacklisting triggers.
                            }
                        }
                    }
                    atcap*=rm;
                    if (dmg<-15)dmg=-15;//Flat limit on repairs to 15 per event. This should cockblock all overflow attempts as well. If you ever need more than this much per event you're being a faggot.
                    integer tf=llListFindList(totals,[owner]);
                    if(tf==-1)totals+=[owner,dmg];
                    else totals=llListReplaceList(totals,[llList2Integer(totals,1)+dmg],tf+1,tf+1);
                    rf=llListFindList(recent,[owner,osrc]);
                    if(rf==-1)recent+=[owner,osrc,n,dmg,atcap,llGetTime()];
                    else 
                    {
                        integer new=llList2Integer(recent,rf+3)+dmg;
                        recent=llListReplaceList(recent,[new],rf+3,rf+3);
                        if(new>atcap)
                        {
                            if(new>atcap*1.25)//If damage being dealt is over the AT CAP by 1.25 trigger blacklisting
                            {
                                if(tf==-1)tf=llListFindList(totals,[owner]);
                                integer tdamage=llList2Integer(totals,tf+1);
                                llOwnerSay("/me :: secondlife:///app/agent/"+(string)owner+"/about has exceeded their AT Cap for "+llKey2Name(src)+" of "+(string)atcap+" with "+(string)new+" total damage! 
        This avatar has sourced "+(string)tdamage+" before being blacklisted. Blacklisting and refunding all damage!");
                                blacklist+=(string)owner;
                                hp+=tdamage;
                                if(hp<=0)hp=0;
                                if(hp>=maxhp)hp=maxhp;
                                handlehp();
                                llListReplaceList(recent,[],rf,rf+5);
                            }
                            return;//Otherwise assume it's an accident and just silently drop
                        }
                    }
                }
                string srcn=llKey2Name(osrc);
                integer pf=llListFindList(proc,[owner,srcn,n]);
                if(pf==-1)proc+=[owner,srcn,n,dmg,1];
                else
                {
                    integer tdmg=llList2Integer(proc,pf+3)+dmg;
                    integer hits=llList2Integer(proc,pf+4)+1;
                    proc=llListReplaceList(proc,[tdmg,hits],pf+3,pf+4);
                }
                ++events;//Adds to events
                if(events==1)llSetTimerEvent(1*llGetRegionTimeDilation());//On the first event, the processing countdown/timer gets started.
                hp-=dmg;
                if(hp<=0)hp=0;
                if(hp>=maxhp)hp=maxhp;
                handlehp();
            }
        }
    }
    timer()
    {
        events=0;
        if(proc!=[])
        {
            integer buffers=(llGetListLength(proc)+1)/4;
            while(buffers)
            {
                key owner=llList2Key(proc,0);
                string own="secondlife:///app/agent/"+(string)owner+"/about";
                string srcn=llList2Key(proc,1);
                string objn=llList2String(proc,2);
                integer dmg=llList2Integer(proc,3);
                integer hits=llList2Integer(proc,4);
                proc=llListReplaceList(proc,[],0,4);
                if(dmg>0)
                {
                    buffer+="Hit by "+(string)own+" with '"+objn+"'";
                    if(srcn!=""&&srcn!=objn)buffer+=" from '"+srcn+"'";
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
            handlehp();
            if(buffer!=[])llOwnerSay("\n"+(string)buffer);
            buffer=[];
        }
        if(recent!=[])
        {
            integer buffers=(llGetListLength(recent)+1)/5;
            integer i=0;
            while(i<buffers)
            {
                integer plus=i*6;
                float time=llList2Float(recent,plus+5);
                if(llGetTime()-time>=4)recent=llListReplaceList(recent,[],0,5);
                ++i;
            }
        }
        if(proc==[]&&recent==[])llSetTimerEvent(0);
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
//  Rezzer Key chaining will now be used to get the rezzer or vehicle size, affecting max DPS allowed. 
//  Rezzers that have a complete LBA description of (LBA.v.,hp,maxhp) and more than 1 script will be considered to be a valid rezzer
//  Recents list will now be cleaned per entry by first time damage was applied. recent+=[owner,osrc,dmg,atcap,llGetTime()] & total+=[owner,damage], default time for cleaning recent is 4s
//  AT Cap is now generated by hitbox size of a valid rezzer, otherwise there's a flat 75 based on source
//  Blacklisting now triggers on 1.25 of cap, otherwise damage is silently dropped in case of things that are SLIGHTLY borderline.
//  Totals list will track an avatars TOTAL DAMAGE over the lifetime of the vehicle. If someone gets blacklisted by exceeding DPM their entry in total will be refunded.
//  For the sake of the antigrief functioning, PROC has to be cleared before it can die. But other than that, damage is now processed when you recieve it and not with a 1s proc delay.
//  Also has lazy namespace dropping, if it's just a key or a float/integer it gets dropped because that's baby grief
//  if((key)n)return;
//  if ((string)((float)n)==n||(string)((integer)n)==n)return;
