#include <amxmodx>
#include <amxmisc>
#include <sqlx> 
#include <zp50_gamemodes>
#include <zp50_log>
#include <zombieplague>
#include <colorchat>

#define PLUGIN "quests"
#define VERSION "2.4"
#define AUTHOR "Lord. Death."

//  Mysql Information
new Host[]     = "74.91.123.158"
new User[]    = "LordD"
new Pass[]     = "jxdPq2SmA0mR"
new Db[]     = "zp_stats"

new Handle:g_SqlTuple
new g_Error[512]
new Saved_Points[33], Quest1[33],Quest2[33],Quest3[33],Quest4[33],Quest5[33],Quest6[33]
new ZomDam[33], HumDam[33], Score[33], Deaths[33], MassInfS[33],Kills[33]
new Mod[2], IsHuman[33], Round
new bool:Loaded[33]
//new QuestDone[33][12]
new Trie:qDone[20] // g means global; t means trie


public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_clcmd("say /challenges", "challenges_menu")
	register_clcmd("say /c", "challenges_menu")
	for(new q = 2;q < 20; q++)
		qDone[q] = TrieCreate()
	//TrieSetCell(
	set_task(2.0,"MySql_Init") // set a task to activate the mysql_init
	
}
public plugin_natives()
{
	register_native("zp_quest_get", "r_points", 1)
	register_native("zp_quest_count_set", "s_points", 1)
	register_native("zp_quest_limit_set", "s_quest", 1)
	register_native("zp_rc_kill", "Client_MassKill", 1)
	register_native("zp_bomb_inf", "Client_MassInf", 1)
}
public plugin_cfg()
{
	Mod[0] = zp_gamemodes_get_id("Infection Mode")
	Mod[1] = zp_gamemodes_get_id("Multiple Infection Mode")
}
public Counter(id)
	ColorChat(id, GREEN, "[GC]^3 You've completed^4 %d Challenges", r_points(id))
public Counter_add(id)
	ColorChat(id, GREEN, "[GC]^3 You've completed^4 a challenge!^3 Your current completed challenges are:^4 %d", r_points(id))	
public r_points(id) return Saved_Points[id];
public s_points(id, num) Saved_Points[id] = num;
public s_quest(id, quest, num)
{
	switch(quest)
	{
		case 1: Quest1[id] += num
		case 2: Quest2[id] += num
		case 3: Quest3[id] += num
		case 4: Quest4[id] += num
		case 5: Quest5[id] += num
		case 6: Quest6[id] += num
		default: return;
	}
}
public challenges_menu(id)
{
	new Title[128], ScoreTxt[128], KillsTxt[128]
	new DeathsTxt[128]
	new DamTxt[128], DamTxtZ[128]
	new SteamID[34]
	get_user_authid(id, SteamID,charsmax(SteamID))
	if(!TrieKeyExists(qDone[3], SteamID))
		formatex(KillsTxt, charsmax(KillsTxt), "Get [%d/50] Kills", Kills[id])		
	else if(!TrieKeyExists(qDone[4], SteamID))
		formatex(KillsTxt, charsmax(KillsTxt), "Get [%d/75] Kills", Kills[id])	
	else if(!TrieKeyExists(qDone[5], SteamID))
		formatex(KillsTxt, charsmax(KillsTxt), "Get [%d/100] Kills", Kills[id])	
	else formatex(KillsTxt, charsmax(KillsTxt), "Get 100 Kills \y[Complete]")
	
	if(!TrieKeyExists(qDone[6], SteamID))
		formatex(ScoreTxt, charsmax(ScoreTxt), "Get [%d/200] Score", Score[id])		
	else if(!TrieKeyExists(qDone[7], SteamID))
		formatex(ScoreTxt, charsmax(ScoreTxt), "Get [%d/250] Score", Score[id])		
	else if(!TrieKeyExists(qDone[8], SteamID))
		formatex(ScoreTxt, charsmax(ScoreTxt), "Get [%d/300] Score", Score[id])		
	else if(!TrieKeyExists(qDone[9], SteamID))
		formatex(ScoreTxt, charsmax(ScoreTxt), "Get [%d/350] Score", Score[id])		
	else if(!TrieKeyExists(qDone[10], SteamID))
		formatex(ScoreTxt, charsmax(ScoreTxt), "Get [%d/400] Score", Score[id])	
	else formatex(ScoreTxt, charsmax(ScoreTxt), "Get 400 Score \y[Complete]")
	
	if(!TrieKeyExists(qDone[11], SteamID))
		formatex(DeathsTxt, charsmax(DeathsTxt), "Get [%d/20] Deaths", Deaths[id])	
	else if(!TrieKeyExists(qDone[12], SteamID))
		formatex(DeathsTxt, charsmax(DeathsTxt), "Get [%d/30] Deaths", Deaths[id])	
	else if(!TrieKeyExists(qDone[13], SteamID))
		formatex(DeathsTxt, charsmax(DeathsTxt), "Get [%d/40] Deaths", Deaths[id])	
	else formatex(DeathsTxt, charsmax(DeathsTxt), "Get 40 Deaths \y[Complete]")	
	
	if(!TrieKeyExists(qDone[14], SteamID))
		formatex(DamTxt, charsmax(DamTxt), "Deal [%d/100000] Damage", HumDam[id])
	else if(!TrieKeyExists(qDone[15], SteamID))
		formatex(DamTxt, charsmax(DamTxt), "Deal [%d/150000] Damage", HumDam[id])	
	else if(!TrieKeyExists(qDone[16], SteamID))
		formatex(DamTxt, charsmax(DamTxt), "Deal [%d/200000] Damage", HumDam[id])
	else formatex(DamTxt, charsmax(DamTxt), "Deal 200,000 Damage \y[Complete]")
		
	if(!TrieKeyExists(qDone[17], SteamID))
		formatex(DamTxtZ, charsmax(DamTxtZ), "Take [%d/40000] Damage", ZomDam[id])	
	else if(!TrieKeyExists(qDone[18], SteamID))
		formatex(DamTxtZ, charsmax(DamTxtZ), "Take [%d/60000] Damage", ZomDam[id])	
	else if(!TrieKeyExists(qDone[19], SteamID))
		formatex(DamTxtZ, charsmax(DamTxtZ), "Take [%d/80000] Damage", ZomDam[id])
	else formatex(DamTxtZ, charsmax(DamTxtZ), "Take 80,000 Damage \y[Complete]")
	
	if(Loaded[id])
		formatex(Title,charsmax(Title),"Your completed challenges:\y [%d]\w^nChallenge list:",r_points(id))
	else
		formatex(Title,charsmax(Title),"Your completed challenges:\w [Loading..]^nChallenge list:")
	new MyM = menu_create(Title,"MQuest",0)

	
	menu_additem(MyM, ScoreTxt)
		
	menu_additem(MyM, KillsTxt)

	menu_additem(MyM, DeathsTxt)
	
	menu_additem(MyM, DamTxt)

	menu_additem(MyM, DamTxtZ)

	menu_additem(MyM, "Kill 3,4 or 5 zombies with 1 RC")
	menu_additem(MyM, "Infect 5,6 or 7 humans with 1 Infection Bomb")
	
	menu_display(id,MyM)
	//menu_additem(MyM, "Survive a infection round without getting rekt")
}
public MQuest(id, menu, item)
{
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}
public MySql_Init() 
{
    g_SqlTuple = SQL_MakeDbTuple(Host,User,Pass,Db)
   
    new ErrorCode,Handle:SqlConnection = SQL_Connect(g_SqlTuple,ErrorCode,g_Error,charsmax(g_Error))
    if(SqlConnection == Empty_Handle)
        set_fail_state(g_Error)
       
    new Handle:Queries
    Queries = SQL_PrepareQuery(SqlConnection,"CREATE TABLE IF NOT EXISTS quest_db ( nick varchar(32), steamid varchar(32), count INT(11)\
    , quest_1 INT(11), quest_2 INT(11), quest_3 INT(11), quest_4 INT(11), quest_5 INT(11), quest_6 INT(11) )")

    if(!SQL_Execute(Queries))
    {
        SQL_QueryError(Queries,g_Error,charsmax(g_Error))
        set_fail_state(g_Error)
       
    }
    
    SQL_FreeHandle(Queries)
   
    SQL_FreeHandle(SqlConnection)   
} 

public plugin_end()
{
    SQL_FreeHandle(g_SqlTuple)
    for(new q = 2;q < 20; q++)
	TrieDestroy(qDone[q])
} 

public Load_MySql(id)
{
if(is_user_connected(id))
{
    if(is_user_bot(id))
	return;
    new szSteamId[32], szTemp[512], iPlayerNick[32]
    get_user_authid(id, szSteamId, charsmax(szSteamId))
    get_user_name(id, iPlayerNick, charsmax(iPlayerNick))

    new Data[1]
    Data[0] = id
    format(szTemp,charsmax(szTemp),"SELECT * FROM `quest_db` WHERE (`steamid` = '%s')", szSteamId)
    SQL_ThreadQuery(g_SqlTuple,"register_client",szTemp,Data,1)
}
}

public register_client(FailState,Handle:Query,Error[],Errcode,Data[],DataSize)
{
    if(FailState == TQUERY_CONNECT_FAILED)
    {
        log_amx("Load - Could not connect to SQL database.  [%d] %s", Errcode, Error)
    }
    else if(FailState == TQUERY_QUERY_FAILED)
    {
        log_amx("Load Query failed. [%d] %s", Errcode, Error)
    }

    new id
    id = Data[0]
    new szSteamId[32], iPlayerNick[32]
    get_user_authid(id, szSteamId, charsmax(szSteamId)) // get user's steamid
    get_user_name(id, iPlayerNick, charsmax(iPlayerNick))    
    if(SQL_NumResults(Query) < 1) 
    {
	if(is_user_connected(id))
	{
		if (equal(szSteamId,"ID_PENDING"))
			return PLUGIN_HANDLED
		    
		new szTemp[512]	
		format(szTemp,charsmax(szTemp),"INSERT INTO `quest_db` ( `nick` , `steamid` , `count` ) VALUES ('%s', '%s' ,'0');", iPlayerNick, szSteamId)
		SQL_ThreadQuery(g_SqlTuple,"IgnoreHandle",szTemp)
		Loaded[id]=true;
	}
    } 
    else 
    {
	if(is_user_connected(id))
	{
		new Text[124]
		// if there are results found
		Saved_Points[id] = SQL_ReadResult(Query, 2)
		Quest1[id] = SQL_ReadResult(Query, 3)
		Quest2[id] = SQL_ReadResult(Query, 4)
		Quest3[id] = SQL_ReadResult(Query, 5)
		Quest4[id] = SQL_ReadResult(Query, 6)
		Quest5[id] = SQL_ReadResult(Query, 7)
		Quest6[id] = SQL_ReadResult(Query, 8)
		Loaded[id]=true;
		format(Text, charsmax(Text), "[ %d ] Challenges Loaded for [ %s ] [ %s ] " , r_points(id) ,iPlayerNick, szSteamId)
		ZP_PointsLog(Text)
	}
    }
    
    return PLUGIN_HANDLED
} 

public Save_MySql(id)
{
	if(is_user_bot(id))
		return;
	if(is_user_connected(id)&&Loaded[id])
	{
		new szSteamId[32],iPlayerNick[32], szTemp[512]
		get_user_authid(id, szSteamId, charsmax(szSteamId))
		get_user_name(id, iPlayerNick, charsmax(iPlayerNick))
		new point = r_points(id)
		new Text[124]
		format(Text, charsmax(Text), "[ %d ] Challenges Saved for [ %s ] [ %s ] - C1: [%d] ,C2: [%d] ,C3: [%d] ,C4: [%d] ,C5: [%d] ,C6: [%d] " , point,iPlayerNick, szSteamId, Quest1[id],Quest2[id],Quest3[id],Quest4[id],Quest5[id],Quest6[id])
		format(szTemp,charsmax(szTemp),"UPDATE `quest_db` SET `count` = '%i' , `quest_1` = '%i' , `quest_2` = '%i' , `quest_3` = '%i' , `quest_4` = '%i'\
		, `quest_5` = '%i' , `quest_6` = '%i' , `nick` = '%s' WHERE `steamid` = '%s'", point, Quest1[id],Quest2[id],Quest3[id],Quest4[id],Quest5[id],Quest6[id],iPlayerNick, szSteamId)
		SQL_ThreadQuery(g_SqlTuple,"IgnoreHandle",szTemp)
		ZP_PointsLog(Text)
	}
} 

public Client_MassKill(id, kills)
{
	
	new current_mode = zp_gamemodes_get_current()
	if(current_mode != Mod[0] && current_mode != Mod[1])
		return;
	new qDoneL[4]
	for(new qL;qL < 3;qL++)
		qDoneL[qL] = 0
	if(kills >= 3)
	{
		if(kills >= 3 && !qDoneL[0])
		{
			
			Saved_Points[id]++
			Save_MySql(id)
			Counter_add(id)
			qDoneL[0] = 1
		}
		if(kills >= 4 && !qDoneL[1])
		{
			Saved_Points[id]++
			Save_MySql(id)
			Counter_add(id)
			qDoneL[1] = 1
		}
		if(kills >= 5 && !qDoneL[2])
		{
			Saved_Points[id]++
			Save_MySql(id)
			Counter_add(id)
			qDoneL[2] = 1
		}
	}
}

public Client_MassInf(id, kills)
{
	new qDoneL[4]
	for(new qL;qL < 3;qL++)
		qDoneL[qL] = 0
	if(kills >= 5)
	{
		if(kills >= 5 && !qDoneL[0])
		{
			Saved_Points[id]++
			Quest1[id]++
			Save_MySql(id)
			Counter_add(id)
			qDoneL[0] = 1
		}
		if(kills >= 6 && !qDoneL[1])
		{
			Saved_Points[id]++
			Quest2[id]++
			Save_MySql(id)
			Counter_add(id)
			qDoneL[1] = 1
		}
		if(kills >= 7 && !qDoneL[2])
		{
			Saved_Points[id]++
			MassInfS[id] = 0
			Quest3[id]++
			Save_MySql(id)
			Counter_add(id)
			qDoneL[2] = 1
		}
	}
}

public client_death(att,vic,wpnindex,hitplace,TK)
{
	new current_mode = zp_gamemodes_get_current()
	if (current_mode != Mod[0] && current_mode != Mod[1])
		return;

	if(att == vic || !att || !vic )
		return;
	if(!is_user_connected(att) || !is_user_connected(vic))
		return

	new ASteamID[34], VSteamID[34]
	get_user_authid(att, ASteamID,charsmax(ASteamID))
	get_user_authid(vic, VSteamID,charsmax(VSteamID))
	
	Score[att] += 3
	Deaths[vic]++
	Kills[att]++
	IsHuman[vic] = 0

	if(Kills[att] >= 50)
	{
		if(Kills[att] >= 50 && !TrieKeyExists(qDone[3], ASteamID))
		{
			Saved_Points[att]++
			Save_MySql(att)
			Counter_add(att)
			TrieSetCell(qDone[3],ASteamID, 1)
		}
		else if(Kills[att] >= 75 && !TrieKeyExists(qDone[4], ASteamID))
		{
			Saved_Points[att]++
			Save_MySql(att)	
			Counter_add(att)
			TrieSetCell(qDone[4],ASteamID, 1)
		}
		else if(Kills[att] >= 100 && !TrieKeyExists(qDone[5], ASteamID))
		{
			Saved_Points[att]++
			Save_MySql(att)	
			Counter_add(att)
			TrieSetCell(qDone[5],ASteamID, 1)
		}
	}
	if(Score[att] >= 200)
	{
		if(Score[att] >= 200 && !TrieKeyExists(qDone[6], ASteamID))
		{
			Saved_Points[att]++
			Save_MySql(att)
			Counter_add(att)
			TrieSetCell(qDone[6],ASteamID, 1)
		}
		else if(Score[att] >= 250 && !TrieKeyExists(qDone[7], ASteamID))
		{
			Saved_Points[att]++
			Save_MySql(att)	
			Counter_add(att)
			TrieSetCell(qDone[7],ASteamID, 1)
		}
		else if(Score[att] >= 300 && !TrieKeyExists(qDone[8], ASteamID))
		{
			Saved_Points[att]++
			Save_MySql(att)	
			Counter_add(att)
			TrieSetCell(qDone[8],ASteamID, 1)
		}
		else if(Score[att] >= 350 && !TrieKeyExists(qDone[9], ASteamID))
		{
			Saved_Points[att]++
			Save_MySql(att)	
			Counter_add(att)
			TrieSetCell(qDone[9],ASteamID, 1)
		}
		else if(Score[att] >= 400 && !TrieKeyExists(qDone[10], ASteamID))
		{
			Saved_Points[att]++
			Save_MySql(att)	
			Counter_add(att)
			TrieSetCell(qDone[10],ASteamID, 1)
		}
	}
	if(Deaths[vic] >= 20)
	{
		if(Deaths[vic] >= 20 && !TrieKeyExists(qDone[11], VSteamID))
		{
			Saved_Points[vic]++
			Save_MySql(vic)
			Counter_add(vic)
			TrieSetCell(qDone[11],VSteamID, 1)
		}
		else if(Deaths[vic] >= 30 && !TrieKeyExists(qDone[12], VSteamID))
		{
			Saved_Points[vic]++
			Save_MySql(vic)	
			Counter_add(vic)
			TrieSetCell(qDone[12],VSteamID, 1)
		}
		else if(Deaths[vic] >= 40 && !TrieKeyExists(qDone[13], VSteamID))
		{
			Saved_Points[vic]++
			Save_MySql(vic)	
			Counter_add(vic)
			TrieSetCell(qDone[13],VSteamID, 1)
		}
	}
}
public client_damage(att,vic,damage,wpnindex,hitplace,TA)
{
	new current_mode = zp_gamemodes_get_current()
	if (current_mode != Mod[0] && current_mode != Mod[1])
		return;
		
	if(att == vic || !att || !vic )
		return;
	if(!is_user_connected(att) || !is_user_connected(vic))
		return
	if(!is_user_alive(vic))
		return
	if(zp_core_is_zombie(vic) && !zp_core_is_zombie(att))
	{
		ZomDam[vic] += damage
		HumDam[att] += damage
	}
	new ASteamID[34], VSteamID[34]

	if(HumDam[att] >= 100000)
	{
		get_user_authid(att, ASteamID,charsmax(ASteamID))
		if(HumDam[att] >= 100000 && !TrieKeyExists(qDone[14], ASteamID))
		{
			Saved_Points[att]++
			Save_MySql(att)
			Counter_add(att)
			TrieSetCell(qDone[14],ASteamID, 1)
		}
		if(HumDam[att] >= 150000 && !TrieKeyExists(qDone[15], ASteamID))
		{
			Saved_Points[att]++
			Save_MySql(att)
			Counter_add(att)
			TrieSetCell(qDone[15],ASteamID, 1)

		}
		if(HumDam[att] >= 200000 && !TrieKeyExists(qDone[16], ASteamID))
		{
			Saved_Points[att]++
			Save_MySql(att)
			Counter_add(att)
			TrieSetCell(qDone[16],ASteamID, 1)

		}
	}
	if(ZomDam[vic] >= 40000)
	{
		
		get_user_authid(vic, VSteamID,charsmax(VSteamID))
		if(ZomDam[vic] >= 40000 && !TrieKeyExists(qDone[17], VSteamID))
		{
			Saved_Points[vic]++
			Quest4[vic]++
			Save_MySql(vic)
			Counter_add(vic)
			TrieSetCell(qDone[17],VSteamID, 1)
		}
		if(ZomDam[vic] >= 60000 && !TrieKeyExists(qDone[18], VSteamID))
		{
			Saved_Points[vic]++
			Quest5[vic]++
			Save_MySql(vic)
			Counter_add(vic)
			TrieSetCell(qDone[18],VSteamID, 1)
		}
		if(ZomDam[vic] >= 80000 && !TrieKeyExists(qDone[19], VSteamID))
		{
			Saved_Points[vic]++
			Quest6[vic]++
			Save_MySql(vic)
			Counter_add(vic)
			TrieSetCell(qDone[19],VSteamID, 1)
		}
	}
}
public client_putinserver(id) Load_MySql(id)
public client_disconnect(id)
{
	Save_MySql(id)
	Kills[id] = 0
	Deaths[id] = 0
	HumDam[id] = 0
	ZomDam[id] = 0
	IsHuman[id] = 0
	Loaded[id]=false;
}
public zp_fw_core_cure_post(id,a)
	IsHuman[id] = 0
	
public zp_fw_core_infect_post(id, a)
{
	if(a != 0 && a != id)
	{
		Score[a]+= 3
		IsHuman[id] = 0
	}
}
public zp_fw_gamemodes_start(mod)
{
	if (mod != Mod[0] && mod != Mod[1])
		return;	
	for(new id = 1; id <= get_maxplayers(); id++)
	{
		if(!is_user_connected(id))
			continue
		//if(zp_core_is_zombie(id))
			//continue;
		IsHuman[id] = 1
		ColorChat(id,GREEN, "[GC]^3 say ^4/challenges^3 to see your challenge progress")
	}
}
public zp_fw_gamemodes_end()
{
	if(Round < 2)
	{
		Round++
		return;
	}
	new id
	for (id = 1; id <= get_maxplayers(); id++)
	{
		if(!is_user_connected(id))
			continue;
		if(IsHuman[id] && is_user_alive(id))
		{
			if(PlayerCount() > 12)
			{
				Saved_Points[id]++
				Save_MySql(id)
				Counter_add(id)
			}
			else ColorChat(id, GREEN, "[GC]^3 Flawless challenge requires +12 connected players to start.")
		}

	}

}
public IgnoreHandle(FailState,Handle:Query,Error[],Errcode,Data[],DataSize)
{
    SQL_FreeHandle(Query)
    
    return PLUGIN_HANDLED
}
stock ZP_PointsLog(const message_fmt[], any:...)
{
	static message[256], filename[32], date[16];
	vformat(message, charsmax(message), message_fmt, 2);
	format_time(date, charsmax(date), "%Y%m%d");
	formatex(filename, charsmax(filename), "QuestLog_%s.log", date);
	log_to_file(filename, "%s", message);
}

PlayerCount()
{
	new Players;
	for(new id;id < get_maxplayers();id++)
	{
		if(!is_user_connected(id))
			continue;
		Players++
	}
	return Players;
}
