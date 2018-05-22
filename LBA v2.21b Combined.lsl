// CONFIGURE SETTINGS HERE
integer LBAType = 0; // which edition to use: 0 = LBA; 1 = LBA Light; 2 = LBA Light Deployable
integer textLink = 0; // which link number to float HP text on; 0 = root prim; -1 = off
integer healthAmount; // current health
integer maxHealth = 100; // maximum health of this object; set to 0 to set with rez param
integer damageCap = 75; // damage received is clamped to this maximum per hit
integer spamTrigger = 50; // damage threshold that will trigger anti-spam after repeated hits
integer verboseMode = FALSE; // whether to enable sending blackbox notification messages to owner
/* These two are seperate integers so that vehicles may have high alpha strike damage without triggering the anti-spam. spamTrigger is only checked on multiple hits, ie, if X munition hits you X times and the cumulative damage is over spamTrigger damage. */
Die()
{
    llListenRemove(myChannelId); // stop accepting damage messages
    llListenRemove(blackboxChannelId); // stop accepting blackbox messages
    llSleep(1); // is this necessary?
    // Add effects here. Explode, trigger sitbase kill prims, etc, or use the link message below.
    // llMessageLinked(LINK_SET, 0, "die", "");
    llDie();
}
/*==========================================================
DO NOT EDIT BELOW THIS LINE, AND REMEMBER TO COMPILE IN MONO
==========================================================*/
float versionNumber = 2.2; // current revision number
list damageQueue; // damage events waiting to be processed
list recentSources; // list of things that have already hurt you; ignores multiple messages if they are not sourced from an attachment and over one damage.
float lastCleanup; // when the last cleaning of the recentSources list happened
list totalDamageList; // combined damage from each source
list blackList; // list of keys to ignore damage from; retrieved from the parcel's blackbox
integer myChannelId; // listen handle for receiving damage
integer blackboxChannelId; // listen handle for blackbox channel in
integer eventCount; // how many events are happening in your processing event. 
vector boundaryLow; // bounding box values to check raycast rifles...
vector boundaryHigh; // bounding box values to check raycast rifles, not reliable in lag
integer blackboxChannelBase; //Region channel for communication with the black box.
integer blackboxChannelOut; // Negative hex channel for Blackbox interaction
integer blackboxChannelIn; // Negative hex channel for Blackbox interaction
key blackboxKey; // obtained from parcel description
key myKey; // key of this object
key myOwner; // key of my owner

UpdateHP() // checks HP and updates text
{
    string lbaStringA;
    string lbaStringB;
    if (LBAType == 0) // standard LBA
    {
        lbaStringA = "LBA.v.";
        lbaStringB = "[LBA]";
    }
    else if (LBAType == 1) // LBA Light
    {
        lbaStringA = "LBA.v.L.";
        lbaStringB = "[LBA LIGHT]";
    }
    else if (LBAType == 2) // LBA Light Deployable
    {
        lbaStringA = "LBA.v.L.";
        lbaStringB = "[LBA LIGHT]";
    }
    string info = lbaStringA + llGetSubString((string)versionNumber, 0, 3) + "," + (string)healthAmount + "," + (string)maxHealth + "," + (string)damageCap + "," + (string)spamTrigger;
    if (textLink > -1)
    {
        integer t = 10;
        string display = "[";
        while (t)
        {
            if (healthAmount > ((10 - t) * maxHealth / 10)) display += "█";
            else display += "-";
            --t;
        }
        display += "]";
        llSetLinkPrimitiveParamsFast(textLink, [PRIM_TEXT, lbaStringB + "\n[" + (string)((integer)healthAmount) + "/" + (string)((integer)maxHealth) + "]\n" + display, <1 - (float)healthAmount / maxHealth, (float)healthAmount / maxHealth, 0>, 1]);
        
    }
    llSetObjectDesc(info);
    if (healthAmount == 0) Die();
}

Initialize()
{
    llSetLinkPrimitiveParamsFast(LINK_SET, [PRIM_TEXT, "", <1,1,1>, 1]); // remove text
    string parcelDesc = llList2String(llGetParcelDetails(llGetPos(), [PARCEL_DETAILS_DESC]), 0);
    integer index = llSubStringIndex(llToLower(parcelDesc), "blackbox:");
    if (index != -1)
    {
        key newKey = (key)llGetSubString(parcelDesc, index + 9, index + 44);
        if (newKey) blackboxKey = newKey; // validate then assign blackbox key
    }
    list boundingBox = llGetBoundingBox(llGetKey());
    boundaryLow = llList2Vector(boundingBox, 0) - <2, 2, 2>;
    boundaryHigh = llList2Vector(boundingBox, 1) + <2, 2, 2>;
    if (boundaryLow.x > boundaryHigh.x)
    {
        float t = boundaryLow.x;
        boundaryLow.x = boundaryHigh.x;
        boundaryHigh.x = t;
    }
    if(boundaryLow.y>boundaryHigh.y)
    {
        float t = boundaryLow.z;
        boundaryLow.z = boundaryHigh.z;
        boundaryHigh.z = t;
    }
    if(boundaryLow.z>boundaryHigh.z)
    {
        float t = boundaryLow.z;
        boundaryLow.z = boundaryHigh.z;
        boundaryHigh.z = t;
    }
    integer myChannel = (integer)("0x" + llGetSubString(llMD5String((string)myKey, 0), 0, 3));
    blackboxChannelBase = (integer)("0x" + llGetSubString(llMD5String((string)llGetRegionName(),0), 0, 3));
    blackboxChannelOut = -blackboxChannelBase;
    blackboxChannelIn = -blackboxChannelBase * 2;
    lastCleanup = llGetTime() - 120;
    if (blackboxKey == "")
    {
        myChannelId = llListen(myChannel, "", NULL_KEY, "");
        if (verboseMode) llOwnerSay("No blackbox found, starting normally");
    }
    else
    {
        blackboxChannelId = llListen(blackboxChannelIn, "", blackboxKey, "");
        llRegionSayTo(blackboxKey, blackboxChannelOut, "get");
        if (verboseMode) llOwnerSay("Blackbox found, awaiting response");
    }
//This function is an added security measure in case people feel like spamming the blackbox reghex channel, to get around a blacklist, 
//return false blacklists, or flood listen events. If you provide a blackbox key in your parcel description, and it is a valid object in the region,
//the reghex listen will specify to only listen to it for blacklists. The format is [:Blackbox:(key):] , you can fetch your blackbox key by 
//rightclicking the object, going to "General", and pressing "Copy keys". If the region is being spammed on the blackbox channel to prevent 
//blacklists from being recieved, this armour will simply not take damage, nor will any other LBA armour in the region.
}


default
{
    state_entry()
    {
        if (LBAType == 0) llCollisionFilter("", NULL_KEY, FALSE); // disable collision detection
        else llCollisionFilter("", NULL_KEY, TRUE); // and enable for LBA Light/Deployable
        myKey = llGetKey();
        myOwner = llGetOwner();
        Initialize();
        healthAmount = maxHealth;
        UpdateHP();
    }
    on_rez(integer param)
    {
        if(param)
        {
            myKey = llGetKey();
            myOwner = llGetOwner();
            blackboxKey = "";
            llListenRemove(myChannelId);
            myChannelId = 0;
            llListenRemove(blackboxChannelId);
            Initialize();
            if (!maxHealth) maxHealth = param;
            healthAmount = maxHealth;
            UpdateHP();
        }
    }
    changed(integer change)
    {
        if(change & CHANGED_REGION)
        {
            blackboxKey = "";
            llListenRemove(blackboxChannelId);
            Initialize();
            UpdateHP();
        }
    }
    listen(integer channel, string name, key id, string text)
    {
        if (healthAmount <= 0) return;
        list objectDetails = llGetObjectDetails(id, [OBJECT_OWNER, OBJECT_CREATOR, OBJECT_ATTACHED_POINT]);
        key objectOwner = llList2Key(objectDetails, 0);
        key objectCreator = llList2Key(objectDetails, 1);
        integer isAttached = llList2Integer(objectDetails, 2);
        if (channel == blackboxChannelIn)
        {
            // if(llList2Key(ownerinfo,1)=="82a665cf-f53b-4c93-87b8-9d0c07c4dbdb")
            // No one is special in public domain.
            blackList = llCSV2List(text);
            if (verboseMode) llOwnerSay("Blacklist recieved: " + llList2CSV(blackList));
            if (!myChannelId)
            {
                integer myChannel = (integer)("0x" + llGetSubString(llMD5String((string)myKey, 0), 0, 3)); //My key hex.
                myChannelId = llListen(myChannel, "", NULL_KEY, "");
            }
        }
        else
        {
            if (objectOwner == "") return; // reject if object derezzed already
            if (llStringLength(text) > 36)
            {
                key targetKey = llGetSubString(text, 0, 35); //Gets the target key from the first 36 (The length of a key) characters in the message
                if(targetKey == myKey || targetKey == myOwner) // Am I the target?
                {
                    string objectOwnerName = llKey2Name(objectOwner);
                    if (objectOwnerName == "") objectOwnerName = objectOwner; // If you can't get the owner name, return the key instead
                    integer damageAmount = (integer)llGetSubString(text, 37, -1);
                    if (isAttached)
                    { // this probably doesn't work well under lag
                        list targetDataList = llGetObjectDetails(objectOwner, [OBJECT_POS, OBJECT_ROT]);
                        vector agentSize = llGetAgentSize(objectOwner); // Gets hitbox size for camera position adjustment
                        vector targetPos = llList2Vector(targetDataList, 0) + <0, 0, agentSize.z / 2>; //Their pos
                        rotation targetRot = llList2Rot(targetDataList, 1);
                        vector camPath = targetPos + <1, 0, 0> * targetRot * llVecDist(targetPos, llGetPos());
                        camPath = (camPath - llGetPos()) / llGetRot();
                        integer boundaryCheck;
                        if (camPath.x > boundaryLow.x)
                        {
                            if (camPath.x < boundaryHigh.x)
                            {
                                if (camPath.y > boundaryLow.y)
                                {
                                    if (camPath.y < boundaryHigh.y)
                                    {
                                        if (camPath.z > boundaryLow.z)
                                        {
                                            if (camPath.z < boundaryHigh.z)
                                            { // nested to reduce evaluations after a false
                                                boundaryCheck = TRUE;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        if (!boundaryCheck)
                        {
                            return;
                        }
                    }
                    else
                    {
                        if (damageAmount > 1)
                        {
                            if (llListFindList(recentSources, [id]) != -1) return; //Check if the object has already damaged you
                            else recentSources += id;
                        }
                    }
                    if (damageAmount > 5) llRegionSay(blackboxChannelBase * -3, "log:" + (string)objectOwner + "," + (string)objectCreator + "," + (string)name + "," + (string)damageAmount); // For logging hits within the region for later evaluation. Checked against the blacklist later.
                    damageQueue += [objectOwner, objectOwnerName, objectCreator, name, damageAmount]; // Adds to the processing event
                    ++eventCount; // Adds to events
                    if (eventCount == 1) llSetTimerEvent(llGetRegionTimeDilation()); // On the first event, the processing countdown/timer gets started.
                    // NOTE: Basing the timer directly on time dilation can have adverse effects.
                }
            }
        }
    }
    timer()
    {
        integer i;
        while(i < eventCount)
        {
            key ownerKey = llList2Key(damageQueue, 0);
            string ownerName = llList2String(damageQueue, 1);
            key objectCreator = llList2Key(damageQueue, 2);
            string objectName = llList2Key(damageQueue, 3);
            integer damageAmount = llList2Integer(damageQueue, 4);
            integer fullDamage = damageAmount;
            if (damageCap)
            {
                if (damageAmount > damageCap) damageAmount = damageCap;
            }
            damageQueue = llDeleteSubList(damageQueue, 0, 4);
            if (llListFindList(blackList, [(string)ownerKey]) == -1 && llListFindList(blackList, [(string)objectCreator]) == -1)
            {
                integer damageIndex = llListFindList(totalDamageList, [ownerKey, ownerName, objectName]);
                if (fullDamage >= 1000) // excessive damage limit
                {
                    totalDamageList = llListReplaceList(totalDamageList, [], damageIndex, damageIndex + 3);
                    blackList += [(string)ownerKey];
                    if (verboseMode) llOwnerSay((string)ownerName + " tried hitting you with " + objectName + " for an excessive " + (string)fullDamage + " damage; adding to blacklist");
                    llRegionSayTo(blackboxKey, blackboxChannelOut, "send:" + (string)ownerKey + "||" + (string)objectCreator + "||" + objectName + "||" + (string)fullDamage + "||Oneshot_1/" + (string)damageAmount + "/" + (string)fullDamage + "/" + (string)damageCap + "/" + (string)spamTrigger);
                    integer removeIndex = llListFindList(damageQueue, [(string)ownerKey]);
                    while (removeIndex != -1)
                    {
                        damageQueue = llDeleteSubList(damageQueue, removeIndex, removeIndex + 3);
                        --eventCount;
                        removeIndex = llListFindList(damageQueue, [(string)ownerKey]);
                    }
                }
                else    
                {
                    if (damageIndex != -1)
                    {
                        integer damageSum = llList2Integer(totalDamageList, damageIndex + 3) + damageAmount;
                        integer hitCount = llList2Integer(totalDamageList, damageIndex + 4) + 1;
                        totalDamageList = llListReplaceList(totalDamageList, [damageSum, hitCount], damageIndex + 3, damageIndex + 4);
                        if (damageSum > spamTrigger)
                        {
                            if (hitCount >= 6)
                            {
                                integer damagePerHit = damageSum / hitCount;
                                if(damagePerHit > 5)
                                {
                                    totalDamageList = llListReplaceList(totalDamageList, [], damageIndex, damageIndex + 3);
                                    blackList += [(string)ownerKey];
                                    if (verboseMode) llOwnerSay((string)ownerName + " is spamming you with damage: " + (string)damageSum + " over " + (string)hitCount + " hits (" + (string)damagePerHit + " damage per hit) with "+(string)damageAmount+" damage on last hit; adding to blacklist");
                                    llRegionSayTo(blackboxKey, blackboxChannelOut, "send:" + (string)ownerKey + "||" + (string)objectCreator + "||" + objectName + "||" + (string)fullDamage + "||Spam_" + (string)hitCount + "/" + (string)fullDamage + "/" + (string)damagePerHit + "/" + (string)damageCap + "/" + (string)spamTrigger);
                                    // @black2; // delet this
                                    integer removeIndex = llListFindList(damageQueue, [(string)ownerKey]);
                                    while (removeIndex !=-1)
                                    {
                                        damageQueue = llDeleteSubList(damageQueue, removeIndex, removeIndex + 3);
                                        --eventCount;
                                        removeIndex = llListFindList(damageQueue, [(string)ownerKey]);
                                    }
                                }
                            }
                        }
                    }
                    else totalDamageList += [ownerKey, ownerName, objectName, damageAmount, 1];
                }
            }
            ++i;
        }
        eventCount = 0;
        integer damageCount = (llGetListLength(totalDamageList) + 1) / 5;
        list outputList; // used to report damage, except in LBA Light Deployable
        i = 0;
        while(i < damageCount)
        {
            integer strideIndex = i * 5;
            integer damageAmount = llList2Integer(totalDamageList, strideIndex + 3);
            if (LBAType != 2) // not used in LBA Light Deployable
            {
                key ownerKey = llList2Key(totalDamageList, strideIndex);
                string ownerName = llList2String(totalDamageList, strideIndex + 1);
                string objectName = llList2String(totalDamageList, strideIndex + 2);
                integer hitCount = llList2Integer(totalDamageList, strideIndex + 4);
                if (damageAmount > 0)
                {
                    if (hitCount == 1) outputList += "Hit by " + ownerName + " with \"" + objectName + "\" for " + (string)damageAmount + " damage.";
                    else outputList += "Hit by " + ownerName + " with \"" + objectName + "\" " + (string)hitCount + " times for " + (string)damageAmount + " damage.";
                }
                else if (damageAmount < 0)
                {
                    if (hitCount == 1) outputList += "Repaired by " + ownerName + " with \"" + objectName + "\" for " + (string)damageAmount + " damage.";
                    else outputList += "Repaired by " + ownerName + " with \"" + objectName + "\" " + (string)hitCount + " times for " + (string)damageAmount + " damage.";
                }
            }
            healthAmount -= damageAmount;
            if (healthAmount < 0) healthAmount = 0;
            if (healthAmount > maxHealth) healthAmount = maxHealth;
            ++i;
        }
        UpdateHP();
        if (outputList) // not used in LBA Light Deployable
        {
            llOwnerSay("Armor integrity reports:\n" + llDumpList2String(outputList, "\n"));
        }
        totalDamageList = [];
        if (llGetTime() > lastCleanup + 120)
        {
            lastCleanup = llGetTime();
            recentSources = [];
            llSetTimerEvent(0);
        }
    }
    collision_start(integer total)
    { // suppressed at state_entry if using LBA Light/Deployable
        integer n;
        while (n < total)
        {
            integer type = llDetectedType(n);
            if (~type & AGENT)
            {
                if (llVecMag(llDetectedVel(n)) > 20) // 10? Is someone shooting you with a popgun?
                {
                    if (healthAmount) --healthAmount;
                    else Die();
                }
            }
            n++;
        }
        UpdateHP();
    }
}

/* CHANGE LOG
2.06 - Release
2.06 -> 2.07 - 
    Added integer neghex1, neghex2 so the script won't have to constantly recalculate reghex*-1/-2
    Added key myOwner, myKey so it won't have to keep looking for llGetOwner/llGetKey on events
    @ 135,- Fixed first channel check in listener to be == instead of =
    @ 121 - Fixed HP display being lost on region crossing, only showing back up when damage taken.
2.07 -> 2.1
    Added list recent, float cleanup
    Updated collision handling, handlehp(); after all collisions are processed, fors switched to whiles
2.1 -> 2.2
    Checks to see if whats damaging it has damaged it before, if the damage is over 1 and not attached
    If attached, checks if the owner is actually aiming at the hitbox with a 2m margin of error.
2.2 -> 2.21
    I FUCKED UP, THE 2M MARGIN OF ERROR DIDN'T TAKE ROTATIONS INTO ACCOUNT LOL
    This has that fixed, I blame tired scripting and 50 hour work weeks :(
    Thank jakobbischerk for finding this by trying to repair my barbed wire of all things
2.21 -> 2.21a
    Improved readability with whitespace and self-documenting variable names.
    Also optimized a few segments of code for performance.
        -Thunder Rahja
2.21a -> 2.21b
    Went further and combined all editions of LBA into one.
    Removed unfiltered blackbox listen to prevent exploitation.
    Blackbox itself may need to be adequately secured to prevent tampering.
    LBA edition selected by LBAType at the top of the script.
    Further optimizations likely if I get bored while working on the Vos Imperium HUD.
        -Thunder Rahja

*/// END CHANGE LOG
