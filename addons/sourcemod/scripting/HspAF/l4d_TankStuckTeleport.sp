#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <left4dhooks>

#define CVAR_FLAGS FCVAR_NOTIFY
#define PLUGIN_VERSION "2.3"

public Plugin myinfo = {
	name = "Tank Anti-Stuck",
	author = "Dragokas, X光",
	description = "Teleport tank if he was stuck within collision and can't move",
	version = PLUGIN_VERSION,
	url = "https://github.com/dragokas"
}

/*
	ChangeLog:

	2.3 (06-December-2023)
	 插件作者只维护到2.2版本,2.3版本全新修改.
	 1. 坦克卡住传送为设置目标附近视野盲区有效位置,惩罚传送为最前方超过设置值距离附近.
	 2. 新增目标选择最前方的幸存者.
	 3. 精简代码,增加插件指令开关功能.

	2.2 (03-Sep-2019)
	 - Returned to the previous stuck detection method (radius position-based)
	 with removing false positives when tank finishes off incapped player nearby or attacking in place.
	 - Some code optimizations, comments, removed some unused.
	 - "On ladder" logic is changed.

	2.1 (09-Aug-2019)
	 - Prevent rush punishment when tank count is 1 elapsed
	 - Tank is react faster when he is blocked on the ladder

	2.0 (05-May-2019)
	 - Collision with another clients (include other tanks) is now not considered as stuck.
	 - Fixed case when TR_DidHit() could return wrong result due to extracting info from global trace.
	 - Added "l4d_TankAntiStuck_dest_object" ConVar to control the destination, 
	 where you want to teleport tank to:
	 (0 - next to current tank, 1 - next to another tank, 2 - next to player). By default: 1 (previously, it was: 2).

	 - Added new violations (punishment is teleporting tank directly to player):
	 1. Punish the player who doesn't move (tank stucker / inactive player)
	 2. Punish the player who rush too far from the nearest tank (and thus, from the team, including team rush).

	 Punishments are enabled by default. To disable, use below ConVars:
	 - l4d_TankAntiStuck_idler_punish
	 - l4d_TankAntiStuck_rusher_punish

	 For detail adjustments, see more new ConVars in the thread.

	 - Code optimization
	 - Tank angry detection is improved
	 - Tank stuck detection is improved to avoid false positives

	1.3 
	 - Added some missing ConVar hooks.

	1.2 (05-Mar-2019)
	 - Added all user's ConVars.
	 - Added late loading code.
	 - Included anti-losing tank control ConVar (thanks to cravenge)

	1.1 (01-Mar-2019)
	 - Added more reliable logic

	1.0 (05-Jan-2019)
	 - Initial release

==========================================================================================

	Credits:

*	Peace-Maker - for some examples on TraceHull filter.

*	stinkyfax - for examples of teleporting in direction math.

*	cravenge - for some ConVar, possibly, preventing tank from losing control when getting stuck.

* 	midnight9, PatriotGames - who tried to help me with another ConVars against losing tank control.

==========================================================================================

	Related topics:
	https://forums.alliedmods.net/showthread.php?t=313696
	https://forums.alliedmods.net/showthread.php?p=2133193
	https://forums.alliedmods.net/showthread.php?t=101998

*/

#define DEBUG 0

ConVar
	g_cEnabled,
	g_cNonAngryTime,
	g_cTankDistanceMax,
	g_cStuckInterval,
	g_cNonStuckRadius,
	g_cDestObject,
	g_cMinTransmit,
	g_cMaxTransmit,
	g_cAllIntellect,
	g_cApplyConVar,
	g_cRusherPunish,
	g_cRusherDist,
	g_cRusherCheckTimes,
	g_cRusherCheckInterv,
	g_cRusherMinPlayers,
	g_cRusherEnable,
	g_cStuckFailsafe,
	g_cTankClawRange,
	g_cTankClawRangeDown;

float g_fNonAngryTime, g_fMaxNonAngryDist, g_fStuckInterval, g_fNonStuckRadius, g_fMinTransmit, g_fMaxTransmit, g_fRusherDist, g_fRusherCheckInterv, g_fTankClawRange;
float g_fPos[MAXPLAYERS+1][3];

bool g_bEnabled, g_bAllIntellect, g_bApplyConVar, g_bRusherPunish, g_bRusherEnable, g_bMapStarted;
bool g_bAngry[MAXPLAYERS+1];

int g_iDestObject, g_iRusherCheckTimes, g_iRusherMinPlayers, g_iPunish;
int g_iStuckTimes[MAXPLAYERS+1], g_iRushTimes[MAXPLAYERS+1];

public void OnPluginStart() {
	CreateConVar("l4d_tank_anti_stuck_version", PLUGIN_VERSION, "plugin version", FCVAR_DONTRECORD);

	g_cEnabled = CreateConVar("l4d_TankAntiStuck_enable",							"1",		"是否开启插件(0=关闭, 1=开启).", CVAR_FLAGS);
	g_cNonAngryTime = CreateConVar("l4d_TankAntiStuck_non_angry_time",				"15.0",		"如果在指定的多少秒坦克出现但没有行动(响起BGM)则自动传送坦克(0=禁用).", CVAR_FLAGS);
	g_cTankDistanceMax = CreateConVar("l4d_TankAntiStuck_tank_distance_max",		"2000.0",	"坦克与最近的幸存者允许的最远距离(BGM响起时),如果超过这个距离则传送坦克(0=禁用).", CVAR_FLAGS);
	g_cStuckInterval = CreateConVar("l4d_TankAntiStuck_check_interval",				"10.0",		"多少秒检测一次坦克是否被卡住.", CVAR_FLAGS);
	g_cNonStuckRadius = CreateConVar("l4d_TankAntiStuck_non_stuck_radius",			"50.0",		"在指定秒内未移动时,坦克被判定为未卡住的最大半径.", CVAR_FLAGS);
	g_cDestObject = CreateConVar("l4d_TankAntiStuck_dest_object",					"3",		"坦克传送到什么物体旁边(0=当前坦克附近, 1=别的坦克附近, 2=随机幸存者附近, 3=最前方幸存者附近).", CVAR_FLAGS);
	g_cMinTransmit = CreateConVar("l4d_TankAntiStuck_min_transmit",					"300.0",	"坦克防卡传送距离目标以及所有幸存者最近距离.", CVAR_FLAGS);
	g_cMaxTransmit = CreateConVar("l4d_TankAntiStuck_max_transmit",					"1000.0",	"坦克防卡传送距离目标最远距离(找不到有效位置自动扩大范围).", CVAR_FLAGS);
	g_cAllIntellect = CreateConVar("l4d_TankAntiStuck_all_intellect",				"1",		"防卡死应用的目标(0=只有BOT, 1=玩家和BOT).", CVAR_FLAGS);
	g_cApplyConVar = CreateConVar("l4d_TankAntiStuck_apply_convar",					"1",		"防止坦克因为卡住而自杀(0=关闭, 1=开启).", CVAR_FLAGS);
	g_cRusherPunish = CreateConVar("l4d_TankAntiStuck_rusher_punish",				"1",		"是否惩罚(把坦克传送到他附近)跑图(出了坦克不打,一个人跑)的玩家(0=关闭, 1=开启).", CVAR_FLAGS);
	g_cRusherDist = CreateConVar("l4d_TankAntiStuck_rusher_dist",					"1500.0",	"离坦克这么远被认为是在跑图.", CVAR_FLAGS);
	g_cRusherCheckTimes = CreateConVar("l4d_TankAntiStuck_rusher_check_times",		"4",		"检测多少次玩家如果在跑图,下一次达到设置检测时间后就执行惩罚传送.", CVAR_FLAGS);
	g_cRusherCheckInterv = CreateConVar("l4d_TankAntiStuck_rusher_check_interval",	"5.0",		"多少秒检测一次玩家是否跑图.", CVAR_FLAGS);
	g_cRusherMinPlayers = CreateConVar("l4d_TankAntiStuck_rusher_minplayers",		"2",		"至少要这么多玩家才考虑检查是否有人跑图.", CVAR_FLAGS);
	g_cRusherEnable = CreateConVar("l4d_TankAntiStuck_rusher_Enable",				"0",		"救援关是否检测跑图(0=关闭, 1=开启).", CVAR_FLAGS);

	g_cStuckFailsafe = FindConVar("tank_stuck_failsafe");
	g_cTankClawRange = FindConVar("claw_range");
	g_cTankClawRangeDown = FindConVar("claw_range_down");

	HookConVarChange(g_cEnabled,			CvarChanged);
	HookConVarChange(g_cNonAngryTime,		CvarChanged);
	HookConVarChange(g_cTankDistanceMax,	CvarChanged);
	HookConVarChange(g_cStuckInterval,		CvarChanged);
	HookConVarChange(g_cNonStuckRadius,		CvarChanged);
	HookConVarChange(g_cDestObject,			CvarChanged);
	HookConVarChange(g_cMinTransmit,		CvarChanged);
	HookConVarChange(g_cMaxTransmit,		CvarChanged);
	HookConVarChange(g_cAllIntellect,		CvarChanged);
	HookConVarChange(g_cApplyConVar,		CvarChanged);
	HookConVarChange(g_cRusherPunish,		CvarChanged);
	HookConVarChange(g_cRusherDist,			CvarChanged);
	HookConVarChange(g_cRusherCheckTimes,	CvarChanged);
	HookConVarChange(g_cRusherCheckInterv,	CvarChanged);
	HookConVarChange(g_cRusherMinPlayers,	CvarChanged);
	HookConVarChange(g_cRusherEnable,		CvarChanged);

	HookEntityOutput("trigger_finale", "FinaleStart", OnFinaleStart);

	RegAdminCmd("sm_tkfk", Cmd_TankAntiStuck, ADMFLAG_ROOT, "插件开关指令");

	//AutoExecConfig(true, "l4d_tank_antistuck");
}

void CvarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	GetCvar();
}

void GetCvar() {
	g_bEnabled = g_cEnabled.BoolValue;
	g_fNonAngryTime = g_cNonAngryTime.FloatValue;
	g_fMaxNonAngryDist = g_cTankDistanceMax.FloatValue;
	g_fStuckInterval = g_cStuckInterval.FloatValue;
	g_fNonStuckRadius = g_cNonStuckRadius.FloatValue;
	g_iDestObject = g_cDestObject.IntValue;
	g_fMinTransmit = g_cMinTransmit.FloatValue;
	g_fMaxTransmit = g_cMaxTransmit.FloatValue;
	g_bAllIntellect = g_cAllIntellect.BoolValue;
	g_bApplyConVar = g_cApplyConVar.BoolValue;
	g_bRusherPunish = g_cRusherPunish.BoolValue;
	g_fRusherDist = g_cRusherDist.FloatValue;
	g_iRusherCheckTimes = g_cRusherCheckTimes.IntValue;
	g_fRusherCheckInterv = g_cRusherCheckInterv.FloatValue;
	g_iRusherMinPlayers = g_cRusherMinPlayers.IntValue;
	g_bRusherEnable = g_cRusherEnable.BoolValue;
	InitHook();
}

public void OnConfigsExecuted() {
	GetCvar();
	if (g_bApplyConVar) {
		if (g_cStuckFailsafe != null)
			g_cStuckFailsafe.SetInt(0);
	}
	g_fTankClawRange = g_cTankClawRangeDown.FloatValue;

	if (g_cTankClawRange.FloatValue > g_fTankClawRange)
		g_fTankClawRange = g_cTankClawRange.FloatValue;
	
	g_fTankClawRange *= 2; // to be sure
}

void InitHook() {
	static bool bHooked;

	if (g_bEnabled) {
		if (!bHooked) {
			HookEvent("tank_spawn",				Event_TankSpawn,		EventHookMode_Post);
			HookEvent("player_death",			Event_PlayerDeath,		EventHookMode_Pre);
			HookEvent("round_start",			Event_RoundStart,		EventHookMode_PostNoCopy);
			HookEvent("round_end",				Event_RoundEnd,			EventHookMode_PostNoCopy);
			HookEvent("finale_win",				Event_RoundEnd,			EventHookMode_PostNoCopy);
			HookEvent("mission_lost",			Event_RoundEnd,			EventHookMode_PostNoCopy);
			HookEvent("map_transition",			Event_RoundEnd,			EventHookMode_PostNoCopy);
			HookEvent("finale_vehicle_leaving", Event_RoundEnd, 		EventHookMode_PostNoCopy);
			bHooked = true;
		}
	}
	else {
		if (bHooked) {
			UnhookEvent("tank_spawn",			Event_TankSpawn,		EventHookMode_Post);
			UnhookEvent("player_death",			Event_PlayerDeath,		EventHookMode_Pre);
			UnhookEvent("round_start",			Event_RoundStart,		EventHookMode_PostNoCopy);
			UnhookEvent("round_end",			Event_RoundEnd,			EventHookMode_PostNoCopy);
			UnhookEvent("finale_win",			Event_RoundEnd,			EventHookMode_PostNoCopy);
			UnhookEvent("mission_lost",			Event_RoundEnd,			EventHookMode_PostNoCopy);
			UnhookEvent("map_transition",		Event_RoundEnd,			EventHookMode_PostNoCopy);
			HookEvent("finale_vehicle_leaving", Event_RoundEnd, 		EventHookMode_PostNoCopy);
			bHooked = false;
		}
	}
}

void CopyVectors(float origin[3], float result[3]) {
	result[0] = origin[0];
	result[1] = origin[1];
	result[2] = origin[2];
}

bool isValidNavArea(float vPos[3]) {
	return L4D2Direct_GetTerrorNavArea(vPos) != Address_Null;
}

bool IsOnLadder(int entity) {
	return GetEntityMoveType(entity) == MOVETYPE_LADDER;
}

bool IsPlayerState(int client) {
	return !GetEntProp(client, Prop_Send, "m_isIncapacitated") && !GetEntProp(client, Prop_Send, "m_isHangingFromLedge");
}

bool IsFinalMap() {
	return FindEntityByClassname(-1, "info_changelevel") == -1 && FindEntityByClassname(-1, "trigger_changelevel") == -1;
}

bool IsAngry(int tank) {
	if (GetEntProp(tank, Prop_Send, "m_zombieState") != 0)
		return true;
	
	if (GetEntProp(tank, Prop_Send, "m_hasVisibleThreats") != 0)
		return true;
		
	return false;
}

bool IsTankAttacking(int tank) {
	return GetEntProp(tank, Prop_Send, "m_fireLayerSequence") > 0;
}

bool IsTank(int client) {
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3 && GetEntProp(client, Prop_Send, "m_zombieClass") == 8 && IsPlayerAlive(client);
}

bool CheckTankIntellect(int tank) {
	if (g_bAllIntellect)
		return true;
	else
		if (IsFakeClient(tank))
			return true;

	return false;
}

bool IsIncappedNearBy(float vOrigin[3]) {
	static float vOriginPlayer[3];
	
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && !IsPlayerState(i) && IsPlayerAlive(i)) {
			GetClientAbsOrigin(i, vOriginPlayer);
			if (GetVectorDistance(vOriginPlayer, vOrigin) <= g_fTankClawRange)
				return true;
		}
	}
	return false;
}

bool TR_EntityFilter(int entity, int mask) {
	if (entity <= MaxClients)
		return false;
	else if (entity > MaxClients) {
		char classname[16] = {'\0'};
		GetEdictClassname(entity, classname, sizeof(classname));
		if (strcmp(classname, "infected") == 0 || strcmp(classname, "witch") == 0 || strcmp(classname, "prop_physics") == 0 || strcmp(classname, "tank_rock") == 0)
			return false;
	}

	return true;
}

bool IsPosStuck(int client, float refpos[3]) {
	bool stuck = false;
	float vMins[3], vMaxs[3], vEnd[3];
	GetClientMins(client, vMins);
	GetClientMaxs(client, vMaxs);
	CopyVectors(refpos, vEnd);
	vEnd[2] += 72.0;
	TR_TraceHullFilter(refpos, vEnd, vMins, vMaxs, MASK_NPCSOLID_BRUSHONLY, TR_EntityFilter);
	stuck = TR_DidHit();

	return stuck;
}

bool GetSingleCompareDist(int client, float vPos[3]) {
	static float pos[3], distance;

	if (IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client)) {
		GetClientAbsOrigin(client, pos);
		distance = GetVectorDistance(vPos, pos, false);
		if (distance > g_fMaxTransmit)
			return true;
	}

	return false;
}

bool GetAllCompareDist(float vPos[3]) {
	static float pos[3], distance;

	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i)) {
			GetClientAbsOrigin(i, pos);
			distance = GetVectorDistance(vPos, pos, false);
			if (distance < g_fMinTransmit)
				return true;
		}
	}

	return false;
}

float GetHeightFromGround(float vPos[3]) {
	float vDown[3];
	vPos[2] += 40.0;
	vDown[2] -= 100000.0;
	Handle hndl = TR_TraceHullFilterEx(vPos, vDown, view_as<float>({-16.0, -16.0, 0.0}), view_as<float>({16.0, 16.0, 72.0}), MASK_PLAYERSOLID, TR_EntityFilter);
	if (TR_DidHit(hndl)) {
		TR_GetEndPosition(vPos, hndl);
		delete hndl;
		return vPos[2];
	}
	delete hndl;

	return vPos[2] - 40.0;
}

float Math_GetRandomFloat(float min, float max) {
	return (GetURandomFloat() * (max  - min)) + min;
}

float GetDistanceToNearestClient(int client) {
	float tpos[3], spos[3], dist, mindist;
	GetClientAbsOrigin(client, tpos);
	
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i)) {
			GetClientAbsOrigin(i, spos);
			dist = GetVectorDistance(tpos, spos, false);
			if (dist < mindist || mindist == 0.0)
				mindist = dist;
		}
	}

	return mindist;
}

int IsClientIdle(int client) {
	if (!HasEntProp(client, Prop_Send, "m_humanSpectatorUserID"))
		return 0;

	return GetClientOfUserId(GetEntProp(client, Prop_Send, "m_humanSpectatorUserID"));
}

int GetAnyRandomSurvivor() {
	int client;
	ArrayList aClients = new ArrayList();

	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerState(i) && IsPlayerAlive(i))
			aClients.Push(i);
	}
	if (aClients.Length > 0) {
		SetRandomSeed(GetGameTickCount());
		client = aClients.Get(GetRandomInt(0, aClients.Length - 1));
	}
	delete aClients;

	return client;
}

int GetAheadSurvivor() {
	static int i;
	static float flow;
	static ArrayList flowList;
	flowList = new ArrayList(2);

	for (i = 1; i <= MaxClients; i++) {
		if (!IsClientInGame(i) || GetClientTeam(i) != 2 || !IsPlayerAlive(i))
			continue;

		flow = L4D2Direct_GetFlowDistance(i);
		if (flow && flow != -9999.0)
			flowList.Set(flowList.Push(flow), i, 1);
	}
	if (flowList.Length == 0) {
		delete flowList;
		return -1;
	}

	flow / L4D2Direct_GetMapMaxFlowDistance() * 100 > 0.0 ? flowList.Sort(Sort_Descending, Sort_Float) : flowList.Sort(Sort_Ascending, Sort_Float);
	i = flowList.Get(0, 1);
	delete flowList;

	return i;
}

int GetNearestTank(int client) {
	float tpos[3], spos[3], dist, mindist;
	int iNearClient;
	GetClientAbsOrigin(client, tpos);

	for (int i = 1; i <= MaxClients; i++) {
		if (i != client && IsClientInGame(i) && GetEntProp(i, Prop_Send, "m_zombieClass") == 8 && IsPlayerAlive(i)) {
			GetClientAbsOrigin(i, spos);
			dist = GetVectorDistance(tpos, spos, false);
			if (dist < mindist || mindist == 0.0) {
				mindist = dist;
				iNearClient = i;
			}
		}
	}

	return iNearClient;
}

int GetSurvivorCountAlive() {
	int count;
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && !IsFakeClient(i) && IsPlayerAlive(i))
			count++;
	}
	return count;
}

char[] GetPlayerName(int client) {
	char sName[32];

	if (!IsFakeClient(client))
		FormatEx(sName, sizeof(sName), "\x04%N", client);
	else {
		GetClientName(client, sName, sizeof(sName));
		SplitString(sName, "Tank", sName, sizeof(sName));
	}

	return sName;
}

char[] GetTrueName(int client) {
	char sName[32];
	int Bot = IsClientIdle(client);

	if (Bot != 0)
		FormatEx(sName, sizeof(sName), "闲置:%N", Bot);
	else
		GetClientName(client, sName, sizeof(sName));

	return sName;
}

bool FindValidLocations(int client, float IsValidPos[3]) {
	static int i;

	for (i = 1; i <= 8; i++) {
		if (L4D_GetRandomPZSpawnPosition(client, i, 10, IsValidPos)) {
			if (!GetSingleCompareDist(client, IsValidPos))
				return true;
		}
	}

	for (i = 0; i < MaxClients; i++) {
		GetClientAbsOrigin(client, IsValidPos);
		IsValidPos[0] += Math_GetRandomFloat(g_fMinTransmit, g_fMaxTransmit);
		IsValidPos[1] += Math_GetRandomFloat(g_fMinTransmit, g_fMaxTransmit);
		IsValidPos[2] = GetHeightFromGround(IsValidPos);
		if (!GetAllCompareDist(IsValidPos) && isValidNavArea(IsValidPos) && !IsPosStuck(client, IsValidPos))
			return true;

		GetClientAbsOrigin(client, IsValidPos);
		IsValidPos[0] -= Math_GetRandomFloat(g_fMinTransmit, g_fMaxTransmit);
		IsValidPos[1] -= Math_GetRandomFloat(g_fMinTransmit, g_fMaxTransmit);
		IsValidPos[2] = GetHeightFromGround(IsValidPos);
		if (!GetAllCompareDist(IsValidPos) && isValidNavArea(IsValidPos) && !IsPosStuck(client, IsValidPos))
			return true;

		GetClientAbsOrigin(client, IsValidPos);
		IsValidPos[0] += Math_GetRandomFloat(g_fMinTransmit, g_fMaxTransmit);
		IsValidPos[1] -= Math_GetRandomFloat(g_fMinTransmit, g_fMaxTransmit);
		IsValidPos[2] = GetHeightFromGround(IsValidPos);
		if (!GetAllCompareDist(IsValidPos) && isValidNavArea(IsValidPos) && !IsPosStuck(client, IsValidPos))
			return true;

		GetClientAbsOrigin(client, IsValidPos);
		IsValidPos[0] -= Math_GetRandomFloat(g_fMinTransmit, g_fMaxTransmit);
		IsValidPos[1] += Math_GetRandomFloat(g_fMinTransmit, g_fMaxTransmit);
		IsValidPos[2] = GetHeightFromGround(IsValidPos);
		if (!GetAllCompareDist(IsValidPos) && isValidNavArea(IsValidPos) && !IsPosStuck(client, IsValidPos))
			return true;

		GetClientAbsOrigin(client, IsValidPos);
		IsValidPos[0] += Math_GetRandomFloat(g_fMinTransmit, g_fMaxTransmit);
		IsValidPos[2] = GetHeightFromGround(IsValidPos);
		if (!GetAllCompareDist(IsValidPos) && isValidNavArea(IsValidPos) && !IsPosStuck(client, IsValidPos))
			return true;

		GetClientAbsOrigin(client, IsValidPos);
		IsValidPos[0] -= Math_GetRandomFloat(g_fMinTransmit, g_fMaxTransmit);
		IsValidPos[2] = GetHeightFromGround(IsValidPos);
		if (!GetAllCompareDist(IsValidPos) && isValidNavArea(IsValidPos) && !IsPosStuck(client, IsValidPos))
			return true;

		GetClientAbsOrigin(client, IsValidPos);
		IsValidPos[1] += Math_GetRandomFloat(g_fMinTransmit, g_fMaxTransmit);
		IsValidPos[2] = GetHeightFromGround(IsValidPos);
		if (!GetAllCompareDist(IsValidPos) && isValidNavArea(IsValidPos) && !IsPosStuck(client, IsValidPos))
			return true;

		GetClientAbsOrigin(client, IsValidPos);
		IsValidPos[1] -= Math_GetRandomFloat(g_fMinTransmit, g_fMaxTransmit);
		IsValidPos[2] = GetHeightFromGround(IsValidPos);
		if (!GetAllCompareDist(IsValidPos) && isValidNavArea(IsValidPos) && !IsPosStuck(client, IsValidPos))
			return true;
	}

	return false;
}

Action Cmd_TankAntiStuck(int client, int args) {
	g_cEnabled.BoolValue = !g_bEnabled;
	PrintToChat(client, "\x04[提示]\x05坦克防卡防跑图传送功能已\x03%s\x05.", g_bEnabled ? "开启" : "关闭");

	return Plugin_Handled;
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast) {
	OnMapStart();
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast) {
	OnMapEnd();
}

public void OnMapStart() {
	g_iPunish = 1;
	g_bMapStarted = true;
}

public void OnMapEnd() {
	g_bMapStarted = false;
}

public void OnClientDisconnect(int client) {
	if (IsFakeClient(client))
		return;

	g_iRushTimes[client] = 0;
}

void OnFinaleStart(const char[] output, int caller, int activator, float delay) {
	int entity = FindEntityByClassname(-1, "trigger_finale");

	if (entity != -1)
		g_iPunish = GetEntProp(entity, Prop_Data, "m_type");
}

void Event_TankSpawn(Event event, const char[] name, bool dontBroadcast) {
	if (!g_bEnabled || !g_bMapStarted) return;
	
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (CheckTankIntellect(client)) {
		BeginTankTracing(client);
		BeginIdlerRusherTracing(client);
		#if (DEBUG)
			PrintToChatAll("%N (id: %i) 出现了.", client, client);
		#endif
	}
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	if (!g_bMapStarted) return;

	int client = GetClientOfUserId(event.GetInt("userid"));

	if (client > 0 && client <= MaxClients && IsClientInGame(client) && g_iRushTimes[client] != 0)
		g_iRushTimes[client] = 0;
}

void BeginIdlerRusherTracing(int client) {
	if (g_bRusherPunish) {
		if (g_bRusherEnable && IsFinalMap() || !IsFinalMap())
			CreateTimer(g_fRusherCheckInterv, Timer_CheckRusher, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}

Action Timer_CheckRusher(Handle timer, int UserId) {
	int tank = GetClientOfUserId(UserId);

	if (!IsTank(tank) || !g_bMapStarted || g_iPunish != 1)
		return Plugin_Stop;

	if (!g_bEnabled || GetEntProp(tank, Prop_Data, "m_iMaxHealth") == GetEntProp(tank, Prop_Data, "m_iHealth"))
		return Plugin_Continue;

	float pos[3], postank[3], distance;
	int client = GetAheadSurvivor(); //获取最前方的幸存者.

	if (client > 0) {
		GetClientAbsOrigin(client, pos);
		if (GetSurvivorCountAlive() >= g_iRusherMinPlayers) {
			GetClientAbsOrigin(tank, postank);
			distance = GetVectorDistance(pos, postank, false);
			if (distance > g_fRusherDist && IsPlayerState(client)) {
				if (g_iRushTimes[client] >= g_iRusherCheckTimes) {
					pos[0] -= 20.0;
					SetEntProp(tank, Prop_Send, "m_bDucked", 1);
					SetEntityFlags(tank, GetEntityFlags(tank) | FL_DUCKING);
					TeleportEntity(tank, pos, NULL_VECTOR, NULL_VECTOR);
					g_iRushTimes[client] = 0;
					PrintToChatAll("\x04[提示]\x05惩罚启动\x03坦克%s\x05传送到跑图玩家\x03%s\x05身边.", GetPlayerName(tank), GetTrueName(client));
					pos[0] += 20.0;
				}
				else 
					g_iRushTimes[client]++;
			}
			else
				g_iRushTimes[client] = 0;
		}
	}

	return Plugin_Continue;
}

void BeginTankTracing(int client) {
	g_iStuckTimes[client] = 0;
	g_bAngry[client] = false;
	GetClientAbsOrigin(client, g_fPos[client]);

	// wait until somebody make tank angry to begin check for stuck
	CreateTimer(2.0, Timer_CheckAngry, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

	if (g_fNonAngryTime) {
		// check if tank didnt't become angry within 30 sec
		CreateTimer(g_fNonAngryTime, Timer_CheckAngryTimeout, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
}

Action Timer_CheckAngry(Handle timer, int UserId) {
	int client = GetClientOfUserId(UserId);

	if (IsTank(client) && g_bMapStarted) {
		// became angry?
		if (IsAngry(client) || g_bAngry[client]) {
			#if (DEBUG)
				PrintToChatAll("%N 发起了进攻.", client);
			#endif

			// check if he is not moving within X sec.
			CreateTimer(g_fStuckInterval, Timer_CheckPos, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			return Plugin_Stop;
		}
	}
	else
		return Plugin_Stop;
	
	return Plugin_Continue;
}

Action Timer_CheckPos(Handle timer, int UserId) {
	int tank = GetClientOfUserId(UserId);

	if (IsTank(tank) && g_bMapStarted) {
		static float pos[3];
		GetClientAbsOrigin(tank, pos);
		pos[2] += 20.0;
		L4D_WarpToValidPositionIfStuck(tank);
		pos[2] -= 20.0;
		static float distance;
		distance = GetVectorDistance(pos, g_fPos[tank], false);
		if (distance < g_fNonStuckRadius && !IsIncappedNearBy(pos) && !IsTankAttacking(tank)) {
			static bool bOnLadder;
			bOnLadder = IsOnLadder(tank);
			if (g_fMaxNonAngryDist != 0.0 && (GetDistanceToNearestClient(tank) > g_fMaxNonAngryDist || g_iStuckTimes[tank] > 2)) {
				// object selectable by ConVar => teleport only when tank looks like completely stuck
				TeleportToObject(tank);
			}
			else if (g_iStuckTimes[tank] > 1 || bOnLadder) {
				#if (DEBUG)
					int anim = GetEntProp(tank, Prop_Send, "m_nSequence");
					PrintToChatAll("%N stucked => micro-teleport, dist: %f, anim: %i", tank, distance, anim);
				#endif
			}
			g_iStuckTimes[tank]++;

			#if (DEBUG)
				PrintToChatAll("%N stuck ++: %i", tank, g_iStuckTimes[tank]);
			#endif
		}
		else {
			g_iStuckTimes[tank] = 0;
		}
		g_fPos[tank] = pos;
	}
	else
		return Plugin_Stop;
	
	return Plugin_Continue;
}

Action Timer_CheckAngryTimeout(Handle timer, int UserId) {
	int client = GetClientOfUserId(UserId);

	if (IsTank(client)) {
		if (GetEntProp(client, Prop_Send, "m_zombieState") == 0) {
			TeleportToObject(client);
		}
		// force angry flag to allow timer to begin check for position even if tank became angry but still not moving
		SetEntProp(client, Prop_Send, "m_zombieState", 1);
		g_bAngry[client] = true; // just in case

		#if (DEBUG)
			PrintToChatAll("%N 进攻超时.", client);
		#endif
	}

	return Plugin_Handled;
}

void TeleportToObject(int client) {
	if (!g_bEnabled || !g_bMapStarted)
		return;

	int target;
	float pos[3];

	switch (g_iDestObject) {
		case 0: {
			//当前坦克附近.
			target = client;
		}
		case 1: {
			//别的坦克附近,如果没有多余坦克则随机获取一个幸存者附近.
			target = GetNearestTank(client) > 0 ? GetNearestTank(client) : GetAnyRandomSurvivor();
		}
		case 2: {
			//随机幸存者附近.
			target = GetAnyRandomSurvivor();
		}
		case 3: {
			//最前方幸存者附近,如果获取不到方向时则随机获取一个幸存者附近.
			target = GetAheadSurvivor() > 0 ? GetAheadSurvivor() : GetAnyRandomSurvivor();
		}
	}

	if (target > 0) {
		if (FindValidLocations(target, pos)) {
			SetEntProp(client, Prop_Send, "m_bDucked", 1);
			SetEntityFlags(client, GetEntityFlags(client) | FL_DUCKING);
			TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR);
			PrintToChatAll("\x04[提示]\x05防卡启动\x03坦克%s\x05%s传送到%s%s\x03%s\x05附近.", 
			GetPlayerName(client), target != GetAheadSurvivor() ? "随机" : "", target == GetAheadSurvivor() ? "前方" : "", g_iDestObject >= 2 ? "玩家" : "", GetTrueName(target));
		}
	}
}