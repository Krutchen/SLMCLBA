integer hp;
integer hp_max = 100;
integer link = LINK_THIS;
integer listen_id;
key me;
string rev = "2.32"; //Current revision number, for just making sure people know you're on version X Y Z.
handle_hp() //Updates your HP text. The only thing you should really dick with is the text display.
{
    if(hp > hp_max) hp = hp_max;
    if(hp <= 0) llDie();
    string text = (string)["[LBA Slim]\n[", hp, "/", hp_max, "]"];
    string info = llList2CSV(["LBA.v.L."+rev, hp, hp_max]);
    float ratio = (float)hp / hp_max;
    vector color = <1 - ratio, ratio, 0>;
    llSetLinkPrimitiveParamsFast(link, [PRIM_TEXT, text, color, 1, PRIM_LINK_TARGET, LINK_THIS, PRIM_DESC, info]);
}
init(integer sp)
{
    if(sp <= hp_max && sp > 0) hp = sp;
    else hp = hp_max;
    me = llGetKey();
    integer hex = (integer)("0x" + llGetSubString(llMD5String((string)me, 0), 0, 3));
    llListenRemove(listen_id);
    listen_id = llListen(hex, "","","");
    handle_hp();
}
default
{
    state_entry()
    {
        llSetLinkPrimitiveParamsFast(LINK_SET, [PRIM_TEXT, "", <1,1,1>, 1]);
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
            integer fast = (llVecMag(llDetectedVel(n)) > 25);
            integer not_avatar = (llDetectedType(n) != 3);
            if(fast && not_avatar) --hp;
        }
        handle_hp();
    }
    listen(integer i, string n, key k, string m)
    {
        list l = llCSV2List(m);
        key target = llList2Key(l, 0);
        integer dmg = llList2Integer(l, 1);
        if(target == me)
        {
            hp -= dmg;
            handle_hp();
        }
    }
}
