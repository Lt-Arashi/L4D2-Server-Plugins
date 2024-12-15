#pragma semicolon 1

#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#include <clientprefs>

#define CVAR_FLAGS		FCVAR_NOTIFY

#define GoodsMaxNum		46

bool DeBug = false;

bool ConfigEffect = false;

int Dried_Fish[32];
int Client_BuySum[32];
int Dried_Fish_Max = 600;
int BuyMode = 0;
bool IsFreeze[32] = {false};
bool KeysCold[32] = {false};
bool CanBuy = true;			//允许玩家购物
bool AdminRob = false;		//管理员零元购
bool GoodsIsFreeze[GoodsMaxNum] = {false};
int Admin_SayZT[32];

int FreezeClientList[32];
int FreezeClientType[32];
int FreezeClientNUM;

int GoodsPrice[GoodsMaxNum] =
{
	0,				//加满子弹
	50,				//燃烧子弹
	50,				//高爆子弹
	100,				//红外线
	150,				//燃烧子弹盒
	150,				//高爆子弹盒
	10,				//小手枪
	350,				//马格南
	100,				//UZI
	150,				//SMG
	150,				//MP5
	100,				//木喷
	150,				//铁喷
	300,			//M16
	350,			//SCAR
	350,			//AK47
	350,			//SG552
	600,			//M60
	350,			//一代连喷
	350,			//二代连喷
	350,			//15连狙
	300,			//30连狙
	500,			//Scout
	600,			//AWP
	600,			//榴弹发射器
	400,				//止痛药
	400,				//肾上腺素
	500,				//医疗包
	600,				//电击器
	250,				//燃烧瓶
	250,				//土质炸弹
	250,				//胆汁罐
	250,				//小刀
	250,				//消防斧
	250,				//砍刀
	250,				//武士刀
	250,				//撬棍
	250,				//草叉
	250,				//高尔夫球杆
	250,				//板球拍
	250,				//棒球棍
	250,				//平底锅
	250,				//电吉他
	250,				//警棍
	250,				//铲子
	250				//电锯
};

char GoodsName[GoodsMaxNum][24] =
{
	"ammo",								//加满子弹
	"INCENDIARY_AMMO",					//燃烧子弹
	"EXPLOSIVE_AMMO",					//高爆子弹
	"LASER_SIGHT",						//红外线
	"upgradepack_incendiary",			//燃烧子弹盒
	"upgradepack_explosive",			//高爆子弹盒
	"pistol",							//小手枪
	"pistol_magnum",					//马格南
	"smg",								//UZI
	"smg_silenced",						//SMG
	"weapon_smg_mp5",					//MP5
	"pumpshotgun",						//木喷
	"shotgun_chrome",					//铁喷
	"rifle",							//M16
	"rifle_desert",						//SCAR
	"rifle_ak47",						//AK47
	"weapon_rifle_sg552",				//SG552
	"rifle_m60",						//M60
	"autoshotgun",						//一代连喷
	"shotgun_spas",						//二代连喷
	"hunting_rifle",					//15连狙
	"sniper_military",					//30连狙
	"weapon_sniper_scout",				//Scout
	"weapon_sniper_awp",				//AWP
	"grenade_launcher",					//榴弹发射器
	"pain_pills",						//止痛药
	"adrenaline",						//肾上腺素
	"first_aid_kit",					//医疗包
	"defibrillator",					//电击器
	"molotov",							//燃烧瓶
	"pipe_bomb",						//土质炸弹
	"vomitjar",							//胆汁罐
	"knife",							//小刀
	"fireaxe",							//消防斧
	"machete",							//砍刀
	"katana",							//武士刀
	"crowbar",							//撬棍
	"pitchfork",						//草叉
	"golfclub",							//高尔夫球杆
	"cricket_bat",						//板球拍
	"baseball_bat",						//棒球棍
	"frying_pan",						//平底锅
	"electric_guitar",					//电吉他
	"tonfa",							//警棍
	"shovel",							//铲子
	"chainsaw"							//电锯
};

char GoodsText[GoodsMaxNum][12] =
{
	"加满子弹",
	"燃烧子弹",
	"高爆子弹",
	"红外线",
	"燃烧子弹盒",
	"高爆子弹盒",
	"小手枪",
	"马格南",
	"UZI",
	"SMG",
	"MP5",
	"木喷",
	"铁喷",
	"M16",
	"SCAR 三连发",
	"AK47",
	"SG552",
	"M60",
	"一代连喷",
	"二代连喷",
	"15连狙 木狙",
	"30连狙 警狙",
	"Scout 鸟狙",
	"AWP 大狙",
	"榴弹发射器",
	"止痛药",
	"肾上腺素",
	"医疗包",
	"电击器",
	"燃烧瓶",
	"土质炸弹",
	"胆汁罐",
	"小刀",
	"消防斧",
	"砍刀",
	"武士刀",
	"撬棍",
	"草叉",
	"高尔夫球杆",
	"板球拍",
	"棒球棍",
	"平底锅",
	"电吉他",
	"警棍",
	"铲子",
	"电锯"
};

char GoodsViewText[GoodsMaxNum][20] =
{
	"加满子弹   ",
	"燃烧子弹   ",
	"高爆子弹   ",
	"红外线      ",
	"燃烧子弹盒",
	"高爆子弹盒",
	"小手枪",
	"马格南",
	"UZI    ",
	"SMG   ",
	"MP5   ",
	"木喷   ",
	"铁喷   ",
	"M16   ",
	"SCAR  ",
	"AK47  ",
	"SG552",
	"M60   ",
	"一代连喷",
	"二代连喷",
	"15连狙 木狙",
	"30连狙 警狙",
	"Scout 鸟狙  ",
	"AWP 大狙   ",
	"榴弹发射器",
	"止痛药   ",
	"肾上腺素",
	"医疗包   ",
	"电击器   ",
	"燃烧瓶   ",
	"土质炸弹",
	"胆汁罐   ",
	"小刀   ",
	"消防斧",
	"砍刀   ",
	"武士刀",
	"撬棍   ",
	"草叉   ",
	"高尔夫球杆",
	"板球拍      ",
	"棒球棍      ",
	"平底锅      ",
	"电吉他      ",
	"警棍         ",
	"铲子         ",
	"电锯         "
};

ConVar GBuyMode;
ConVar GCommonKillNUM;
ConVar GCommonKillGive;
ConVar GSpecialKillGive;
ConVar GTankKillGive;
ConVar GWitchKillGive;
ConVar GKillGive_Max;
ConVar GGoodsPrice[GoodsMaxNum];

char Dried_Fish_Name[12]	= "小鱼干";
char Reward_Text[36]		= "管理员奖励了全员";					 //全员奖励提示
char Confiscate_Text[36]	= "管理员没收了全员";					 //全员扣钱提示

bool AllGoodsIsFreeze[6] = {false};
bool AllSuperiorWeaponsIsFreeze[3] = {false};
bool AllSharpMeleeIsFreeze = false;
bool AllBluntMeleeIsFreeze = false;

bool BTxtConfigEffect = false;
bool BTxtConfig[8] =
{
	true,		// 0 - 购物播报
	true,		// 1 - 击杀获得小鱼干提示
	true,		// 2 - 击杀获得小鱼干达到上限时提示
	true,		// 3 - 禁用混合模式
	true,		// 4 - 冻结玩家提示
	true,		// 5 - 冻结商品提示
	true,		// 6 - 记录玩家购买商品
	true		// 7 - 双按键开启购物菜单
};

char TxtConfig[8][9] =
{
	"BuyPrint",
	"KIGPrint",
	"KGFPrint",
	"IsNotMix",
	"FreGamer",
	"FreGoods",
	"BYRecord",
	"UTwoKeys"
};

char GoodsMenuText[7][16] =
{
	"子弹",
	"小枪",
	"大枪",
	"医疗物品",
	"投掷物",
	"近战武器",
	"购物后台"
};

char SuperiorWeaponsMenuText[4][16] =
{
	"步枪",
	"连喷",
	"狙击枪",
	"榴弹发射器"
};

char CantShowBuyMenuText[4][64] =
{
	"只允许生还者购物.",
	"死者不允许购物捏.",
	"您的账户已被管理员冻结, 请联系管理员解冻.",
	"购物已被管理员禁用."
};

char CantBuyGoodsText[6][64] =
{
	"你有再多的",					//商品被冻结
	"也买不到哦~",
	"你有再多的",					//商品购物次数达到上限
	"现在也买不了了.",
	"你需要更多的",					//小鱼干不够
	"你看看你的钱包, 空空如也!"		//没有小鱼干
};

char KillGiveText[3][64] =
{
	"并从其身上掠夺了",				//掠夺小鱼干
	"你装",							//掠夺小鱼干达到上限
	"的袋子已经满了."
};

char ZRecordText[128];
char BuyConfig_Text[22][8] =
{
	"BuyName",
	"RewText",
	"ConText",
	"NotSurT",
	"IsDeadT",
	"FreezeT",
	"CantBuy",
	"FreGdst",
	"FreGdrd",
	"NumLtst",
	"NumLtrd",
	"NEnough",
	"ZeroBuy",
	"KIGiveT",
	"GFullst",
	"GFullrd",
	"SixAmmo",
	"Primawp",
	"Superwp",
	"Medical",
	"Missile",
	"MeleePr"
};

int CommonKill[32];
int CommonKillNUM	= 5;
int CommonKillGive	= 10;
int SpecialKillGive	= 10;
int TankKillGive	= 25;
int WitchKillGive	= 20;
int KillGive_Max	= 250;

Handle FAnneMode_DriedFish;
Handle KGiveMode_DriedFish;
Handle ClientBuy_RecordSum;

char Infected_Name[6][8] =
{
	"Smoker",
	"Boomer",
	"Hunter",
	"Spitter",
	"Jockey",
	"Charger"
};

char FilePath[PLATFORM_MAX_PATH], FileLine[PLATFORM_MAX_PATH];

bool bLate;
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) 
{
	EngineVersion test = GetEngineVersion();
	
	if( test != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}

	bLate = late;
	return APLRes_Success; 
}

public void OnPluginStart()
{
	FAnneMode_DriedFish		= RegClientCookie("l4d2_dfb_fam",	"dried_fish_buy.smx",	CookieAccess_Protected);
	KGiveMode_DriedFish		= RegClientCookie("l4d2_dfb_kgm",	"dried_fish_buy.smx",	CookieAccess_Protected);
	ClientBuy_RecordSum		= RegClientCookie("l4d2_dfb_cbr",	"dried_fish_buy.smx",	CookieAccess_Protected);

	IsGetBuyConfig();//获取文件里的内容.

	GBuyMode			= CreateConVar("l4d2_dried_fish_buy_buy_mode",				"0",	"开局购物模式 (0 = 开局定数, 1 = 击杀奖励).", CVAR_FLAGS, true, 0.0, true, 1.0);
	GCommonKillNUM		= CreateConVar("l4d2_dried_fish_buy_kill_a_common_number",	"5",	"击杀奖励模式下, 给予货币需要击杀的小丧尸数量.", CVAR_FLAGS, true, 1.0);
	GCommonKillGive		= CreateConVar("l4d2_dried_fish_buy_kill_b_common_give",	"10",	"击杀奖励模式下, 击杀一定数量的小丧尸获得的货币数量.", CVAR_FLAGS, true, 1.0);
	GSpecialKillGive	= CreateConVar("l4d2_dried_fish_buy_kill_c_special_give",	"20",	"击杀奖励模式下, 击杀一只特感(不含Tank)给予的货币数量.", CVAR_FLAGS, true, 1.0);
	GTankKillGive		= CreateConVar("l4d2_dried_fish_buy_kill_d_tank_give",		"25",	"击杀奖励模式下, 击杀一只Tank给予全员的货币数量.", CVAR_FLAGS, true, 1.0);
	GWitchKillGive		= CreateConVar("l4d2_dried_fish_buy_kill_e_witch_give",		"20",	"击杀奖励模式下, 击杀一只Witch给予的货币数量.", CVAR_FLAGS, true, 1.0);
	GKillGive_Max		= CreateConVar("l4d2_dried_fish_buy_kill_f_give_max",		"250",	"击杀奖励模式下, 可获得的货币数量的上限.", CVAR_FLAGS, true, 1.0);
	char convar_str1[64], convar_str2[5], convar_str3[64];
	for (int i = 0; i < GoodsMaxNum ; i++)
	{
		int a = (i + 1) / 10, b = (i + 1) % 10;
		char temp_str1[2], temp_str2[2];
		IntToString(a, temp_str1, sizeof(temp_str1));
		IntToString(b, temp_str2, sizeof(temp_str2));
		Format(convar_str1, sizeof(convar_str1), "l4d2_dried_fish_buy_%s_%s_%s_price", temp_str1, temp_str2, GoodsName[i]);
		IntToString(GoodsPrice[i], convar_str2, sizeof(convar_str2));
		Format(convar_str3, sizeof(convar_str3), "%s的价格.", GoodsText[i]);
		GGoodsPrice[i] = CreateConVar(convar_str1, convar_str2, convar_str3, CVAR_FLAGS, true, 0.0);
	}

	GBuyMode.AddChangeHook(ConVarChanged);
	GCommonKillNUM.AddChangeHook(ConVarChanged);
	GCommonKillGive.AddChangeHook(ConVarChanged);
	GSpecialKillGive.AddChangeHook(ConVarChanged);
	GTankKillGive.AddChangeHook(ConVarChanged);
	GWitchKillGive.AddChangeHook(ConVarChanged);
	GKillGive_Max.AddChangeHook(ConVarChanged);
	for (int i = 0; i < GoodsMaxNum ; i++)
		GGoodsPrice[i].AddChangeHook(ConVarChanged);

	RegConsoleCmd("say",			Command_Say);
	RegConsoleCmd("say_team",		Command_SayTeam);

	RegConsoleCmd("sm_buy",			Command_Buy,					"玩家购物菜单.");
	RegConsoleCmd("sm_shop",			Command_Buy,					"玩家购物菜单.");
	RegConsoleCmd("sm_buyreload",	Command_Buy_Config_Reload,		"重新加载购物Config");
	if (DeBug)
		RegConsoleCmd("sm_buyview",		Command_DeBug_ViewBuyConfig,	"");

	HookEvent("round_start",		Event_RoundStart,				EventHookMode_PostNoCopy);			//回合开始.
	HookEvent("player_death",		Event_PlayerDeath);													//玩家死亡.
	HookEvent("witch_killed",		Event_WitchKilled);													//击杀Witch.

	//AutoExecConfig(true, "l4d2_dried_fish_buy");//生成指定文件名的CFG.

	if (bLate)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
				OnClientCookiesCached(i);
		}
	}
}





// ====================================================================================================
// ConVarChanged
// ====================================================================================================

public void ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

public void GetCvars()
{
	BuyMode			= GBuyMode.IntValue;
	CommonKillNUM	= GCommonKillNUM.IntValue;
	CommonKillGive	= GCommonKillGive.IntValue;
	SpecialKillGive	= GSpecialKillGive.IntValue;
	TankKillGive	= GTankKillGive.IntValue;
	WitchKillGive	= GWitchKillGive.IntValue;
	KillGive_Max	= GKillGive_Max.IntValue;
	for (int i = 0; i < GoodsMaxNum ; i++)
		GoodsPrice[i] = GGoodsPrice[i].IntValue;

	BuyConfigEffect();
}

public void OnConfigsExecuted()
{
	IsGetBuyConfig();
	BuyConfigEffect();
}





// ====================================================================================================
// TxT Config Get
// ====================================================================================================

//获取文件里的购物配置
public void IsGetBuyConfig()
{
	BuildPath(Path_SM, FilePath, sizeof(FilePath), "configs/l4d2_dried_fish_buy_text.txt");
	if (FileExists(FilePath))
		IsSetBuyText();

	BuildPath(Path_SM, FilePath, sizeof(FilePath), "configs/l4d2_dried_fish_buy_configs.txt");
	if (FileExists(FilePath))
		IsSetBuyConfig();
}

//获取购物文本配置
public void IsSetBuyText()
{
	File file = OpenFile(FilePath, "rb");

	if (file)
	{
		while (!file.EndOfFile())
		{
			file.ReadLine(FileLine, sizeof(FileLine));
			TrimString(FileLine);

			if (strlen(FileLine) > 1 && FileLine[0] != '/')
			{
				char Target_Str[8];
				strcopy(Target_Str, sizeof(Target_Str), FileLine);
				for (int i = 0; i < 22 ; i++)
				{
					if (strcmp(Target_Str, BuyConfig_Text[i]) == 0)
					{
						int loc_start = -1, loc_end = -1;
						for (int j = 8; j < strlen(FileLine) ; j++)
						{
							if (FileLine[j] == '\"')
							{
								if (loc_start == -1)
									loc_start = j + 1;
								else
								{
									loc_end = j;
									break;
								}
							}
						}

						if (loc_start > 0 && loc_end > 0 && loc_start < loc_end)
						{
							char Get_Str[64];
							for (int j = loc_start ; j < loc_end ; j++)
								Get_Str[j - loc_start] = FileLine[j];

							GetConfig_Text(Get_Str, i);
						}
						break;
					}
				}
			}
		}
	}
	delete file;
}

//获取购物配置
public void IsSetBuyConfig()
{
	File file = OpenFile(FilePath, "rb");

	if (file)
	{
		while (!file.EndOfFile())
		{
			file.ReadLine(FileLine, sizeof(FileLine));
			TrimString(FileLine);

			if (strlen(FileLine) > 1 && FileLine[0] != '/')
			{
				char Target_Str[9];
				strcopy(Target_Str, sizeof(Target_Str), FileLine);
				for (int i = 0; i < 8 ; i++)
				{
					if (strcmp(Target_Str, TxtConfig[i]) == 0)
					{
						for (int j = 9 ; j < strlen(FileLine) ; j++)
						{
							if (FileLine[j] == '0')
							{
								BTxtConfig[i] = false;
								break;
							}
							else if (FileLine[j] == '1')
							{
								BTxtConfig[i] = true;
								break;
							}
							else if (FileLine[j] >= '2' && FileLine[j] <= '9')
								break;
						}
						if (DeBug)
							PrintToChatAll("\x05[INFO] \x04BTxtConfig [%d] is loading. (set \x03%d\x04)", i, BTxtConfig[i]?1:0);
						break;
					}
				}
			}
		}
	}

	if (!BTxtConfigEffect)
	{
		if (!BTxtConfig[3])
		{
			for (int i = 1; i <= MaxClients ; i++)
				Dried_Fish[i] = Dried_Fish_Max;
		}

		if (BTxtConfig[6])
			StartRecord();
	}

	BTxtConfigEffect = true;
	delete file;
}

public void GetConfig_Text(char[] Set_Str, int CI)
{
	if (CI == 0)
		Format(Dried_Fish_Name, sizeof(Dried_Fish_Name), "%s", Set_Str);
	else if (CI == 1)
		Format(Reward_Text, sizeof(Reward_Text), "%s", Set_Str);
	else if (CI == 2)
		Format(Confiscate_Text, sizeof(Confiscate_Text), "%s", Set_Str);
	else if (CI <= 6)
		Format(CantShowBuyMenuText[CI - 3], sizeof(CantShowBuyMenuText[]), "%s", Set_Str);
	else if (CI <= 12)
		Format(CantBuyGoodsText[CI - 7], sizeof(CantBuyGoodsText[]), "%s", Set_Str);
	else if (CI <= 15)
		Format(KillGiveText[CI - 13], sizeof(KillGiveText[]), "%s", Set_Str);
	else if (CI <= 21)
		Format(GoodsMenuText[CI - 16], sizeof(GoodsMenuText[]), "%s", Set_Str);
	
	if (DeBug)
	{
		PrintToChatAll("\x05[INFO] \x04Buy Config [%d] is loading.", CI);
		PrintToChatAll("\x05(str \x03: \x04%s\x05)", Set_Str);
	}
}

public void BuyConfigEffect()
{
	if (!ConfigEffect)
	{
		if (BuyMode == 0)
		{
			for (int i = 1; i <= MaxClients ; i++)
				Dried_Fish[i] = Dried_Fish_Max;
		}
		else if (BuyMode == 1)
		{
			for (int i = 1; i <= MaxClients ; i++)
			{
				if (IsClientInGame(i) && !IsFakeClient(i))
					Save_Player_DriedFish(i, false, BuyMode);
			}
		}
		ConfigEffect = true;
	}
}





// ====================================================================================================
// Cookie
// ====================================================================================================

//加载玩家Cookie
public void OnClientCookiesCached(int client)
{
	if (!IsFakeClient(client))
	{
		if (ConfigEffect && BuyMode == 1)
			Save_Player_DriedFish(client, false, BuyMode);

		char TempStr[11];
		GetClientCookie(client, ClientBuy_RecordSum, TempStr, sizeof(TempStr));
		Client_BuySum[client] = StringToInt(TempStr);
	}
}

//玩家连接
public void OnClientConnected(int client)
{
	if (!IsFakeClient(client))
		IsFreeze[client] = false;
}

//玩家离开.
public void OnClientDisconnect(int client)
{
	if (!IsFakeClient(client))
	{
		IsFreeze[client] = false;
		if (BuyMode == 1)
			Save_Player_DriedFish(client, true, BuyMode);

		char TempStr[11];
		IntToString(Client_BuySum[client], TempStr, sizeof(TempStr));
		SetClientCookie(client, ClientBuy_RecordSum, TempStr);
		Client_BuySum[client] = 0;
	}
}






//地图开始
public void OnMapStart()
{
	if (BTxtConfigEffect && BTxtConfig[6])
		StartRecord();
}





// ====================================================================================================
// Hook Event
// ====================================================================================================

//回合开始.
public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if ((ConfigEffect && BuyMode == 0) || !BTxtConfig[3])
	{
		for (int i = 1; i <= MaxClients ; i++)
			Dried_Fish[i] = Dried_Fish_Max;
	}

	for (int i = 1; i <= MaxClients ; i++)
		KeysCold[i] = false;
}

//玩家死亡.
public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));

	if (BuyMode == 1 || !BTxtConfig[3])
	{
		if (IsSurvivor(attacker) && !IsFakeClient(attacker) && IsPlayerAlive(attacker))
		{
			if (IsInfected(client))
			{
				int ZombieClass = GetEntProp(client, Prop_Send, "m_zombieClass");
				if (ZombieClass >= 1 && ZombieClass <= 6)
				{
					Dried_Fish[attacker] += SpecialKillGive;

					if (BTxtConfig[1])
					{
						PrintToChat(attacker, "\x04[提示] \x05你击杀了一只 \x04%s\x05, %s \x04%d \x05%s.[ \x04%d \x05/ \x04%d \x05]",
							Infected_Name[ZombieClass - 1], KillGiveText[0], SpecialKillGive, Dried_Fish_Name,
							Dried_Fish[attacker] > KillGive_Max? KillGive_Max : Dried_Fish[attacker], KillGive_Max);
					}

					if (Dried_Fish[attacker] >= KillGive_Max)
					{
						Dried_Fish[attacker] = KillGive_Max;

						if (BTxtConfig[2])
						{
							PrintToChat(attacker, "\x04[提示] \x05%s%s%s[ \x04%d \x05]",
								KillGiveText[1], Dried_Fish_Name, KillGiveText[2], Dried_Fish[attacker]);
						}
					}
				}
				else if (ZombieClass == 8)
				{
					if (BTxtConfig[1])
					{
						PrintToChatAll("\x04[提示] \x05生还者们击杀了一只 \x04Tank\x05, %s \x04%d \x05%s.",
							KillGiveText[0], TankKillGive, Dried_Fish_Name);
					}

					for (int i = 1; i <= MaxClients ; i++)
					{
						if (IsClientInGame(i) && GetClientTeam(i) == 2 && !IsFakeClient(i) && IsPlayerAlive(i))
						{
							Dried_Fish[i] += TankKillGive;
							if (Dried_Fish[i] >= KillGive_Max)
							{
								Dried_Fish[i] = KillGive_Max;

								if (BTxtConfig[2])
								{
									PrintToChat(i, "\x04[提示] \x05%s%s%s[ \x04%d \x05]",
										KillGiveText[1], Dried_Fish_Name, KillGiveText[2], Dried_Fish[i]);
								}
							}
						}
					}
				}
			}
			else
			{
				char classname[32];
				int entity = GetEventInt(event, "entityid");
				GetEdictClassname(entity, classname, sizeof(classname));
				if (IsValidEdict(entity) && strcmp(classname, "infected") == 0)
					CommonKill[attacker] ++;

				if (CommonKill[attacker] >= CommonKillNUM)
				{
					CommonKill[attacker] -= CommonKillNUM;
					Dried_Fish[attacker] += CommonKillGive;

					if (BTxtConfig[1])
					{
						PrintToChat(attacker, "\x04[提示] \x05你击杀了%d只小丧尸, %s \x04%d \x05%s.[ \x04%d \x05/ \x04%d \x05]",
							CommonKillNUM, KillGiveText[0], CommonKillGive, Dried_Fish_Name,
							Dried_Fish[attacker] > KillGive_Max? KillGive_Max : Dried_Fish[attacker], KillGive_Max);
					}

					if (Dried_Fish[attacker] >= KillGive_Max)
					{
						Dried_Fish[attacker] = KillGive_Max;

						if (BTxtConfig[2])
						{
							PrintToChat(attacker, "\x04[提示] \x05%s%s%s[ \x04%d \x05]",
								KillGiveText[1], Dried_Fish_Name, KillGiveText[2], Dried_Fish[attacker]);
						}
					}
				}
			}
		}
	}
}

//击杀Witch.
public void Event_WitchKilled(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (BuyMode == 1 || !BTxtConfig[3])
	{
		if (IsSurvivor(client) && !IsFakeClient(client) && IsPlayerAlive(client))
		{
			Dried_Fish[client] += WitchKillGive;

			if (BTxtConfig[1])
			{
				PrintToChat(client, "\x04[提示] \x05你击杀了一只 \x04witch\x05, %s \x04%d \x05%s.[ \x04%d \x05/ \x04%d \x05]",
					KillGiveText[0], WitchKillGive, Dried_Fish_Name,
					Dried_Fish[client] > KillGive_Max? KillGive_Max : Dried_Fish[client], KillGive_Max);
			}

			if (Dried_Fish[client] >= KillGive_Max)
			{
				Dried_Fish[client] = KillGive_Max;

				if (BTxtConfig[2])
				{
					PrintToChat(client, "\x04[提示] \x05%s%s%s[ \x04%d \x05]",
						KillGiveText[1], Dried_Fish_Name, KillGiveText[2], Dried_Fish[client]);
				}
			}
		}
	}
}





// ====================================================================================================
// Say
// ====================================================================================================

public Action Command_Say(int client, int args)
{
	if (!IsValidAdminClient(client) || Admin_SayZT[client] == 0)
		return Plugin_Continue;

	char arg[12];
	GetCmdArg(1, arg, sizeof(arg));
	CheckSay(client, arg);
	if (Admin_SayZT[client] == 4 || IsPureDigital(arg))
		return Plugin_Handled;

	return Plugin_Continue;
}

public Action Command_SayTeam(int client, int args)
{
	if (!IsValidAdminClient(client) || Admin_SayZT[client] == 0)
		return Plugin_Continue;

	char arg[12];
	GetCmdArg(1, arg, sizeof(arg));
	CheckSay(client, arg);
	if (Admin_SayZT[client] == 4 || IsPureDigital(arg))
		return Plugin_Handled;

	return Plugin_Continue;
}

//检查Say
public void CheckSay(int client, char[] str)
{
	if (!IsValidAdminClient(client) || Admin_SayZT[client] == 0)
		return;

	if (Admin_SayZT[client] <= 3)
	{
		if (IsPureDigital(str))
		{
			int number = StringToInt(str);
			if (number < 0)
				number = 0;
			
			if (Admin_SayZT[client] == 1)
			{
				Dried_Fish_Max = number;
				PrintToChatAll("\x04[提示] \x05管理员已经开局%s数量设置为: \x03%d", Dried_Fish_Name, number);
			}
			else
			{
				for (int i = 1; i <= MaxClients ; i++)
				{
					if (IsClientInGame(i) && !IsFakeClient(i))
					{
						if (Admin_SayZT[client] == 2)
						{
							Dried_Fish[i] += number;
							PrintToChatAll("\x04[提示] \x05%s %d %s.", Reward_Text, number, Dried_Fish_Name);
						}
						else
						{
							Dried_Fish[i] -= number;
							if (Dried_Fish[i] < 0)
								Dried_Fish[i] = 0;
							
							PrintToChatAll("\x04[提示] \x05%s %d %s.", Confiscate_Text, number, Dried_Fish_Name);
						}
					}
				}
			}
		}
		else
		{
			PrintToChatAll("\x04[ERROR] \x03请输入非负纯数字!");
			return;
		}
	}
	else if (Admin_SayZT[client] == 4)
	{
		if (strlen(str) > 0)
			Format(Dried_Fish_Name, sizeof(Dried_Fish_Name), "%s", str);

		PrintToChatAll("\x04[提示] \x05管理员已将货币名称更改为: \x03%s", Dried_Fish_Name);
	}
	Admin_SayZT[client] = 0;
}





// ====================================================================================================
// OnPlayerRunCmd
// ====================================================================================================

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if (!BTxtConfig[7])
		return Plugin_Continue;

	if (client <= 0 || client > MaxClients || !IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Continue;
	
	if ((buttons & IN_RELOAD) && (buttons & IN_USE))
	{
		if (!KeysCold[client])
		{
			KeysCold[client] = true;
			CreateTimer(0.3, ReCold_KeysCold, client);
			CheckClientCanBuy(client);
		}
	}
	return Plugin_Continue;
}





// ====================================================================================================
// Timer Action
// ====================================================================================================

public Action ReCold_KeysCold(Handle timer, int client)
{
	KeysCold[client] = false;
	return Plugin_Continue;
}





// ====================================================================================================
// Buy Command
// ====================================================================================================

//重新加载购物Config
public Action Command_Buy_Config_Reload(int client, int args)
{
	if (IsValidAdminClient(client))
		IsGetBuyConfig();
	
	return Plugin_Handled;
}

//Debug
public Action Command_DeBug_ViewBuyConfig(int client, int args)
{
	if (client <= 0 || client > MaxClients || !IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Handled;

	if (args == 1)
	{
		int arg = GetCmdArgInt(1);
		if (arg == 0)
			IsGetBuyConfig();
		else if (arg == 1)
		{
			for (int i = 1; i <= MaxClients ; i++)
			{
				if (IsClientInGame(i) && !IsFakeClient(i))
					PrintToChatAll("\x05%N \x04: \x05%s", IsFreeze[i]?"Freeze":"Normal");
			}
		}
		else if (arg == 2)
		{
			for (int i = 0; i < GoodsMaxNum ; i++)
				PrintToChatAll("\x05%s \x04: \x05%s", GoodsText[i], GoodsIsFreeze[i]?"Freeze":"Normal");
		}
	}
	return Plugin_Handled;
}

//玩家购物
public Action Command_Buy(int client, int args)
{
	if (client <= 0 || client > MaxClients || !IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Handled;

	CheckClientCanBuy(client);
	return Plugin_Handled;
}

public void CheckClientCanBuy(int client)
{
	if (bCheckClientAccess(client))
	{
		Show_Buy_MainMenu(client);
		return;
	}

	if (GetClientTeam(client) != 2)
	{
		PrintToChat(client, "\x04[ERROR] \x03%s", CantShowBuyMenuText[0]);
		return;
	}

	if (!IsPlayerAlive(client))
	{
		PrintToChat(client, "\x04[ERROR] \x03%s", CantShowBuyMenuText[1]);
		return;
	}

	if (IsFreeze[client])
	{
		PrintToChat(client, "\x04[ERROR] \x03%s", CantShowBuyMenuText[2]);
		return;
	}
	
	if (!CanBuy)
	{
		PrintToChat(client, "\x04[ERROR] \x03%s", CantShowBuyMenuText[3]);
		return;
	}

	Show_Buy_MainMenu(client);
}





// ====================================================================================================
// Show Menu
// ====================================================================================================

//展开购物主菜单
public void Show_Buy_MainMenu(int client)
{
	Handle menu = CreatePanel();
	char text[48];
	Format(text, sizeof(text), "购物  当前%s: %d", Dried_Fish_Name, Dried_Fish[client]);
	SetPanelTitle(menu, text);
	for (int i = 0; i < 6 ; i++)
		DrawPanelItem(menu, GoodsMenuText[i]);
	if (bCheckClientAccess(client))
		DrawPanelItem(menu, GoodsMenuText[6]);
	DrawPanelText(menu, " \n");
	DrawPanelItem(menu, "关闭");
	SendPanelToClient(menu, client, Buy_MainMenu, 25);
}

//展开子弹菜单
public void Show_Buy_AmmoMenu(int client)
{
	if (!IsValidClient(client))
		return;

	Handle menu = CreatePanel();
	char text[48];
	Format(text, sizeof(text), "%s  当前%s: %d", GoodsMenuText[0], Dried_Fish_Name, Dried_Fish[client]);
	SetPanelTitle(menu, text);
	for (int i = 0; i < 6 ; i++)
	{
		Format(text, sizeof(text), "%s    %d", GoodsViewText[i], GoodsPrice[i]);
		DrawPanelItem(menu, text);
	}
	DrawPanelText(menu, " \n");
	DrawPanelItem(menu, "返回");
	DrawPanelItem(menu, "关闭");
	SendPanelToClient(menu, client, Buy_AmmoMenu, 25);
}

//展开小枪菜单
public void Show_Buy_PrimaryWeaponsMenu(int client)
{
	if (!IsValidClient(client))
		return;

	Handle menu = CreatePanel();
	char text[48];
	Format(text, sizeof(text), "%s  当前%s: %d", GoodsMenuText[1], Dried_Fish_Name, Dried_Fish[client]);
	SetPanelTitle(menu, text);
	for (int i = 6; i < 13 ; i++)
	{
		Format(text, sizeof(text), "%s    %d", GoodsViewText[i], GoodsPrice[i]);
		DrawPanelItem(menu, text);
	}
	DrawPanelText(menu, " \n");
	DrawPanelItem(menu, "返回");
	DrawPanelItem(menu, "关闭");
	SendPanelToClient(menu, client, Buy_PrimaryWeaponsMenu, 25);
}

//展开大枪菜单
public void Show_Buy_SuperiorWeaponsMenu(int client)
{
	if (!IsValidClient(client))
		return;

	Handle menu = CreatePanel();
	char text[48];
	Format(text, sizeof(text), "%s  当前%s: %d", GoodsMenuText[2], Dried_Fish_Name, Dried_Fish[client]);
	SetPanelTitle(menu, text);
	for (int i = 0; i < 4 ; i++)
	{
		Format(text, sizeof(text), "%s", SuperiorWeaponsMenuText[i]);
		DrawPanelItem(menu, text);
	}
	DrawPanelText(menu, " \n");
	DrawPanelItem(menu, "返回");
	DrawPanelItem(menu, "关闭");
	SendPanelToClient(menu, client, Buy_SuperiorWeaponsMenu, 25);
}

//展开步枪菜单
public void Show_Buy_RifleMenu(int client)
{
	if (!IsValidClient(client))
		return;

	Handle menu = CreatePanel();
	char text[48];
	Format(text, sizeof(text), "%s  当前%s: %d", SuperiorWeaponsMenuText[0], Dried_Fish_Name, Dried_Fish[client]);
	SetPanelTitle(menu, text);
	for (int i = 13; i < 18 ; i++)
	{
		Format(text, sizeof(text), "%s    %d", GoodsViewText[i], GoodsPrice[i]);
		DrawPanelItem(menu, text);
	}
	DrawPanelText(menu, " \n");
	DrawPanelItem(menu, "返回");
	DrawPanelItem(menu, "关闭");
	SendPanelToClient(menu, client, Buy_RifleMenu, 25);
}

//展开连喷菜单
public void Show_Buy_AutoShotGunMenu(int client)
{
	if (!IsValidClient(client))
		return;

	Handle menu = CreatePanel();
	char text[48];
	Format(text, sizeof(text), "%s  当前%s: %d", SuperiorWeaponsMenuText[1], Dried_Fish_Name, Dried_Fish[client]);
	SetPanelTitle(menu, text);
	for (int i = 18; i < 20 ; i++)
	{
		Format(text, sizeof(text), "%s    %d", GoodsViewText[i], GoodsPrice[i]);
		DrawPanelItem(menu, text);
	}
	DrawPanelText(menu, " \n");
	DrawPanelItem(menu, "返回");
	DrawPanelItem(menu, "关闭");
	SendPanelToClient(menu, client, Buy_AutoShotGunMenu, 25);
}

//展开狙击枪菜单
public void Show_Buy_SniperMenu(int client)
{
	if (!IsValidClient(client))
		return;

	Handle menu = CreatePanel();
	char text[48];
	Format(text, sizeof(text), "%s  当前%s: %d", SuperiorWeaponsMenuText[2], Dried_Fish_Name, Dried_Fish[client]);
	SetPanelTitle(menu, text);
	for (int i = 20; i < 24 ; i++)
	{
		Format(text, sizeof(text), "%s    %d", GoodsViewText[i], GoodsPrice[i]);
		DrawPanelItem(menu, text);
	}
	DrawPanelText(menu, " \n");
	DrawPanelItem(menu, "返回");
	DrawPanelItem(menu, "关闭");
	SendPanelToClient(menu, client, Buy_SniperMenu, 25);
}

//展开医疗物品菜单
public void Show_Buy_MedicalMenu(int client)
{
	if (!IsValidClient(client))
		return;

	Handle menu = CreatePanel();
	char text[48];
	Format(text, sizeof(text), "%s  当前%s: %d", GoodsMenuText[3], Dried_Fish_Name, Dried_Fish[client]);
	SetPanelTitle(menu, text);
	for (int i = 25; i < 29 ; i++)
	{
		Format(text, sizeof(text), "%s    %d", GoodsViewText[i], GoodsPrice[i]);
		DrawPanelItem(menu, text);
	}
	DrawPanelText(menu, " \n");
	DrawPanelItem(menu, "返回");
	DrawPanelItem(menu, "关闭");
	SendPanelToClient(menu, client, Buy_MedicalMenu, 25);
}

//展开投掷物菜单
public void Show_Buy_MissileMenu(int client)
{
	if (!IsValidClient(client))
		return;

	Handle menu = CreatePanel();
	char text[48];
	Format(text, sizeof(text), "%s  当前%s: %d", GoodsMenuText[4], Dried_Fish_Name, Dried_Fish[client]);
	SetPanelTitle(menu, text);
	for (int i = 29; i < 32 ; i++)
	{
		Format(text, sizeof(text), "%s    %d", GoodsViewText[i], GoodsPrice[i]);
		DrawPanelItem(menu, text);
	}
	DrawPanelText(menu, " \n");
	DrawPanelItem(menu, "返回");
	DrawPanelItem(menu, "关闭");
	SendPanelToClient(menu, client, Buy_MissileMenu, 25);
}

//展开近战菜单
public void Show_Buy_MeleeMenu(int client)
{
	if (!IsValidClient(client))
		return;

	Handle menu = CreatePanel();
	char text[48];
	Format(text, sizeof(text), "%s  当前%s: %d", GoodsMenuText[5], Dried_Fish_Name, Dried_Fish[client]);
	SetPanelTitle(menu, text);
	DrawPanelItem(menu, "利器");
	DrawPanelItem(menu, "钝器");
	DrawPanelItem(menu, "电锯");
	DrawPanelText(menu, " \n");
	DrawPanelItem(menu, "返回");
	DrawPanelItem(menu, "关闭");
	SendPanelToClient(menu, client, Buy_MeleeMenu, 25);
}

//展开利器菜单
public void Show_Buy_SharpMeleeMenu(int client)
{
	if (!IsValidClient(client))
		return;

	
	Handle menu = CreatePanel();
	char text[48];
	Format(text, sizeof(text), "利器  当前%s: %d", Dried_Fish_Name, Dried_Fish[client]);
	SetPanelTitle(menu, text);
	for (int i = 32; i < 38 ; i++)
	{
		Format(text, sizeof(text), "%s    %d", GoodsViewText[i], GoodsPrice[i]);
		DrawPanelItem(menu, text);
	}
	DrawPanelText(menu, " \n");
	DrawPanelItem(menu, "返回");
	DrawPanelItem(menu, "关闭");
	SendPanelToClient(menu, client, Buy_SharpMeleeMenu, 25);
}

//展开钝器菜单
public void Show_Buy_BluntMeleeMenu(int client)
{
	if (!IsValidClient(client))
		return;

	Handle menu = CreatePanel();
	char text[48];
	Format(text, sizeof(text), "钝器  当前%s: %d", Dried_Fish_Name, Dried_Fish[client]);
	SetPanelTitle(menu, text);
	for (int i = 38; i < 45 ; i++)
	{
		Format(text, sizeof(text), "%s    %d", GoodsViewText[i], GoodsPrice[i]);
		DrawPanelItem(menu, text);
	}
	DrawPanelText(menu, " \n");
	DrawPanelItem(menu, "返回");
	DrawPanelItem(menu, "关闭");
	SendPanelToClient(menu, client, Buy_BluntMeleeMenu, 25);
}

//展开管理员菜单
public void Show_Buy_AdminMenu(int client)
{
	if (!IsValidAdminClient(client))
		return;

	Handle menu = CreatePanel();
	SetPanelTitle(menu, GoodsMenuText[6]);
	char text[48];
	DrawPanelItem(menu, "货币数量设置");
	Format(text, sizeof(text), "%s玩家购物", CanBuy?"关闭":"开启");
	DrawPanelItem(menu, text);
	Format(text, sizeof(text), "%s管理员零元购", AdminRob?"关闭":"开启");
	DrawPanelItem(menu, text);
	Format(text, sizeof(text), "更改为%s", BuyMode == 1?"开局定数购物":"击杀奖励购物");
	DrawPanelItem(menu, text);
	DrawPanelItem(menu, "冻结");
	DrawPanelText(menu, " \n");
	DrawPanelItem(menu, "返回");
	DrawPanelItem(menu, "关闭");
	SendPanelToClient(menu, client, Buy_AdminMenu, 25);
}

//展开管理员货币数量设置菜单
public void Show_Buy_AdminSetMenu(int client)
{
	if (!IsValidAdminClient(client))
		return;

	Handle menu = CreatePanel();
	SetPanelTitle(menu, "货币数量设置");
	char text[48];
	Format(text, sizeof(text), "设置开局%s数量", Dried_Fish_Name);
	DrawPanelItem(menu, text);
	DrawPanelItem(menu, "全员奖励");
	DrawPanelItem(menu, "全员扣钱");
	DrawPanelItem(menu, "设置货币名字");
	DrawPanelText(menu, " \n");
	DrawPanelItem(menu, "返回");
	DrawPanelItem(menu, "关闭");
	SendPanelToClient(menu, client, Buy_AdminSetMenu, 25);
}

//展开冻结菜单
public void Show_FreezeMenu(int client)
{
	if (!IsValidAdminClient(client))
		return;

	Handle menu = CreatePanel();
	SetPanelTitle(menu, "冻结");
	DrawPanelItem(menu, "冻结玩家");
	DrawPanelItem(menu, "冻结商品");
	DrawPanelText(menu, " \n");
	DrawPanelItem(menu, "返回");
	DrawPanelItem(menu, "关闭");
	SendPanelToClient(menu, client, FreezeMenu, 25);
}

//展开冻结玩家菜单
public void Show_FreezeClientMenu(int client)
{
	if (!IsValidAdminClient(client))
		return;

	CheckFreezeClient();

	Handle menu = CreatePanel();
	char text[48];
	SetPanelTitle(menu, "冻结玩家");
	for (int i = FreezeClientType[client]; i < FreezeClientType[client] + 6 ; i++)
	{
		if (FreezeClientList[i] == 0)
			DrawPanelItem(menu, "无数据");
		else
		{
			GetClientName(FreezeClientList[i], text, sizeof(text));
			Format(text, sizeof(text), "%s %s", IsFreeze[FreezeClientList[i]]?"解冻":"冻结", text);
			DrawPanelItem(menu, text);
		}
	}
	DrawPanelItem(menu, "上一页");
	DrawPanelItem(menu, "下一页");
	DrawPanelText(menu, " \n");
	DrawPanelItem(menu, "返回");
	DrawPanelItem(menu, "关闭");
	SendPanelToClient(menu, client, FreezeClientMenu, 25);
}

//展开冻结商品菜单
public void Show_FreezeGoodsMenu(int client)
{
	if (!IsValidAdminClient(client))
		return;

	Handle menu = CreatePanel();
	SetPanelTitle(menu, "冻结商品");
	char text[64];
	for (int i = 0; i < 6 ; i++)
	{
		Format(text, sizeof(text), "冻结%s", GoodsMenuText[i]);
		DrawPanelItem(menu, text);
	}
	DrawPanelText(menu, " \n");
	DrawPanelItem(menu, "返回");
	DrawPanelItem(menu, "关闭");
	SendPanelToClient(menu, client, FreezeGoodsMenu, 25);
}

//展开冻结子弹菜单
public void Show_Freeze_AmmoMenu(int client)
{
	if (!IsValidAdminClient(client))
		return;

	Handle menu = CreatePanel();
	char text[48];
	Format(text, sizeof(text), "冻结%s", GoodsMenuText[0]);
	SetPanelTitle(menu, text);
	for (int i = 0; i < 6 ; i++)
	{
		Format(text, sizeof(text), "%s%s", GoodsIsFreeze[i]?"解冻":"冻结", GoodsText[i]);
		DrawPanelItem(menu, text);
	}
	Format(text, sizeof(text), "%s所有%s", AllGoodsIsFreeze[0]?"解冻":"冻结", GoodsMenuText[0]);
	DrawPanelItem(menu, text);
	DrawPanelText(menu, " \n");
	DrawPanelItem(menu, "返回");
	DrawPanelItem(menu, "关闭");
	SendPanelToClient(menu, client, Freeze_AmmoMenu, 25);
}

//展开冻结小枪菜单
public void Show_Freeze_PrimaryWeaponsMenu(int client)
{
	if (!IsValidAdminClient(client))
		return;

	Handle menu = CreatePanel();
	char text[48];
	Format(text, sizeof(text), "冻结%s", GoodsMenuText[1]);
	SetPanelTitle(menu, text);
	for (int i = 6; i < 13 ; i++)
	{
		Format(text, sizeof(text), "%s%s", GoodsIsFreeze[i]?"解冻":"冻结", GoodsText[i]);
		DrawPanelItem(menu, text);
	}
	Format(text, sizeof(text), "%s所有%s", AllGoodsIsFreeze[1]?"解冻":"冻结", GoodsMenuText[1]);
	DrawPanelItem(menu, text);
	DrawPanelText(menu, " \n");
	DrawPanelItem(menu, "返回");
	DrawPanelItem(menu, "关闭");
	SendPanelToClient(menu, client, Freeze_PrimaryWeaponsMenu, 25);
}

//展开冻结大枪菜单
public void Show_Freeze_SuperiorWeaponsMenu(int client)
{
	if (!IsValidAdminClient(client))
		return;

	Handle menu = CreatePanel();
	char text[48];
	Format(text, sizeof(text), "冻结%s", GoodsMenuText[2]);
	SetPanelTitle(menu, text);
	for (int i = 0; i < 3 ; i++)
	{
		Format(text, sizeof(text), "冻结%s", SuperiorWeaponsMenuText[i]);
		DrawPanelItem(menu, text);
	}
	Format(text, sizeof(text), "%s%s", GoodsIsFreeze[24]?"解冻":"冻结", GoodsText[24]);
	DrawPanelItem(menu, text);
	Format(text, sizeof(text), "%s所有%s", AllGoodsIsFreeze[2]?"解冻":"冻结", GoodsMenuText[2]);
	DrawPanelItem(menu, text);
	DrawPanelText(menu, " \n");
	DrawPanelItem(menu, "返回");
	DrawPanelItem(menu, "关闭");
	SendPanelToClient(menu, client, Freeze_SuperiorWeaponsMenu, 25);
}

//展开冻结步枪菜单
public void Show_Freeze_RifleMenu(int client)
{
	if (!IsValidAdminClient(client))
		return;

	Handle menu = CreatePanel();
	char text[48];
	Format(text, sizeof(text), "冻结%s", SuperiorWeaponsMenuText[0]);
	SetPanelTitle(menu, text);
	for (int i = 13; i < 18 ; i++)
	{
		Format(text, sizeof(text), "%s%s", GoodsIsFreeze[i]?"解冻":"冻结", GoodsText[i]);
		DrawPanelItem(menu, text);
	}
	Format(text, sizeof(text), "%s所有%s", AllSuperiorWeaponsIsFreeze[0]?"解冻":"冻结", SuperiorWeaponsMenuText[0]);
	DrawPanelItem(menu, text);
	DrawPanelText(menu, " \n");
	DrawPanelItem(menu, "返回");
	DrawPanelItem(menu, "关闭");
	SendPanelToClient(menu, client, Freeze_RifleMenu, 25);
}

//展开冻结连喷菜单
public void Show_Freeze_AutoShotGunMenu(int client)
{
	if (!IsValidAdminClient(client))
		return;

	Handle menu = CreatePanel();
	char text[48];
	Format(text, sizeof(text), "冻结%s", SuperiorWeaponsMenuText[1]);
	SetPanelTitle(menu, text);
	for (int i = 18; i < 20 ; i++)
	{
		Format(text, sizeof(text), "%s%s", GoodsIsFreeze[i]?"解冻":"冻结", GoodsText[i]);
		DrawPanelItem(menu, text);
	}
	Format(text, sizeof(text), "%s所有%s", AllSuperiorWeaponsIsFreeze[1]?"解冻":"冻结", SuperiorWeaponsMenuText[1]);
	DrawPanelItem(menu, text);
	DrawPanelText(menu, " \n");
	DrawPanelItem(menu, "返回");
	DrawPanelItem(menu, "关闭");
	SendPanelToClient(menu, client, Freeze_AutoShotGunMenu, 25);
}

//展开冻结狙击枪菜单
public void Show_Freeze_SniperMenu(int client)
{
	if (!IsValidAdminClient(client))
		return;

	Handle menu = CreatePanel();
	char text[48];
	Format(text, sizeof(text), "冻结%s", SuperiorWeaponsMenuText[2]);
	SetPanelTitle(menu, text);
	for (int i = 20; i < 24 ; i++)
	{
		Format(text, sizeof(text), "%s%s", GoodsIsFreeze[i]?"解冻":"冻结", GoodsText[i]);
		DrawPanelItem(menu, text);
	}
	Format(text, sizeof(text), "%s所有%s", AllSuperiorWeaponsIsFreeze[2]?"解冻":"冻结", SuperiorWeaponsMenuText[2]);
	DrawPanelItem(menu, text);
	DrawPanelText(menu, " \n");
	DrawPanelItem(menu, "返回");
	DrawPanelItem(menu, "关闭");
	SendPanelToClient(menu, client, Freeze_SniperMenu, 25);
}

//展开冻结医疗物品菜单
public void Show_Freeze_MedicalMenu(int client)
{
	if (!IsValidAdminClient(client))
		return;

	Handle menu = CreatePanel();
	char text[48];
	Format(text, sizeof(text), "冻结%s", GoodsMenuText[3]);
	SetPanelTitle(menu, text);
	for (int i = 25; i < 29 ; i++)
	{
		Format(text, sizeof(text), "%s%s", GoodsIsFreeze[i]?"解冻":"冻结", GoodsText[i]);
		DrawPanelItem(menu, text);
	}
	Format(text, sizeof(text), "%s所有%s", AllGoodsIsFreeze[3]?"解冻":"冻结", GoodsMenuText[3]);
	DrawPanelItem(menu, text);
	DrawPanelText(menu, " \n");
	DrawPanelItem(menu, "返回");
	DrawPanelItem(menu, "关闭");
	SendPanelToClient(menu, client, Freeze_MedicalMenu, 25);
}

//展开冻结投掷物菜单
public void Show_Freeze_MissileMenu(int client)
{
	if (!IsValidAdminClient(client))
		return;

	Handle menu = CreatePanel();
	char text[48];
	Format(text, sizeof(text), "冻结%s", GoodsMenuText[4]);
	SetPanelTitle(menu, text);
	for (int i = 29; i < 32 ; i++)
	{
		Format(text, sizeof(text), "%s%s", GoodsIsFreeze[i]?"解冻":"冻结", GoodsText[i]);
		DrawPanelItem(menu, text);
	}
	Format(text, sizeof(text), "%s所有%s", AllGoodsIsFreeze[4]?"解冻":"冻结", GoodsMenuText[4]);
	DrawPanelItem(menu, text);
	DrawPanelText(menu, " \n");
	DrawPanelItem(menu, "返回");
	DrawPanelItem(menu, "关闭");
	SendPanelToClient(menu, client, Freeze_MissileMenu, 25);
}

//展开冻结近战菜单
public void Show_Freeze_MeleeMenu(int client)
{
	if (!IsValidAdminClient(client))
		return;

	Handle menu = CreatePanel();
	char text[48];
	Format(text, sizeof(text), "冻结%s", GoodsMenuText[5]);
	SetPanelTitle(menu, text);
	DrawPanelItem(menu, "冻结利器");
	DrawPanelItem(menu, "冻结钝器");
	Format(text, sizeof(text), "%s%s", GoodsIsFreeze[45]?"解冻":"冻结", GoodsText[45]);
	DrawPanelItem(menu, text);
	Format(text, sizeof(text), "%s所有%s", AllGoodsIsFreeze[5]?"解冻":"冻结", GoodsMenuText[5]);
	DrawPanelItem(menu, text);
	DrawPanelText(menu, " \n");
	DrawPanelItem(menu, "返回");
	DrawPanelItem(menu, "关闭");
	SendPanelToClient(menu, client, Freeze_MeleeMenu, 25);
}

//展开冻结利器菜单
public void Show_Freeze_SharpMeleeMenu(int client)
{
	if (!IsValidAdminClient(client))
		return;

	Handle menu = CreatePanel();
	char text[48];
	SetPanelTitle(menu, "冻结利器");
	for (int i = 32; i < 38 ; i++)
	{
		Format(text, sizeof(text), "%s%s", GoodsIsFreeze[i]?"解冻":"冻结", GoodsText[i]);
		DrawPanelItem(menu, text);
	}
	Format(text, sizeof(text), "%s所有利器", AllSharpMeleeIsFreeze?"解冻":"冻结");
	DrawPanelItem(menu, text);
	DrawPanelText(menu, " \n");
	DrawPanelItem(menu, "返回");
	DrawPanelItem(menu, "关闭");
	SendPanelToClient(menu, client, Freeze_SharpMeleeMenu, 25);
}

//展开冻结钝器菜单
public void Show_Freeze_BluntMeleeMenu(int client)
{
	if (!IsValidAdminClient(client))
		return;

	Handle menu = CreatePanel();
	char text[48];
	SetPanelTitle(menu, "冻结钝器");
	for (int i = 38; i < 45 ; i++)
	{
		Format(text, sizeof(text), "%s%s", GoodsIsFreeze[i]?"解冻":"冻结", GoodsText[i]);
		DrawPanelItem(menu, text);
	}
	Format(text, sizeof(text), "%s所有钝器", AllBluntMeleeIsFreeze?"解冻":"冻结");
	DrawPanelItem(menu, text);
	DrawPanelText(menu, " \n");
	DrawPanelItem(menu, "返回");
	DrawPanelItem(menu, "关闭");
	SendPanelToClient(menu, client, Freeze_BluntMeleeMenu, 25);
}





// ====================================================================================================
// Menu
// ====================================================================================================

//购物主菜单
public int Buy_MainMenu(Menu menu, MenuAction action, int client, int itemNum)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if (bCheckClientAccess(client))
			{
				if (itemNum > 7)
				{
					delete menu;
					return 0;
				}
			}
			else
			{
				if (itemNum > 6)
				{
					delete menu;
					return 0;
				}
			}

			switch (itemNum)
			{
				case 1 :
					Show_Buy_AmmoMenu(client);
				case 2:
					Show_Buy_PrimaryWeaponsMenu(client);
				case 3 :
					Show_Buy_SuperiorWeaponsMenu(client);
				case 4 :
					Show_Buy_MedicalMenu(client);
				case 5 :
					Show_Buy_MissileMenu(client);
				case 6 :
					Show_Buy_MeleeMenu(client);
				case 7 :
				{
					if (bCheckClientAccess(client))
						Show_Buy_AdminMenu(client);
				}
			}
		}
		case MenuAction_End:
			delete menu;
	}
	return 0;
}

//子弹菜单
public int Buy_AmmoMenu(Menu menu, MenuAction action, int client, int itemNum)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if (itemNum <= 6)
				Buy_OneGoods(client, itemNum - 1);
			else if (itemNum == 7)
				Show_Buy_MainMenu(client);
			else
				delete menu;
		}
		case MenuAction_End:
			delete menu;
	}
	return 0;
}

//小枪菜单
public int Buy_PrimaryWeaponsMenu(Menu menu, MenuAction action, int client, int itemNum)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if (itemNum <= 7)
				Buy_OneGoods(client, itemNum + 5);
			else if (itemNum == 8)
				Show_Buy_MainMenu(client);
			else
				delete menu;
		}
		case MenuAction_End:
			delete menu;
	}
	return 0;
}

//大枪菜单
public int Buy_SuperiorWeaponsMenu(Menu menu, MenuAction action, int client, int itemNum)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if (itemNum > 5)
			{
				delete menu;
				return 0;
			}

			switch (itemNum)
			{
				case 1 :
					Show_Buy_RifleMenu(client);
				case 2:
					Show_Buy_AutoShotGunMenu(client);
				case 3 :
					Show_Buy_SniperMenu(client);
				case 4 :
					Buy_OneGoods(client, 24);
				case 5 :
					Show_Buy_MainMenu(client);
			}
		}
		case MenuAction_End:
			delete menu;
	}
	return 0;
}

//步枪菜单
public int Buy_RifleMenu(Menu menu, MenuAction action, int client, int itemNum)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if (itemNum <= 5)
				Buy_OneGoods(client, itemNum + 12);
			else if (itemNum == 6)
				Show_Buy_SuperiorWeaponsMenu(client);
			else
				delete menu;
		}
		case MenuAction_End:
			delete menu;
	}
	return 0;
}

//连喷菜单
public int Buy_AutoShotGunMenu(Menu menu, MenuAction action, int client, int itemNum)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if (itemNum <= 2)
				Buy_OneGoods(client, itemNum + 17);
			else if (itemNum == 3)
				Show_Buy_SuperiorWeaponsMenu(client);
			else
				delete menu;
		}
		case MenuAction_End:
			delete menu;
	}
	return 0;
}

//狙击枪菜单
public int Buy_SniperMenu(Menu menu, MenuAction action, int client, int itemNum)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if (itemNum <= 4)
				Buy_OneGoods(client, itemNum + 19);
			else if (itemNum == 5)
				Show_Buy_SuperiorWeaponsMenu(client);
			else
				delete menu;
		}
		case MenuAction_End:
			delete menu;
	}
	return 0;
}

//医疗物品菜单
public int Buy_MedicalMenu(Menu menu, MenuAction action, int client, int itemNum)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if (itemNum <= 4)
				Buy_OneGoods(client, itemNum + 24);
			else if (itemNum == 5)
				Show_Buy_MainMenu(client);
			else
				delete menu;
		}
		case MenuAction_End:
			delete menu;
	}
	return 0;
}

//投掷物菜单
public int Buy_MissileMenu(Menu menu, MenuAction action, int client, int itemNum)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if (itemNum <= 3)
				Buy_OneGoods(client, itemNum + 28);
			else if (itemNum == 4)
				Show_Buy_MainMenu(client);
			else
				delete menu;
		}
		case MenuAction_End:
			delete menu;
	}
	return 0;
}

//近战武器菜单
public int Buy_MeleeMenu(Menu menu, MenuAction action, int client, int itemNum)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if (itemNum > 4)
			{
				delete menu;
				return 0;
			}

			switch (itemNum)
			{
				case 1 :
					Show_Buy_SharpMeleeMenu(client);
				case 2:
					Show_Buy_BluntMeleeMenu(client);
				case 3 :
					Buy_OneGoods(client, 45);
				case 4 :
					Show_Buy_MainMenu(client);
			}
		}
		case MenuAction_End:
			delete menu;
	}
	return 0;
}

//利器菜单
public int Buy_SharpMeleeMenu(Menu menu, MenuAction action, int client, int itemNum)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if (itemNum <= 6)
				Buy_OneGoods(client, itemNum + 31);
			else if (itemNum == 7)
				Show_Buy_MeleeMenu(client);
			else
				delete menu;
		}
		case MenuAction_End:
			delete menu;
	}
	return 0;
}

//钝器菜单
public int Buy_BluntMeleeMenu(Menu menu, MenuAction action, int client, int itemNum)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if (itemNum <= 7)
				Buy_OneGoods(client, itemNum + 37);
			else if (itemNum == 8)
				Show_Buy_MeleeMenu(client);
			else
				delete menu;
		}
		case MenuAction_End:
			delete menu;
	}
	return 0;
}

//管理员菜单
public int Buy_AdminMenu(Menu menu, MenuAction action, int client, int itemNum)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if (itemNum > 6)
			{
				delete menu;
				return 0;
			}

			switch (itemNum)
			{
				case 1 :
					Show_Buy_AdminSetMenu(client);
				case 2 :
				{
					if (CanBuy)
						CanBuy = false;
					else
						CanBuy = true;
					PrintToChatAll("\x05[INFO] \x03管理员已%s玩家购物.", CanBuy?"开启":"关闭");
					Show_Buy_AdminMenu(client);
				}
				case 3 :
				{
					if (AdminRob)
						AdminRob = false;
					else
						AdminRob = true;
					PrintToChatAll("\x05[INFO] \x03管理员已%s管理员零元购.", AdminRob?"开启":"关闭");
					Show_Buy_AdminMenu(client);
				}
				case 4:
				{
					if (!BTxtConfig[3])
					{
						PrintToChat(client, "\x04[ERROR] \x03当前为混合模式.");
						return 0;
					}

					BuyMode = 1 - BuyMode;
					for (int i = 1; i <= MaxClients ; i++)
					{
						if (IsClientInGame(i) && !IsFakeClient(i))
						{
							Save_Player_DriedFish(i, true, (1 - BuyMode));
							Save_Player_DriedFish(i, false, BuyMode);
						}
					}
					PrintToChatAll("\x05[INFO] \x03管理员已将购物模式更改为 \x04%s", BuyMode == 0?"开局定数购物":"击杀奖励购物");
					Show_Buy_AdminMenu(client);
				}
				case 5 :
					Show_FreezeMenu(client);
				case 6 :
					Show_Buy_MainMenu(client);
			}
		}
		case MenuAction_End:
			delete menu;
	}
	return 0;
}

//管理员货币数量设置菜单
public int Buy_AdminSetMenu(Menu menu, MenuAction action, int client, int itemNum)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if (itemNum <= 4)
			{
				Admin_SayZT[client] = itemNum;
				PrintToChat(client, "\x04[提示] \x05请在聊天框输入设置%s.", itemNum == 4?"名字":"数量");
				Show_Buy_AdminMenu(client);
			}
			else if (itemNum == 5)
			{
				Admin_SayZT[client] = 0;
				Show_Buy_AdminMenu(client);
			}
			else
			{
				Admin_SayZT[client] = 0;
				delete menu;
			}
		}
		case MenuAction_End:
			delete menu;
	}
	return 0;
}

//冻结菜单
public int FreezeMenu(Menu menu, MenuAction action, int client, int itemNum)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if (itemNum > 3)
			{
				delete menu;
				return 0;
			}

			switch (itemNum)
			{
				case 1 :
				{
					FreezeClientType[client] = 0;
					Show_FreezeClientMenu(client);
				}
				case 2:
					Show_FreezeGoodsMenu(client);
				case 3 :
					Show_Buy_AdminMenu(client);
			}
		}
		case MenuAction_End:
			delete menu;
	}
	return 0;
}

//冻结玩家菜单
public int FreezeClientMenu(Menu menu, MenuAction action, int client, int itemNum)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if (itemNum <= 6)
			{
				int target = FreezeClientList[FreezeClientType[client] * 6 + itemNum - 1];
				if (target > 0)
					Freeze_Client(client, target);
				
				Show_FreezeClientMenu(client);
			}
			else if (itemNum == 7)
			{
				if (FreezeClientNUM > 6 && FreezeClientType[client] > 0)
					FreezeClientType[client] --;

				Show_FreezeClientMenu(client);
			}
			else if (itemNum == 8)
			{
				if (FreezeClientNUM > ((FreezeClientType[client] + 1) * 6))
					FreezeClientType[client] ++;

				Show_FreezeClientMenu(client);
			}
			else if (itemNum == 9)
				Show_FreezeMenu(client);
			else
				delete menu;
		}
		case MenuAction_End:
			delete menu;
	}
	return 0;
}

//冻结商品菜单
public int FreezeGoodsMenu(Menu menu, MenuAction action, int client, int itemNum)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if (itemNum > 7)
			{
				delete menu;
				return 0;
			}

			switch (itemNum)
			{
				case 1 :
					Show_Freeze_AmmoMenu(client);
				case 2:
					Show_Freeze_PrimaryWeaponsMenu(client);
				case 3 :
					Show_Freeze_SuperiorWeaponsMenu(client);
				case 4 :
					Show_Freeze_MedicalMenu(client);
				case 5 :
					Show_Freeze_MissileMenu(client);
				case 6 :
					Show_Freeze_MeleeMenu(client);
				case 7 :
					Show_FreezeMenu(client);
			}
		}
		case MenuAction_End:
			delete menu;
	}
	return 0;
}

//冻结子弹菜单
public int Freeze_AmmoMenu(Menu menu, MenuAction action, int client, int itemNum)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if (itemNum <= 6)
			{
				Freeze_OneGoods(itemNum - 1);
				Show_Freeze_AmmoMenu(client);
			}
			else if (itemNum == 7)
			{
				if (AllGoodsIsFreeze[0])
					AllGoodsIsFreeze[0] = false;
				else
					AllGoodsIsFreeze[0] = true;

				for (int i = 0; i < 6; i++)
					GoodsIsFreeze[i] = AllGoodsIsFreeze[0];

				if (BTxtConfig[5])
					PrintToChatAll("\x05[INFO] \x03所有%s \x04已被管理员 \x03%s", GoodsMenuText[0], AllGoodsIsFreeze[0]?"冻结":"解冻");
				Show_Freeze_AmmoMenu(client);
			}
			else if (itemNum == 8)
				Show_FreezeGoodsMenu(client);
			else
				delete menu;
		}
		case MenuAction_End:
			delete menu;
	}
	return 0;
}

//冻结小枪菜单
public int Freeze_PrimaryWeaponsMenu(Menu menu, MenuAction action, int client, int itemNum)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if (itemNum <= 7)
			{
				Freeze_OneGoods(itemNum + 5);
				Show_Freeze_PrimaryWeaponsMenu(client);
			}
			else if (itemNum == 8)
			{
				if (AllGoodsIsFreeze[1])
					AllGoodsIsFreeze[1] = false;
				else
					AllGoodsIsFreeze[1] = true;

				for (int i = 6; i < 13; i++)
					GoodsIsFreeze[i] = AllGoodsIsFreeze[1];

				if (BTxtConfig[5])
					PrintToChatAll("\x05[INFO] \x03所有%s \x04已被管理员 \x03%s", GoodsMenuText[1], AllGoodsIsFreeze[1]?"冻结":"解冻");
				Show_Freeze_PrimaryWeaponsMenu(client);
			}
			else if (itemNum == 9)
				Show_FreezeGoodsMenu(client);
			else
				delete menu;
		}
		case MenuAction_End:
			delete menu;
	}
	return 0;
}

//冻结大枪菜单
public int Freeze_SuperiorWeaponsMenu(Menu menu, MenuAction action, int client, int itemNum)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if (itemNum > 6)
			{
				delete menu;
				return 0;
			}

			switch (itemNum)
			{
				case 1 :
					Show_Freeze_RifleMenu(client);
				case 2:
					Show_Freeze_AutoShotGunMenu(client);
				case 3 :
					Show_Freeze_SniperMenu(client);
				case 4 :
				{
					Freeze_OneGoods(24);
					Show_Freeze_SuperiorWeaponsMenu(client);
				}
				case 5 :
				{
					if (AllGoodsIsFreeze[2])
						AllGoodsIsFreeze[2] = false;
					else
						AllGoodsIsFreeze[2] = true;

					for (int i = 13; i < 25; i++)
						GoodsIsFreeze[i] = AllGoodsIsFreeze[2];

					if (BTxtConfig[5])
						PrintToChatAll("\x05[INFO] \x03所有%s \x04已被管理员 \x03%s", GoodsMenuText[2], AllGoodsIsFreeze[2]?"冻结":"解冻");
					Show_Freeze_SuperiorWeaponsMenu(client);
				}
				case 6 :
					Show_FreezeGoodsMenu(client);
			}
		}
		case MenuAction_End:
			delete menu;
	}
	return 0;
}

//冻结步枪菜单
public int Freeze_RifleMenu(Menu menu, MenuAction action, int client, int itemNum)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if (itemNum <= 5)
			{
				Freeze_OneGoods(itemNum + 12);
				Show_Freeze_RifleMenu(client);
			}
			else if (itemNum == 6)
			{
				if (AllSuperiorWeaponsIsFreeze[0])
					AllSuperiorWeaponsIsFreeze[0] = false;
				else
					AllSuperiorWeaponsIsFreeze[0] = true;
				
				for (int i = 13; i < 18; i++)
					GoodsIsFreeze[i] = AllSuperiorWeaponsIsFreeze[0];

				if (BTxtConfig[5])
					PrintToChatAll("\x05[INFO] \x03所有%s \x04已被管理员 \x03%s", SuperiorWeaponsMenuText[0], AllSuperiorWeaponsIsFreeze[0]?"冻结":"解冻");
				Show_Freeze_RifleMenu(client);
			}
			else if (itemNum == 7)
				Show_Freeze_SuperiorWeaponsMenu(client);
			else
				delete menu;
		}
		case MenuAction_End:
			delete menu;
	}
	return 0;
}

//冻结连喷菜单
public int Freeze_AutoShotGunMenu(Menu menu, MenuAction action, int client, int itemNum)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if (itemNum <= 2)
			{
				Freeze_OneGoods(itemNum + 17);
				Show_Freeze_AutoShotGunMenu(client);
			}
			else if (itemNum == 3)
			{
				if (AllSuperiorWeaponsIsFreeze[1])
					AllSuperiorWeaponsIsFreeze[1] = false;
				else
					AllSuperiorWeaponsIsFreeze[1] = true;
				
				for (int i = 18; i < 20; i++)
					GoodsIsFreeze[i] = AllSuperiorWeaponsIsFreeze[1];

				if (BTxtConfig[5])
					PrintToChatAll("\x05[INFO] \x03所有%s \x04已被管理员 \x03%s", SuperiorWeaponsMenuText[1], AllSuperiorWeaponsIsFreeze[1]?"冻结":"解冻");
				Show_Freeze_AutoShotGunMenu(client);
			}
			else if (itemNum == 4)
				Show_Freeze_SuperiorWeaponsMenu(client);
			else
				delete menu;
		}
		case MenuAction_End:
			delete menu;
	}
	return 0;
}

//冻结狙击枪菜单
public int Freeze_SniperMenu(Menu menu, MenuAction action, int client, int itemNum)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if (itemNum <= 4)
			{
				Freeze_OneGoods(itemNum + 19);
				Show_Freeze_SniperMenu(client);
			}
			else if (itemNum == 5)
			{
				if (AllSuperiorWeaponsIsFreeze[2])
					AllSuperiorWeaponsIsFreeze[2] = false;
				else
					AllSuperiorWeaponsIsFreeze[2] = true;
				
				for (int i = 20; i < 24; i++)
					GoodsIsFreeze[i] = AllSuperiorWeaponsIsFreeze[2];

				if (BTxtConfig[5])
					PrintToChatAll("\x05[INFO] \x03所有%s \x04已被管理员 \x03%s", SuperiorWeaponsMenuText[2], AllSuperiorWeaponsIsFreeze[2]?"冻结":"解冻");
				Show_Freeze_SniperMenu(client);
			}
			else if (itemNum == 6)
				Show_Freeze_SuperiorWeaponsMenu(client);
			else
				delete menu;
		}
		case MenuAction_End:
			delete menu;
	}
	return 0;
}

//冻结医疗物品菜单
public int Freeze_MedicalMenu(Menu menu, MenuAction action, int client, int itemNum)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if (itemNum <= 4)
			{
				Freeze_OneGoods(itemNum + 24);
				Show_Freeze_MedicalMenu(client);
			}
			else if (itemNum == 5)
			{
				if (AllGoodsIsFreeze[3])
					AllGoodsIsFreeze[3] = false;
				else
					AllGoodsIsFreeze[3] = true;

				for (int i = 25; i < 29; i++)
					GoodsIsFreeze[i] = AllGoodsIsFreeze[3];

				if (BTxtConfig[5])
					PrintToChatAll("\x05[INFO] \x03所有%s \x04已被管理员 \x03%s", GoodsMenuText[3], AllGoodsIsFreeze[3]?"冻结":"解冻");
				Show_Freeze_MedicalMenu(client);
			}
			else if (itemNum == 6)
				Show_FreezeGoodsMenu(client);
			else
				delete menu;
		}
		case MenuAction_End:
			delete menu;
	}
	return 0;
}

//冻结投掷物菜单
public int Freeze_MissileMenu(Menu menu, MenuAction action, int client, int itemNum)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if (itemNum <= 3)
			{
				Freeze_OneGoods(itemNum + 28);
				Show_Freeze_MissileMenu(client);
			}
			else if (itemNum == 4)
			{
				if (AllGoodsIsFreeze[4])
					AllGoodsIsFreeze[4] = false;
				else
					AllGoodsIsFreeze[4] = true;

				for (int i = 29; i < 32; i++)
					GoodsIsFreeze[i] = AllGoodsIsFreeze[4];

				if (BTxtConfig[5])
					PrintToChatAll("\x05[INFO] \x03所有%s \x04已被管理员 \x03%s", GoodsMenuText[4], AllGoodsIsFreeze[4]?"冻结":"解冻");
				Show_Freeze_MissileMenu(client);
			}
			else if (itemNum == 5)
				Show_FreezeGoodsMenu(client);
			else
				delete menu;
		}
		case MenuAction_End:
			delete menu;
	}
	return 0;
}

//冻结近战武器菜单
public int Freeze_MeleeMenu(Menu menu, MenuAction action, int client, int itemNum)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if (itemNum > 5)
			{
				delete menu;
				return 0;
			}

			switch (itemNum)
			{
				case 1 :
					Show_Freeze_SharpMeleeMenu(client);
				case 2:
					Show_Freeze_BluntMeleeMenu(client);
				case 3 :
				{
					Freeze_OneGoods(45);
					Show_Freeze_MeleeMenu(client);
				}
				case 4 :
				{
					if (AllGoodsIsFreeze[5])
						AllGoodsIsFreeze[5] = false;
					else
						AllGoodsIsFreeze[5] = true;

					for (int i = 32; i < 46; i++)
						GoodsIsFreeze[i] = AllGoodsIsFreeze[5];

					if (BTxtConfig[5])
						PrintToChatAll("\x05[INFO] \x03所有%s \x04已被管理员 \x03%s", GoodsMenuText[5], AllGoodsIsFreeze[5]?"冻结":"解冻");
					Show_Freeze_MeleeMenu(client);
				}
				case 5 :
					Show_FreezeGoodsMenu(client);
			}
		}
		case MenuAction_End:
			delete menu;
	}
	return 0;
}

//冻结利器菜单
public int Freeze_SharpMeleeMenu(Menu menu, MenuAction action, int client, int itemNum)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if (itemNum <= 6)
			{
				Freeze_OneGoods(itemNum + 31);
				Show_Freeze_SharpMeleeMenu(client);
			}
			else if (itemNum == 7)
			{
				if (AllSharpMeleeIsFreeze)
					AllSharpMeleeIsFreeze = false;
				else
					AllSharpMeleeIsFreeze = true;

				for (int i = 32; i < 38; i++)
					GoodsIsFreeze[i] = AllSharpMeleeIsFreeze;

				if (BTxtConfig[5])
					PrintToChatAll("\x05[INFO] \x03所有利器 \x04已被管理员 \x03%s", AllSharpMeleeIsFreeze?"冻结":"解冻");
				Show_Freeze_SharpMeleeMenu(client);
			}
			else if (itemNum == 8)
				Show_Freeze_MeleeMenu(client);
			else
				delete menu;
		}
		case MenuAction_End:
			delete menu;
	}
	return 0;
}

//冻结钝器菜单
public int Freeze_BluntMeleeMenu(Menu menu, MenuAction action, int client, int itemNum)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if (itemNum <= 7)
			{
				Freeze_OneGoods(itemNum + 37);
				Show_Freeze_BluntMeleeMenu(client);
			}
			else if (itemNum == 8)
			{
				if (AllBluntMeleeIsFreeze)
					AllBluntMeleeIsFreeze = false;
				else
					AllBluntMeleeIsFreeze = true;

				for (int i = 38; i < 45; i++)
					GoodsIsFreeze[i] = AllBluntMeleeIsFreeze;

				if (BTxtConfig[5])
					PrintToChatAll("\x05[INFO] \x03所有利器 \x04已被管理员 \x03%s", AllBluntMeleeIsFreeze?"冻结":"解冻");
				Show_Freeze_BluntMeleeMenu(client);
			}
			else if (itemNum == 9)
				Show_Freeze_MeleeMenu(client);
			else
				delete menu;
		}
		case MenuAction_End:
			delete menu;
	}
	return 0;
}





// ====================================================================================================
// Buy Goods
// ====================================================================================================

//购物
public void Buy_OneGoods(int client, int goods)
{
	if (!IsValidClient(client))
		return;

	if (bCheckClientAccess(client) && AdminRob)
	{
		Give_Client_OneGoods(client, goods, true);
		return;
	}

	if (GoodsIsFreeze[goods])
	{
		PrintToChat(client, "\x04[ERROR] \x03%s%s%s", CantBuyGoodsText[0], Dried_Fish_Name, CantBuyGoodsText[1]);
		return;
	}

	if (Dried_Fish[client] < GoodsPrice[goods])
	{
		if (Dried_Fish[client] == 0)
			PrintToChat(client, "\x04[ERROR] \x03%s", CantBuyGoodsText[5]);
		else
			PrintToChat(client, "\x04[ERROR] \x03%s%s.", CantBuyGoodsText[4], Dried_Fish_Name);

		return;
	}

	Dried_Fish[client] -= GoodsPrice[goods];
	if (BTxtConfig[6])
	{
		Client_BuySum[client] += GoodsPrice[goods];
		SaveMessage(Get_BuyRecord_Text(client, goods));
	}
	Give_Client_OneGoods(client, goods, false);
}

//购物成功
public void Give_Client_OneGoods(int client, int goods, bool IsAdminRob)
{
	if (!IsValidClient(client))
		return;
	
	char CommandText[32];
	if (goods >= 1 && goods <= 3)
	{
		int flags = GetCommandFlags("upgrade_add");
		SetCommandFlags("upgrade_add", flags & ~FCVAR_CHEAT);
		Format(CommandText, sizeof(CommandText), "upgrade_add %s", GoodsName[goods]);
		FakeClientCommand(client, CommandText);
		SetCommandFlags("upgrade_add", flags|FCVAR_CHEAT);
	}
	else
	{
		int flags = GetCommandFlags("give");
		SetCommandFlags("give", flags & ~FCVAR_CHEAT);
		Format(CommandText, sizeof(CommandText), "give %s", GoodsName[goods]);
		FakeClientCommand(client, CommandText);
		SetCommandFlags("give", flags|FCVAR_CHEAT);
	}

	if (BTxtConfig[0])
		PrintToChatAll("\x05[INFO] \x03%N \x04%s了一个%s, 剩余%s : \x05%d", client, (IsAdminRob || GoodsPrice[goods] <= 0)?"白嫖":"购买", GoodsText[goods], Dried_Fish_Name, Dried_Fish[client]);
}





// ====================================================================================================
// Freeze
// ====================================================================================================

//整理冻结玩家列表
public void CheckFreezeClient()
{
	FreezeClientNUM = 0;
	for (int i = 1; i <= MaxClients ; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			FreezeClientList[FreezeClientNUM] = i;
			FreezeClientNUM ++;
		}
	}
	for (int i = FreezeClientNUM ; i <= MaxClients ; i++)
		FreezeClientList[i] = 0;
}

//冻结玩家
public void Freeze_Client(int client, int target)
{
	if (target > 0 && target <= MaxClients && IsClientInGame(target) && !IsFakeClient(target))
	{
		if (IsFreeze[target])
			IsFreeze[target] = false;
		else
			IsFreeze[target] = true;

		if (BTxtConfig[4])
		{
			if (client == target)
				PrintToChat(client, "\x04[提示] \x03难道你真的是天才?");
			else
			{
				PrintToChat(client, "\x04[提示] \x05你已%s \x04%N \x05的购物账号.", IsFreeze[target]?"冻结":"解冻", target);
				PrintToChat(target, "\x04[提示] \x05你的购物账号已被管理员 \x04%s\x05.", IsFreeze[target]?"冻结":"解冻");
			}
		}
	}
	else
		PrintToChat(client, "\x04[ERROR] \x03冻结目标丢失.");
}

//冻结某商品
public void Freeze_OneGoods(int goods)
{
	if (GoodsIsFreeze[goods])
		GoodsIsFreeze[goods] = false;
	else
		GoodsIsFreeze[goods] = true;
	
	if (BTxtConfig[5])
		PrintToChatAll("\x05[INFO] \x03%s \x04已被管理员 \x03%s", GoodsText[goods], GoodsIsFreeze[goods]?"冻结":"解冻");
}





// ====================================================================================================
// Cookie Get & Set
// ====================================================================================================

// 存储/获取 玩家小鱼干数量数据
public void Save_Player_DriedFish(int client, bool IsSave, int CBuyMode)
{
	if (IsFakeClient(client))
		return;

	if (IsSave)
	{
		if (CBuyMode == 0)
		{
			char TempStr[11];
			IntToString(Dried_Fish[client], TempStr, sizeof(TempStr));
			SetClientCookie(client, FAnneMode_DriedFish, TempStr);
		}
		else if (CBuyMode == 1)
		{
			char TempStr[11];
			IntToString(Dried_Fish[client], TempStr, sizeof(TempStr));
			SetClientCookie(client, KGiveMode_DriedFish, TempStr);
		}
	}
	else
	{
		if (CBuyMode == 0)
		{
			char TempStr[11];
			GetClientCookie(client, FAnneMode_DriedFish, TempStr, sizeof(TempStr));
			Dried_Fish[client] = StringToInt(TempStr);
		}
		else if (CBuyMode == 1)
		{
			char TempStr[11];
			GetClientCookie(client, KGiveMode_DriedFish, TempStr, sizeof(TempStr));
			Dried_Fish[client] = StringToInt(TempStr);
		}
	}
}





// ====================================================================================================
// Log Record
// ====================================================================================================

//开始记录 生产log文件
public void StartRecord()
{
	char map[128], msg[1024], date[21], time[21], logFile[100];

	GetCurrentMap(map, sizeof(map));

	FormatTime(date, sizeof(date), "%y.%m.%d", -1);
	Format(logFile, sizeof(logFile), "/logs/l4d2_dried_fish_buy[%s].log", date);
	BuildPath(Path_SM, ZRecordText, PLATFORM_MAX_PATH, logFile);

	FormatTime(time, sizeof(time), "%d/%m/%Y %H:%M:%S", -1);
	Format(msg, sizeof(msg), "[%s] --- NEW MAP STARTED: %s ---", time, map);

	SaveMessage("--=================================================================--");
	SaveMessage(msg);
	SaveMessage("--=================================================================--");
}

//获取购买记录字符串
char[] Get_BuyRecord_Text(int client, int goods)
{
	char text[128] = "error";
	if (client <= 0 || client > MaxClients || !IsClientInGame(client) || IsFakeClient(client))
		return text;

	char client_name[32];
	GetClientName(client, client_name, sizeof(client_name));
	Format(text, sizeof(text), "%s 购买了 %s, 花费 %d %s. [历史消费: %d]",
		client_name, GoodsText[goods], GoodsPrice[goods], Dried_Fish_Name, Client_BuySum[client]);
	
	return text;
}

//存储字符串
public void SaveMessage(char[] message)
{
	Handle fileHandle = OpenFile(ZRecordText, "a");
	WriteFileLine(fileHandle, message);
	CloseHandle(fileHandle);
}





// ====================================================================================================
// Bool
// ====================================================================================================

//判定玩家是否有效
public bool IsValidClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client) &&
		(bCheckClientAccess(client) || (GetClientTeam(client) == 2 && IsPlayerAlive(client) && !IsFreeze[client] && CanBuy));
}

//判定玩家是否为有效的管理员
public bool IsValidAdminClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client) && bCheckClientAccess(client);
}

//判定玩家是否为幸存者
public bool IsSurvivor(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2;
}

//判定玩家是否为感染者
public bool IsInfected(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3;
}

//判定玩家是否为管理员
public bool bCheckClientAccess(int client)
{
	if (GetUserFlagBits(client) & ADMFLAG_ROOT)
		return true;
	return false;
}

//判定字符串是否为纯数字
public bool IsPureDigital(char[] str)
{
	for (int i = 0; i < strlen(str) ; i++)
	{
		if (str[i] < '0' || str[i] > '9')
			return false;
	}
	return true;
}