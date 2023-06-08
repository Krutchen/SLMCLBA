integer hp=50;//Current AP
integer hpmax=1000;//Max AP
integer link=0;//Text Display Link
integer hex;
key me;

//ensure that we eventually have an update, say we're under a lot of fire and we never hit the timer.
integer num_hits_without_update=0;
updateAP(){
        if(hp<1) {
            llDie();
        }
        if(num_hits_without_update < 20) {
            num_hits_without_update++;
            llSetTimerEvent(0.15);
        } else {
            num_hits_without_update = 0;
            llSetLinkPrimitiveParamsFast(link,[
                PRIM_TEXT,"[GLBA-V] \n AP: " + (string)(hp) + "/" +(string)(hpmax),<0.0,1.0,0.0>,1.0,
                PRIM_LINK_TARGET, LINK_THIS,
                PRIM_DESC, "LBA.v.GLBA.1.3," + (string)hp + "," + (string)hpmax
            ]);
        }
}
default{
    on_rez(integer n){
        hp = hpmax;
        llSetObjectDesc("LBA.v.GLBA.1.3");
        me=llGetKey();
        hex=(integer)("0x" + llGetSubString(llMD5String((string)me,0), 0, 3));
        llListen(hex, "","","");
        updateAP();
    }
    timer() {
        num_hits_without_update = 0;
        llSetLinkPrimitiveParamsFast(link,[
            PRIM_TEXT,"[GLBA-V] \n AP: " + (string)(hp) + "/" +(string)(hpmax),<0.0,1.0,0.0>,1.0,
            PRIM_LINK_TARGET, LINK_THIS,
            PRIM_DESC, "LBA.v.GLBA.1.3," + (string)hp + "," + (string)hpmax
        ]);
        llSetTimerEvent(0);
    }
    
    collision_start(integer n){
        while(n--){
            if(llVecMag(llDetectedVel(n)) > 25)
            {
                --hp;
            }
        }
        updateAP();
    }
    listen(integer i, string s, key k, string m){
        list l = llParseString2List(m,[","],[]);
        string prefix = llList2String(l,0);
        string suffix = llList2String(l,1);
        if(i==hex){
            if (prefix==(string)me){
                hp-=(integer)suffix;
                if(hp > hpmax) hp = hpmax;
                updateAP();
            }
        }
    }
}