integer link=4;//WHERE YOUR HP TEXT WILL BE DISPLAYED! DON'T FUCK UP!
integer hp;//This is your HP. It is affected by rez params, but on startup it turns 
integer maxhp=100;//Max HP of your hitbox, yo.
integer atcap=75;//Clamps damage over this amount to this damage. Don't be a faggot with it m8.
integer trigger=50;//At what damage anti-spam will trigger. Don't be an asshole with this or you will get blacklisted.
//These two are seperate integers so that vehicles may have high alpha strike damage without triggering the anti-spam. Trigger is only checked on multiple hits, ie, if X munition hits you X times and the culmative damage is over TRIGGER damage.
die()
{
    llSleep(1);
    //PUT ALL EXPLODEY SHIT AND SITBASE KILLING HOOKS IN HERE!!!!!
    llDie();
}
//DON'T TOUCH ANY OF THE SHIT BELOW THIS - REMEMBER, SAVE THIS IN MONO.
float rev=2.2;//Current revision number, for just making sure people know you're on version X Y Z.
list proc=[];//Damage events being processed into the buffer
list recent=[];//List of things that have already hurt you. Ignores multiple messages if they are not sourced from an attachment and over one damage.
float cleanup;//When the last cleaning of the recent list happened, so you don't get a stack heap lol.
list totals=[];//The combined damage from munitions, don't touch me either you fuckboy. Processed damage gets pushed into this
list buffer=[];//This builds the message for the ownersay when you get damaged, don't touch me either
list blacklist=[];//List of keys that are a bunch of cock monglers, don't touch me, for one, and also this will be overwritten on blacklist communication.
integer lh;//Don't touch me
integer lh2;//For cleaning up listens on the reghex channel from regions you've left, Don't touch me please.
integer events=0;//How many events are happening in your processing event. 
vector min;
vector max;
//Bounding box values for checking against raycast rifles.
handlehp()//Updates your HP text. The only thing you should really dick with is the text display.
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
    string info="LBA.v."+llGetSubString((string)rev,0,3)+","+(string)hp+","+(string)maxhp+","+(string)atcap+","+(string)trigger;
    llSetLinkPrimitiveParamsFast(link,[PRIM_TEXT,"[LBA] \n ["+(string)((integer)hp)+"/"+(string)((integer)maxhp)+"] \n "+display,<1.-(float)hp/maxhp,(float)hp/maxhp,0.>,1,PRIM_LINK_TARGET,LINK_THIS,PRIM_DESC,info]);
    if(hp==0)die();
}
open()
{
    llSetLinkPrimitiveParamsFast(-1,[PRIM_TEXT,"",<1,1,1>,1]);
    string parcel=llList2String(llGetParcelDetails(llGetPos(),[PARCEL_DETAILS_DESC]),0);//Fetches parcel description
    list descfind=llParseString2List(parcel,["[:",":]"],[]);//Then sorts through, making new entries for stuff between [: and :]
    integer l=llGetListLength(descfind);//Gets the number of entries
    if(l>0)//Are there any?
    {
        l=l+1;
        while(--l)//Sort through them
        {
            string s=llList2String(descfind,l);
            if(llGetSubString(s,0,8)=="Blackbox:")//Did we find the blackbox entry?
            {
                s=llDeleteSubString(s,0,8);
                blackbox=(key)s;//Assign this shit, fam
                list d=llGetObjectDetails(blackbox,[OBJECT_POS]);
            }
        }
    }
    list bb=llGetBoundingBox(llGetKey());
    min=llList2Vector(bb,0)-<2,2,2>;
    max=llList2Vector(bb,1)+<2,2,2>;
    float t;
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
    reghex=(integer)("0x" + llGetSubString(llMD5String((string)llGetRegionName(),0), 0, 3));//My region hex
    neghex1 = reghex*-1;//Don't touch me
    neghex2 = reghex*-2;//Or me, we're for blackbox channels
    cleanup=llGetTime()-120;
    if(blackbox=="")
    {
        message=0;
        lh=llListen(hex,"","","");
        lh2=llListen(neghex2,"","","");
        llRegionSay(neghex1,"get");
        llOwnerSay("No Blackbox found, starting normally");
    }
    else
    {
        message=1;
        lh2=llListen(neghex2,"",blackbox,"");
        llRegionSay(neghex1,"get");
        llOwnerSay("Blackbox found, awaiting response");
    }
//This function is an added security measure in case people feel like spamming the blackbox reghex channel, to get around a blacklist, 
//return false blacklists, or flood listen events. If you provide a blackbox key in your parcel description, and it is a valid object in the region,
//the reghex listen will specify to only listen to it for blacklists. The format is [:Blackbox:(key):] , you can fetch your blackbox key by 
//rightclicking the object, going to "General", and pressing "Copy keys". If the region is being spammed on the blackbox channel to prevent 
//blacklists from being recieved, this armour will simply not take damage, nor will any other LBA armour in the region.
}
integer reghex;//Region channel for communication with the black box.
integer neghex1;//Negative hex channel for Blackbox interaction
integer neghex2;//Negative hex channel for Blackbox interaction
key blackbox="";//Black box key, Don't touch me, this is what your hitbox communicates with for its blackbox.
integer message=0;//Relates to the blackbox finding, yo.
key myKey;//Me
key myOwner;//Who owns me!
default
{
    state_entry()
    {
        myKey = llGetKey();
        myOwner = llGetOwner();
        open();
        hp=maxhp;
        handlehp();
    }
    on_rez(integer n)
    {
        if(n)
        {
            myKey = llGetKey();
            myOwner = llGetOwner();
            blackbox="";
            llListenRemove(lh);
            llListenRemove(lh2);
            open();
            hp=n;
            handlehp();
        }
    }
    changed(integer c)
    {
        if(c&CHANGED_REGION)
        {
            blackbox="";
            llListenRemove(lh2);
            open();
            handlehp();
        }
    }
    listen(integer c, string n, key id, string m)
    {
        if(hp<=0)return;
        list ownerinfo=llGetObjectDetails(id,[OBJECT_OWNER,OBJECT_CREATOR,OBJECT_ATTACHED_POINT]);
        if(c==neghex2)
        {
            if(llList2Key(ownerinfo,1)=="82a665cf-f53b-4c93-87b8-9d0c07c4dbdb")
            {
                blacklist=llParseString2List(m,[","],[]);
                llOwnerSay("/me : Blacklist Recieved");
                llOwnerSay(llDumpList2String(blacklist," , "));
                if(message==1)
                {
                    message=0;
                    integer hex=(integer)("0x" + llGetSubString(llMD5String((string)myKey,0), 0, 3));//My key hex.
                    lh=llListen(hex,"","","");
                }
            }
        }
        else
        {
            if(llList2String(ownerinfo,0)=="")return;//Munition needs to stay around for a moment so that you can gather Owner & Creator details, otherwise fuck off.
            if(llStringLength(m)>36)
            {
                key target=llGetSubString(m,0,35);//Gets the target key from the first 36 (The length of a key) characters in the message
                if(target==myKey||target==myOwner)//First things first, am I the target?
                {
                    key owner=llList2Key(ownerinfo,0);//Gets the owner key from Ownerinfo
                    key creator=llList2Key(ownerinfo,1);//Gets the creator key from Ownerinfo
                    integer att=llList2Integer(ownerinfo,2);
                    string n2=llKey2Name(owner);//Gets the owner name
                    if(n2=="")n2=owner;//If you can't get the owner name, return the key instead
                    integer dmg=(integer)llGetSubString(m,37,-1);//This is the damage, fuck you.
                    if (atcap) // use atcap to limit repairs
                    {
                        if (dmg < -atcap) dmg = -atcap;
                    }
                    else if (dmg < -maxhp) // use maxhp to limit repairs
                    {
                        dmg = -maxhp;
                    }
                    if(att)
                    {
                        list tdl=llGetObjectDetails(owner,[OBJECT_POS,OBJECT_ROT]);//target data list
                        vector csize=llGetAgentSize(owner);//Gets hitbox size for camera position adjustment
                        vector tpos=llList2Vector(tdl,0)+<0,0,csize.z/2>;//Their pos
                        rotation trot=llList2Rot(tdl,1);//Their rot
                        vector camvec=tpos+<1,0,0>*trot*llVecDist(tpos,llGetPos());
                        camvec=(camvec-llGetPos())/llGetRot();
                        integer bc=0;
                        if (camvec.x>min.x&&camvec.y>min.y&&camvec.z>min.z&&
                        camvec.x<max.x&&camvec.y<max.y&&camvec.z<max.z)bc=1;
                        if(!bc)
                        {
                            return;
                        }
                    }
                    if(!att)
                    {
                        if(dmg>1)
                        {
                            if(llListFindList(recent,[id])>-1)return;//Check if the object has already damaged you
                            else recent+=id;
                        }
                    }
                    if(dmg>5)llRegionSay(reghex*-3,"log:"+(string)owner+","+(string)creator+","+(string)n+","+(string)dmg);//For logging hits within the region for later evaluation. If you don't have this active, blacklisting won't even work, man.
                    proc+=[owner,n2,creator,n,dmg];//Adds to the processing event
                    ++events;//Adds to events
                    if(events==1)llSetTimerEvent(1*llGetRegionTimeDilation());//On the first event, the processing countdown/timer gets started.
                }
            }
        }
    }
    timer()
    {
        integer i=0;
        while(i<events)
        {
            key owner=llList2Key(proc,0);
            string ownern=llList2String(proc,1);
            key creator=llList2Key(proc,2);
            string name=llList2Key(proc,3);
            integer dmg=llList2Integer(proc,4);
            integer full=dmg;
            if(atcap>0)
            {
                if(dmg>atcap)dmg=atcap;
            }
            proc=llListReplaceList(proc,[],0,4);
            if(llListFindList(blacklist,[(string)owner])==-1&&llListFindList(blacklist,[(string)creator])==-1)
            {
                integer find=llListFindList(totals,[owner,ownern,name]);
                if(full>=1000)
                {
                    totals=llListReplaceList(totals,[],find,find+3);
                    blacklist+=[(string)owner];
                    llOwnerSay((string)ownern+" tried hitting you with "+name+" for a full "+(string)full+" damage, adding to blacklist");
                    llRegionSay(neghex1,"send:"+(string)owner+"||"+(string)creator+"||"+name+"||"+(string)full+"||Oneshot_1/"+(string)dmg+"/"+(string)full+"/"+(string)atcap+"/"+(string)trigger);
                    @black;
                    integer blackfind=llListFindList(proc,[(string)owner]);
                    if(blackfind!=-1)
                    {
                        proc=llListReplaceList(proc,[],blackfind,blackfind+3);
                        --events;
                        jump black;
                    }
                }
                else    
                {
                    if(find!=-1)
                    {
                        integer tdmg=llList2Integer(totals,find+3)+dmg;
                        integer hits=llList2Integer(totals,find+4)+1;
                        totals=llListReplaceList(totals,[tdmg,hits],find+3,find+4);
                        if(tdmg>trigger)
                        {
                            if(hits>=6)
                            {
                                integer dph=tdmg/hits;
                                if(dph>5)
                                {
                                    totals=llListReplaceList(totals,[],find,find+3);
                                    blacklist+=[(string)owner];
                                    llOwnerSay((string)ownern+" is spamming you with damage, "+(string)tdmg+" over "+(string)hits+" hits for "+(string)dph+" damage per hit, "+(string)dmg+" on last hit, adding to blacklist");
                                    llRegionSay(neghex1,"send:"+(string)owner+"||"+(string)creator+"||"+name+"||"+(string)full+"||Spam_"+(string)hits+"/"+(string)full+"/"+(string)dph+"/"+(string)atcap+"/"+(string)trigger);
                                    @black2;
                                    integer blackfind=llListFindList(proc,[(string)owner]);
                                    if(blackfind!=-1)
                                    {
                                        proc=llListReplaceList(proc,[],blackfind,blackfind+3);
                                        --events;
                                        jump black2;
                                    }
                                }
                            }
                        }
                    }
                    else totals+=[owner,ownern,name,dmg,1];
                }
            }
            ++i;
        }
        events=0;
        integer buffers;
        buffers=(llGetListLength(totals)+1)/5;
        i=0;
        while(i<buffers)
        {
            integer plus=i*5;
            key owner=llList2Key(totals,plus+0);
            string ownern=llList2Key(totals,plus+1);
            string name=llList2Key(totals,plus+2);
            integer dmg=llList2Integer(totals,plus+3);
            integer hits=llList2Integer(totals,plus+4);
            if(dmg>0)
            {
                if(hits==1)buffer+="Hit by "+(string)ownern+" with '"+name+"' for "+(string)dmg+" damage";
                else buffer+="Hit by "+(string)ownern+" with '"+name+"' "+(string)hits+" times for "+(string)dmg+" damage";
            }
            else if(dmg<0)
            {
                if(hits==1)buffer+="Repaired by "+(string)ownern+" for "+(string)dmg+" damage";
                else buffer+="Repaired by "+(string)ownern+" "+(string)hits+" times for "+(string)dmg+" damage";
            }
            if(i<buffers-1)buffer+=" \n";
            hp-=dmg;
            if(hp<=0)hp=0;
            if(hp>=maxhp)hp=maxhp;
            ++i;
        }
        handlehp();
        if(buffer!=[])llOwnerSay("\n"+(string)buffer);
        totals=[];
        buffer=[];
        if(llGetTime()-cleanup>120)
        {
            cleanup=llGetTime();
            recent=[];
            llSetTimerEvent(0);
        }
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
