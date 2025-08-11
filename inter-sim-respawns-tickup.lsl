string spawnsim;
vector startpos;
rotation startrot;
integer respawndelay=1;//Whether or not to wait before respawning
integer spawndelay=15;//How long to wait on respawning. 1s per 10 HP for full LBA, 1s per 20 HP for LBA Light.
integer hp=150;
default
{
    state_entry()
    {        
        spawnsim=llGetRegionName();
        startpos=llGetPos();
        startrot=llGetRot();
        llLinksetDataReset();
        llLinksetDataWrite((string)(llGetRegionCorner()/256),(string)startpos);
    }
    on_rez(integer n)
    {
        spawnsim=llGetRegionName();
        startpos=llGetPos();
        startrot=llGetRot();
        llLinksetDataReset();
        llLinksetDataWrite("1",(string)(llGetRegionCorner()/256)+"/"+(string)llGetPos());
        if(n)
        {
            parent=llList2Key(llGetObjectDetails(llGetKey(),[OBJECT_REZZER_KEY]),0);
            list mes=llParseString2List(llGetStartString(),[":","/"],[]);
            if(llList2String(mes,0)=="respawndelay")respawndelay=(integer)llList2String(mes,1);
            llOwnerSay("@acceptpermission=add");//RLV command for accepting perms
            llSleep(.1);
            llOwnerSay("@sit:"+(string)llGetKey()+"=force");//RLV autositting on your vehicle
            llLinkSitTarget(seat1,<0,0,-.75>,<0,0,0,0>);
        }
    }
    changed(integer c)
    {
        if(c&CHANGED_REGION)
        {
            llSetStatus(STATUS_PHYSICS,1);
            llSetStatus(STATUS_PHANTOM,0);
            if(llGetRegionName()!=spawnsim)
            {
                integer count=llLinksetDataCountKeys();
                vector simpos=llGetRegionCorner()/256;
                integer temp=count;
                integer find=-1;//If no entry is found, this doesn't change and an entry is added. If an entry is found, iterates back up deleting border crossings after that entry because we have doubled back into an already visited sim
                while(count)
                {
                    string data=llLinksetDataRead((string)count);
                    list parse=llParseString2List(data,["/"],[]);
                    if(llList2String(parse,0)==(string)simpos)
                    {
                        find=count;
                        count=0;
                    }
                    else count--;
                }
                if(find==-1)
                {
                    string data=(string)simpos+"/"+(string)llGetPos();
                    count=temp;
                    llLinksetDataWrite((string)(count+1),data);
                    count++;
                }
                else
                {
                    count=temp;
                    find++;
                    while(find<=count)
                    {
                        llLinksetDataDelete((string)find);
                        find++;
                    }
                }
            }
            else
            {
                llLinksetDataReset();
                llLinksetDataWrite("1",(string)(llGetRegionCorner()/256)+"/"+(string)startpos);
            }
        }
        if(c&CHANGED_LINK)
        {
            user=llAvatarOnLinkSitTarget(LINK_THIS);
            if(user!=NULL_KEY)
            {
                if(user==llGetOwner())llRequestPermissions(user,0x4|0x10|0x800);
                else 
                {
                    llUnSit(user);
                    user=NULL_KEY;
                    return;
                }
            }
            else llDie();
        }  
    }
    link_message(integer sn, integer n, string m, key id)
    {
        if(m=="die")//Your LBA script has hit 0 HP, have it fire a link message that the vehicle has died
        {
            llSetTimerEvent(0);
            lmotor=<0,0,0>;
            amotor=<0,0,0>;
            llSetVehicleVectorParam(VEHICLE_LINEAR_MOTOR_DIRECTION,lmotor);
            llSetVehicleVectorParam(VEHICLE_ANGULAR_MOTOR_DIRECTION,amotor);
            llSetStatus(STATUS_PHYSICS,0);
            float respawntime;//used if traveling sims for discounting respawn times
            if(spawnsim!=llGetRegionName())
            {
                moving=0;
                respawntime=llGetTime();
                integer count=llLinksetDataCountKeys();
                if(count>10)//If you have this many entries just teleport back home or you're going to be here all day and/or risk getting lost on a border crossing
                {
                    llMapDestination(spawnsim,startpos,startpos);
                    llDie();
                    return;
                }
                while(count>1)
                {
                    vector simpos=llGetRegionCorner()/256;//Gets my CURRENT SIM POSITION
                    list parse=llParseString2List(llLinksetDataRead((string)count),["/"],[]);
                    vector borderpos=(vector)llList2String(parse,1);//Gets my current sim entry point
                    parse=llParseString2List(llLinksetDataRead((string)(count-1)),["/"],[]);
                    vector newpos=(vector)llList2String(parse,0);//Gets my PREVIOUS SIM POSITION
                    vector difpos=simpos-newpos;//Finds the offset/difference between current and previous sim
                    if(difpos.x<0)borderpos.x=254;
                    if(difpos.x>0)borderpos.x=2;
                    if(difpos.y<0)borderpos.y=254;
                    if(difpos.y>0)borderpos.y=2;//Clamps my edge position to the border to avoid any weird situations where borderpos was saved late (and too far away from the border)
                    llSetRegionPos(borderpos);//Move to the borcer
                    llSleep(.2);
                    llSetRegionPos(borderpos+(difpos*-8));//Offset into the next region, llSetRegionPos can reach 10 meters into a neighboring sim
                    llLinksetDataDelete((string)count);//Delete this border crossing entry
                    count--;//iterate and repeat
                    llSleep(.2);
                }
            }
            llSetRot(startrot);
            llSetRegionPos(startpos);
            llLinksetDataReset();//Clear the linkset data
            llLinksetDataWrite("1",(string)(llGetRegionCorner()/256)+"/"+(string)startpos);//set the first entry
            if(respawndelay)
            {
                integer moddelay=spawndelay;//modified spawn delay
                if(respawntime)//time the respawn started
                {
                    integer timetospawn=(integer)(llGetTime()-respawntime);
                    moddelay=moddelay-timetospawn;//discounts by how long ago respawning started
                    if(moddelay<0)moddelay=0;
                }
                llOwnerSay("/me :: DIED, RESPAWNING @ "+(string)startpos+" in "+(string)moddelay+"s");
                if(moddelay>0)//This iterates if moddelay is greater than 0
                {
                    integer ticks=hp/10;
                    integer start=ticks-moddelay;
                    if(start<0)start=0;
                    while(start<ticks)
                    {
                        if(start>1)llMessageLinked(LINK_THIS,start*10,"hp","");//messages your LBA to tick up HP
                        llSleep(1);
                        ++start;
                    }
                }
            }
            else
            {
                llOwnerSay("/me :: DIED, RESPAWNING @ "+(string)startpos);
                llSleep(.1);
            }
            llMessageLinked(LINK_THIS,55,"respawn","");//Tells your LBA script via link message to refill hp
            llSetTimerEvent(.1);
            llSetStatus(STATUS_PHYSICS,1);
            llSetStatus(STATUS_PHANTOM,0);
        }
    }
}
