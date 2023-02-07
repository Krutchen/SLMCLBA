integer hp;
integer maxhp = 100;
integer link = 0;
integer listenId;
key me;
string rev="2.3";//Current revision number, for just making sure people know you're on version X Y Z.          
handlehp()//Updates your HP text. The only thing you should really dick with is the text display.
{
    if(hp<0)hp=0;
    string info="LBA.v.L."+rev+","+(string)hp+","+(string)maxhp;
    llSetLinkPrimitiveParamsFast(link,[PRIM_TEXT,"[LBA Slim] \n ["+(string)((integer)hp)+"/"+(string)((integer)maxhp)+"] \n ",<1.-(float)hp/maxhp,(float)hp/maxhp,0.>,1,PRIM_LINK_TARGET,LINK_THIS,PRIM_DESC,info]);
    if(hp==0)llDie();
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
