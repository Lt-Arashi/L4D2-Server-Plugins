#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdktools_functions>
#include <entity>
//#include <binhooks>

#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo = 
{
	name = "输入!run迅速润出服务器",
	author = "LeePie",
	description = "输入!run退服",
	version = PLUGIN_VERSION,
	url = ""
};

public OnPluginStart()
{
    RegConsoleCmd("sm_run", Run);
}

public Action:Run(client, args)
{
    KickClient(client,"细狗这就提桶跑路了？");
}

