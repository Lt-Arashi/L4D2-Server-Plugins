#pragma semicolon 1

#pragma newdecls required
#include <sourcemod>
#include <dhooks>
#include <left4dhooks>
#include <l4d2util>

#define CVAR_FLAGS		FCVAR_NOTIFY

int
    hpz[32],
	hpt[32];

int
    hpgive  = 40,
	givemax = 2;

Handle hp_seek;

ConVar
    ghpgive,
	ggivemax;

public Plugin myinfo = 
{
	name 			= "pills_give_by_hp",
	author 			= "77",
	description 	= "根据血量给药.",
	version 		= "1.2",
	url 			= "N/A"
}

public void OnPluginStart()
{
	ghpgive  = CreateConVar("l4d2_pills_give_by_hp_threshold", "50", "幸存者生命值低于多少时给药?", CVAR_FLAGS, true, 2.0);
	ggivemax = CreateConVar("l4d2_pills_give_by_hp_number",    "0",  "每回合最多发给每位幸存者多少瓶药?", CVAR_FLAGS, true, 0.0);

	ghpgive.AddChangeHook(ConVarChanged);
	ggivemax.AddChangeHook(ConVarChanged);

	HookEvent("round_start",	Event_RoundStart);	//回合开始.

	//AutoExecConfig(true, "pills_give_by_hp");
}

public void ConVarChanged(ConVar convar, const char[] oldvalue, const char[] newvalue)
{
	GetCvars();
}

void GetCvars()
{
	hpgive  = ghpgive.IntValue;
	givemax = ggivemax.IntValue;
	
	for (int i = 0; i < 32 ; i++)
	{
		hpz[i] = givemax;
	}
}


//回合开始.
public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if (hp_seek == null)
	{
		hp_seek = CreateTimer(1.0, HPF, _, TIMER_REPEAT);
	}
	for (int i = 0; i < 32 ; i++)
	{
		hpz[i] = givemax;
	}
}

public Action HPF(Handle timer)
{
	pt();
	//PrintToChatAll("pt");
	return Plugin_Continue;
}

void pt()
{
	for (int i = 0; i < 32 ; i++)
	{
		if (hpt[i] > 0)
		    hpt[i] = hpt[i] - 1;
	}
	int flags = GetCommandFlags("give");	
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);	
	for (int i = 1; i <= MaxClients; i++)
	{
		/*PrintToChat(i, "Check :");
		PrintToChat(i, "HP : %d", GetSurvivorHP(i));
		PrintToChat(i, "hpz : %d", hpz[i]);
		PrintToChat(i, "hpt : %d", hpt[i]);
		if (IsHavePills(i))
		{
			PrintToChat(i, "YES");
		}
		else
		{
			PrintToChat(i, "NO");
		}*/
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && IsPlayerState(i))
		{
			if (GetSurvivorHP(i) < hpgive && hpt[i] == 0 && hpz[i] > 0 && !IsHavePills(i))
			{
				FakeClientCommand(i, "give pain_pills");
				hpt[i] = 7;
				hpz[i] = hpz[i] - 1;
			}
		}
	}
	SetCommandFlags("give", flags|FCVAR_CHEAT);
}

bool IsHavePills(int client)
{
	int player_weapon = GetPlayerWeaponSlot(client, 4);
	int player_wepid  = IdentifyWeapon(player_weapon);
	if (player_wepid == 15 || player_wepid == 23)
	{
		return true;
	}
	else
	{
		return false;
	}
}

//幸存者总血量.
int GetSurvivorHP(int client)
{
	int HP = GetClientHealth(client) + GetPlayerTempHealth(client);
	return IsPlayerAlive(client) ? HP > 999 ? 999 : HP : 0;//如果幸存者血量大于999就显示为999
}

//幸存者虚血量.
int GetPlayerTempHealth(int client)
{
	static Handle painPillsDecayCvar;
	painPillsDecayCvar = FindConVar("pain_pills_decay_rate");
	if (painPillsDecayCvar == null)
		return -1;

	int tempHealth = RoundToCeil(GetEntPropFloat(client, Prop_Send, "m_healthBuffer") - ((GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime")) * GetConVarFloat(painPillsDecayCvar))) - 1;
	return tempHealth < 0 ? 0 : tempHealth;
}

//正常状态.
stock bool IsPlayerState(int client)
{
	return !GetEntProp(client, Prop_Send, "m_isIncapacitated") && !GetEntProp(client, Prop_Send, "m_isHangingFromLedge");
}