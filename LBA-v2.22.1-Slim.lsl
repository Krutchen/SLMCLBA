integer hp;             
integer maxhp = 100;    
integer cap = 0;        
integer link = 0;       
integer hex;            
key me;    
float rev=2.3;//Current revision number, for just making sure people know you're on version X Y Z.             
handlehp()//Updates your HP text. The only thing you should really dick with is the text display.
{
    string info="LBA.v.L."+llGetSubString((string)rev,0,3)+","+(string)hp+","+(string)maxhp;
    llSetLinkPrimitiveParamsFast(link,[PRIM_TEXT,"[LBA Slim] \n ["+(string)((integer)hp)+"/"+(string)((integer)maxhp)+"] \n ",<1.-(float)hp/maxhp,(float)hp/maxhp,0.>,1,PRIM_LINK_TARGET,LINK_THIS,PRIM_DESC,info]);
    if(hp==0)llDie();
}
init(integer s)
{
    if(s <= maxhp && s > 0) hp = s;
    else hp = maxhp;
    if(!cap) cap = maxhp;
    me = llGetKey();
    hex = (integer)("0x" + llGetSubString(llMD5String((string)me,0), 0, 3));
    llListen(hex, "","","");
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
        list l = llParseString2List(m,[","],[]);
        string target = llList2String(l,0);
        integer dmg = (integer)llList2String(l,1);
        if(i == hex)
        {
            if(target == (string)me)
            {
                if((key)n)return;
                if ((string)((float)n)==n||(string)((integer)n)==n)return;
                if(dmg<-15)dmg=-15;//Cap to -15, stops overflow attempts.
                //llOwnerSay(llKey2Name(llGetOwnerKey(k)) +" : "+ s +" : "+(string)dmg);
                //if(dmg > cap) dmg = cap;
                hp -= dmg;
                if(hp > maxhp) hp = maxhp;
                handlehp();
            }
        }       
    } 
}
