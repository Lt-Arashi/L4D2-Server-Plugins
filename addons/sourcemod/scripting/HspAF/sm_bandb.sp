#include <sourcemod>

#define AUTHID_SIZE    21
#define MSG_SIZE       128
#define CACHE_DURATION 120

#define isPlayer(%1) (IsClientInGame(%1) && !IsFakeClient(%1))
#define isAdmin(%1) GetAdminFlag(GetUserAdmin(%1), Admin_Reservation)

Database g_db;
ArrayList g_bannedList;
bool g_debug = false;

public Plugin myinfo = {
	name = "[Any] Ban DB",
	author = "lakwsh",
	version = "1.2.1",
	url = "https://github.com/lakwsh/sm_bandb"
};

enum struct BanInfo {
	int SteamID;
	char Reason[MSG_SIZE];
	int Expiration;
}

public void OnPluginStart() {
	g_bannedList = new ArrayList(sizeof(BanInfo));

	RegAdminCmd("sm_debug", Cmd_Debug, ADMFLAG_KICK, "切换调试模式");
	RegAdminCmd("sm_bancheck", Cmd_BanCheck, ADMFLAG_KICK, "重新检查封禁状态");
}

public void OnPluginEnd() {
	delete g_bannedList;
}

public Action Cmd_Debug(int client, int args) {
	if (!g_debug) {
		g_debug = true;
		int count = 0;
		for (int i = 1; i <= MaxClients; i++) {
			if (isPlayer(i) && !isAdmin(i)) {
				KickClient(i, "服务器已进入调试模式,不便之处敬请谅解");
				count++;
			}
		}
		ServerCommand("sv_cookie 0");
		PrintToChatAll("\x04[提示]\x05服务器已进入调试模式.");
		ReplyToCommand(client, "[DebugMode] %d 个非管理员玩家被踢出服务器.", count);
		ReplyToCommand(client, "[DebugMode] 已进入调试模式.");
	} else {
		g_debug = false;
		PrintToChatAll("\x04[提示]\x05服务器已退出调试模式.");
		ReplyToCommand(client, "[DebugMode] 已退出调试模式.");
	}
	return Plugin_Handled;
}

public Action Cmd_BanCheck(int client, int args) {
	char reason[MSG_SIZE];
	for (int i = 1; i <= MaxClients; i++) {
		if (isPlayer(i) && IsPlayerBanned(i, reason, sizeof(reason))) {
			KickClient(i, "%s", reason);
			ReplyToCommand(client, "已踢出: %N", i);
		}
	}
	return Plugin_Handled;
}

public bool OnClientConnect(int client, char[] rejectmsg, int maxlen) {
	if (IsFakeClient(client)) return true;
	for (int i = 0; i < g_bannedList.Length; ++i) {
		BanInfo info;
		g_bannedList.GetArray(i, info);
		if (GetTime() > info.Expiration) {
			g_bannedList.Erase(i--);
			continue;
		}
		if (GetSteamAccountID(client, false) == info.SteamID) {
			strcopy(rejectmsg, maxlen, info.Reason);
			return false;
		}
	}
	return !IsPlayerBanned(client, rejectmsg, maxlen);
}

// BanClient的command参数不能为空
public Action OnBanClient(int client, int time, int flags, const char[] reason, const char[] kick_message, const char[] command, any source) {
	if (time) return Plugin_Continue;
	AddToCache(GetSteamAccountID(client, false), reason);

	char auth[AUTHID_SIZE];
	GetClientAuthId(client, AuthId_Steam2, auth, sizeof(auth));

	LoadDatabase();
	if (!g_db) {
		LogError("数据库连接失败,无法封禁玩家: %s", auth);
		return Plugin_Continue;
	}
	char error[MSG_SIZE];
	DBStatement query = SQL_PrepareQuery(g_db, "INSERT INTO `banned` (`auth`, `reason`) VALUES (?, ?)", error, sizeof(error));
	if (query) {
		query.BindString(0, auth, false);
		query.BindString(1, reason, false);
		SQL_LockDatabase(g_db);
		bool ret = SQL_Execute(query);
		SQL_UnlockDatabase(g_db);
		delete query;
		if (ret) return Plugin_Handled; // 阻止文件写入
		SQL_GetError(g_db, error, sizeof(error));
	}
	LogError("数据库状态异常,无法封禁玩家: auth[%s] error[%s]", auth, error);
	return Plugin_Continue;
}

void AddToCache(int id, const char[] reason) {
	BanInfo info;
	info.SteamID = id;
	strcopy(info.Reason, sizeof(info.Reason), reason);
	info.Expiration = GetTime() + CACHE_DURATION;
	g_bannedList.PushArray(info);
}

void LoadDatabase() {
	char error[MSG_SIZE];
	g_db = SQL_Connect("ban", true, error, sizeof(error));
/*
	KeyValues kv = new KeyValues("");
	kv.SetString("driver", "mysql");
	kv.SetString("host", "localhost");
	kv.SetString("database", "l4d2");
	kv.SetString("user", "l4d2");
	kv.SetString("pass", "123456");
	kv.SetString("port", "3306");
	g_db = SQL_ConnectCustom(kv, error, sizeof(error), true);
	delete kv;
*/
	if (!g_db || !g_db.SetCharset("utf8")) LogError("数据库状态异常: %s", error);
}

void OnPlayerBanned(Database db, DBResultSet results, const char[] error, any data) {
	int client = GetClientOfUserId(data);
	if (!client) return;
	if (!results) {
		KickClient(client, "数据库状态异常,禁止进入");
		LogError("封禁数据查询失败: %s", error);
		return;
	}

	if (!results.RowCount) return;
	char reason[MSG_SIZE];
	strcopy(reason, sizeof(reason), "你已被封禁");
	if (results.FetchRow()) results.FetchString(0, reason, sizeof(reason));
	AddToCache(GetSteamAccountID(client, false), reason);
	KickClient(client, "%s", reason);
}

bool IsPlayerBanned(int client, char[] msg, int maxlen) {
	char auth[AUTHID_SIZE];
	GetClientAuthId(client, AuthId_Steam2, auth, sizeof(auth), false);
	if (g_debug && !GetAdminFlag(FindAdminByIdentity(AUTHMETHOD_STEAM, auth), Admin_Reservation)) {
		strcopy(msg, maxlen, "服务器处于调试模式,仅限管理员进入");
		return true;
	}

	LoadDatabase();
	if (!g_db) {
		strcopy(msg, maxlen, "数据库状态异常,禁止进入");
		return true;
	}
	char sql[86+sizeof(auth)*2];
	g_db.Format(sql, sizeof(sql), "SELECT CONCAT_WS('\n', `time`, `reason`) FROM `banned` WHERE `auth` LIKE '%%%s' LIMIT 1", auth[9]);
	g_db.Query(OnPlayerBanned, sql, GetClientUserId(client), DBPrio_High);
	return false;
}