#pragma semicolon 1
#pragma newdecls required

#include <sdktools_voice>

#define PLUGIN_VERSION "1.0"

bool g_bSpeaking[MAXPLAYERS + 1];

char g_sSpeaking[PLATFORM_MAX_PATH];

public Plugin myinfo =
{
	name = "l4d2_VoiceDisplayRestrictions",
	author = "X光",
	description = "语音显示谁在说话和限制自由麦",
	version = PLUGIN_VERSION,
	url = "QQ群59046067"
};

void OnQueryFinished(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue)
{
	if (result == ConVarQuery_Okay)
	{
		if (StringToInt(cvarValue) != 0)
		{
			if (GetClientListeningFlags(client) != VOICE_MUTED)
			{
				SetClientListeningFlags(client, VOICE_MUTED);
				PrintToChat(client, "\x04[HspAF]\x05腐竹发现你是\x04开放式麦克风\x05已经把你的嘴巴塞住了,设置\x03按键通话\x05可恢复正常聊天.");
			}
		}
		else if (GetClientListeningFlags(client) != VOICE_NORMAL)
		{
			SetClientListeningFlags(client, VOICE_NORMAL);
			PrintToChat(client, "\x04[HspAF]\x05腐竹发现你设置了\x04按键通话\x05已解除静音.");
		}
	}
}

public void OnClientSpeaking(int client)
{
	g_bSpeaking[client] = true;
}

public void OnMapStart()
{
	CreateTimer(1.0, SecurityZoneRecoveryTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

Action SecurityZoneRecoveryTimer(Handle timer)
{
	static int i;
	static bool show;
	g_sSpeaking[0] = '\0';
	show = false;

	for (i = 1; i <= MaxClients; i++)
	{
		if (g_bSpeaking[i])
		{
			g_bSpeaking[i] = false;
			if (!IsClientInGame(i))
				continue;

			QueryClientConVar(i, "voice_vox", OnQueryFinished);
			if (GetClientListeningFlags(i) == VOICE_MUTED)
				continue;

			if (Format(g_sSpeaking, sizeof g_sSpeaking, "%s\n%N", g_sSpeaking, i) >= (sizeof g_sSpeaking - 1))
				break;

			show = true;
		}
	}
	if (show)
		PrintCenterTextAll("%s 正在大声喧哗", g_sSpeaking);

	return Plugin_Continue;
}