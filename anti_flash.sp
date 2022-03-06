#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =  {
	name = "Anti Flash", 
	author = "babka68", 
	description = "Плагин позволяет убрать ослепление от светошумовой гранаты", 
	version = "1.0", 
	url = "https://vk.com/zakazserver68"
};
// ConVars
bool g_bTeam, g_bSelf, g_bDead, g_bDeafen;

// Offset
int g_iFlashAlpha = -1, g_iFlashDuration = -1;
int g_iClient, g_iTeam; // Владелец последней сработавшей флешки

public void OnPluginStart() {
	if ((g_iFlashDuration = FindSendPropInfo("CCSPlayer", "m_flFlashDuration")) == -1) {
		SetFailState("Failed to find CCSPlayer::m_flFlashDuration offset");
	}
	
	if ((g_iFlashAlpha = FindSendPropInfo("CCSPlayer", "m_flFlashMaxAlpha")) == -1) {
		SetFailState("Failed to find CCSPlayer::m_flFlashMaxAlpha offset");
	}
	
	ConVar cvar;
	cvar = CreateConVar("sm_anti_flash_team", "0", "Ослепить товарищей по команде [1 - Слепить, 0 - Не слепить]", _, true, 0.0, true, 1.0);
	cvar.AddChangeHook(CVarChanged_Team);
	g_bTeam = cvar.BoolValue;
	
	cvar = CreateConVar("sm_anti_flash_self", "0", "Ослепить самого себя [1 - Слепить, 0 - Не слепить]", _, true, 0.0, true, 1.0);
	cvar.AddChangeHook(CVarChanged_Self);
	g_bSelf = cvar.BoolValue;
	
	cvar = CreateConVar("sm_anti_flash_dead", "0", "Ослепить мертвых игроков [1 - Слепить, 0 - Не слепить]", _, true, 0.0, true, 1.0);
	cvar.AddChangeHook(CVarChanged_Dead);
	g_bDead = cvar.BoolValue;
	
	cvar = CreateConVar("sm_anti_flash_deafen", "0", "Оглушать игрока при ослеплении [1 - да, 0 - нет]", _, true, 0.0, true, 1.0);
	cvar.AddChangeHook(CVarChanged_Deafen);
	g_bDeafen = cvar.BoolValue;
	
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

public void CVarChanged_Dead(ConVar CVar, const char[] oldValue, const char[] newValue) {
	g_bDead = CVar.BoolValue;
}

public void CVarChanged_Deafen(ConVar CVar, const char[] oldValue, const char[] newValue) {
	g_bDeafen = CVar.BoolValue;
}

public void Event_FlashbangDetonate(Event event, const char[] name, bool dontBroadcast) {
	g_iTeam = (g_iClient = GetClientOfUserId(event.GetInt("userid"))) > 0 ? GetClientTeam(g_iClient) : 0;
}

public void Event_PlayerBlind(Event event, const char[] name, bool dontBroadcast) {
	CreateTimer(0.0, Timer_Player_Blind, event.GetInt("userid"), TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_Player_Blind(Handle timer, any client) {
	if ((client = GetClientOfUserId(client)) < 1) {
		RemoveBlind(client);
	}
	
	bool self = g_iClient == client;
	if (g_iTeam == GetClientTeam(client)) {
		// Себя
		if (self && !g_bSelf) {
			RemoveBlind(client);
		}
		// Команду
		else if (!self && !g_bTeam) {
			RemoveBlind(client);
		}
		// Мертвых
		else if (!g_bDead && !IsPlayerAlive(client)) {
			RemoveBlind(client);
		}
		// Оглушение
		else if (!g_bDeafen) {
			RemoveDeafen(client);
		}
	}
}

void RemoveBlind(int client) {
	SetEntDataFloat(client, g_iFlashDuration, 0.0); // Время
	SetEntDataFloat(client, g_iFlashAlpha, 0.0); // Прозрачность
}

void RemoveDeafen(int client) {
	ClientCommand(client, "dsp_player 0.0"); // Оглушение
} 
