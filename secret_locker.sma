#include <amxmodx>
#include <fakemeta>
#include <engine>
#include <fun>
#include <hamsandwich>
#include <zp50_gamemodes>
#include <zp50_colorchat>

new Infection, Multi
new Ent1,Ent2,Ent3,Ent4

new Map
new Float:InSecret[33]
new bool:Human[33]
new bool:Lock;

enum _:
{
    COLORS=1,
    LASER,
    APPALL,
    APPREHENSION,
    BLUEROOM,
    MECHANIX,
    LABORATORY,
    ABYSS,
    ABANDON,
    SNOWMAN,
    STONEDUST,
    ASSAULTED,
    ANTARCTICA,
    HIDEOUT,
    JUGGERNAUT,
    INFINITY,
    ARMY,
    DUSTB,
    MINECRAFT,
    TORONTO,
    CHRISTMAS,
    AREA51,
    ALTERNATIVE,
    COLDSTEEL,
    DS_AZTEC,
    DOJO,
    FIVE,
    EGYPTIAN,
    GC_AZTEC
}

public CheckMap()
{    
    new mapname[32]
    get_mapname(mapname,charsmax(mapname))

    if(equali(mapname,"zm_lgk_colors"))
    {
        Map = COLORS         
        create_secret(Float:{-2997.0,2628.0,-14.6},Float:{465.0,448.0,151.2},Float:{-465.0,-448.0,-151.2})
    }
    else if(equali(mapname,"zm_lgk_laser"))
    {
        Map = LASER
        Ent1=engfunc(EngFunc_FindEntityByString, 0, "model", "*147")            
        create_secret(Float:{3441.0,-3456.0,-3906.8},Float:{416.1,451.2,200.0},Float:{-416.1,-451.2,-200.0})
    }
    else if(equali(mapname,"zm_lgk_appall_v1"))
    {
        Map = APPALL
        Ent1=engfunc(EngFunc_FindEntityByString, 0, "model", "*165")
        create_secret(Float:{3561.1,453.3,-3815.0},Float:{421.1,628.6,326.5},Float:{-421.1,-628.6,-326.5})
    }
    else if(equali(mapname,"zm_apprehension"))
    {
        Map = APPREHENSION
        Ent1=engfunc(EngFunc_FindEntityByString, 0, "model", "*34")        
        create_secret(Float:{3464.4,-3549.2,596.0},Float:{482.4,300.2,963.2},Float:{-482.4,-300.2,-963.2})        
        create_secret(Float:{-1595.0,2720.0,-194.3},Float:{35.2,31.8,30.7},Float:{-35.2,-31.8,-30.7})
    }
    else if(equali(mapname,"zm_lgk_blueroom_remake2"))
    {
        Map = BLUEROOM
        Ent1=engfunc(EngFunc_FindEntityByString, 0, "model", "*26")        
        create_secret(Float:{454.3,-654.6,-42.5},Float:{224.5,248.3,95.1},Float:{-224.5,-248.3,-95.1})
    }
    else if(equali(mapname,"zm_mechanix_v2"))
    {
        Map = MECHANIX
        Ent1=engfunc(EngFunc_FindEntityByString, 0, "model", "*49")         
        create_secret(Float:{2721.7,3094.6,-2915.8},Float:{491.1,477.5,182.5},Float:{-491.1,-477.5,-182.5})
    }
    else if(equali(mapname, "zm_lgk_laboratory_v3"))
    {
        Map = LABORATORY
        Ent1=engfunc(EngFunc_FindEntityByString, 0, "model", "*75") 
        Ent2=engfunc(EngFunc_FindEntityByString, 0, "model", "*65")         
        create_secret(Float:{-3106.1,2763.1,-437.0},Float:{566.5,502.8,256.5},Float:{-566.5,-502.8,-256.5})
        create_secret(Float:{-606.6,-3083.0,-96.2},Float:{385.1,71.3,66.6},Float:{-385.1,-71.3,-66.6})
        create_secret(Float:{-190.0,-1438.4,96.9},Float:{155.8,584.1,208.8},Float:{-155.8,-584.1,-208.8})
    }
    else if(equali(mapname, "zm_zod_abyss"))
    {
        Map = ABYSS
        Ent1=engfunc(EngFunc_FindEntityByString, 0, "model", "*32")
        create_secret(Float:{-2983.9,-3059.3,-2760.7},Float:{1126.0,1285.1,542.2},Float:{-1126.0,-1285.1,-542.2})      
        
        new ent =  create_entity("info_target");
        entity_set_string(ent, EV_SZ_classname, "abyss_zone")        
        entity_set_origin(ent, Float:{3926.2,2052.4,3860.3})        
        entity_set_int(ent, EV_INT_solid, SOLID_TRIGGER)
        entity_set_size(ent, Float:{-19.1,-40.5,-30.0},Float:{19.1,40.5,30.0})   
    }
    else if(equali(mapname, "zm_abandon_v2"))
    {
        Map = ABANDON
        Ent1=engfunc(EngFunc_FindEntityByString, 0, "model", "*88") 
        create_secret(Float:{2849.2,-3121.7,-3229.4},Float:{634.2,370.4,322.7},Float:{-634.2,-370.4,-322.7})
    }
    else if(equali(mapname, "zm_lgk_snowman_v3"))
    {
        Map = SNOWMAN
        Ent1=engfunc(EngFunc_FindEntityByString, 0, "model", "*56") 
        Ent2=engfunc(EngFunc_FindEntityByString, 0, "model", "*94") 
        create_secret(Float:{-1796.2,589.6,-357.3},Float:{697.7,1330.8,448.9},Float:{-697.7,-1330.8,-448.9})        
        create_secret(Float:{-997.4,-2316.3,21.5},Float:{135.8,239.5,130.1},Float:{-135.8,-239.5,-130.1})
        create_secret(Float:{-1499.7,-3587.3,-331.8},Float:{694.8,341.8,272.0},Float:{-694.8,-341.8,-272.0})
    }
    else if(equali(mapname, "zm_lgk_stonedust2"))
    {
        Map = STONEDUST
        Ent1=engfunc(EngFunc_FindEntityByString, 0, "model", "*201") 
        Ent2=engfunc(EngFunc_FindEntityByString, 0, "model", "*225") 
        create_secret(Float:{-1639.5,326.1,-134.0},Float:{84.1,148.9,56.1},Float:{-84.1,-148.9,-56.1})        
        create_secret(Float:{-1434.1,461.9,168.0},Float:{208.0,151.4,349.3},Float:{-208.0,-151.4,-349.3})        
        create_secret(Float:{1911.4,170.5,-44.2},Float:{140.3,269.0,97.1},Float:{-140.3,-269.0,-97.1})
        create_secret(Float:{1538.5,-1379.1,-326.2},Float:{25.4,33.9,29.7},Float:{-25.4,-33.9,-29.7})
    }
    else if(equali(mapname, "zm_lgk_assaulted2"))
    {
        Map = ASSAULTED
        Ent1=engfunc(EngFunc_FindEntityByString, 0, "model", "*197") 
        Ent2=engfunc(EngFunc_FindEntityByString, 0, "model", "*169")        
        create_secret(Float:{-1420.2,-178.9,-149.1},Float:{185.0,563.8,104.8},Float:{-185.0,-563.8,-104.8})
        create_secret(Float:{121.7,-511.1,-754.7},Float:{253.3,59.4,45.4},Float:{-253.3,-59.4,-45.4})
    }
    else if(equali(mapname, "zm_antarctica_v2"))
    {
        Map = ANTARCTICA
        //Ent1=engfunc(EngFunc_FindEntityByString, 0, "model", "*54") 
        create_secret(Float:{3521.0,2593.8,184.0},Float:{480.5,434.3,269.5},Float:{-480.5,-434.3,-269.5})
    }
    else if(equali(mapname, "zm_zod_hideout"))
    {
        Map = HIDEOUT
        Ent1=engfunc(EngFunc_FindEntityByString, 0, "model", "*72") 
        create_secret(Float:{887.6,-814.9,-434.6},Float:{115.5,185.2,56.0},Float:{-115.5,-185.2,-56.0})
    }    
    else if(equali(mapname, "zm_lgk_juggernaut"))
    {
        Map = JUGGERNAUT
        Ent1=engfunc(EngFunc_FindEntityByString, 0, "model", "*5") 
        Ent2=engfunc(EngFunc_FindEntityByString, 0, "model", "*6") 
        Ent3=engfunc(EngFunc_FindEntityByString, 0, "model", "*7") 
        Ent4=engfunc(EngFunc_FindEntityByString, 0, "model", "*8") 
        create_secret(Float:{-557.5,-24.8,1031.4},Float:{513.2,29.0,126.7},Float:{-513.2,-29.0,-126.7})        
        create_secret(Float:{188.3,-120.9,1123.3},Float:{134.1,122.2,136.0},Float:{-134.1,-122.2,-136.0})
    }    
    else if(equali(mapname, "zm_aztec_infinity"))
    {
        Map = INFINITY
        Ent1=engfunc(EngFunc_FindEntityByString, 0, "model", "*19")             
        remove_entity(engfunc(EngFunc_FindEntityByString, 0, "model", "*62"))    
        remove_entity(engfunc(EngFunc_FindEntityByString, 0, "model", "*20"))    
        create_secret(Float:{322.0,258.5,8.8},Float:{566.1,328.1,243.4},Float:{-566.1,-328.1,-243.4})
    }
    else if(equali(mapname, "zm_new_army"))
    {
        Map = ARMY
        Ent1=engfunc(EngFunc_FindEntityByString, 0, "model", "*23") 
        create_secret(Float:{-419.5,-132.7,-614.4},Float:{40.3,75.5,34.1},Float:{-40.3,-75.5,-34.1})
        create_secret(Float:{1450.2,984.4,-77.1},Float:{258.6,470.7,230.1},Float:{-258.6,-470.7,-230.1})
    }
    else if(equali(mapname, "zm_zod_dustb"))
    {
        Map = DUSTB
        remove_entity(engfunc(EngFunc_FindEntityByString, 0, "model", "*66") )
        Ent1=engfunc(EngFunc_FindEntityByString, 0, "model", "*112") 
    }
    else if(equali(mapname, "zm_minecraft"))
    {
        Map = MINECRAFT
        Ent1=engfunc(EngFunc_FindEntityByString, 0, "model", "*97")
        create_secret(Float:{1537.1,-1101.8,-1607.8},Float:{31.8,152.7,26.3},Float:{-31.8,-152.7,-26.3}) 
    }
    else if(equali(mapname, "zm_toronto_v4"))
    {
        Map = TORONTO
        create_secret(Float:{-1862.5,-2105.7,-3362.4},Float:{2238.2,2001.8,1433.4},Float:{-2238.2,-2001.8,-1433.4})
    }
    else if(equali(mapname, "zm_a_zow_christmas"))
    {
        Map = CHRISTMAS        
        Ent1=engfunc(EngFunc_FindEntityByString, 0, "model", "*104")        
        create_secret(Float:{1215.9,-87.1,76.1},Float:{77.6,148.8,54.0},Float:{-77.6,-148.8,-54.0})
    }
    else if(equali(mapname, "zm_area51_v2"))
    {
        Map = AREA51        
        Ent1=engfunc(EngFunc_FindEntityByString, 0, "model", "*220")        
        create_secret(Float:{-3694.4,-3325.0,-3808.6},Float:{502.1,793.5,321.4},Float:{-502.1,-793.5,-321.4})
    }
    else if(equali(mapname, "zm_alternative_v2"))
    {
        Map = ALTERNATIVE        
        Ent1=engfunc(EngFunc_FindEntityByString, 0, "model", "*25")
        Ent2=engfunc(EngFunc_FindEntityByString, 0, "model", "*29")         
        create_secret(Float:{-611.9,-349.9,112.2},Float:{66.7,32.7,101.5},Float:{-66.7,-32.7,-101.5})        
        create_secret(Float:{941.0,1617.4,253.5},Float:{311.9,446.2,245.6},Float:{-311.9,-446.2,-245.6})                
        create_secret(Float:{559.0,1719.4,177.0},Float:{671.5,263.6,235.2},Float:{-671.5,-263.6,-235.2})
        create_secret(Float:{-568.2,1875.2,333.8},Float:{476.7,181.6,117.1},Float:{-476.7,-181.6,-117.1})
    }
    else if(equali(mapname, "zm_coldsteel_v4"))
    {
        Map = COLDSTEEL        
        Ent1=engfunc(EngFunc_FindEntityByString, 0, "model", "*66")        
        create_secret(Float:{2847.2,2769.2,3638.2},Float:{84.5,48.8,84.9},Float:{-84.5,-48.8,-84.9})
        create_secret(Float:{-3353.2,-2665.0,-3560.3},Float:{659.3,1388.8,561.3},Float:{-659.3,-1388.8,-561.3})
        create_secret(Float:{3297.2,-3435.9,-3498.0},Float:{549.8,600.9,329.8},Float:{-549.8,-600.9,-329.8})
    }
    else if(equali(mapname, "zm_ds_aztec"))
    {
        Map = DS_AZTEC        
        Ent1=engfunc(EngFunc_FindEntityByString, 0, "model", "*40")  
        Ent2=engfunc(EngFunc_FindEntityByString, 0, "model", "*20")                  
        create_secret(Float:{-1532.0,889.7,66.0},Float:{171.3,180.8,92.6},Float:{-171.3,-180.8,-92.6})
        create_secret(Float:{29.8,-1584.2,-634.1},Float:{485.3,279.6,310.4},Float:{-485.3,-279.6,-310.4})    
    }
    else if(equali(mapname, "zm_gc_dojo"))
    {
        Map = DOJO        
        Ent1=engfunc(EngFunc_FindEntityByString, 0, "model", "*38")  
        Ent2=engfunc(EngFunc_FindEntityByString, 0, "model", "*45")          
        create_secret(Float:{-50.1,76.7,391.1},Float:{250.1,248.6,110.9},Float:{-250.1,-248.6,-110.9})
        create_secret(Float:{1067.2,951.8,153.3},Float:{325.5,341.7,166.4},Float:{-325.5,-341.7,-166.4})
        create_secret(Float:{-1273.7,463.2,64.0},Float:{100.6,28.7,26.1},Float:{-100.6,-28.7,-26.1})
    }
    else if(equali(mapname, "zm_five_hd"))
    {
        Map = FIVE        
        Ent1=engfunc(EngFunc_FindEntityByString, 0, "model", "*11")  
        Ent2=engfunc(EngFunc_FindEntityByString, 0, "model", "*12") 
        Ent3=engfunc(EngFunc_FindEntityByString, 0, "model", "*121")
        create_secret(Float:{2341.4,-615.5,740.4},Float:{905.8,769.9,322.2},Float:{-905.8,-769.9,-322.2})   
        create_secret(Float:{810.9,3049.0,658.9},Float:{1762.6,1253.3,461.3},Float:{-1762.6,-1253.3,-461.3})
        create_secret(Float:{-1679.5,-550.2,-222.6},Float:{39.9,82.6,30.8},Float:{-39.9,-82.6,-30.8})    
    }
    else if(equali(mapname, "zm_zod_egyptian"))
    {
        Map = EGYPTIAN        
        Ent1=engfunc(EngFunc_FindEntityByString, 0, "model", "*32")  
        create_secret(Float:{186.8,20.8,-635.3},Float:{441.2,516.1,286.8},Float:{-441.2,-516.1,-286.8})
    }
    else if(equali(mapname, "zm_gc_aztec_a2"))
    {
        Map = GC_AZTEC        
        Ent1=engfunc(EngFunc_FindEntityByString, 0, "model", "*44")
        Ent2=engfunc(EngFunc_FindEntityByString, 0, "model", "*43")
        create_secret(Float:{-905.1,-32.7,-91.0},Float:{53.2,29.6,56.6},Float:{-53.2,-29.6,-56.6})
        create_secret(Float:{-1463.6,401.9,123.5},Float:{228.6,205.8,112.6},Float:{-228.6,-205.8,-112.6})
        create_secret(Float:{-1398.8,88.2,239.4},Float:{443.1,144.8,86.5},Float:{-443.1,-144.8,-86.5})
    }
    
}

public yeet(id)
{
    switch(Map)
    {
        case COLORS:
        {
            if(random(2))
            {
                set_pev(id, pev_origin, {-288.0, -336.0, 144.0})      
                set_pev(id, pev_angles, {0.0,0.0,0.0});
                set_pev(id, pev_fixangle, 1);
            }
            else
            {
                set_pev(id, pev_origin, {2112.0, 896.0, 160.0})      
                set_pev(id, pev_angles, {0.0,0.0,0.0});
                set_pev(id, pev_fixangle, 1);
            }
        }
        case LASER:
        {
            set_pev(id, pev_origin, {1024.0, -225.0, 145.0})
            set_pev(id, pev_angles, {0.0,0.0,0.0});
            set_pev(id, pev_fixangle, 1);
        }
        case APPALL:
        {
            set_pev(id, pev_origin, {192.0, 736.0, 344.0})            
            set_pev(id, pev_angles, {0.0,0.0,0.0});
            set_pev(id, pev_fixangle, 1);
        }
        case APPREHENSION:
        {
            set_pev(id, pev_origin, {-2864.0, 2416.0, -248.0})            
            set_pev(id, pev_angles, {0.0,0.0,0.0});
            set_pev(id, pev_fixangle, 1);            
        }        
        case BLUEROOM:
        {
            set_pev(id, pev_origin, {371.0, 993.0, -22.0})            
            set_pev(id, pev_angles, {0.0,0.0,0.0});
            set_pev(id, pev_fixangle, 1);            
        }        
        case MECHANIX:
        {
            set_pev(id, pev_origin, {368.0,848.0,-186.0})            
            set_pev(id, pev_angles, {0.0,180.0,0.0});
            set_pev(id, pev_fixangle, 1); 
        }
        case LABORATORY:
        {
            set_pev(id, pev_origin, {-1631.819946, -1055.380004, -112.000000})            
            set_pev(id, pev_angles, {0.0,0.0,0.0});
            set_pev(id, pev_fixangle, 1); 
        }
        case ABYSS:
        {
            set_pev(id, pev_origin, {2176.0, 3696.0, 3796.0})            
            set_pev(id, pev_angles, {0.0,271.0,0.0});
            set_pev(id, pev_fixangle, 1); 
        }
        case ABANDON:
        {
            set_pev(id, pev_origin, {-576.0, -720.0, 760.0})            
            set_pev(id, pev_angles, {0.0,271.0,0.0});
            set_pev(id, pev_fixangle, 1);            
        }
        case SNOWMAN:
        { 
            set_pev(id, pev_origin, {-448.0, -832.0, -68.0})            
            set_pev(id, pev_angles, {0.0,0.0,0.0});
            set_pev(id, pev_fixangle, 1);   
        }
        case STONEDUST:
        { 
            set_pev(id, pev_origin, {800.0, -736.0, -47.0})            
            set_pev(id, pev_angles, {0.0,0.0,0.0});
            set_pev(id, pev_fixangle, 1);   
        }
        case ASSAULTED:
        { 
            set_pev(id, pev_origin, {1188.0, -378.0, -196.0})            
            set_pev(id, pev_angles, {0.0,90.0,0.0});
            set_pev(id, pev_fixangle, 1);  
        }
        case ANTARCTICA:
        { 
            set_pev(id, pev_origin, {-32.0, -864.0, 16.0})            
            set_pev(id, pev_angles, {0.0,90.0,0.0});
            set_pev(id, pev_fixangle, 1);  
        }
        case HIDEOUT:
        { 
            set_pev(id, pev_origin, {56.0, -170.0, 8.0})            
            set_pev(id, pev_angles, {0.0,0.0,0.0});
            set_pev(id, pev_fixangle, 1);  
        }
        case JUGGERNAUT:
        { 
            set_pev(id, pev_origin, {0.0, -1140.0, 730.0})            
            set_pev(id, pev_angles, {0.0,180.0,0.0});
            set_pev(id, pev_fixangle, 1);  
        }    
        case INFINITY:
        { 
            set_pev(id, pev_origin, {-640.0, -832.0, -144.0})            
            set_pev(id, pev_angles, {0.0,0.0,0.0});
            set_pev(id, pev_fixangle, 1);  
        }            
        case ARMY:
        { 
            set_pev(id, pev_origin, {576.0, 1016.0, 184.0})            
            set_pev(id, pev_angles, {0.0,180.0,0.0});
            set_pev(id, pev_fixangle, 1);  
        }           
        case MINECRAFT:
        { 
            set_pev(id, pev_origin, {1261.0,-872.0,-757.0})            
            set_pev(id, pev_angles, {0.0,-90.0,0.0});
            set_pev(id, pev_fixangle, 1);  
        }      
        case TORONTO:
        { 
            set_pev(id, pev_origin, {-392.0, 1824.0, 3024.0})            
            set_pev(id, pev_angles, {0.0,0.0,0.0});
            set_pev(id, pev_fixangle, 1);  
        }       
        case CHRISTMAS:
        {       
            set_pev(id, pev_origin, { 1216.0, -96.0, 256.0})            
            set_pev(id, pev_angles, {90.0,0.0,0.0});
            set_pev(id, pev_fixangle, 1);             
        }
        case AREA51:
        {
            set_pev(id, pev_origin, {-2040.0, -121.0, -44.0})            
            set_pev(id, pev_angles, {0.0,90.0,0.0});
            set_pev(id, pev_fixangle, 1);                  
        }        
        case ALTERNATIVE:
        {
            set_pev(id, pev_origin, {-3136.0, 512.0, 312.0})            
            set_pev(id, pev_angles, {0.0,0.0,0.0});
            set_pev(id, pev_fixangle, 1);                  
        }      
        case COLDSTEEL:
        {
            set_pev(id, pev_origin, {2000.0, 1632.0, 3408.0})            
            set_pev(id, pev_angles, {0.0,0.0,0.0});
            set_pev(id, pev_fixangle, 1);                  
        }     
        case DS_AZTEC:
        {
            set_pev(id, pev_origin, {-320.574005, 335.177001, -496.0})            
            set_pev(id, pev_angles, {0.0,270.0,0.0});
            set_pev(id, pev_fixangle, 1);                  
        }
        case DOJO:
        {
            set_pev(id, pev_origin, {-64.000000, -704.000000, 96.000000})            
            set_pev(id, pev_angles, {0.0,90.0,0.0});
            set_pev(id, pev_fixangle, 1);                  
        }
        case FIVE:
        {
            set_pev(id, pev_origin, {192.000000, -511.000000, -72.000000})            
            set_pev(id, pev_angles, {0.0,0.0,0.0});
            set_pev(id, pev_fixangle, 1);                  
        }
        case EGYPTIAN:
        {
            set_pev(id, pev_origin, {-400.000000, -64.000000, 47.000000})            
            set_pev(id, pev_angles, {0.0,90.0,0.0});
            set_pev(id, pev_fixangle, 1);                  
        }
        case GC_AZTEC:
        {
            if(random(2))
            set_pev(id, pev_origin, {319.0, 335.0, -496.0}) 
            else
            set_pev(id, pev_origin, {-321.0, 335.0, -496.0}) 
            set_pev(id, pev_angles, {0.0,270.0,0.0});
            set_pev(id, pev_fixangle, 1); 
        }
    }

    return PLUGIN_HANDLED;
}
public lock()
{
    Lock=true;
    switch(Map)
    {
        case APPREHENSION,BLUEROOM,MECHANIX,/*ANTARCTICA,*/HIDEOUT,ARMY,MINECRAFT,CHRISTMAS,COLDSTEEL:
        {            
            set_pev(Ent1, pev_classname, "func_wall")
            set_pev(Ent1, pev_solid, SOLID_BBOX)
            set_pev(Ent1, pev_movetype, MOVETYPE_PUSHSTEP)            
        }
        case LASER, APPALL,AREA51,EGYPTIAN:
        {
            set_pev(Ent1, pev_target, "")
        }
        case LABORATORY,ALTERNATIVE,DS_AZTEC:
        {
            set_pev(Ent1, pev_target, "")
            set_pev(Ent2, pev_target, "")
        }
        case ABANDON:
        {            
            DispatchSpawn(Ent1);
            set_pev(Ent1, pev_health, 1.0)
            set_pev(Ent1, pev_deadflag, 0)
            set_pev(Ent1, pev_takedamage, 0.0)
            set_pev(Ent1, pev_ltime, 0.0)
        }
        case SNOWMAN,ASSAULTED,DOJO,GC_AZTEC:
        {            
            set_pev(Ent1, pev_classname, "func_wall")
            set_pev(Ent1, pev_solid, SOLID_BBOX)
            set_pev(Ent1, pev_movetype, MOVETYPE_PUSHSTEP)               
            set_pev(Ent2, pev_target, "")
        }
        case STONEDUST:
        {            
            set_pev(Ent1, pev_classname, "func_wall")
            set_pev(Ent1, pev_solid, SOLID_BBOX)
            set_pev(Ent1, pev_movetype, MOVETYPE_PUSHSTEP) 
            set_pev(Ent2, pev_classname, "func_wall")
            set_pev(Ent2, pev_solid, SOLID_BBOX)
            set_pev(Ent2, pev_movetype, MOVETYPE_PUSHSTEP)     
        }
        case JUGGERNAUT:
        {            
            entity_set_size(Ent1, Float:{0.0, 0.0, 0.0},Float:{0.0, 0.0, 0.0}); 
            entity_set_size(Ent2, Float:{0.0, 0.0, 0.0},Float:{0.0, 0.0, 0.0});
            entity_set_size(Ent3, Float:{0.0, 0.0, 0.0},Float:{0.0, 0.0, 0.0}); 
            entity_set_size(Ent4, Float:{0.0, 0.0, 0.0},Float:{0.0, 0.0, 0.0}); 
        }
        case INFINITY:
        {      
            set_pev(Ent1, pev_classname, "func_wall")
            set_pev(Ent1, pev_solid, SOLID_BBOX)
            set_pev(Ent1, pev_movetype, MOVETYPE_PUSHSTEP)    
        }
        case DUSTB:
        {
            if(zp_gamemodes_get_current()!=Infection&&zp_gamemodes_get_current()!=Multi)
            { 
                set_pev(Ent1, pev_target, "")
            }
        }
        case ABYSS:
        {
            set_pev(Ent1, pev_target, "out")
        }
        case FIVE:
        {                  
            set_pev(Ent1, pev_classname, "func_wall")
            set_pev(Ent1, pev_solid, SOLID_BBOX)
            set_pev(Ent1, pev_movetype, MOVETYPE_PUSHSTEP) 
            set_pev(Ent2, pev_classname, "func_wall")
            set_pev(Ent2, pev_solid, SOLID_BBOX)
            set_pev(Ent2, pev_movetype, MOVETYPE_PUSHSTEP) 
            set_pev(Ent3, pev_target, "")
        }
    }
    return PLUGIN_HANDLED;
}

public unlock()
{
    Lock=false;
    switch(Map)
    {
        case APPREHENSION,BLUEROOM,MECHANIX,HIDEOUT,ARMY,MINECRAFT,CHRISTMAS,COLDSTEEL:
        {            
            set_pev(Ent1, pev_classname, "func_illusionary")
            set_pev(Ent1, pev_solid, SOLID_NOT)
        }
        case LASER:
        {            
            set_pev(Ent1, pev_target, "Room2")
        }
        case APPALL:
        {
            set_pev(Ent1, pev_target, "shopvick")
        }
        case LABORATORY:
        {
            set_pev(Ent1, pev_target, "secrettele.")
            set_pev(Ent2, pev_target, "tele4")
        }
        case ABYSS,DUSTB:
        {
            set_pev(Ent1, pev_target, "secret")
        }
        case ABANDON:
        {
            DispatchSpawn(Ent1);
            set_pev(Ent1, pev_health, 800.0)            
            set_pev(Ent1, pev_takedamage, 1.0)
        }
        case SNOWMAN:
        {
            set_pev(Ent1, pev_classname, "func_illusionary")
            set_pev(Ent1, pev_solid, SOLID_NOT)
            set_pev(Ent2, pev_target, "hardsurf")
        }        
        case STONEDUST:
        {
            set_pev(Ent1, pev_classname, "func_illusionary")
            set_pev(Ent1, pev_solid, SOLID_NOT)
            set_pev(Ent2, pev_classname, "func_illusionary")
            set_pev(Ent2, pev_solid, SOLID_NOT)
        }
        case ASSAULTED:
        {            
            set_pev(Ent1, pev_classname, "func_illusionary")
            set_pev(Ent1, pev_solid, SOLID_NOT)
            set_pev(Ent2, pev_target, "telea")
        }/*
        case ANTARCTICA:
        {            
            set_pev(Ent1, pev_classname, "trigger_push")      
            set_pev(Ent1, pev_solid, SOLID_TRIGGER)
        }*/
        case JUGGERNAUT:
        {         
            entity_set_size(Ent1, Float:{311.0, -41.0, 199.0},Float:{317.0, -3.0, 353.0});  
            entity_set_size(Ent2, Float:{311.0, -41.0, 499.0}, Float:{317.0, -3.0, 653.0});
            entity_set_size(Ent3, Float:{311.0, -41.0, 803.0}, Float:{317.0, -3.0, 957.0});
            entity_set_size(Ent4, Float:{311.0, -161.0, 947.0}, Float:{317.0, -123.0, 1109.0});
        }
        case INFINITY:
        {            
            set_pev(Ent1, pev_classname, "func_illusionary")
            set_pev(Ent1, pev_solid, SOLID_NOT)
        }    
        case AREA51:
        {
            set_pev(Ent1,pev_target,"Secret")
        }        
        case ALTERNATIVE:
        {
            set_pev(Ent1,pev_target,"b1")
            set_pev(Ent2,pev_target,"c1")
        }     
        case DS_AZTEC:
        {
            set_pev(Ent1,pev_target,"s2")
            set_pev(Ent2,pev_target,"s1")
        }   
        case DOJO:
        {
            set_pev(Ent1, pev_classname, "func_illusionary")
            set_pev(Ent1, pev_solid, SOLID_NOT)
            set_pev(Ent2,pev_target,"topsecretexit")
        }
        case FIVE:
        {
            set_pev(Ent1, pev_classname, "func_illusionary")
            set_pev(Ent1, pev_solid, SOLID_NOT)
            set_pev(Ent2, pev_classname, "func_illusionary")
            set_pev(Ent2, pev_solid, SOLID_NOT)
            set_pev(Ent3,pev_target,"wov")
        }
        case EGYPTIAN:
        {
            set_pev(Ent1, pev_target, "secdoor")
        }
        case GC_AZTEC:
        {            
            set_pev(Ent1, pev_classname, "func_illusionary")
            set_pev(Ent1, pev_solid, SOLID_NOT)            
            set_pev(Ent2,pev_target,"scrt_dst")
        }
    }    
    return PLUGIN_HANDLED;
}


public plugin_init()
{
    register_plugin("Secret Locker","1.0","zXCaptainXz")
    register_touch("secret_zone","player","fw_touch")
    register_touch("abyss_zone","player","fw_touch2")
    register_touch("func_ladder","player","blah")
    RegisterHam(Ham_Killed,"player","death",1)
    CheckMap()
}

public blah()return PLUGIN_HANDLED;
public client_disconnected(id) Human[id]=false;
public death(id) Human[id]=false;
public zp_fw_core_infect_post(id) Human[id]=false;
public zp_fw_core_cure_post(id) Human[id]=true;


public fw_touch(zone, id)
{    
    if(!Lock)
    {
        InSecret[id]=get_gametime();
    
        static i
        for(i=1;i<33;i++)
        {              
            if(Human[i]&&InSecret[i]+0.1<get_gametime())
            {
                return PLUGIN_CONTINUE;
            }            
        }      
    }

    yeet(id)
    
    if(zp_gamemodes_get_current()==Infection||zp_gamemodes_get_current()==Multi)
    {
        if(zp_core_is_zombie(id))
        {
            zp_colored_print(id,"You have been ^3Expelled^1 from the^3 Secret Room^1 since it's^3 Locked!")
        }
        else
        {            
            zp_colored_print(id,"You have been ^3Expelled^1 from the^3 Secret Room^1 since there's^3 No Humans Outside The Secret!")
        }
    }
    else
    if(zp_gamemodes_get_current()==ZP_NO_GAME_MODE)
    {
        zp_colored_print(id,"You have been ^3Expelled^1 from the^3 Secret Room^1 since the round hasn't started!")
    }
    else
    {
        zp_colored_print(id,"You have been ^3Expelled^1 from the^3 Secret Room^1 since this is a^3 Special Mode^1!")
    }
    
    return PLUGIN_CONTINUE;
}

public fw_touch2(zone, id)
{   
    new Float:vec[3]     
    new tname[32]
    pev(Ent1, pev_target, tname, charsmax(tname))
    new ent = find_ent_by_tname(0, tname)
    pev(ent ,pev_origin,vec)
    set_pev(id, pev_origin, vec)          
    pev(ent,pev_angles,vec)
    set_pev(id, pev_angles, vec);
    set_pev(id, pev_fixangle, 1); 
    return PLUGIN_CONTINUE;
}

public plugin_cfg()
{
    Infection = zp_gamemodes_get_id("Infection Mode")
    Multi = zp_gamemodes_get_id("Multiple Infection Mode")
}
public zp_fw_gamemodes_start(id)
{
    if(id==Infection||id==Multi)
    {
        unlock()
    }
}

public zp_fw_gamemodes_end()
{
    lock()
}

public zp_fw_core_last_human(id)
{
    lock();
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

stock create_secret(const Float:origin[3],const Float:size1[3],const Float:size2[3])
{    
    new ent =  create_entity("info_target");
    entity_set_string(ent, EV_SZ_classname, "secret_zone")
    entity_set_origin(ent, origin)        
    entity_set_int(ent, EV_INT_solid, SOLID_TRIGGER)
    entity_set_size(ent, size2,size1)      
    return PLUGIN_HANDLED;
}
