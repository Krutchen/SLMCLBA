integer hp;
integer maxhp = 100;
integer link = 0;
integer listenId;
key me;
integer num_hits_without_update=0;
string rev = "3.0";
handlehp()//Updates your HP text. The only thing you should really dick with is the text display.
{
	if(hp<=0) {
		llDie();
        }
        if(num_hits_without_update < 20) {
            num_hits_without_update++;
            llSetTimerEvent(0.15);
        } else {
        	string info="LBA.v.L."+rev+","+(string)hp+","+(string)maxhp;
            num_hits_without_update = 0;
            llSetLinkPrimitiveParamsFast(link,[
                PRIM_TEXT,"[LBA Slim] \n AP: " + (string)(hp) + "/" +(string)(maxhp),<0.0,1.0,0.0>,1.0,
                PRIM_LINK_TARGET, LINK_THIS,
                PRIM_DESC, info
            ]);
        }
}
init(integer s)
{
    if(s <= maxhp && s > 0) hp = s;
    else hp = maxhp;
    me = llGetKey();
    integer hex = (integer)("0x" + llGetSubString(llMD5String((string)me,0), 0, 3));
    llListenRemove(listenId);
    listenId = llListen(hex, "","","");
    handlehp();
}
default
{
    state_entry() 
    {
    	init(0);
    }
    on_rez(integer sp)
    {
        init(sp);
    }
    timer() 
    {
        num_hits_without_update = 0;
        llSetLinkPrimitiveParamsFast(link,[
            PRIM_TEXT,"[LBA Slim] \n AP: " + (string)(hp) + "/" +(string)(maxhp),<0.0,1.0,0.0>,1.0,
            PRIM_LINK_TARGET, LINK_THIS,
            PRIM_DESC, "LBA.v.L.GLBA.1.3," + (string)hp + "," + (string)maxhp
        ]);
        llSetTimerEvent(0);
    }
    collision_start(integer n)
    {
        while(n--)
        {
            if(llVecMag(llDetectedVel(n)) > 25 && llDetectedType(n) != 3)--hp;
        }
        handlehp();
    }
    listen(integer i, string n, key k, string m)
    {
        list l = llCSV2List(m);
        key target = llList2Key(l,0);
        integer dmg = llList2Integer(l,1);
        if(target == me)
        {
            hp -= dmg;
            if(hp > maxhp) hp = maxhp;
            handlehp();
        }
    }
}
