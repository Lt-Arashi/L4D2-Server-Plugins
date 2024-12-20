#pragma semicolon 1
#pragma newdecls required
//使用新语法
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.0.7"
#define CVAR_FLAGS FCVAR_NOTIFY

#define IsValidClient(%1)		(1 <= %1 <= MaxClients && IsClientInGame(%1))


ConVar plugin_enable;
ConVar sound_enable;
ConVar pic_enable;

Handle Time = INVALID_HANDLE;
Handle Time1 = INVALID_HANDLE;
Handle sound_1 = INVALID_HANDLE;
Handle sound_2 = INVALID_HANDLE;
Handle sound_3 = INVALID_HANDLE;
Handle hit1 = INVALID_HANDLE;
Handle hit2 = INVALID_HANDLE;
Handle hit3 = INVALID_HANDLE;
Handle hit4 = INVALID_HANDLE;
Handle g_blast = INVALID_HANDLE;
Handle g_fire = INVALID_HANDLE;
Handle g_hit = INVALID_HANDLE;
Handle g_kill = INVALID_HANDLE;

enum {
	kill_1,
	hit_armor,
	kill,
	hit_armor_1
};

Handle g_taskCountdown[33] = INVALID_HANDLE,g_taskClean[33] = INVALID_HANDLE;
int g_killCount[33] = 0;
bool IsVictimDeadPlayer[MAXPLAYERS+1] = { false, ... };

public Plugin myinfo = 
{
	name = "击中反馈",
	author = "TsukasaSato",
	description = "自定义击中和击杀的图标、声音、时长",
	version = "PLUGIN_VERSION"
}

public void OnPluginStart()
{
	char Game_Name[64];
	GetGameFolderName(Game_Name, sizeof(Game_Name));
	if(!StrEqual(Game_Name, "left4dead2", false))
	{
		SetFailState("本插件仅支持L4D2!");
	}

	CreateConVar("l4d2_hitsound", PLUGIN_VERSION, "Plugin version", 0);
	Time = CreateConVar("sm_hitsound_showtime", "0.3", "图标存在的时长(默认为0.3)");
	Time1 = CreateConVar("sm_hitsound_showtime_auto", "0.1", "自动武器击中图标存在的时长(默认为0.1)");
	sound_1 = CreateConVar("sm_hitsound_mp3_headshot", "hitsound/headshot.mp3", "爆头音效的地址");	
	sound_2 = CreateConVar("sm_hitsound_mp3_hit", "hitsound/hit.mp3", "击中音效的地址");
	sound_3 = CreateConVar("sm_hitsound_mp3_kill", "hitsound/kill.mp3", "击杀音效的地址");
	hit1 = CreateConVar("sm_hitsound_pic_headshot", "overlays/hitsound/kill", "爆头图标的地址");
	hit2 = CreateConVar("sm_hitsound_pic_hit", "overlays/hitsound/hit", "击中图标的地址");
	hit3 = CreateConVar("sm_hitsound_pic_kill", "overlays/hitsound/kill", "击杀图标的地址");
	hit4 = CreateConVar("sm_hitsound_pic_hit_auto", "overlays/hitsound/hit1", "自动武器击杀图标的地址");
	
	sound_enable = CreateConVar("sm_hitsound_sound_enable", "1", "是否开启音效(0-关, 1-开)", CVAR_FLAGS);
	pic_enable = CreateConVar("sm_hitsound_pic_enable", "1", "是否开启及击杀图标(0-关, 1-开)", CVAR_FLAGS);
	g_blast = CreateConVar("sm_blast_damage_enable", "0", "是否开启爆炸反馈提示(0-关, 1-开 建议关闭)", CVAR_FLAGS);
	g_fire = CreateConVar("sm_fire_damage_enable", "0", "是否开启火烧反馈提示", CVAR_FLAGS);
	g_hit = CreateConVar("sm_hit_infected_enable", "1", "是否开启感染者击中反馈声音(0-关, 1-开 建议开启)", CVAR_FLAGS);
	g_kill = CreateConVar("sm_kill_infected_enable", "1", "是否开启感染者击杀反馈声音(0-关, 1-开 建议开启)", CVAR_FLAGS);
	
	plugin_enable = CreateConVar("sm_hitsound_enable","1","是否开启本插件(0-关, 1-开)", CVAR_FLAGS);
	//AutoExecConfig(true, "l4d2_hitsound");//是否生成cfg注释即不生成
	if (GetConVarInt(plugin_enable) == 1)
	{
		HookEvent("infected_hurt",			Event_InfectedHurt, EventHookMode_Pre); //感染受伤
		HookEvent("infected_death",			Event_InfectedDeath); //感染死亡
		HookEvent("player_death",			Event_PlayerDeath); // 玩家死亡
		HookEvent("player_hurt",				Event_PlayerHurt, EventHookMode_Pre); //玩家受伤
		HookEvent("tank_spawn", Event_TankSpawn);
		HookEvent("player_spawn", Event_Spawn);
		HookEvent("round_start", Event_round_start,EventHookMode_Post);
		HookEvent("player_incapacitated", PlayerIncap);
	}
}

public void Event_Spawn(Event event, const char[] name, bool dontBroadcast)
{
	int Client = GetClientOfUserId(GetEventInt(event, "userid"));
	IsVictimDeadPlayer[Client] = false;
}


public Action PlayerIncap(Handle event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsValidClient(victim) && GetClientTeam(victim) == 3 && GetEntProp(victim, Prop_Send, "m_zombieClass") == 8)
	IsVictimDeadPlayer[victim] = true;
}

public Action Event_TankSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int tank = GetClientOfUserId(GetEventInt(event, "userid"));
	IsVictimDeadPlayer[tank] = false;
}

public Action Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	bool heatshout = false;
	heatshout = GetEventBool(event, "headshot");
	int IsHeatshout = 0;
	int damagetype = GetEventInt(event, "type");

	if(GetConVarInt(g_fire) == 0 && damagetype & DMG_BURN)
        return Plugin_Changed;
		
	if(GetConVarInt(g_blast) == 0 && damagetype & DMG_BLAST)
		return Plugin_Changed;

	if (heatshout) IsHeatshout = 1;
	
	if(IsValidClient(victim))
	{
		if(GetClientTeam(victim) == 3)
		{
			if(IsValidClient(attacker))
			{
				if(GetClientTeam(attacker) == 2)	
				{
					if(!IsFakeClient(attacker))
					{
						if(IsHeatshout)
						{
							if(GetConVarInt(pic_enable) == 1)
							{
								ShowKillMessage(attacker,kill_1);
							}
							char sound1[64]; 
							GetConVarString(sound_1, sound1, sizeof(sound1));
							if (GetConVarInt(sound_enable) == 1)
							{
								PrecacheSound(sound1, true);
								EmitSoundToClient(attacker, sound1, SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
							}
							if(g_taskClean[attacker] != INVALID_HANDLE)
							{
								KillTimer(g_taskClean[attacker]);
								g_taskClean[attacker] = INVALID_HANDLE;
							}
							float showtime = GetConVarFloat(Time);
							g_taskClean[attacker] = CreateTimer(showtime,task_Clean,attacker);
							}else{
							if (GetConVarInt(pic_enable) == 1)
							{
								ShowKillMessage(attacker,kill);
							}
							if(g_taskClean[attacker] != INVALID_HANDLE)
							{
								KillTimer(g_taskClean[attacker]);
								g_taskClean[attacker] = INVALID_HANDLE;
							}
							float showtime = GetConVarFloat(Time);
							g_taskClean[attacker] = CreateTimer(showtime,task_Clean,attacker);
							char sound3[64];
							GetConVarString(sound_3, sound3, sizeof(sound3));
							if (GetConVarInt(sound_enable) == 1)
							{
								PrecacheSound(sound3, true);
								EmitSoundToClient(attacker,sound3, SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
							}				
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action Event_PlayerHurt(Handle event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	int damagetype = GetEventInt(event, "type");
	char WeaponName[64];
	GetEventString(event, "weapon", WeaponName, sizeof(WeaponName));
//火inferno
//火entityflame

	if(GetConVarInt(g_fire) == 0 && damagetype & DMG_BURN)
        return Plugin_Changed;

	if(GetConVarInt(g_blast) == 0 && damagetype & DMG_BLAST)
        return Plugin_Changed;
		
	
	if(strcmp(WeaponName, "sniper_awp", false) == 0||strcmp(WeaponName, "sniper_scout", false) == 0||strcmp(WeaponName, "pistol_magnum", false) == 0||strcmp(WeaponName, "shotgun_spas", false) == 0||strcmp(WeaponName, "hunting_rifle", false) == 0||strcmp(WeaponName, "sniper_military", false) == 0||strcmp(WeaponName, "autoshotgun", false) == 0||strcmp(WeaponName, "pumpshotgun", false) == 0||strcmp(WeaponName, "shotgun_chrome", false) == 0||strcmp(WeaponName, "pistol", false) == 0)
	{
	if(IsValidClient(victim))
	{
		if(IsValidClient(attacker))
		{
			if(!IsFakeClient(attacker))
			{
				if(GetClientTeam(victim) == 3)
				{
					if(IsVictimDeadPlayer[victim] == false)
					{
					if (GetConVarInt(pic_enable) == 1)
					{
						ShowKillMessage(attacker,hit_armor);
					}
					char sound2[64];
					GetConVarString(sound_2, sound2, sizeof(sound2));				
					if (GetConVarInt(sound_enable) == 1)
					{
						//PrintToChatAll("获取到的武器是%s", WeaponName);
						PrecacheSound(sound2, true);
						EmitSoundToClient(attacker, sound2, SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
					}
					if(g_taskClean[attacker] != INVALID_HANDLE)
					{
						KillTimer(g_taskClean[attacker]);
						g_taskClean[attacker] = INVALID_HANDLE;
					}
					float showtime = GetConVarFloat(Time);
					g_taskClean[attacker] = CreateTimer(showtime,task_Clean,attacker);
					}
				}
			}
		}
	}
	}
	else
	{
	if(IsValidClient(victim))
	{
		if(IsValidClient(attacker))
		{
			if(!IsFakeClient(attacker))
			{
				if(GetClientTeam(victim) == 3)
				{
					if(IsVictimDeadPlayer[victim] == false)
					{
					if (GetConVarInt(pic_enable) == 1)
					{
						ShowKillMessage(attacker,hit_armor_1);
					}
					char sound2[64];
					GetConVarString(sound_2, sound2, sizeof(sound2));				
					if (GetConVarInt(sound_enable) == 1)
					{
						//PrintToChatAll("获取到的武器是%s", WeaponName);
						PrecacheSound(sound2, true);
						EmitSoundToClient(attacker, sound2, SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
					}
					if(g_taskClean[attacker] != INVALID_HANDLE)
					{
						KillTimer(g_taskClean[attacker]);
						g_taskClean[attacker] = INVALID_HANDLE;
					}
					float showtime = GetConVarFloat(Time1);
					g_taskClean[attacker] = CreateTimer(showtime,task_Clean,attacker);
					}
				}
			}
		}
	}
	
	}
	
	return Plugin_Changed;
}

public Action Event_InfectedDeath(Handle event, const char[] name, bool dontBroadcast)
{
	int victim = GetEventInt(event, "infected_id");
	char sname[32];
	GetEdictClassname(victim, sname, sizeof(sname));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	bool heatshout = false;
	heatshout = GetEventBool(event, "headshot");
	bool damagetype = GetEventBool(event, "blast");
	int IsHeatshout = 0;
	int WeaponID = GetEventInt(event, "weapon_id");


	if(GetConVarInt(g_fire) == 0 && WeaponID == 0)
    return Plugin_Changed;


	if(GetConVarInt(g_blast) == 0 && damagetype)
    return Plugin_Changed;
	
	if (heatshout) IsHeatshout = 1;
	
	if(IsValidClient(attacker))
	{
	if (IsHeatshout)
	{
		if(GetClientTeam(attacker) == 2)	
		{
			if(!IsFakeClient(attacker))
			{
				if (GetConVarInt(pic_enable) == 1)
				{
				ShowKillMessage(attacker,kill_1);
				}
				char sound1[64];
				GetConVarString(sound_1, sound1, sizeof(sound1));
				if (GetConVarInt(sound_enable) == 1)
				{
				if(GetConVarInt(g_kill) == 1)
				{
				PrecacheSound(sound1, true);
				EmitSoundToClient(attacker, sound1, SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
				}
				}
				if(g_taskClean[attacker] != INVALID_HANDLE)
				{
				KillTimer(g_taskClean[attacker]);
				g_taskClean[attacker] = INVALID_HANDLE;
				}
				float showtime = GetConVarFloat(Time);
				g_taskClean[attacker] = CreateTimer(showtime,task_Clean,attacker);
			}
		}
	}
	else 
	{
	if(GetClientTeam(attacker) == 2)	
		{
			if(!IsFakeClient(attacker))
			{
			if (GetConVarInt(pic_enable) == 1)
			{
				ShowKillMessage(attacker,kill);
			}
			char sound3[64];
			GetConVarString(sound_3, sound3, sizeof(sound3));
			if (GetConVarInt(sound_enable) == 1)
			{
				if(GetConVarInt(g_kill) == 1)
				{
				//PrintToChatAll("获取到的id是%i", WeaponID);
				PrecacheSound(sound3, true);
				EmitSoundToClient(attacker, sound3, SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
				}				
			}
			if(g_taskClean[attacker] != INVALID_HANDLE)
			{
				KillTimer(g_taskClean[attacker]);
				g_taskClean[attacker] = INVALID_HANDLE;
			}
			float showtime = GetConVarFloat(Time);
			g_taskClean[attacker] = CreateTimer(showtime,task_Clean,attacker);
				}
			}
		}
	}
	return Plugin_Continue;
}
/*
public OnMapStart()
{
	char sounda[64];
	GetConVarString(sound_1, sounda, sizeof(sounda));
	char soundb[64];
	GetConVarString(sound_2, soundb, sizeof(soundb));
	char soundc[64];
	GetConVarString(sound_3, soundc, sizeof(soundc));
	if (!IsSoundPrecached(sounda)) PrecacheSound(sounda, true);
	if (!IsSoundPrecached(soundb)) PrecacheSound(soundb, true);
	if (!IsSoundPrecached(soundc)) PrecacheSound(soundc, true);
}
*/

public Action Event_InfectedHurt(Handle event, const char[] event_name, bool dontBroadcast)
{
	int victim = GetEventInt(event, "entityid");
	char sname[32];
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	int dmg = GetEventInt(event, "amount");
	int eventhealth = GetEntProp(victim, Prop_Data, "m_iHealth");
	bool IsVictimDead = false;
	int damagetype = GetEventInt(event, "type");

	if(GetConVarInt(g_fire) == 0 && damagetype & DMG_BURN)
        return Plugin_Changed;

	if(GetConVarInt(g_blast) == 0 && damagetype & DMG_BLAST)
        return Plugin_Changed;
	
	if(IsValidClient(attacker))
	{
	if(!IsFakeClient(attacker))
		{
	if((eventhealth - dmg) <= 0)
			{
				IsVictimDead = true;
			}


	if(!IsVictimDead)
	{
		if (StrEqual(sname, "witch"))
		{
			if (GetConVarInt(pic_enable) == 1)
			{
			ShowKillMessage(attacker,hit_armor_1);
			}
			char sound2[64];
			GetConVarString(sound_2, sound2, sizeof(sound2));
			if (GetConVarInt(sound_enable) == 1)
			{
				if(GetConVarInt(g_hit) == 1)
				{
				PrecacheSound(sound2, true);
				EmitSoundToClient(attacker, sound2, SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
				}
			}
			if(g_taskClean[attacker] != INVALID_HANDLE)
			{
				KillTimer(g_taskClean[attacker]);
				g_taskClean[attacker] = INVALID_HANDLE;
			}
			float showtime = GetConVarFloat(Time1);
			g_taskClean[attacker] = CreateTimer(showtime,task_Clean,attacker);
			}else{
			if (GetConVarInt(pic_enable) == 1)
			{
				ShowKillMessage(attacker,hit_armor_1);
			}
			char sound2[64];
			GetConVarString(sound_2, sound2, sizeof(sound2));
			if (GetConVarInt(sound_enable) == 1)
			{
				if(GetConVarInt(g_hit) == 1)
				{
				PrecacheSound(sound2, true);
				EmitSoundToClient(attacker, sound2, SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
				}
			}
			if(g_taskClean[attacker] != INVALID_HANDLE)
			{
				KillTimer(g_taskClean[attacker]);
				g_taskClean[attacker] = INVALID_HANDLE;
			}
			float showtime = GetConVarFloat(Time1);
			g_taskClean[attacker] = CreateTimer(showtime,task_Clean,attacker);
				}
			}

	
	
		}
	}
	return Plugin_Changed;
}

public void Event_round_start(Handle event,const char[] name,bool dontBroadcast)
{
	for(int client=1;client <= MaxClients;client++)
	{
		g_killCount[client] = 0;
		if(g_taskCountdown[client] != INVALID_HANDLE)
		{
			KillTimer(g_taskCountdown[client]);
			g_taskCountdown[client] = INVALID_HANDLE;
		}
	}
}

public Action task_Countdown(Handle Timer, int client)
{
	g_killCount[client] --;
	if(!IsPlayerAlive(client) || g_killCount[client]==0)
	{
		KillTimer(Timer);
		g_taskCountdown[client] = INVALID_HANDLE;
	}
}

public Action task_Clean(Handle Timer, int client)
{
	KillTimer(Timer);
	g_taskClean[client] = INVALID_HANDLE;
	int iFlags = GetCommandFlags("r_screenoverlay") & (~FCVAR_CHEAT);
	SetCommandFlags("r_screenoverlay", iFlags);
	ClientCommand(client, "r_screenoverlay \"\"");
}

public void ShowKillMessage(int client,int type)
{
	char overlays_file[64];
	char pic1[64];
	char pic2[64];
	char pic3[64];
	char pic4[64];
	GetConVarString(hit1, pic1, sizeof(pic1));
	GetConVarString(hit2, pic2, sizeof(pic2));
	GetConVarString(hit3, pic3, sizeof(pic3));
	GetConVarString(hit4, pic4, sizeof(pic4));
	Format(overlays_file,sizeof(overlays_file),"%s.vtf",pic1);
	PrecacheDecal(overlays_file,true);
	Format(overlays_file,sizeof(overlays_file),"%s.vtf",pic2);
	PrecacheDecal(overlays_file,true);
	Format(overlays_file,sizeof(overlays_file),"%s.vtf",pic3);
	PrecacheDecal(overlays_file,true);
	Format(overlays_file,sizeof(overlays_file),"%s.vtf",pic4);
	PrecacheDecal(overlays_file,true);
	Format(overlays_file,sizeof(overlays_file),"%s.vmt",pic1);
	PrecacheDecal(overlays_file,true);
	Format(overlays_file,sizeof(overlays_file),"%s.vmt",pic2);
	PrecacheDecal(overlays_file,true);
	Format(overlays_file,sizeof(overlays_file),"%s.vmt",pic3);
	PrecacheDecal(overlays_file,true);
	Format(overlays_file,sizeof(overlays_file),"%s.vmt",pic4);
	PrecacheDecal(overlays_file,true);
	
	
	int iFlags = GetCommandFlags("r_screenoverlay") & (~FCVAR_CHEAT);
	SetCommandFlags("r_screenoverlay", iFlags);
	switch(type)
	{
		case (kill_1):ClientCommand(client, "r_screenoverlay \"%s\"",pic1);
		case (kill):ClientCommand(client, "r_screenoverlay \"%s\"",pic3);
		case (hit_armor):ClientCommand(client, "r_screenoverlay \"%s\"",pic2);
		case (hit_armor_1):ClientCommand(client, "r_screenoverlay \"%s\"",pic4);
	}
}

public void OnClientDisconnect_Post(int client)
{
	if(g_taskCountdown[client] != INVALID_HANDLE)
	{
		KillTimer(g_taskCountdown[client]);
		g_taskCountdown[client] = INVALID_HANDLE;
	}
	
	if(g_taskClean[client] != INVALID_HANDLE)
	{
		KillTimer(g_taskClean[client]);
		g_taskClean[client] = INVALID_HANDLE;
	}
}
