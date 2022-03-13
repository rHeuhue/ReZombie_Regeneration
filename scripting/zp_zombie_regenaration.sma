#include <amxmodx>
#include <reapi>

/*
	MOD_TYPES:
	0 = Zombie Plague
	1 = BaseBuilder
	2 = VeCo Zombie BaseBuilder
	3 = Default
*/

#define MOD_TYPE 0

new Float:glb_fZombieMaxHealth[MAX_CLIENTS + 1]

enum (+=10)
{
	TASKID_DELAYED_SPAWN = 2022,
	TASKID_REGENERATION
}

enum fVars
{
	Float:REGENERATION_AMOUNT,
	Float:REGENERATION_TIME
}

new g_eCvars[fVars]

#if MOD_TYPE == 0
native zp_get_user_zombie(id)

#define is_player_zombie(%0) zp_get_user_zombie(%0)

new const PLUGIN_NAME[] = "ZP: Zombie Regeneration"

#elseif MOD_TYPE == 1
native bb_is_user_zombie(id)

#define is_player_zombie(%0) bb_is_user_zombie(%0)

new const PLUGIN_NAME[] = "BB: Zombie Regeneration"

#elseif MOD_TYPE == 2
native is_user_zombie(id)

#define is_player_zombie(%0) is_user_zombie(%0)

new const PLUGIN_NAME[] = "VZBB: Zombie Regeneration"
#elseif MOD_TYPE == 3
#define is_player_zombie(%0) (get_member(%0, m_iTeam) == TEAM_TERRORIST)

new const PLUGIN_NAME[] = "Re: Zombie Regeneration"
#else
	#assert "Please select one of the mod types correctly: 0 = Zombie Plague | 1 = BaseBuilder (Tirant) | 2 = VeCo Zombie BaseBuilder | 3 = Normal gameplay"
#endif

new const PLUGIN_VERSION[] = "1.0.0"

public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, "Huehue @ AMXX-BG.INFO")
	register_cvar("ReZombieRegeneration", PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_PROTECTED)
	
	RegisterHookChain(RG_CBasePlayer_Spawn, "RG__CBasePlayer_Spawn", true)
	RegisterHookChain(RG_CBasePlayer_TakeDamage, "RG__CBasePlayer_TakeDamage", true)

	new pCvar

	pCvar = create_cvar("zp_zombie_regeneration_amount", "10.0", FCVAR_NONE, "The amount of HP you will get every time.^nDepends on <zp_zombie_regeneration_time> cvar.")
	bind_pcvar_float(pCvar, g_eCvars[REGENERATION_AMOUNT])

	pCvar = create_cvar("zp_zombie_regeneration_time", "1.0", FCVAR_NONE, "Every X(in seconds) giving HP")
	bind_pcvar_float(pCvar, g_eCvars[REGENERATION_TIME])

	AutoExecConfig(true, "ReZombieRegeneration", "HuehuePlugins_Config")
}

public RG__CBasePlayer_Spawn(id)
{
	if (is_user_alive(id) && is_player_zombie(id))
	{
		if (task_exists(id + TASKID_REGENERATION))
			remove_task(id + TASKID_REGENERATION)

		if (task_exists(id + TASKID_DELAYED_SPAWN))
			remove_task(id + TASKID_DELAYED_SPAWN)

		set_task(3.0, "Check_MaxHealth", id + TASKID_DELAYED_SPAWN)
	}
}
public Check_MaxHealth(iTaskID)
{
	static id
	id = iTaskID - TASKID_DELAYED_SPAWN
	if (is_user_alive(id))
	{
		get_entvar(id, var_health, glb_fZombieMaxHealth[id])

		if (task_exists(id + TASKID_DELAYED_SPAWN))
			remove_task(id + TASKID_DELAYED_SPAWN)
	}
}

public RG__CBasePlayer_TakeDamage(iVictim, Inflictor, iAttacker, Float:fDamage, iDamageBit)
{
	#pragma unused Inflictor, iAttacker, fDamage, iDamageBit

	if (is_user_alive(iVictim) && is_player_zombie(iVictim) && !task_exists(iVictim + TASKID_REGENERATION))
	{
		set_task(g_eCvars[REGENERATION_TIME], "Regenerate_Health", iVictim + TASKID_REGENERATION, .flags = "b")
	}
}

public Regenerate_Health(iTaskID)
{
	static id
	id = iTaskID - TASKID_REGENERATION

	if (is_user_alive(id))
	{
		if (task_exists(id + TASKID_REGENERATION) && !is_player_zombie(id))
		{
			remove_task(id + TASKID_REGENERATION)
			return PLUGIN_CONTINUE
		}

		static Float:flHealth
		flHealth = get_entvar(id, var_health)

		if (flHealth >= glb_fZombieMaxHealth[id])
		{
			remove_task(id + TASKID_REGENERATION)
			return PLUGIN_CONTINUE
		}
		set_entvar(id, var_health, floatclamp(flHealth + g_eCvars[REGENERATION_AMOUNT], flHealth, glb_fZombieMaxHealth[id]))
	}
	return PLUGIN_CONTINUE
}