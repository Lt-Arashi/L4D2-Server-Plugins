#include <sourcemod>
#include <sdktools>

#define MODELS_BREAK_BALL			"models/props_unique/airport/atlas_break_ball.mdl"
#define L4D2_TEAM_ALL -1
#define MAXCES 33
#define VOTE_INTERVAL 10.0
#define HEIGHT_DIFF 100.0
#define MENU_DURATION 10
 
int g_iYesVotes, g_iNoVotes, g_iPlayersCount, FinalSphere,  TempSphere[MAXCES] = {-1,...};
bool VoteInProgress;
bool CanPlayerVote[MAXCES], RescueCome;
float CoolTime = -VOTE_INTERVAL;
Handle timer_remove[MAXCES];

public Plugin myinfo =
{
	name = "召集生还者",
	author = "仟姬物语",
	description = "投票召集所有生还者到发光球处",
	version = "QQ：892510007；可接插件定制",
	url = "https://space.bilibili.com/10684945"
};
 
 
public void OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart);
	HookEvent("finale_vehicle_ready", Event_FinaleVehicleReady);
	RegConsoleCmd("sm_gl", cmdGatherVote);
	AddCommandListener(on_cmd_vote, "vote");
	AddCommandListener(Listener_CallVote, "callvote");
}

public void OnMapStart()
{
	VoteInProgress = false;
	PrecacheModel(MODELS_BREAK_BALL);
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	RescueCome = false;
	CreateTimer(60.0, NoticeSurvivor, _, TIMER_FLAG_NO_MAPCHANGE);
}

void Event_FinaleVehicleReady(Event event, const char[] name, bool dontBroadcast) {
	RescueCome = true;
}

public Action NoticeSurvivor(Handle timer) 
{
	for(int i=1;i<=MaxClients;i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == 2)
			PrintToChat(i, "\x04<Tips>\x05发送\x01@gl\x05可投票召集生还者。");
	}
	return Plugin_Stop;
}

public Action cmdGatherVote(int client, int args)
{
	if(!PermissiveCondition(client))
		return Plugin_Handled;
	GatherMenu(client);
	return Plugin_Continue;
}

public void GatherMenu(int client) {
	Menu menu = new Menu(SelectDistance);
	menu.SetTitle("向前传送距离");
	for(int i;i<=0;i++)
	{
		char strnum[2][12];
		IntToString(i		,	strnum[0], sizeof(strnum[]));
		IntToString(i * 1 ,	strnum[1], sizeof(strnum[]));
		menu.AddItem(strnum[0], strnum[1]);
	}
	menu.ExitBackButton = false;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int SelectDistance(Menu menu, MenuAction action, int client, int itemNum) {
	switch (action) {
		case MenuAction_Select:
		{
			float pos[3], ang[3], fwd[3], final[3], dist = itemNum * 100.0;
			GetClientEyePosition(client, pos);
			GetClientEyeAngles(client, ang);
			GetAngleVectors(ang, fwd, NULL_VECTOR, NULL_VECTOR);
			NormalizeVector(fwd, fwd);
			ScaleVector(fwd, dist);
			AddVectors(pos, fwd, final);

			RemoveTempSphere(client);
			TempSphere[client] = CreateEntityByName("prop_dynamic");
			if (IsValidEntity(TempSphere[client])) {
				final[2] -= HEIGHT_DIFF;
				DispatchKeyValue(TempSphere[client], "model", MODELS_BREAK_BALL);
				DispatchKeyValueVector(TempSphere[client], "origin", final);
				DispatchSpawn(TempSphere[client]);
				SetEntityRenderMode(TempSphere[client], RENDER_GLOW);
				SetEntityRenderColor(TempSphere[client], 255, 255, 255, 0);
				SetEntProp(TempSphere[client], Prop_Send, "m_iGlowType", 3);
				SetEntProp(TempSphere[client], Prop_Send, "m_glowColorOverride", RGB_TO_INT(131, 111, 255));
				SetEntData(TempSphere[client], GetEntSendPropOffs(TempSphere[client], "m_CollisionGroup"), 1, 1, true);
				SetEntProp(TempSphere[client], Prop_Send, "m_hOwnerEntity", client);
			}

			PreviewMenu(client);
		}
		case MenuAction_End: delete menu;
	}
	return 0;
}

public void PreviewMenu(int client) {
	Menu menu = new Menu(ConfirmedWithoutRrror);
	menu.SetTitle("确认无误");
	menu.AddItem("0", "确定");
	menu.AddItem("1", "取消");
	menu.ExitBackButton = true;
	menu.Display(client, MENU_DURATION);
	delete timer_remove[client];
	timer_remove[client] = CreateTimer(float(MENU_DURATION), DeleteTempSphere, client);
}

public int ConfirmedWithoutRrror(Menu menu, MenuAction action, int client, int itemNum) {
	switch (action) {
		case MenuAction_Select:
		{
			switch(itemNum)
			{
				case 0:
				{
					if(!IsValidEntity(TempSphere[client]))
					{
						PrintToChat(client, "发光球已失效");
						return 0;
					}
					if(!PermissiveCondition(client))
						return 0;
					CoolTime = GetEngineTime();

					FinalSphere = TempSphere[client];
					TempSphere[client] = -1;
					SetEntProp(FinalSphere, Prop_Send, "m_glowColorOverride", RGB_TO_INT(255, 110, 180));
					CallNativeVote(client);
				}
				case 1:
				{
					RemoveTempSphere(client);
					GatherMenu(client);
				}
			}
		}
		case MenuAction_Cancel: {
			if (itemNum == MenuCancel_ExitBack)
				RemoveTempSphere(client);
		}
		case MenuAction_End: delete menu;
	}
	delete timer_remove[client];
	return 0;
}

public bool PermissiveCondition(int client)
{
	if(VoteInProgress)
	{
		PrintToChat(client, "\x04<Tips>\x05已有投票正在进行。");
		return false;
	}
	if(RescueCome)
	{
		PrintToChat(client, "\x04<Tips>\x05救援来临后无法发起投票。");
		return false;
	}
	if(!IsPlayerAlive(client))
	{
		PrintToChat(client, "\x04<Tips>\x05你都寄了你投个G8票。");
		return false;
	}
	if(GetEntProp(client, Prop_Send, "m_isIncapacitated"))
	{
		PrintToChat(client, "\x04<Tips>\x05被制服后无法发起投票。");
		return false;
	}
	if(GetControlInfe(client))
	{
		PrintToChat(client, "\x04<Tips>\x05被控制时无法发起投票。");
		return false;
	}
	float time_diff = GetEngineTime() - CoolTime;
	if(time_diff <= VOTE_INTERVAL)
	{
		PrintToChat(client, "\x04<Tips>\x05请等待\x01%d\x05秒后再尝试投票。", RoundToFloor(VOTE_INTERVAL - time_diff));
		return false;
	}
	return true;
}

public void CallNativeVote(int client)
{
	char name[MAX_NAME_LENGTH];
	GetClientName(client, name, MAX_NAME_LENGTH);
	BfWrite bf = UserMessageToBfWrite(StartMessageAll("VoteStart", USERMSG_RELIABLE));
	bf.WriteByte(L4D2_TEAM_ALL);
	bf.WriteByte(0);
	bf.WriteString("#L4D_TargetID_Player");
	bf.WriteString("传送所有人到光环处?");
	bf.WriteString(name);
	EndMessage();
 
	g_iYesVotes = 1;
	g_iNoVotes = 0;
	g_iPlayersCount = 1;
	VoteInProgress = true;
 
	for (int i = 1; i <= MaxClients; i++)
	{
		if (i != client && IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == 2)
		{
			CanPlayerVote[i] = true;
			g_iPlayersCount ++;
		}
	}
 
	UpdateVotes();
	CreateTimer(10.0, timerVoteCheck, client, TIMER_FLAG_NO_MAPCHANGE);
}
 
public Action timerVoteCheck(Handle timer, int client)
{
	if (VoteInProgress)
	{
		VoteInProgress = false;
		UpdateVotes();
	}
 
	return Plugin_Continue;
}
 
public void UpdateVotes()
{
	Event event = CreateEvent("vote_changed");
	event.SetInt("yesVotes", g_iYesVotes);
	event.SetInt("noVotes", g_iNoVotes);
	event.SetInt("potentialVotes", g_iPlayersCount);
	event.Fire();
 
	if (g_iYesVotes + g_iNoVotes == g_iPlayersCount || !VoteInProgress)
	{
		PrintToServer("投票完成！");
 
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i))
				CanPlayerVote[i] = false;
		}
 
		VoteInProgress = false;
 
		if (g_iYesVotes > g_iNoVotes)
		{
			BfWrite bf = UserMessageToBfWrite(StartMessageAll("VotePass"));
			bf.WriteByte(L4D2_TEAM_ALL);
			bf.WriteString("#L4D_TargetID_Player");
			bf.WriteString("已召集所有生还者");
			EndMessage();
			CreateTimer(3.0, ConveyEveryone, _, TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
			BfWrite bf = UserMessageToBfWrite(StartMessageAll("VoteFail"));
			bf.WriteByte(L4D2_TEAM_ALL);
			EndMessage();
			CreateTimer(3.0, DeleteFinalSphere, _, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}
 
public Action on_cmd_vote(int client, const char[] command, int args)
{
	if (VoteInProgress && CanPlayerVote[client])
	{
		CanPlayerVote[client] = false;

		char arg[8];
		GetCmdArg(1, arg, sizeof arg);
 
		PrintToServer("已从%i处获得投票%s", client, arg);
 
		if (strcmp(arg, "Yes", true) == 0)
			g_iYesVotes++;
		else if (strcmp(arg, "No", true) == 0)
			g_iNoVotes++;
 
		UpdateVotes();
	}
 
	return Plugin_Continue;
}

public Action Listener_CallVote(int client, const char[] command, int args)
{
	if(VoteInProgress)
	{
		PrintToChat(client, "\x04<Tips>\x03已有投票正在进行。");
		return Plugin_Handled;
	}
	VoteInProgress = true;
	CreateTimer(10.0, timerVoteExpire, _, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

public Action timerVoteExpire(Handle timer)
{
	VoteInProgress = false;
	return Plugin_Stop;
}

public Action ConveyEveryone(Handle timer)
{
	float pos[3];
	if(IsValidEntity(FinalSphere))
	{
		GetEntPropVector(FinalSphere, Prop_Data, "m_vecOrigin", pos);
		AcceptEntityInput(FinalSphere, "Kill");
	}
	if(RescueCome)
	{
		PrintToChatAll("\x04<Tips>\x05救援来临,投票作废。");
		return Plugin_Stop;
	}
	pos[2] += HEIGHT_DIFF;
	for(int i=1;i<=MaxClients;i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
			TeleportEntity(i, pos, NULL_VECTOR, NULL_VECTOR);
	}
	return Plugin_Stop;
}

public Action DeleteFinalSphere(Handle timer)
{
	if(IsValidEntity(FinalSphere))
		AcceptEntityInput(FinalSphere, "Kill");
	return Plugin_Stop;
}

public Action DeleteTempSphere(Handle timer, int client)
{
	timer_remove[client] = null;
	RemoveTempSphere(client);
	return Plugin_Stop;
}

public void RemoveTempSphere(int client) {
	if(IsValidEntity(TempSphere[client])) {
		AcceptEntityInput(TempSphere[client], "Kill");
		TempSphere[client] = -1;
	}
}

int GetControlInfe(int client)
{
    static const char control_state[][] = {
        "m_jockeyAttacker",
        "m_pummelAttacker",
        "m_carryAttacker",
        "m_pounceAttacker",
        "m_tongueOwner"
    };
    int special_infe;
    for(int i; i<sizeof(control_state); i++) {
        special_infe = GetEntPropEnt(client, Prop_Send, control_state[i]);
        if(special_infe > 0)
            return special_infe;
    }
    return 0;
}

stock int RGB_TO_INT(int red, int green, int blue) 
{
	return (blue * 65536) + (green * 256) + red;
}