#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =  {
	name = "Anti Flash", 
	author = "babka68", 
	description = "Плагин позволяет убрать ослепление от светошумовой гранаты", 
	version = "1.0", 
	url = "https://vk.com/zakazserver68"
};

bool g_bTeam, g_bSelf;
int g_iClient, g_iTeam; // Владелец последней сработавшей флешки

public void OnPluginStart() {
	
	ConVar cvar;
	cvar = CreateConVar("sm_anti_flash_team", "1", "Ослепить товарище по команде [1 - Не слепить, 0 - Слепить]", _, true, 0.0, true, 1.0);
	cvar.AddChangeHook(CVarChanged_Team);
	g_bTeam = cvar.BoolValue;
	
	cvar = CreateConVar("sm_anti_flash_self", "1", "Ослепить самого себя [1 - Не слепить, 0 - Слепить]", _, true, 0.0, true, 1.0);
	cvar.AddChangeHook(CVarChanged_Self);
	g_bSelf = cvar.BoolValue;
	
	AutoExecConfig(true, "anti_flash");
	
	HookEvent("flashbang_detonate", Event_FlashbangDetonate, EventHookMode_Pre); // Каждый раз, когда взрывается вспышка
	HookEvent("player_blind", Event_PlayerBlind, EventHookMode_Post); // Каждый раз, когда игрок ослеплен вспышкой.
}

public void CVarChanged_Team(ConVar CVar, const char[] oldValue, const char[] newValue) {
	g_bTeam = CVar.BoolValue;
}
public void CVarChanged_Self(ConVar CVar, const char[] oldValue, const char[] newValue) {
	g_bSelf = CVar.BoolValue;
}
public void Event_FlashbangDetonate(Event event, const char[] name, bool dontBroadcast) {
	g_iTeam = (g_iClient = GetClientOfUserId(event.GetInt("userid"))) > 0 ? GetClientTeam(g_iClient) : 0;
}


public void Event_PlayerBlind(Event event, const char[] name, bool dontBroadcast) {
	CreateTimer(0.0, Timer_Player_Blind, event.GetInt("userid"), TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_Player_Blind(Handle timer, any client) {
	if ((client = GetClientOfUserId(client)) < 1) {
		return Plugin_Stop;
	}
	
	bool self = g_iClient == client;
	if ((self && g_bSelf) || (!self && g_bTeam) && g_iTeam == GetClientTeam(client)) {
		SetEntPropFloat(client, Prop_Send, "m_flFlashDuration", 0.0); // Время
		SetEntPropFloat(client, Prop_Send, "m_flFlashMaxAlpha", 0.0); // Прозрачность
		ClientCommand(client, "dsp_player 0.0"); // Оглушение
		return Plugin_Stop;
	}
	return Plugin_Stop;
}

