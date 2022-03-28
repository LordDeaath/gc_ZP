#include <amxmodx>
#include <hamsandwich>
#include <zp50_gamemodes>
#include <zp50_colorchat>
#include <cstrike>

//#define TEST
#if defined TEST
#include <fun>
#endif

new Infection,Multi, bool:IsInfection,Map;

new bool:Zombie[33]

enum{COLORS=1, LASER, APPALL, APPREHENSION, BIOHAZARD,AWAKEN,BLUEROOM,MECHANIX,DOJO,LABORATORY,CUBEWORLD,DOWNTOWN,ABYSS,TOMB,ABANDON,CONCERT,JUGGERNAUT,EGYPTIAN}

enum{ALLOW_INFECTION,SLAY_PLAYER,PREVENT_INFECTION}

public CheckMap()
{
    new mapname[32]
    get_mapname(mapname, charsmax(mapname))
    if(equali(mapname, "zm_lgk_colors")) Map = COLORS
    else if(equali(mapname, "zm_lgk_laser")) Map = LASER
    else if(equali(mapname, "zm_lgk_appall_v1")) Map = APPALL
    else if(equali(mapname, "zm_apprehension")) Map = APPREHENSION
    else if(equali(mapname, "zm_biohazard_base_mx")) Map = BIOHAZARD
    else if(equali(mapname, "zm_gc_awaken")) Map = AWAKEN
    else if(equali(mapname, "zm_lgk_blueroom_remake2")) Map = BLUEROOM
    else if(equali(mapname, "zm_mechanix_v2")) Map = MECHANIX
    else if(equali(mapname, "zm_gc_dojo")) Map = DOJO
    else if(equali(mapname, "zm_lgk_laboratory_v3")) Map = LABORATORY
    else if(equali(mapname, "zm_cubeworld_v1")) Map = CUBEWORLD
    else if(equali(mapname, "zm_downtown")) Map = DOWNTOWN
    else if(equali(mapname, "zm_zod_abyss")) Map = ABYSS
    else if(equali(mapname, "zm_lgk_tomb")) Map = TOMB 
    else if(equali(mapname, "zm_abandon_v2")) Map = ABANDON
    else if(equali(mapname, "zm_af-concert-2017_final")) Map = CONCERT
    else if(equali(mapname, "zm_lgk_juggernaut")) Map = JUGGERNAUT
    else if(equali(mapname, "zm_zod_egyptian")) Map = EGYPTIAN

    /*
    else if(equali(mapname, "")) Map = 
    */
}

public check(victim,attacker)
{
    switch(Map)
    {
        case COLORS:
        {
            new ho[3]
            get_user_origin(victim, ho)
            if(InCube(ho,239,270,-110,770,386,-37))
            {
                new zmo[3]
                get_user_origin(attacker, zmo)
                if(InCube(zmo,288,223,-8,740,449,173))return PREVENT_INFECTION
            }
            else if(InCube(ho,2397,-874,450,2591,-712,555))
            {                
                new zmo[3]
                get_user_origin(attacker, zmo)
                if(InCube(zmo,2254,-702,335,2590,-559,511))return PREVENT_INFECTION

            }
            else if(InTriangle(ho,2167,-1072,2402,-713,2580,-1115,449,535))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InTriangle(zmo,2427,-670,2152,-1060,2108,-685,393,526))return PREVENT_INFECTION;
            }
        }
        case LASER:
        {
            new ho[3]
            get_user_origin(victim, ho)
            if(InCube(ho,773,-416,-115,1152,9,-25))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,835,-382,-12,1137,-49,139))return PREVENT_INFECTION;
            }            
            if(InCube(ho,864,-283,-79,865,-186,-15)||InCube(ho,921,-319,-78,1054,-116,-15)||InTriangle(ho,935,-117,866,-191,928,-323,-80,-16)||InTriangle(ho,865,-255,930,-321,927,-124,-80,-7))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(!InCube(zmo,864,-283,-79,865,-186,-15)&&!InCube(zmo,921,-319,-78,1054,-116,-15)&&!InTriangle(zmo,935,-117,866,-191,928,-323,-80,-16)&&!InTriangle(zmo,865,-255,930,-321,927,-124,-80,-7)&&!InCube(zmo,802,-289,-77,1059,-161,-12))return SLAY_PLAYER;
            }
            else if(InCube(ho,33,1218,131,163,1665,204))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,30,1184,31,161,1688,97)||InCube(zmo,-33,1070,117,203,1184,231))return PREVENT_INFECTION;
            }
            else if(InCube(ho,640,162,40,734,476,102))
            {                
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,618,503,0,769,584,125)||InCube(zmo,511,163,41,607,504,123))return SLAY_PLAYER;
            }
            else if(InCube(ho,1024,-799,-14,1247,-513,116))
            {                
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,869,-479,-11,1280,-343,158)||InCube(zmo,869,-788,21,990,-343,158))return SLAY_PLAYER;
            }
            else if(InCube(ho,-831,-32,394,-304,99,453)||InCube(ho,-831,-32,392,-704,591,453))
            {                
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(!InCube(zmo,-831,-31,397,-697,715,452)&&!InCube(zmo,-831,-31,388,-303,100,452)&&!InCube(zmo,-452,-158,398,-305,99,450))return PREVENT_INFECTION;
            }
        }
        case APPALL:
        {
            new ho[3]
            get_user_origin(victim,ho)
            if(InCube(ho,1,-1759,18,290,-1313,210))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,322,-1735,54,446,-1280,115)||InCube(zmo,-96,-1282,19,242,-1006,278))return SLAY_PLAYER;
            }
            else if(InCube(ho,478,-1760,21,767,-1312,212))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,318,-1741,54,445,-1278,116)||InCube(zmo,528,-1280,22,781,-1154,231))return SLAY_PLAYER;
            }
            else if(InCube(ho,-445,-1090,-91,-253,-962,-28))
            {                
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-595,-1235,-89,-223,-1121,17)||InCube(zmo,-595,-1235,-90,-477,-954,17)||InCube(zmo,-221,-1217,-88,-127,-1025,-24))return SLAY_PLAYER;
            }
            else if(InCube(ho,-964,-1567,69,-897,-1376,144))
            {               
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-862,-1667,70,-795,-1376,176)||InCube(zmo,-960,-1667,-32,-795,-1599,176))return SLAY_PLAYER
            }
            else if(InCube(ho,-765,-1568,69,-701,-1377,130))
            {             
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-878,-1662,70,-802,-1376,135)||InCube(zmo,-878,-1662,-30,-699,-1598,135))return SLAY_PLAYER
            }
            else if(InCube(ho,-352,-127,-87,-129,160,52))
            {          
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-504,-224,-90,-383,306,69)||InCube(zmo,-504,192,-89,0,306,69)||InCube(zmo,-94,-104,-89,0,192,-28))return SLAY_PLAYER;
            }
        }
        case APPREHENSION:
        {
            new ho[3]
            get_user_origin(victim,ho)
            if(InCube(ho,-1339,1481,-360,-945,2061,-297))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-1376,1467,-267,-910,2096,-107)) return PREVENT_INFECTION;
            }
            else if(InCube(ho,-2012,3336,-234,-1760,3469,-48))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-1903,3506,-201,-1777,3615,-141)||InCube(zmo,-2229,3177,-235,-2063,3473,-75)||InCube(zmo,-2229,3177,-233,-1760,3319,-75)) return SLAY_PLAYER;
            }           
        } 
        case BIOHAZARD:
        {
            new ho[3]
            get_user_origin(victim,ho)
            if(InCube(ho,-289,761,99,162,945,152))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-394,649,53,-302,960,236)||InCube(zmo,-394,649,58,296,744,236)||InCube(zmo,181,744,58,296,895,260)) return SLAY_PLAYER;
            }
            if(InCube(ho,-288,760,104,123,811,153))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-285,826,105,124,895,163)) return SLAY_PLAYER;
            }
            if(InCube(ho,-221,817,104,165,879,153))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-223,896,104,189,949,156)) return SLAY_PLAYER;
            }
            else if(InCube(ho,-750,-555,264,-327,-439,313))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-764,-422,218,-172,-290,434)||InCube(zmo,-311,-573,229,-209,-335,378)) return SLAY_PLAYER;
            }
            if(InCube(ho,-749,-492,264,-383,-437,309))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-754,-586,264,-384,-503,328)) return SLAY_PLAYER;
            }
            if(InCube(ho,-693,-557,264,-324,-485,325))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-692,-636,264,-237,-575,351)) return SLAY_PLAYER;
            }            
        }
        case AWAKEN:
        {
            new ho[3]
            get_user_origin(victim,ho)
            if(InCube(ho,402,-1390,-10,702,-1266,90))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,285,-1486,-10,702,-1408,192)||InCube(zmo,285,-1486,-12,386,-1158,192)||InCube(zmo,386,-1245,-12,645,-1158,59)) return SLAY_PLAYER;
            }
            if(InCube(ho,182,-758,-8,702,-672,69))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,167,-876,-10,707,-767,100)) return SLAY_PLAYER;
            }
            if(InCube(ho,183,-759,-12,305,-525,144))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,0,-824,-6,164,-531,249)) return SLAY_PLAYER;
            }
            if(InCube(ho,302,-769,-8,708,-674,99))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,309,-660,24,706,-525,76)) return SLAY_PLAYER;
            }
            if(InCube(ho,304,-663,23,638,-602,76))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,318,-590,22,638,-511,76)) return SLAY_PLAYER;
            }
            if(InCube(ho,200,-650,-8,302,-528,111))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,324,-587,24,447,-478,93)) return SLAY_PLAYER;
            }
            else if(InCube(ho,-700,-997,-8,-201,-546,43))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-703,-527,-10,-95,-428,161)||InCube(zmo,-190,-903,-8,-95,-428,161)||InCube(zmo,-709,-1114,-7,-199,-1011,135)) return SLAY_PLAYER;
            }
            if(InCube(ho,-619,-903,-9,-289,-633,41))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-277,-822,-8,-209,-546,41)||InCube(zmo,-707,-624,-11,-209,-546,41)||InCube(zmo,-707,-1003,-11,-626,-624,48)||InCube(zmo,-626,-1003,-9,-196,-912,48)) return SLAY_PLAYER;
            }
            else if(InCube(ho,-607,-1783,5,-456,-1569,83))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-703,-1550,8,-388,-1410,157)||InCube(zmo,-452,-1790,3,-364,-1415,131)||InCube(zmo,-696,-1856,3,-364,-1790,61)||InCube(zmo,-696,-1856,4,-615,-1646,61)) return SLAY_PLAYER;
            }
            else if(InCube(ho,-369,527,-11,369,936,180))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-447,451,-8,-381,1023,44)||InCube(zmo,-447,951,-10,-33,1023,44)||InCube(zmo,29,950,-13,457,1037,52)||InCube(zmo,384,511,-5,457,1037,52)||InCube(zmo,-348,274,-6,388,482,175)) return SLAY_PLAYER;
            }
        }
        case BLUEROOM:
        {
            new ho[3]
            get_user_origin(victim,ho)
            if(InCube(ho,-1180,-285,-256,-784,-51,-197))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-1101,-386,-257,-681,-321,-194)||InCube(zmo,-752,-386,-260,-681,4,-194)||InCube(zmo,-1259,-33,-259,-614,112,-41)) return SLAY_PLAYER;
            }
            else if(InCube(ho,-1340,-1152,-259,-957,-609,-131))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-926,-1154,-256,-744,-581,-71)) return SLAY_PLAYER;
            }
            if(InCube(ho,-1341,-1151,-258,-1014,-1088,-132))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-1341,-1054,-257,-1014,-991,-131)) return SLAY_PLAYER;
            }
            else if(InCube(ho,-1285,-1053,-259,-959,-992,-132))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-1285,-959,-258,-959,-896,-131)) return SLAY_PLAYER;
            }
            else if(InCube(ho,-1278,-1449,-256,-1049,-1311,-193))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-1277,-1280,-258,-988,-1168,-196)) return SLAY_PLAYER;
            }
            else if(InCube(ho,906,942,-241,1204,1246,-97))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,772,837,-257,888,1263,-25)) return SLAY_PLAYER;
            }
            else if(InCube(ho,-428,1088,-258,-242,1294,-195))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-224,975,-257,-173,1238,-173)||InCube(zmo,-489,975,-258,-173,1075,-173)) return SLAY_PLAYER;
            }
           
        }
        case MECHANIX:
        {
            new ho[3]
            get_user_origin(victim,ho)
            if(InCube(ho,-192,-384,-281,203,-265,-162))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-218,-567,-289,268,-400,-146)) return SLAY_PLAYER;
            }    
            else if(InCube(ho,-408,-90,-281,-105,126,-171))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-549,-5,-288,-426,258,-177)||InCube(zmo,-547,140,-262,-31,255,-179)) return SLAY_PLAYER;
            }
            if(InCube(ho,-267,-241,-283,-53,83,-167))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-40,-238,-260,39,138,-196)) return SLAY_PLAYER;
            }
            if(InCube(ho,104,-155,-281,407,126,-171))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,6,139,-266,547,256,-184)||InCube(zmo,423,-8,-296,547,256,-184)) return SLAY_PLAYER;
            }
            if(InCube(ho,55,-242,-281,271,80,-172))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-39,-239,-257,39,86,-195)) return SLAY_PLAYER;
            }
            if(InTriangle(ho,121,145,49,56,142,41,-281,-105))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InTriangle(zmo,182,201,-18,10,-24,193,-264,-195)) return SLAY_PLAYER;
            }
            if(InTriangle(ho,-42,66,-116,141,-147,36,-271,-170))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InTriangle(zmo,16,4,-180,206,2,194,-262,-177)) return SLAY_PLAYER;
            }
            if(InCube(ho,-181,267,-281,191,399,-170))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-202,416,-285,158,590,-143)) return SLAY_PLAYER;
            }
            else if(InCube(ho,880,1224,-330,1311,1287,-267))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,877,936,-353,1308,1205,-243)) return SLAY_PLAYER;
            }
            else if(InCube(ho,882,857,-328,1309,917,-267))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,880,936,-354,1298,1208,-243)) return SLAY_PLAYER;
            }
            else if(InCube(ho,128,331,-49,342,400,50)||InCube(ho,272,331,-49,342,607,50))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,130,418,-67,260,660,31)) return SLAY_PLAYER;
            }
            else if(InCube(ho,-344,320,-50,-128,399,43)||InCube(ho,-344,320,-49,-272,606,43))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-254,415,-65,-127,711,36)) return SLAY_PLAYER;
            }
            
        }
        case DOJO:
        {
            new ho[3]
            get_user_origin(victim,ho)
            if(InCube(ho,-1779,22,69,-1487,384,142))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-1475,-1,-16,-1164,392,200)) return SLAY_PLAYER;
            }
            
            if(InCube(ho,-1742,-78,70,-1488,82,157))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-1764,-305,-9,-1472,-99,197)) return SLAY_PLAYER;
            }
            if(InCube(ho,-1730,306,70,-1554,385,136))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-1731,157,70,-1552,287,143)) return SLAY_PLAYER;
            }
            if(InCube(ho,-1661,210,70,-1477,338,148))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-1663,11,70,-1485,188,133)) return SLAY_PLAYER;
            }
            if(InCube(ho,-1732,114,70,-1553,281,144))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-1731,-82,70,-1552,94,133)) return SLAY_PLAYER;
            }
            if(InCube(ho,-1661,17,71,-1488,383,132))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-1664,-79,69,-1488,0,131)) return SLAY_PLAYER;
            }
            else if(InCube(ho,-1570,96,-8,-1488,285,42))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-1470,-15,-8,-1360,382,170)) return SLAY_PLAYER;
            }
            else if(InCube(ho,-1726,-766,70,-1296,-433,132))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-1281,-769,-12,-1097,-242,180)||InCube(zmo,-1725,-413,69,-1097,-242,180)) return SLAY_PLAYER;
            }
            if(InCube(ho,-1600,-765,-10,-1299,-431,51))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-1599,-416,-10,-1184,-303,85)||InCube(zmo,-1276,-766,-9,-1184,-303,85)) return SLAY_PLAYER;
            }
            if(InCube(ho,-1727,-431,-9,-1283,-337,52))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-1736,-319,-9,-1281,-170,100)) return SLAY_PLAYER;
            }
            if(InCube(ho,-1726,-651,70,-1298,-433,130))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-1726,-640,-9,-1296,-431,52)) return SLAY_PLAYER;
            }
            else if(InCube(ho,243,-414,38,437,-361,91))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,121,-342,37,439,-271,141)||InCube(zmo,121,-430,-9,224,-271,141)) return SLAY_PLAYER;
            }
            else if(InCube(ho,1232,-703,1,1454,-306,62))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,1032,-703,0,1200,-114,146)||InCube(zmo,1067,-141,186,1067,-141,186)) return SLAY_PLAYER;
            }
            if(InCube(ho,1389,-703,0,1454,-306,63))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,1236,-703,0,1363,-303,64)) return SLAY_PLAYER;
            }
            else if(InCube(ho,-94,1376,21,93,1498,82))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-95,1232,21,109,1342,84)) return SLAY_PLAYER;
            }
            if(InCube(ho,-223,1487,21,-32,1612,83))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-229,1332,22,-33,1455,84)) return SLAY_PLAYER;
            }
            if(InCube(ho,-93,1602,22,93,1678,82))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-96,1473,18,96,1571,85)) return SLAY_PLAYER;
            }
            else if(InCube(ho,-1262,960,21,-972,1131,89))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-1263,827,21,-888,942,89)) return SLAY_PLAYER;
            }
            else if(InCube(ho,-1406,1330,101,-1198,1569,163))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-1184,1180,104,-1052,1578,238)||InCube(zmo,-1405,1180,102,-1052,1309,238)) return SLAY_PLAYER;
            }
            else if(InCube(ho,-1344,1437,99,-1298,1678,102))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-1282,1250,100,-1133,1683,216)||InCube(zmo,-1346,1250,98,-1133,1425,216)) return SLAY_PLAYER;
            }
            if(InCube(ho,-1343,1441,102,-1297,1679,182))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-1344,1289,103,-1176,1422,186)||InCube(zmo,-1279,1289,101,-1176,1679,186)) return SLAY_PLAYER;
            }
            if(InCube(ho,-1407,1520,101,-1359,1679,164))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-1406,1329,102,-1361,1502,162)) return SLAY_PLAYER;
            }
            if(InCube(ho,-1344,1598,99,-1297,1679,175))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-1344,1437,100,-1296,1584,208)) return SLAY_PLAYER;
            }
            else if(InCube(ho,-753,1008,406,-686,1362,469))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-672,994,405,-454,1375,494)) return SLAY_PLAYER;
            }
        } 
        case LABORATORY:
        {
            new ho[3]
            get_user_origin(victim,ho)
            if(InCube(ho,386,402,-509,750,654,-448))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,448,673,-510,897,797,-410)||InCube(zmo,758,269,-521,897,797,-410)||InCube(zmo,308,156,-510,902,384,-372)) return SLAY_PLAYER;
            }      
            else if(InCube(ho,-1105,-335,-239,-896,-77,-157))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-1197,-571,-237,-896,-353,-109)) return SLAY_PLAYER;
            }     
            if(InCube(ho,-1038,-254,-238,-829,-77,-167))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-1038,-520,-238,-807,-274,-144)) return SLAY_PLAYER;
            }
            if(InCube(ho,-1102,-174,-237,-898,-80,-146))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-1156,-593,-239,-896,-192,-70)) return SLAY_PLAYER;
            }
            else if(InCube(ho,-1933,-2445,-237,-1763,-1842,-161))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-1807,-2566,-236,-1605,-2483,-137)||InCube(zmo,-1740,-2544,-239,-1559,-1654,-130)||InCube(zmo,-2144,-1811,-245,-1617,-1591,-112)||InCube(zmo,-2102,-2575,-249,-1945,-1720,-126)||InCube(zmo,-2102,-2575,-237,-1888,-2482,-126)) return SLAY_PLAYER;
            }
        }
        case CUBEWORLD:
        {
            new ho[3]
            get_user_origin(victim,ho)
            if(InCube(ho,-750,1154,67,-623,1293,170))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-889,1025,3,-770,1381,186)) return SLAY_PLAYER;
            }
            else if(InCube(ho,-2766,-381,35,-2577,-102,124))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-2558,-382,-61,-2379,-78,95)) return SLAY_PLAYER;
            }
            else if(InCube(ho,-46,1489,161,398,1583,223))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,15,1615,160,400,1761,232)) return SLAY_PLAYER;
            }
        }
        case DOWNTOWN:
        {
            new ho[3]
            get_user_origin(victim,ho)
            if(InCube(ho,1001,-1039,154,1046,-794,208))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,1072,-1040,153,1172,-650,228)||InCube(zmo,976,-768,130,1172,-650,228)) return SLAY_PLAYER;
            }
            else if(InCube(ho,1217,-1038,153,1261,-794,207))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,1097,-1039,153,1191,-661,266)||InCube(zmo,1097,-767,130,1287,-661,266)) return SLAY_PLAYER;
            }
            else if(InCube(ho,-590,-797,25,-345,-753,80))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-592,-726,24,-188,-596,171)||InCube(zmo,-327,-825,-3,-188,-596,171)) return SLAY_PLAYER;
            }
            else if(InCube(ho,-590,-581,25,-346,-538,78))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-591,-689,25,-190,-608,122)||InCube(zmo,-321,-689,0,-190,-511,122)) return SLAY_PLAYER;
            }
            else if(InCube(ho,1570,-661,139,1757,-490,221))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,1786,-550,153,1974,-294,287)||InCube(zmo,1447,-475,143,1834,-305,280)||InCube(zmo,1291,-830,146,1547,-393,283)||InCube(zmo,1508,-801,148,1917,-685,258)||InCube(zmo,1785,-801,153,1917,-600,258)) return SLAY_PLAYER;
            }
            else if(InCube(ho,1498,-740,155,1826,-412,208))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,1348,-551,132,1470,-193,292)||InCube(zmo,1403,-401,116,1931,-263,320)||InCube(zmo,1844,-947,112,1970,-313,299)||InCube(zmo,1300,-836,125,1913,-763,309)||InCube(zmo,1300,-836,129,1473,-600,309)) return SLAY_PLAYER;
            }
            else if(InCube(ho,-636,-1085,209,-593,-913,254)||InCube(ho,-636,-1085,209,-161,-1040,254))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-573,-1014,194,-159,-783,344)) return SLAY_PLAYER;
            }
            else if(InCube(ho,594,-685,2,662,-497,55))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,411,-693,2,565,-496,99)) return SLAY_PLAYER;
            }
            else if(InCube(ho,-606,-382,130,-560,-192,201))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-534,-380,131,-449,-136,257)) return SLAY_PLAYER;
            }
            else if(InCube(ho,1817,65,153,1982,267,230))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,1612,-90,128,1793,264,266)||InCube(zmo,1612,-90,130,2029,42,266)) return SLAY_PLAYER;
            }
        }
        case ABYSS:
        {
            new ho[3]
            get_user_origin(victim,ho)
            if(InCube(ho,1263,2160,3444,1631,2224,3508)||InCube(ho,1553,2160,3446,1631,2365,3508))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,1138,2255,3445,1519,2368,3537)) return SLAY_PLAYER;
            }
            if(InCube(ho,1457,2304,3445,1628,2429,3507))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,1169,2303,3445,1426,2431,3534)) return SLAY_PLAYER;
            }
           
        }
        case TOMB:
        {
            new ho[3]
            get_user_origin(victim,ho)
            if(InCube(ho,765,-354,-12,992,352,52))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,548,-492,-12,1127,-382,126)||InCube(zmo,555,375,-10,1125,491,164)||InCube(zmo,607,-484,-11,736,480,127)) return SLAY_PLAYER;
            } 
            if(InCube(ho,863,63,-11,989,350,51))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,864,-83,-11,1127,30,58)||InCube(zmo,1013,-83,-14,1127,486,58)) return SLAY_PLAYER;
            }
            if(InCube(ho,864,-352,-10,992,-65,52))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,864,-28,-9,1137,80,81)||InCube(zmo,1010,-479,-15,1137,80,81)) return SLAY_PLAYER;
            }
            else if(InCube(ho,-640,63,-108,-289,127,-43))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-639,-47,-107,-256,34,-37)) return SLAY_PLAYER;
            }
            else if(InCube(ho,-639,-127,-107,-287,-64,-44))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-640,-33,-107,-255,34,-41)) return SLAY_PLAYER;
            }
            else if(InCube(ho,425,-27,148,751,32,210)||InCube(ho,323,-190,152,511,188,210))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(!InCube(zmo,323,-190,152,511,188,210)&&!InCube(zmo,413,-22,147,923,35,210)) return PREVENT_INFECTION;
            }
            else if(InCube(ho,-287,257,406,351,318,468))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-384,352,405,255,415,468)||InCube(zmo,-384,113,379,-318,415,468)||InCube(zmo,-367,85,392,408,232,528)) return SLAY_PLAYER;
            }
            else if(InCube(ho,-287,-319,405,350,-257,468))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-384,-417,405,255,-353,468)||InCube(zmo,-384,-417,399,-316,-173,468)||InCube(zmo,-364,-222,375,446,-56,513)) return SLAY_PLAYER;
            }
            else if(InCube(ho,-639,64,375,-513,127,434))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-640,-3,372,-390,33,449)||InCube(zmo,-480,-3,374,-390,224,449)) return SLAY_PLAYER;
            }
            else if(InCube(ho,-639,-126,370,-512,-58,435))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-639,-29,374,-411,19,458)||InCube(zmo,-480,-224,373,-411,19,458)) return SLAY_PLAYER;
            }
            else if(InCube(ho,129,641,21,189,765,81))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,12,640,21,94,865,115)||InCube(zmo,12,798,18,193,865,115)) return SLAY_PLAYER;
            }    
            else if(InCube(ho,-95,-863,150,638,-800,211))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,0,-767,149,683,-681,260)) return SLAY_PLAYER;
            }    
            if(InCube(ho,-95,-863,149,-33,-737,211))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,0,-769,148,85,-621,261)||InCube(zmo,-211,-713,140,85,-621,261)||InCube(zmo,-191,-960,142,-123,-657,212)) return SLAY_PLAYER;
            }   
            if(InCube(ho,-97,-861,149,62,-803,218))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-192,-960,161,62,-896,224)) return SLAY_PLAYER;
            }
            if(InCube(ho,128,-862,162,637,-801,224))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,128,-959,160,638,-895,223)) return SLAY_PLAYER;
            }
        } 
        case ABANDON:
        {
            new ho[3]
            get_user_origin(victim,ho)
            if(InCube(ho,81,-589,509,531,-501,639))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,70,-496,505,523,-395,655)) return SLAY_PLAYER;
            }    
            else if(InCube(ho,167,-496,513,638,-407,649))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,160,-399,546,611,-308,653)) return SLAY_PLAYER;
            }
            else if(InCube(ho,73,-415,499,527,-311,666))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,31,-302,512,524,-215,669)) return SLAY_PLAYER;
            }
            else if(InCube(ho,370,109,493,656,240,645))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,323,-31,493,681,103,712)) return SLAY_PLAYER;
            }   
            else if(InCube(ho,-672,-976,527,-382,-864,624)||InCube(ho,-670,-974,530,-458,-864,704))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-768,-849,466,-364,-735,625)||InCube(zmo,-750,-845,471,-466,-724,703)) return SLAY_PLAYER;
            }
            else if(InCube(ho,-1087,-303,917,-1020,208,997))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-1089,-307,745,-1024,206,854)) return SLAY_PLAYER;
            }
            else if(InCube(ho,-1678,49,514,-1377,270,671))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-1779,-113,544,-1712,207,619)||InCube(zmo,-1779,-113,499,-1207,20,619)||InCube(zmo,-1339,20,499,-1207,270,685)) return SLAY_PLAYER;
            }
            else if(InCube(ho,-1679,-365,512,-1378,-144,670))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-1789,-303,546,-1714,16,610)||InCube(zmo,-1789,-129,503,-1196,16,610)||InCube(zmo,-1344,-367,503,-1196,-129,653)) return SLAY_PLAYER;
            }
            else if(InCube(ho,-126,573,511,29,828,655))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-271,478,513,-145,830,690)||InCube(zmo,-271,478,510,36,554,690)) return SLAY_PLAYER;
            }
            if(InCube(ho,-117,574,502,33,739,653))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-128,539,386,6,743,488)) return SLAY_PLAYER;
            }
        }
        case CONCERT:
        {
            new ho[3]
            get_user_origin(victim,ho)     
            if(InCube(ho,472,1424,-970,680,1492,-917))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,473,1340,-971,679,1408,-918)) return SLAY_PLAYER;
            }
            if(InCube(ho,473,1340,-971,679,1408,-918))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,472,1424,-970,680,1492,-917)) return SLAY_PLAYER;
            }
            if(InCube(ho,427,1344,-958,550,1485,-912))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,317,1226,-958,551,1327,-853)||InCube(zmo,317,1226,-960,408,1488,-853)) return SLAY_PLAYER;
            }
            else if(InCube(ho,600,1345,-958,725,1485,-912))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,600,1175,-958,825,1326,-830)||InCube(zmo,745,1175,-957,825,1486,-830)) return SLAY_PLAYER;
            }
            else if(InCube(ho,424,1344,-893,726,1486,-848))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,305,1217,-985,407,1490,-766)||InCube(zmo,305,1217,-985,844,1336,-713)||InCube(zmo,740,1259,-961,838,1489,-713)) return SLAY_PLAYER;
            }
            else if(InCube(ho,1057,911,-970,1104,1278,-907))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,970,911,-970,1039,1279,-892)) return SLAY_PLAYER;
            }
            if(InCube(ho,992,964,-970,1104,1329,-907))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,929,975,-971,976,1416,-792)||InCube(zmo,929,1344,-969,1103,1416,-792)) return SLAY_PLAYER;
            }
            else if(InCube(ho,46,910,-969,93,1278,-907))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,113,911,-969,208,1277,-907)) return SLAY_PLAYER;
            }
            if(InCube(ho,49,963,-970,157,1325,-909))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,177,976,-970,272,1433,-795)||InCube(zmo,48,1344,-970,272,1433,-795)) return SLAY_PLAYER;
            }
            else if(InCube(ho,1138,418,-881,1186,864,-834)||InCube(ho,826,814,-883,1186,864,-834))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,821,414,-969,1113,797,-654)||InCube(zmo,1045,337,-882,1182,398,-832)) return SLAY_PLAYER;
            }
            else if(InCube(ho,138,191,-890,496,238,-835)||InCube(ho,448,191,-890,496,558,-835))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,128,255,-976,434,614,-734)) return SLAY_PLAYER;
            }
            else if(InCube(ho,863,255,-882,1183,399,-835))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,700,414,-929,1184,537,-751)||InCube(zmo,700,203,-965,850,537,-751)||InCube(zmo,771,166,-883,1129,240,-790)) return SLAY_PLAYER;
            }
            if(InCube(ho,912,334,-883,1184,400,-835))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,914,259,-883,1183,318,-833)) return SLAY_PLAYER;
            }
            else if(InCube(ho,16,639,-971,144,815,-899))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,159,524,-971,245,814,-789)||InCube(zmo,-34,524,-973,245,627,-789)) return SLAY_PLAYER;
            }
            if(InCube(ho,-31,688,-970,79,863,-907))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,98,689,-969,242,871,-843)) return SLAY_PLAYER;
            }
            if(InCube(ho,-35,633,-969,13,814,-871))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,30,636,-972,114,814,-905)) return SLAY_PLAYER;
            }
            if(InCube(ho,-30,640,-890,142,863,-828))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,158,496,-1017,268,863,-734)||InCube(zmo,-36,496,-1017,268,624,-678)) return SLAY_PLAYER;
            }
            if(InCube(ho,33,640,-889,143,814,-827))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-31,640,-954,13,814,-831)) return SLAY_PLAYER;
            }
            if(InCube(ho,97,688,-891,143,863,-828))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-32,688,-890,79,864,-827)) return SLAY_PLAYER;
            }
            else if(InCube(ho,-590,194,-968,-482,557,-909))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-590,577,-970,-395,647,-794)||InCube(zmo,-463,415,-972,-395,647,-794)||InCube(zmo,-462,60,-973,-381,351,-796)||InCube(zmo,-593,60,-972,-381,178,-796)) return SLAY_PLAYER;
            }
            if(InCube(ho,-609,256,-971,-543,485,-909))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-526,259,-970,-474,493,-908)) return SLAY_PLAYER;
            }
            
            if(InCube(ho,-526,259,-970,-474,493,-908))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-609,256,-971,-543,485,-909)) return SLAY_PLAYER;
            }
            if(InCube(ho,-591,192,-890,-418,557,-828))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-591,576,-970,-255,689,-720)||InCube(zmo,-408,47,-993,-255,689,-720)||InCube(zmo,-590,50,-993,-277,173,-754)) return SLAY_PLAYER;
            }
        }
        case JUGGERNAUT:
        {
            new ho[3]
            get_user_origin(victim,ho)
            if(InCube(ho,56,-215,33,316,-89,86))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-70,-74,33,226,23,151)||InCube(zmo,-70,-310,-15,52,23,151)||InCube(zmo,-42,-317,-3,316,-223,227)) return SLAY_PLAYER;
            }
            else if(InCube(ho,-2088,-194,29,-1920,-103,82))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-2087,-92,28,-1815,-2,141)||InCube(zmo,-1915,-312,-2,-1815,-2,141)) return SLAY_PLAYER;
            }
            else if(InCube(ho,-1974,-1422,410,-1716,-1233,465))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-1973,-1210,410,-1630,-1139,537)||InCube(zmo,-1689,-1482,392,-1630,-1139,537)) return SLAY_PLAYER;
            }
            else if(InCube(ho,-1973,-1018,411,-1715,-832,464))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-1974,-1152,408,-1519,-1037,524)||InCube(zmo,-1696,-1152,395,-1519,-697,524)) return SLAY_PLAYER;
            }
            else if(InCube(ho,-355,-1234,597,117,-1154,659))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-356,-1118,598,116,-1004,658)) return SLAY_PLAYER;
            }
            else if(InCube(ho,-356,-1118,598,116,-1004,658))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-355,-1234,597,117,-1154,659)) return SLAY_PLAYER;
            }
            else if(InCube(ho,-2033,-1967,475,-1937,-1850,527))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-2034,-1829,473,-1932,-1715,537)) return SLAY_PLAYER;
            }
            else if(InCube(ho,-2157,-1846,475,-2052,-1749,532))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-2152,-1728,473,-2051,-1639,530)) return SLAY_PLAYER;
            }
            else if(InCube(ho,-2035,-1741,473,-1931,-1651,529))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-2034,-1631,473,-1932,-1528,528)) return SLAY_PLAYER;
            }
            else if(InCube(ho,-2155,-1656,474,-2051,-1552,528))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-2151,-1531,473,-2051,-1441,537)) return SLAY_PLAYER;
            }
            else if(InCube(ho,-2035,-1537,472,-1931,-1447,535))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-2034,-1428,473,-1877,-1372,619)) return SLAY_PLAYER;
            }
            else if(InCube(ho,-2031,-1955,36,-1919,-1795,88))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-2151,-1954,37,-2062,-1690,205)||InCube(zmo,-2151,-1797,4,-1833,-1690,205)) return SLAY_PLAYER;
            }
        }        
        case EGYPTIAN:
        {
            new ho[3]
            get_user_origin(victim,ho)
            if(InCube(ho,386,800,3,846,1117,82))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,163,837,-29,372,1254,144)||InCube(zmo,163,1131,14,926,1254,144)||InCube(zmo,863,800,19,926,1198,82)) return SLAY_PLAYER;
            }
            if(InCube(ho,461,736,-1,926,1055,100))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,942,623,-2,1089,1026,165)||InCube(zmo,354,623,3,1089,723,165)||InCube(zmo,382,654,21,447,1055,87)) return SLAY_PLAYER;
            } 
            else if(InCube(ho,897,-543,22,1326,-481,82)||InCube(ho,897,-909,22,1326,-849,83))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,805,-819,14,1218,-581,129)) return SLAY_PLAYER;
            }
            if(InCube(ho,-101,-1150,5,-17,-897,67))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,16,-1204,-11,152,-864,145)) return SLAY_PLAYER;
            }
            if(InCube(ho,-301,-1151,4,-16,-1058,66))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-400,-1248,5,10,-1185,68)||InCube(zmo,-397,-1184,4,-332,-899,65)) return SLAY_PLAYER;
            }
            else if(InCube(ho,-397,-1150,-61,-288,-898,0))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-609,-1195,-79,-430,-881,41)) return SLAY_PLAYER;
            }
            if(InCube(ho,-398,-1148,-62,-113,-993,18))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-424,-1247,-62,-15,-1187,0)||InCube(zmo,-91,-1247,-63,-17,-893,8)) return SLAY_PLAYER;
            }
            if(InCube(ho,-301,-1053,-62,-114,-993,-16))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-402,-967,-62,-17,-897,-1)||InCube(zmo,-398,-1149,-63,-329,-899,-3)) return SLAY_PLAYER;
            }
            else if(InCube(ho,-723,699,14,-654,956,82))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-624,691,-17,-550,917,108)) return SLAY_PLAYER;
            }
            else if(InCube(ho,-144,702,14,-80,946,79))
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if(InCube(zmo,-283,695,-14,-176,906,137)) return SLAY_PLAYER;
            }


        }
        /*  
            if()
            {
                new zmo[3]
                get_user_origin(attacker,zmo)
                if() return SLAY_PLAYER;
            }
        }*/
        /*
        case :
        {
            new ho[3]
            get_user_origin(victim,ho)
           
        } */
    }
    return ALLOW_INFECTION;
}

public plugin_init()
{
    register_plugin("[ZP] Prevent Walling","1.0","zXCaptainXz")
    RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
    RegisterHam(Ham_Killed, "player", "fw_Killed")
    CheckMap()
    #if defined TEST
    register_clcmd("goo","go")
    register_concmd("tpme","teleportme")
    #endif
}

#if defined TEST
public go(id)
{
    zp_gamemodes_start(0, id)
    set_user_godmode(id,1)
    set_user_maxspeed(id, 750.0)
    set_user_noclip(id, !get_user_noclip(id))
    return PLUGIN_HANDLED;
}

public teleportme(id)
{
    new arg[32],x[8],y[8],origin[3]
    read_args(arg, charsmax(arg))
    strtok(arg,x,charsmax(x),arg,charsmax(arg),',')    
    strtok(arg,y,charsmax(y),arg,charsmax(arg),',')    

    origin[0]=str_to_num(x)
    origin[1]=str_to_num(y)
    origin[2]=str_to_num(arg)
    set_user_origin(id, origin)

}
#endif

public plugin_cfg()
{
    Infection = zp_gamemodes_get_id("Infection Mode")
    Multi = zp_gamemodes_get_id("Multiple Infection Mode")
}

public zp_fw_gamemodes_start(game_mode_id) if(game_mode_id==Infection||game_mode_id==Multi) IsInfection=true;else IsInfection=false;
#if !defined TEST
public zp_fw_core_last_human() IsInfection=false;
#endif
public zp_fw_core_infect_post(id)   Zombie[id]=true
public zp_fw_core_cure_post(id)     Zombie[id]=false
public client_disconnected(id){        Zombie[id]=false;remove_task(id);}
public fw_Killed(id)                Zombie[id]=false;

public fw_TakeDamage(victim, inflictor, attacker)
{
    if(!IsInfection) return HAM_IGNORED    
    if(!is_user_connected(attacker)) return HAM_IGNORED
    if(Zombie[victim]) return HAM_IGNORED;
    if(!Zombie[attacker]) return HAM_IGNORED;
    static action;
    action = check(victim, attacker)
    switch(action)
    {
        case SLAY_PLAYER:
        {
            ExecuteHamB(Ham_Killed, victim, attacker, true)
            static attacker_name[32], victim_name[32]
            get_user_name(attacker, attacker_name, charsmax(attacker_name))
            get_user_name(victim, victim_name, charsmax(victim_name))
            zp_colored_print(0, "^3%s^4 STRANGLED^3 %s^1 through the^4 Wall!",attacker_name, victim_name)
            set_task(5.5, "task_respawn", victim)
            return HAM_SUPERCEDE;            
        }
        case PREVENT_INFECTION:
        {
            zp_colored_print(attacker, "You cannot^4 Infect^1 through this^4 Wall^1!")
            return HAM_SUPERCEDE
        }
    }

    return HAM_IGNORED;
}

public task_respawn(id)
{
    if(is_user_alive(id))
        return;

    // Get player's team
    new CsTeams:team = cs_get_user_team(id)

    // Player moved to spectators
    if (team == CS_TEAM_SPECTATOR || team == CS_TEAM_UNASSIGNED)
        return;

    if(zp_core_get_human_count()>1)
        return;

    if(zp_gamemodes_get_current()!=Infection&&zp_gamemodes_get_current()!=Multi)
        return;

    zp_core_respawn_as_zombie(id, true)    
    ExecuteHamB(Ham_CS_RoundRespawn, id)
    
    zp_colored_print(id, "You have been^3 Respawned^1 to fight the^3 Last Human!")
}

stock isContained(Point, A, B) {	

	if (Point > A && Point < B) {
		return true;
	}

	return false;
}

stock InCube(Origin[3], CX, CY, CZ, CHX, CHY, CHZ) {
	if (isContained(Origin[0], CX, CHX) && isContained(Origin[1], CY, CHY) && isContained(Origin[2], CZ, CHZ)) {
		return true;
	}
	return false;
}

public InTriangle(O[3],X1,Y1,X2,Y2,X3,Y3,H1,H2)
{
	new A=abs(X1*(Y2-Y3)+X2*(Y3-Y1)+X3*(Y1-Y2))
	new A1=abs(O[0]*(Y2-Y3)+X2*(Y3-O[1])+X3*(O[1]-Y2))
	new A2=abs(X1*(O[1]-Y3)+O[0]*(Y3-Y1)+X3*(Y1-O[1]))
	new A3=abs(X1*(Y2-O[1])+X2*(O[1]-Y1)+O[0]*(Y1-Y2))
	return ((A==(A1+A2+A3))&&((O[2]>H1&&O[2]<H2)||(O[2]<H1&&O[2]>H2)))
}