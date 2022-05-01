#include <amxmodx>
#include <zombieplague>
#include <nvault>
#include <zmvip>
#include <colorchat>

#define NV_NAME "GET_AMMO"
#define TAG "[GC]"

enum player_struct {
    mtime,bool:ftime,key[64]
}
new g_player[33][player_struct];

new cvar_save_type,cvar_time, cvar_max, MyLimit;

public plugin_init() {

    register_plugin("Free VIP [viptest]", "1.0", "Clauu | Lord. Death.");
    
    cvar_save_type = register_cvar("get_vip_save_type","1"); // how to save data 1 by authid, 2 by ip or 3 by name
    cvar_time = register_cvar("get_vip_cd","240"); // time in minutes, 720minutes=12hours it will be auto calculated
    cvar_max = register_cvar("get_vip_max","2");
    
    register_clcmd("say /viptest", "cmd_ap");
    register_clcmd("say_team /viptest", "cmd_ap");
    register_clcmd("say /tryvip", "cmd_ap");
    register_clcmd("say /vt", "cmd_ap");
    register_clcmd("say_team /tryvip", "cmd_ap");
    register_clcmd("say_team /vt", "cmd_ap");

}
        
public cmd_ap(id) {

    new nv = nvault_open(NV_NAME);
    
    if(nv == INVALID_HANDLE) {
        ColorChat(id,GREEN,"%s ^3VIP^1 test is ^4off.",TAG);
        return;
    }

    new txt_min[32];
    new pminutes = get_pcvar_num(cvar_time);
    build_time(pminutes,txt_min,charsmax(txt_min));
    if(MyLimit >= get_pcvar_num(cvar_max))
    {
    	ColorChat(id,GREEN,"[GC]^3 Max Trial VIP ^4(%d).^3 try again nextmap.", get_pcvar_num(cvar_max) )
	return;
    }
    if(g_player[id][ftime])
    {
	ColorChat(id,GREEN,"[GC]^1 You are now ^3VIP^1 till the map is over. ^3try again in^4 %s!^1 to get free ^4VIP",txt_min);
	zv_set_user_flags(id, 17)// ZV_MAIN
	g_player[id][ftime]=false;
	nvault_touch(nv,g_player[id][key],g_player[id][mtime]=get_systime());
	MyLimit++
	return;
    }
    
    new user_time=get_systime()-g_player[id][mtime];
    new diff_min=(user_time<(pminutes*60))?pminutes-(user_time/60):pminutes;
    build_time(diff_min,txt_min,charsmax(txt_min));
    
    if(user_time>=(pminutes*60))
    {
	ColorChat(id,GREEN,"[GC]^1 You are now ^3VIP^1 till the map is over. ^3try again in^4 %s!^1 to get free ^4VIP",txt_min);
	zv_set_user_flags(id, 17)
	nvault_touch(nv,g_player[id][key],g_player[id][mtime]=get_systime());
	MyLimit++
    }
    else
	ColorChat(id,GREEN,"[GC]^3 Retry again in^4 %s ^3to get free ^4VIP",txt_min);
        
    nvault_close(nv);
}

public client_putinserver(id) {
        
    new nv,data[32];
    get_auth(id,g_player[id][key],charsmax(g_player[][key]));
    g_player[id][mtime]=get_systime();
    g_player[id][ftime]=false;
    formatex(data,charsmax(data),"%d",g_player[id][mtime]);
    
    if((nv=nvault_open(NV_NAME))==INVALID_HANDLE)
        return;
    
    if(!nvault_lookup(nv,g_player[id][key],data,charsmax(data),g_player[id][mtime])) {
        nvault_set(nv,g_player[id][key],data);
        g_player[id][ftime]=true;
    }
    
    nvault_close(nv);
}    

public client_disconnect(id) {
    
    g_player[id][mtime]=0;
    g_player[id][ftime]=false;
}

stock get_auth(id,data[],len)
    switch(get_pcvar_num(cvar_save_type)) {
        case 1: get_user_authid(id,data,len);
        case 2: get_user_ip(id,data,len,1);
        case 3: get_user_name(id,data,len);
    }

stock build_time(pminutes,data[],len)
{
    if(pminutes==1)
        copy(data,len,"1 minute");
    else if(pminutes!=1&&pminutes<60)
        formatex(data,len,"%d minutes",pminutes);
    else if(pminutes==60)
        copy(data,len,"1 hour");
    else {
        new ptime=pminutes/60;
        if(ptime*60==pminutes)
            formatex(data,len,"%d %s",ptime,(ptime==1)?"hour":"hours");
        else {
            new diff=pminutes-ptime*60;
            formatex(data,len,"%d %s and %d %s",ptime,(ptime==1)?"hour":"hours",diff,(diff==1)?"minute":"minutes");
        }
    }
}