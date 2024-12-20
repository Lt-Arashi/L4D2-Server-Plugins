/*
 *	v1.1
 *	1:增加打开夜视仪弹出亮度设置菜单,设置减弱加强亮度,也可以手动开启亮度菜单.
 *
 *	v1.0
 *	1:幸存者双击F,感染者单击F,开启关闭夜视仪.
 *	2:聚光灯部分借鉴King_OXO(edited, now have cookie)大佬源码,防止实体溢出删除实体部分感谢little_froy大佬指导和提供借鉴源码.
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <multicolors>

#define PLUGIN_VERSION "1.1"

#define	UseTeam2	(1 << 0)
#define UseTeam3	(1 << 1)

ConVar g_cNightVisionMode;

int g_iNightVisionMode;

int IMPULS_FLASHLIGHT = 100;

int g_iBrightness[MAXPLAYERS+1];

int g_iPlayerLight[MAXPLAYERS+1] = {-1, ...};

float g_fPressTime[MAXPLAYERS+1];

public Plugin myinfo =
{
	name = "l4d2_NightVision",
	author = "X光",
	description = "夜视仪",
	version = PLUGIN_VERSION,
	url = "QQ群59046067"
};

public void OnPluginStart()
{
	g_cNightVisionMode = CreateConVar("l4d2_night_vision_mode", "1", "0=关闭, 1=只有幸存者可以使用, 2=只有感染者可以使用, 3=都可以使用.");
	g_cNightVisionMode.AddChangeHook(ConVarChange);

	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("player_disconnect", Event_PlayerDisconnect);


	//AutoExecConfig(true, "l4d2_NightVision");
}

public void ConVarChange(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetConVar();
}

void GetConVar()
{
	g_iNightVisionMode = g_cNightVisionMode.IntValue;
}

public void OnConfigsExecuted()
{
	GetConVar();
}

public void OnClientPutInServer(int client)
{
	if (IsFakeClient(client))
		return;

	CreateTimer(10.0, TimerAnnounce, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

Action TimerAnnounce(Handle timer, any client)
{
	if ((client = GetClientOfUserId(client)))
	{
		if (IsClientInGame(client))
		{
			switch (g_iNightVisionMode)
			{
				case 1:
				{
					if (GetClientTeam(client) == 2)
						CPrintToChat(client,"{default}[{blue}HspAF{default}] {blue}幸存者{default}双击F{blue}开关夜视仪.");
				}
				case 2:
				{
					if (GetClientTeam(client) == 3)
						CPrintToChat(client,"{default}[{blue}HspAF{default}] {blue}感染者{default}单击F{blue}开关夜视仪.");
				}
				case 3:
					CPrintToChat(client,"{default}[{blue}HspAF{default}] {blue}幸存者{default}双击F{blue}感染者{default}单击F{blue}开关夜视仪.");
			}
		}
	}

	return Plugin_Continue;
}

Action Hook_SetTransmit(int entity, int client)
{
	int ref = EntIndexToEntRef(entity);

	if (g_iPlayerLight[client] == ref)
		return Plugin_Continue;

	return Plugin_Handled;
}

void RemoveRef(int& ref)
{
	int entity = EntRefToEntIndex(ref);

	if (entity != -1)
		RemoveEdict(entity);

	ref = -1;
}

void ResetSpriteNormal(int client)
{
	if (g_iPlayerLight[client] != -1)
		RemoveRef(g_iPlayerLight[client]);
}

void SwitchNightVision(int client)
{
	if (g_iPlayerLight[client] == -1)
	{
		int Light = CreateEntityByName("light_dynamic");
		if (IsValidEntity(Light))
		{
			g_iPlayerLight[client] = EntIndexToEntRef(Light);

			DispatchKeyValue(Light, "_light", "255 255 255 255");

			char item[4];
			Format(item, sizeof item, "%d", g_iBrightness[client]);
			DispatchKeyValue(Light, "brightness", item);

			DispatchKeyValueFloat(Light, "spotlight_radius", 32.0);
			DispatchKeyValueFloat(Light, "distance", 750.0);
			DispatchKeyValue(Light, "style", "0");
			DispatchSpawn(Light);
			AcceptEntityInput(Light, "TurnOn");
			SetVariantString("!activator");
			AcceptEntityInput(Light, "SetParent", client);
			TeleportEntity(Light, view_as<float>({0.0, 0.0, 20.0}), view_as<float>({0.0, 0.0, 0.0}), NULL_VECTOR);
			SDKHook(Light, SDKHook_SetTransmit, Hook_SetTransmit);
			PrintHintText(client, "夜视仪已开启");
		}
	}
	else
	{
		ResetSpriteNormal(client);
		ClientCommand(client, "slot10");
		PrintHintText(client, "夜视仪已关闭");
	}
}

public void OnClientDisconnect(int client)
{
	ResetSpriteNormal(client);
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
		ResetSpriteNormal(i);
}

void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!client || !IsClientInGame(client) || IsFakeClient(client))
		return;

	ClientCommand(client, "slot10");
	int team = event.GetInt("team");

	switch (g_iNightVisionMode)
	{
		case 1:
		{
			if (team == 1 || team == 2)
				return;
		}
		case 2:
		{
			if (team == 3)
				return;
		}
		case 3:
			return;
	}

	ResetSpriteNormal(client);
}

void Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!client || g_iBrightness[client] != 0 || IsFakeClient(client))
		return;

	g_iBrightness[client] = 0;
}

public void OnPlayerRunCmdPre(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
	if (impulse == IMPULS_FLASHLIGHT)
	{
		if (g_iNightVisionMode & UseTeam2 && GetClientTeam(client) == 2)
		{
			float time = GetEngineTime();
			if(time - g_fPressTime[client] < 0.3)
				SwitchNightVision(client);

			g_fPressTime[client] = time; 
		}
		if (g_iNightVisionMode & UseTeam3 && GetClientTeam(client) == 3)
			SwitchNightVision(client);
	}
}