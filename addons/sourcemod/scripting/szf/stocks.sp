//Zombie Soul related indexes
#define SKIN_ZOMBIE			5
#define SKIN_ZOMBIE_SPY		SKIN_ZOMBIE + 18

static char g_sClassFiles[view_as<int>(TFClass_Engineer) + 1][16] = { "", "scout", "sniper", "soldier", "demo", "medic", "heavy", "pyro", "spy", "engineer" };
static int g_iVoodooIndex[view_as<int>(TFClass_Engineer) + 1] =  {-1, 5617, 5625, 5618, 5620, 5622, 5619, 5624, 5623, 5621};
static int g_iZombieSoulIndex[view_as<int>(TFClass_Engineer) + 1];

////////////////
// Math
////////////////

stock int max(int a, int b)
{
	return (a > b) ? a : b;
}

stock int min(int a, int b)
{
	return (a < b) ? a : b;
}

stock float fMax(float a, float b)
{
	return (a > b) ? a : b;
}

stock float fMin(float a, float b)
{
	return (a < b) ? a : b;
}

stock void VectorTowards(const float vecOrigin[3], const float vecTarget[3], float vecAngle[3])
{
	float vecResults[3];
	MakeVectorFromPoints(vecOrigin, vecTarget, vecResults);
	GetVectorAngles(vecResults, vecAngle);
}

stock void AnglesToVelocity(const float vecAngle[3], float vecVelocity[3], float flSpeed = 1.0)
{
	GetAngleVectors(vecAngle, vecVelocity, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(vecVelocity, vecVelocity);
	ScaleVector(vecVelocity, flSpeed);
}

// https://github.com/samisalreadytaken/vs_library/blob/2480773c8904c4d6012d2ecf46bfc7c1fbd9fb28/src/vs_math.nut#L1469
stock void RotateVector(const float vecVector[3], const float vecAngle[3], float vecResult[3])
{
	float flSP = Sine(DegToRad(vecAngle[0]));
	float flCP = Cosine(DegToRad(vecAngle[0]));
	float flSY = Sine(DegToRad(vecAngle[1]));
	float flCY = Cosine(DegToRad(vecAngle[1]));
	float flSR = Sine(DegToRad(vecAngle[2]));
	float flCR = Cosine(DegToRad(vecAngle[2]));
	
	float flCRCY = flCR * flCY;
	float flCRSY = flCR * flSY;
	float flSRCY = flSR * flCY;
	float flSRSY = flSR * flSY;
	
	vecResult[0] = (vecVector[0]*flCP*flCY) + vecVector[1] * (flSP*flSRCY-flCRSY) + vecVector[2] * (flSP*flCRCY+flSRSY);
	vecResult[1] = (vecVector[0]*flCP*flSY) + vecVector[1] * (flSP*flSRSY+flCRCY) + vecVector[2] * (flSP*flCRSY-flSRCY);
	vecResult[2] = (vecVector[0]*-flSP) + (vecVector[1]*flSR*flCP) + (vecVector[2]*flCR*flCP);
}

stock void WorldSpaceCenter(int iEntity, float vecCenter[3])
{
	float vecOrigin[3], vecMins[3], vecMaxs[3], vecOffset[3];
	GetEntPropVector(iEntity, Prop_Data, "m_vecAbsOrigin", vecOrigin);
	GetEntPropVector(iEntity, Prop_Data, "m_vecMins", vecMins);
	GetEntPropVector(iEntity, Prop_Data, "m_vecMaxs", vecMaxs);
	
	AddVectors(vecMins, vecMaxs, vecOffset);
	ScaleVector(vecOffset, 0.5);
	
	AddVectors(vecOrigin, vecOffset, vecCenter);
}

////////////////
// SZF Team
////////////////

stock int IsZombie(int iClient)
{
	return TF2_GetClientTeam(iClient) == TFTeam_Zombie;
}

stock int IsSurvivor(int iClient)
{
	return TF2_GetClientTeam(iClient) == TFTeam_Survivor;
}

stock int GetZombieCount()
{
	int iCount = 0;
	for (int iClient = 1; iClient <= MaxClients; iClient++)
		if (IsValidZombie(iClient))
			iCount++;
	
	return iCount;
}

stock int GetSurvivorCount()
{
	int iCount = 0;
	for (int iClient = 1; iClient <= MaxClients; iClient++)
		if (IsValidLivingSurvivor(iClient))
			iCount++;
	
	return iCount;
}

stock int GetActivePlayerCount()
{
	int i = 0;
	for (int iClient = 1; iClient <= MaxClients; iClient++)
		if (IsValidClient(iClient) && TF2_GetClientTeam(iClient) > TFTeam_Spectator)
			i++;
	
	return i;
}

////////////////
// Models
////////////////

//Grabs the entity model by looking in the precache database of the server
void GetEntityModel(int iEntity, char[] sModel, int iMaxSize, char[] sPropName = "m_nModelIndex")
{
	int iIndex = GetEntProp(iEntity, Prop_Send, sPropName);
	GetModelPath(iIndex, sModel, iMaxSize);
}

void GetModelPath(int iIndex, char[] sModel, int iMaxSize)
{
	int iTable = FindStringTable("modelprecache");
	ReadStringTable(iTable, iIndex, sModel, iMaxSize);
}

int GetModelIndex(const char[] sModel)
{
	int iTable = FindStringTable("modelprecache");
	return FindStringIndex(iTable, sModel);
}

stock void AddModelToDownloadsTable(const char[] sModel)
{
	static const char sFileType[][] = {
		"dx80.vtx",
		"dx90.vtx",
		"mdl",
		"phy",
		"vvd",
	};
	
	char sRoot[PLATFORM_MAX_PATH];
	strcopy(sRoot, sizeof(sRoot), sModel);
	ReplaceString(sRoot, sizeof(sRoot), ".mdl", "");
	
	for (int i = 0; i < sizeof(sFileType); i++)
	{
		char sBuffer[PLATFORM_MAX_PATH];
		Format(sBuffer, sizeof(sBuffer), "%s.%s", sRoot, sFileType[i]);
		if (FileExists(sBuffer))
			AddFileToDownloadsTable(sBuffer);
	}
}

stock void PrecacheZombieSouls()
{
	char sPath[64];
	//Loops through all class types available
	for (int iClass = 1; iClass < view_as<int>(TFClass_Engineer) + 1; iClass++)
	{
		Format(sPath, sizeof(sPath), "models/player/items/%s/%s_zombie.mdl", g_sClassFiles[iClass], g_sClassFiles[iClass]);
		g_iZombieSoulIndex[iClass] = PrecacheModel(sPath);
	}
}

stock void ApplyVoodooCursedSoul(int iClient)
{
	if (TF2_IsPlayerInCondition(iClient, TFCond_HalloweenGhostMode))
		return;
	
	//Reset custom models
	SetVariantString("");
	AcceptEntityInput(iClient, "SetCustomModel");
	
	TFClassType nClass = TF2_GetPlayerClass(iClient);
	SetEntProp(iClient, Prop_Send, "m_bForcedSkin", true);
	SetEntProp(iClient, Prop_Send, "m_nForcedSkin", (nClass == TFClass_Spy) ? SKIN_ZOMBIE_SPY : SKIN_ZOMBIE);
	
	int iWearable = CreateVoodooWearable(iClient, nClass);
	if (iWearable != INVALID_ENT_REFERENCE)
		TF2_EquipWeapon(iClient, iWearable);
}

stock int CreateVoodooWearable(int iClient, TFClassType nClass)
{
	int iWearable = TF2_CreateWeapon(iClient, g_iVoodooIndex[view_as<int>(nClass)]); //Not really a weapon, but still works
	if (iWearable != INVALID_ENT_REFERENCE)
		SetEntProp(iWearable, Prop_Send, "m_nModelIndexOverrides", g_iZombieSoulIndex[view_as<int>(nClass)]);
	
	return iWearable;
}

stock int GetClassVoodooItemDefIndex(TFClassType nClass)
{
	return g_iVoodooIndex[nClass];
}

stock void AddWeaponVision(int iWeapon, int iFlag)
{
	//Get current flag and add into it
	float flVal = float(TF_VISION_FILTER_NONE);
	TF2_WeaponFindAttribute(iWeapon, ATTRIB_VISION, flVal);
	flVal = float(RoundToNearest(flVal) | iFlag);
	TF2Attrib_SetByDefIndex(iWeapon, ATTRIB_VISION, flVal);
}

stock void RemoveWeaponVision(int iWeapon, int iFlag)
{
	//If have vision, get current flag and remove it
	float flVal = float(TF_VISION_FILTER_NONE);
	if (!TF2_WeaponFindAttribute(iWeapon, ATTRIB_VISION, flVal))
		return;
	
	flVal = float(RoundToNearest(flVal) & ~iFlag);
	TF2Attrib_SetByDefIndex(iWeapon, ATTRIB_VISION, flVal);
}

stock void PrecacheSound2(const char[] sSoundPath)
{
	char sBuffer[PLATFORM_MAX_PATH];
	strcopy(sBuffer, sizeof(sBuffer), sSoundPath);
	PrecacheSound(sBuffer, true);
	
	if (sBuffer[0] == '#')
		strcopy(sBuffer, sizeof(sBuffer), sBuffer[1]);	//Remove '#' from start of string
	
	Format(sBuffer, sizeof(sBuffer), "sound/%s", sBuffer);
	AddFileToDownloadsTable(sBuffer);
}

int CreateBonemerge(int iEntity, const char[] sAttachment = NULL_STRING)
{
	int iProp = CreateEntityByName("tf_taunt_prop");
	
	int iTeam = GetEntProp(iEntity, Prop_Send, "m_iTeamNum");
	SetEntProp(iProp, Prop_Data, "m_iInitialTeamNum", iTeam);
	SetEntProp(iProp, Prop_Send, "m_iTeamNum", iTeam);
	SetEntProp(iProp, Prop_Send, "m_nSkin", GetEntProp(iEntity, Prop_Send, "m_nSkin"));
	
	char sModel[PLATFORM_MAX_PATH];
	GetEntPropString(iEntity, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
	SetEntityModel(iProp, sModel);
	
	DispatchSpawn(iProp);
	
	SetEntPropEnt(iProp, Prop_Data, "m_hEffectEntity", iEntity);
	//SetEntProp(iProp, Prop_Send, "m_fEffects", GetEntProp(iProp, Prop_Send, "m_fEffects")|EF_BONEMERGE|EF_NOSHADOW|EF_NOINTERP);
	SetEntProp(iProp, Prop_Send, "m_fEffects", EF_BONEMERGE|EF_NOSHADOW|EF_NORECEIVESHADOW|EF_NOINTERP);
	
	SetVariantString("!activator");
	AcceptEntityInput(iProp, "SetParent", iEntity);
	
	if (sAttachment[0])
	{
		SetVariantString(sAttachment);
		AcceptEntityInput(iProp, "SetParentAttachmentMaintainOffset");
	}
	
	SetEntityRenderMode(iProp, RENDER_TRANSCOLOR);
	SetEntityRenderColor(iProp, 0, 0, 0, 0);
	return iProp;
}

////////////////
// SZF Class
////////////////

stock void TF2_GetClassName(char[] sBuffer, int iLength, int iClass)
{
	strcopy(sBuffer, iLength, g_sClassNames[iClass]);
}

stock void GetInfectedName(char[] sBuffer, int iLength, int iInfected)
{
	strcopy(sBuffer, iLength, g_sInfectedNames[iInfected]);
}

stock Infected GetInfected(const char[] sBuffer)
{
	for (int i; i < sizeof(g_sInfectedNames); i++)
		if (StrEqual(sBuffer, g_sInfectedNames[i], false))
			return view_as<Infected>(i);
	
	return Infected_Unknown;
}

////////////////
// Client Validity
////////////////

stock bool IsValidClient(int iClient)
{
	return 0 < iClient <= MaxClients && IsClientInGame(iClient) && !IsClientSourceTV(iClient) && !IsClientReplay(iClient);
}

stock bool IsValidSurvivor(int iClient)
{
	return IsValidClient(iClient) && IsSurvivor(iClient);
}

stock bool IsValidZombie(int iClient)
{
	return IsValidClient(iClient) && IsZombie(iClient);
}

stock bool IsValidLivingClient(int iClient)
{
	return IsValidClient(iClient) && IsPlayerAlive(iClient);
}

stock bool IsValidLivingSurvivor(int iClient)
{
	return IsValidSurvivor(iClient) && IsPlayerAlive(iClient);
}

stock bool IsValidLivingZombie(int iClient)
{
	return IsValidZombie(iClient) && IsPlayerAlive(iClient);
}

////////////////
// Map
////////////////

stock bool IsMapSZF()
{
	char sMap[PLATFORM_MAX_PATH];
	GetCurrentMap(sMap, sizeof(sMap));
	GetMapDisplayName(sMap, sMap, sizeof(sMap));
	
	if (StrContains(sMap, "zf_") == 0 || StrContains(sMap, "szf_") == 0)
		return true;
	
	return false;
}

stock void FireRelay(const char[] sInput, const char[] sTargetName1, const char[] sTargetName2 = "", int iActivator = -1)
{
	char sTargetName[255];
	int iEntity;
	while ((iEntity = FindEntityByClassname(iEntity, "logic_relay")) != -1)
	{
		GetEntPropString(iEntity, Prop_Data, "m_iName", sTargetName, sizeof(sTargetName));
		if (StrEqual(sTargetName1, sTargetName) || (sTargetName2[0] && StrEqual(sTargetName2, sTargetName)))
			AcceptEntityInput(iEntity, sInput, iActivator, iActivator);
	}
}

stock int GetCapturePointFromTrigger(int iTrigger)
{
	char sTriggerName[128];
	GetEntPropString(iTrigger, Prop_Data, "m_iszCapPointName", sTriggerName, sizeof(sTriggerName));	//Get trigger cap name
	
	int iCP = INVALID_ENT_REFERENCE;
	while ((iCP = FindEntityByClassname(iCP, "team_control_point")) != INVALID_ENT_REFERENCE)	//find team_control_point
	{
		char sPointName[128];
		GetEntPropString(iCP, Prop_Data, "m_iName", sPointName, sizeof(sPointName));
		if (strcmp(sPointName, sTriggerName, false) == 0)	//Check if trigger cap is the same as team_control_point
			return iCP;
	}
	
	return INVALID_ENT_REFERENCE;
}

stock void GetCurrentMapDisplayName(char[] sBuffer, int iLength)
{
	GetCurrentMap(sBuffer, iLength);
	GetMapDisplayName(sBuffer, sBuffer, iLength);
}

////////////////
// Round
////////////////

stock void TF2_EndRound(TFTeam nTeam)
{
	int iIndex = CreateEntityByName("game_round_win");
	DispatchKeyValue(iIndex, "force_map_reset", "1");
	DispatchSpawn(iIndex);
	
	if (iIndex == -1)
	{
		LogError("[SZF] Can't create 'game_round_win', can't end round!");
	}
	else
	{
		SetVariantInt(view_as<int>(nTeam));
		AcceptEntityInput(iIndex, "SetTeam");
		AcceptEntityInput(iIndex, "RoundWin");
	}
}

////////////////
// Weapon State
////////////////

stock bool TF2_IsEquipped(int iClient, int iIndex)
{
	for (int iSlot = 0; iSlot <= WeaponSlot_BuilderEngie; iSlot++)
	{
		int iWeapon = TF2_GetItemInSlot(iClient, iSlot);
		if (iWeapon > MaxClients && GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex") == iIndex)
			return true;
	}
	
	return false;
}

stock bool TF2_IsWielding(int iClient, int iIndex)
{
	int iWeapon = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
	if (iWeapon > MaxClients)
		return GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex") == iIndex;
	
	return false;
}

stock void TF2_SwitchActiveWeapon(int iClient, int iWeapon)
{
	char sClassname[256];
	GetEntityClassname(iWeapon, sClassname, sizeof(sClassname));
	FakeClientCommand(iClient, "use %s", sClassname);
}

stock bool TF2_IsSlotClassname(int iClient, int iSlot, char[] sClassname)
{
	int iWeapon = GetPlayerWeaponSlot(iClient, iSlot);
	if (iWeapon > MaxClients && IsValidEdict(iWeapon))
	{
		char sClassname2[32];
		GetEdictClassname(iWeapon, sClassname2, sizeof(sClassname2));
		if (StrEqual(sClassname, sClassname2))
			return true;
	}
	
	return false;
}

stock bool IsRazorbackActive(int iClient)
{
	int iEntity = -1;
	while ((iEntity = FindEntityByClassname(iEntity, "tf_wearable_razorback")) != -1)
		if (IsClassname(iEntity, "tf_wearable_razorback") && GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity") == iClient && GetEntProp(iEntity, Prop_Send, "m_iItemDefinitionIndex") == 57)
			return GetEntPropFloat(iClient, Prop_Send, "m_flItemChargeMeter", TFWeaponSlot_Secondary) >= 100.0;
	
	return false;
}

stock int TF2_GetItemSlot(int iIndex, TFClassType iClass = TFClass_Unknown)
{
	int iSlot = -1;
	if (iClass == TFClass_Unknown)
		iSlot = TF2Econ_GetItemDefaultLoadoutSlot(iIndex);
	else
		iSlot = TF2Econ_GetItemLoadoutSlot(iIndex, iClass);
	
	if (iSlot >= 0)
	{
		// Econ reports wrong slots for Engineer and Spy
		
		switch (iSlot)
		{
			case 5: return WeaponSlot_PDABuild; // Construction PDA and Disguise Kit
			case 6: return WeaponSlot_PDADestroy; // Destruction PDA and Invis Watch
		}
		
		switch (iClass)
		{
			case TFClass_Spy:
			{
				switch (iSlot)
				{
					case 1: return WeaponSlot_Primary; // Revolver
					case 4: return WeaponSlot_Secondary; // Sapper
				}
			}
			
			case TFClass_Engineer:
			{
				switch (iSlot)
				{
					case 4: return WeaponSlot_BuilderEngie; // Toolbox
				}
			}
		}
		
		return iSlot;
	}
	
	return -1;
}

stock int TF2_GetItemInSlot(int iClient, int iSlot)
{
	int iEntity = GetPlayerWeaponSlot(iClient, iSlot);
	if (iEntity > MaxClients)
		return iEntity;
	
	iEntity = SDKCall_GetEquippedWearable(iClient, iSlot);
	if (iEntity > MaxClients)
		return iEntity;
	
	return -1;
}

stock void TF2_RemoveItemInSlot(int iClient, int iSlot)
{
	int iEntity = GetPlayerWeaponSlot(iClient, iSlot);
	if (iEntity > MaxClients)
		TF2_RemoveWeaponSlot(iClient, iSlot);
	
	int iWearable = SDKCall_GetEquippedWearable(iClient, iSlot);
	if (iWearable > MaxClients)
		TF2_RemoveWearable(iClient, iWearable);
}

stock void SetNextAttack(int iClient, float flDuration, bool bMeleeOnly = true)
{
	if (!IsValidClient(iClient))
		return;
	
	//Primary, secondary and melee
	for (int iSlot = WeaponSlot_Primary; iSlot <= WeaponSlot_Melee; iSlot++)
	{
		if (bMeleeOnly && iSlot < WeaponSlot_Melee)
			continue;
		
		int iWeapon = GetPlayerWeaponSlot(iClient, iSlot);
		if (iWeapon > MaxClients && IsValidEntity(iWeapon))
		{
			SetEntPropFloat(iWeapon, Prop_Send, "m_flNextPrimaryAttack", flDuration);
			SetEntPropFloat(iWeapon, Prop_Send, "m_flNextSecondaryAttack", flDuration);
		}
	}
}

////////////////
// Entities
////////////////

stock bool IsClassname(int iEntity, const char[] sClassname)
{
	if (iEntity > MaxClients)
	{
		char sClassname2[256];
		GetEntityClassname(iEntity, sClassname2, sizeof(sClassname2));
		return (StrEqual(sClassname2, sClassname));
	}
	
	return false;
}

stock int GetChildEntity(int iEntity, const char[] sClassname)
{
	int iOther = INVALID_ENT_REFERENCE;
	while ((iOther = FindEntityByClassname(iOther, sClassname)) != INVALID_ENT_REFERENCE)
	{
		if (GetEntPropEnt(iOther, Prop_Send, "moveparent") == iEntity)
			return iOther;
	}
	
	return INVALID_ENT_REFERENCE;
}

stock void AddEntityEffect(int iEntity, int iFlag)
{
	SetEntProp(iEntity, Prop_Send, "m_fEffects", GetEntProp(iEntity, Prop_Send, "m_fEffects") | iFlag);
}

stock void RemoveEntityEffect(int iEntity, int iFlag)
{
	SetEntProp(iEntity, Prop_Send, "m_fEffects", GetEntProp(iEntity, Prop_Send, "m_fEffects") & ~iFlag);
}

stock float DistanceFromEntityToPoint(int iEntity, const float vecOrigin[3])
{
	float vecOther[3];
	GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", vecOther);
	return GetVectorDistance(vecOther, vecOrigin);
}

stock float DistanceFromEntities(int iEntity1, int iEntity2)
{
	float vecOrigin1[3], vecOrigin2[3];
	GetEntPropVector(iEntity1, Prop_Send, "m_vecOrigin", vecOrigin1);
	GetEntPropVector(iEntity2, Prop_Send, "m_vecOrigin", vecOrigin2);
	return GetVectorDistance(vecOrigin1, vecOrigin2);
}

////////////////
// Cloak
////////////////

stock float TF2_GetCloakMeter(int iClient)
{
	return GetEntPropFloat(iClient, Prop_Send, "m_flCloakMeter");
}

stock void TF2_SetCloakMeter(int iClient, float flCloak)
{
	SetEntPropFloat(iClient, Prop_Send, "m_flCloakMeter", flCloak);
}

////////////////
// Ammo
////////////////

stock int TF2_GetAmmo(int iClient, int iSlot)
{
	int iWeapon = GetPlayerWeaponSlot(iClient, iSlot);
	if (iWeapon > MaxClients)
	{
		int iAmmoType = GetEntProp(iWeapon, Prop_Send, "m_iPrimaryAmmoType");
		if (iAmmoType > -1)
			return GetEntProp(iClient, Prop_Send, "m_iAmmo", _, iAmmoType);
	}
	
	return 0;
}

stock void TF2_SetAmmo(int iClient, int iSlot, int iAmmo)
{
	int iWeapon = GetPlayerWeaponSlot(iClient, iSlot);
	if (iWeapon > 0)
	{
		int iAmmoType = GetEntProp(iWeapon, Prop_Send, "m_iPrimaryAmmoType");
		if (iAmmoType > -1)
			SetEntProp(iClient, Prop_Send, "m_iAmmo", iAmmo, _, iAmmoType);
	}
}

stock void TF2_AddAmmo(int iClient, int iSlot, int iAmmo)
{
	iAmmo += TF2_GetAmmo(iClient, iSlot);
	TF2_SetAmmo(iClient, iSlot, iAmmo);
}

stock void TF2_SetMetal(int iClient, int iMetal)
{
	SetEntProp(iClient, Prop_Send, "m_iAmmo", iMetal, _, 3);
}

public Action Timer_UpdateClientHud(Handle timer, int serial)
{
	int client = GetClientFromSerial(serial);
	if (0 < client <= MaxClients)
	{
		//Call client to reset HUD meter
		Event event = CreateEvent("localplayer_pickup_weapon", true);
		event.FireToClient(client);
		event.Cancel();
	}
	
	return Plugin_Continue;
}

////////////////
// Spawn
////////////////

stock void SpawnClient(int iClient, TFTeam nTeam, bool bRespawn = true)
{
	//1. Prevent players from spawning if they're on an invalid team.
	//        Prevent players from spawning as an invalid class.
	if (IsClientInGame(iClient) && (IsSurvivor(iClient) || IsZombie(iClient)))
	{
		TFClassType nClass = TF2_GetPlayerClass(iClient);
		if (nTeam == TFTeam_Zombie && !IsValidZombieClass(nClass))
			nClass = GetRandomZombieClass();
		
		if (nTeam == TFTeam_Survivor && !IsValidSurvivorClass(nClass))
			nClass = GetRandomSurvivorClass();
		
		//Use of m_lifeState here prevents:
		//1. "[Player] Suicided" messages.
		//2. Adding a death to player stats.
		SetEntProp(iClient, Prop_Send, "m_lifeState", 2);
		TF2_SetPlayerClass(iClient, nClass);
		TF2_ChangeClientTeam(iClient, nTeam);
		SetEntProp(iClient, Prop_Send, "m_lifeState", 0);
		
		Classes_SetClient(iClient);
		
		if (bRespawn)
			TF2_RespawnPlayer(iClient);
	}
}

stock void TF2_RespawnPlayer2(int iClient)
{
	TFClassType nClass = TF2_GetPlayerClass(iClient);
	TFTeam nTeam = TF2_GetClientTeam(iClient);
	
	if (nTeam == TFTeam_Zombie && !IsValidZombieClass(nClass))
		TF2_SetPlayerClass(iClient, GetRandomZombieClass());
		
	if (nTeam == TFTeam_Survivor && !IsValidSurvivorClass(nClass))
		TF2_SetPlayerClass(iClient, GetRandomSurvivorClass());
	
	Classes_SetClient(iClient);
	
	TF2_RespawnPlayer(iClient);
}

stock void SetTeamRespawnTime(TFTeam nTeam, float flTime)
{
	int iEntity = FindEntityByClassname(-1, "tf_gamerules");
	if (iEntity != -1)
	{
		SetVariantFloat(flTime/2.0);
		switch (nTeam)
		{
			case TFTeam_Blue: AcceptEntityInput(iEntity, "SetBlueTeamRespawnWaveTime", -1, -1, 0);
			case TFTeam_Red: AcceptEntityInput(iEntity, "SetRedTeamRespawnWaveTime", -1, -1, 0);
		}
	}
}

////////////////
// Weapon
////////////////

static ConfigAttributes g_AttribsNone;

stock int TF2_CreateWeapon(int iClient, int iIndex, ConfigAttributes attribs = g_AttribsNone, bool bAllowReskin = false)
{
	TFClassType iClass = TF2_GetPlayerClass(iClient);
	char sClassname[256];
	TF2Econ_GetItemClassName(iIndex, sClassname, sizeof(sClassname));
	TF2Econ_TranslateWeaponEntForClass(sClassname, sizeof(sClassname), iClass);
	
	int iSubType;
	if ((StrEqual(sClassname, "tf_weapon_builder") || StrEqual(sClassname, "tf_weapon_sapper")) && iClass == TFClass_Spy)
	{
		iSubType = view_as<int>(TFObject_Sapper);
		
		//Apparently tf_weapon_sapper causes client crashes
		sClassname = "tf_weapon_builder";
	}
	
	int iWeapon = -1;
	
	if (bAllowReskin)
	{
		int iSlot = TF2Econ_GetItemLoadoutSlot(iIndex, iClass);	//Uses econ slot
		Address pItem = SDKCall_GetLoadoutItem(iClient, iClass, iSlot);
		
		if (pItem && Config_GetOriginalItemDefIndex(LoadFromAddress(pItem+view_as<Address>(g_iOffsetItemDefinitionIndex), NumberType_Int16)) == iIndex)
			iWeapon = SDKCall_GiveNamedItem(iClient, sClassname, iSubType, pItem);
	}
	
	if (iWeapon == -1)
	{
		iWeapon = CreateEntityByName(sClassname);
		if (IsValidEntity(iWeapon))
		{
			SetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex", iIndex);
			SetEntProp(iWeapon, Prop_Send, "m_bInitialized", true);
			SetEntProp(iWeapon, Prop_Send, "m_iEntityQuality", 0);
			SetEntProp(iWeapon, Prop_Send, "m_iEntityLevel", 1);
			
			if (iSubType)
			{
				SetEntProp(iWeapon, Prop_Send, "m_iObjectType", iSubType);
				SetEntProp(iWeapon, Prop_Data, "m_iSubType", iSubType);
			}
		}
	}
	
	if (IsValidEntity(iWeapon))
	{
		TF2_WeaponApplyAttribute(iClient, iWeapon, attribs);
		DispatchSpawn(iWeapon);
	}
	
	return iWeapon;
}

stock void TF2_EquipWeapon(int iClient, int iWeapon)
{
	SetEntProp(iWeapon, Prop_Send, "m_bValidatedAttachedEntity", true);
	
	char sClassname[256];
	GetEntityClassname(iWeapon, sClassname, sizeof(sClassname));
	if (StrContains(sClassname, "tf_wearable") == 0)
		SDKCall_EquipWearable(iClient, iWeapon);
	else
		EquipPlayerWeapon(iClient, iWeapon);
}

stock int TF2_CreateAndEquipWeapon(int iClient, int iIndex, ConfigAttributes attribs = g_AttribsNone, bool bAllowReskin = false)
{
	int iWeapon = TF2_CreateWeapon(iClient, iIndex, attribs, bAllowReskin);
	if (iWeapon == INVALID_ENT_REFERENCE)
		return iWeapon;
	
	TF2_EquipWeapon(iClient, iWeapon);
	
	return iWeapon;
}

stock void TF2_WeaponApplyAttribute(int iClient, int iWeapon, ConfigAttributes attribs)
{
	TFClassType nClass = TF2_GetPlayerClass(iClient);
	
	for (int i = 0; i < attribs.iCount; i++)
	{
		if (!attribs.nClass[i] || attribs.nClass[i] == nClass)
			TF2Attrib_SetByDefIndex(iWeapon, attribs.iIndex[i], attribs.flValue[i]);
	}
}

stock bool TF2_WeaponFindAttribute(int iWeapon, int iAttrib, float &flVal)
{
	Address addAttrib = TF2Attrib_GetByDefIndex(iWeapon, iAttrib);
	if (addAttrib == Address_Null)
		return TF2_DefIndexFindAttribute(GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex"), iAttrib, flVal);
	
	flVal = TF2Attrib_GetValue(addAttrib);
	
	return true;
}

stock void TF2_RemoveAllAttributes(int iClient)
{
	for (int iSlot = 1; iSlot <= WeaponSlot_BuilderEngie; iSlot++)
	{
		int iWeapon = TF2_GetItemInSlot(iClient, iSlot);
		if (iWeapon != INVALID_ENT_REFERENCE)
			TF2Attrib_RemoveAll(iWeapon);
	}
}

stock bool TF2_DefIndexFindAttribute(int iDefIndex, int iAttrib, float &flVal)
{
	ArrayList attribs = TF2Econ_GetItemStaticAttributes(iDefIndex);
	
	int iLength = attribs.Length;
	for (int i = 0; i < iLength; i++)
	{
		if (attribs.Get(i, 0) == iAttrib)
		{
			flVal = attribs.Get(i, 1);
			
			delete attribs;
			return true;
		}
	}
	
	delete attribs;
	return false;
}

stock float TF2_TranslateAttributeValue(int iIndex, float flValue)
{
	enum
	{
		ATTDESCFORM_VALUE_IS_PERCENTAGE,			// Printed as:	((m_flValue*100)-100.0)
		ATTDESCFORM_VALUE_IS_INVERTED_PERCENTAGE,	// Printed as:	((m_flValue*100)-100.0) if it's > 1.0, or ((1.0-m_flModifier)*100) if it's < 1.0
		ATTDESCFORM_VALUE_IS_ADDITIVE,				// Printed as:	m_flValue
		ATTDESCFORM_VALUE_IS_ADDITIVE_PERCENTAGE,	// Printed as:	(m_flValue*100)
		ATTDESCFORM_VALUE_IS_OR,					// Printed as:  m_flValue, but results are ORd together instead of added
		ATTDESCFORM_VALUE_IS_DATE,					// Printed as a date
		ATTDESCFORM_VALUE_IS_ACCOUNT_ID,			// Printed as steam user name
		ATTDESCFORM_VALUE_IS_PARTICLE_INDEX,		// Printed as a particle description
		ATTDESCFORM_VALUE_IS_KILLSTREAKEFFECT_INDEX,// Printed as killstreak effect description
		ATTDESCFORM_VALUE_IS_KILLSTREAK_IDLEEFFECT_INDEX,  // Printed as idle effect description
		ATTDESCFORM_VALUE_IS_ITEM_DEF,				// Printed as item name
		ATTDESCFORM_VALUE_IS_FROM_LOOKUP_TABLE,		// Printed as a string from a lookup table, specified by the attribute definition name
	};
	
	Address pAttrib = TF2Econ_GetAttributeDefinitionAddress(iIndex);
	int iFormat = LoadFromAddress(pAttrib + view_as<Address>(0x24), NumberType_Int32);
	
	switch (iFormat)
	{
		case ATTDESCFORM_VALUE_IS_PERCENTAGE: return (flValue * 100.0) - 100.0;
		case ATTDESCFORM_VALUE_IS_INVERTED_PERCENTAGE: return flValue > 1.0 ? (flValue * 100.0) - 100.0 : (1.0 - flValue) * 100.0;
		case ATTDESCFORM_VALUE_IS_ADDITIVE: return flValue;
		case ATTDESCFORM_VALUE_IS_ADDITIVE_PERCENTAGE: return flValue * 100.0;
		case ATTDESCFORM_VALUE_IS_OR: return flValue;
	}
	
	return 0.0;
}

stock void CheckClientWeapons(int iClient)
{
	//Weapons
	for (int iSlot = WeaponSlot_Primary; iSlot <= WeaponSlot_BuilderEngie; iSlot++)
	{
		int iWeapon = GetPlayerWeaponSlot(iClient, iSlot);
		if (iWeapon > MaxClients)
		{
			int iIndex = GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex");
			if (OnGiveNamedItem(iClient, iIndex) >= Plugin_Handled)
				TF2_RemoveItemInSlot(iClient, iSlot);
		}
	}
	
	//Cosmetics
	int iWearable = MaxClients+1;
	while ((iWearable = FindEntityByClassname(iWearable, "tf_wearable*")) > MaxClients)
	{
		if (GetEntPropEnt(iWearable, Prop_Send, "m_hOwnerEntity") == iClient || GetEntPropEnt(iWearable, Prop_Send, "moveparent") == iClient)
		{
			int iIndex = GetEntProp(iWearable, Prop_Send, "m_iItemDefinitionIndex");
			if (OnGiveNamedItem(iClient, iIndex) >= Plugin_Handled)
				TF2_RemoveWearable(iClient, iWearable);
		}
	}
	
	//MvM Canteen
	int iPowerupBottle = MaxClients+1;
	while ((iPowerupBottle = FindEntityByClassname(iPowerupBottle, "tf_powerup_bottle*")) > MaxClients)
	{
		if (GetEntPropEnt(iPowerupBottle, Prop_Send, "m_hOwnerEntity") == iClient || GetEntPropEnt(iPowerupBottle, Prop_Send, "moveparent") == iClient)
		{
			if (OnGiveNamedItem(iClient, GetEntProp(iPowerupBottle, Prop_Send, "m_iItemDefinitionIndex")) >= Plugin_Handled)
				TF2_RemoveWearable(iClient, iPowerupBottle);
		}
	}
}

stock int TF2_GetBuilding(int iClient, TFObjectType nType, TFObjectMode nMode = TFObjectMode_None)
{
	int iBuilding = MaxClients+1;
	while ((iBuilding = FindEntityByClassname(iBuilding, "obj_*")) > MaxClients)
	{
		if (GetEntPropEnt(iBuilding, Prop_Send, "m_hBuilder") == iClient
			&& view_as<TFObjectType>(GetEntProp(iBuilding, Prop_Send, "m_iObjectType")) == nType
			&& view_as<TFObjectMode>(GetEntProp(iBuilding, Prop_Send, "m_iObjectMode")) == nMode)
		{
			return iBuilding;
		}
	}
	
	return INVALID_ENT_REFERENCE;
}

////////////////
// Cookie
////////////////

stock int GetCookie(int iClient, Cookie cookie)
{
	if (!IsClientConnected(iClient) || !AreClientCookiesCached(iClient))
		return 0;
	
	char sValue[8];
	cookie.Get(iClient, sValue, sizeof(sValue));
	return StringToInt(sValue);
}

stock void AddToCookie(int iClient, int iAmount, Cookie cookie)
{
	if (!IsClientConnected(iClient) || !AreClientCookiesCached(iClient))
		return;
	
	char sValue[8];
	cookie.Get(iClient, sValue, sizeof(sValue));
	iAmount += StringToInt(sValue);
	IntToString(iAmount, sValue, sizeof(sValue));
	cookie.Set(iClient, sValue);
}

stock void SetCookie(int iClient, int iAmount, Cookie cookie)
{
	if (!IsClientConnected(iClient) || !AreClientCookiesCached(iClient))
		return;
	
	char sValue[8];
	IntToString(iAmount, sValue, sizeof(sValue));
	cookie.Set(iClient, sValue);
}

////////////////
// Trace
////////////////

stock bool PointsAtTarget(float vecPos[3], any iTarget)
{
	float vecTargetPos[3];
	GetClientEyePosition(iTarget, vecTargetPos);
	
	Handle hTrace = TR_TraceRayFilterEx(vecPos, vecTargetPos, MASK_VISIBLE, RayType_EndPoint, Trace_DontHitOtherEntities, iTarget);
	
	int iHit = -1;
	if (TR_DidHit(hTrace))
		iHit = TR_GetEntityIndex(hTrace);
	
	delete hTrace;
	return (iHit == iTarget);
}

stock int GetClientPointVisible(int iClient, float flDistance = 100.0)
{
	float vecOrigin[3], vecAngles[3], vecEndOrigin[3];
	GetClientEyePosition(iClient, vecOrigin);
	GetClientEyeAngles(iClient, vecAngles);
	
	Handle hTrace = TR_TraceRayFilterEx(vecOrigin, vecAngles, MASK_ALL, RayType_Infinite, Trace_DontHitEntity, iClient);
	TR_GetEndPosition(vecEndOrigin, hTrace);
	
	int iReturn = -1;
	int iHit = TR_GetEntityIndex(hTrace);
	
	if (TR_DidHit(hTrace) && iHit != iClient && GetVectorDistance(vecOrigin, vecEndOrigin) < flDistance)
		iReturn = iHit;
	
	delete hTrace;
	return iReturn;
}

stock bool ObstactleBetweenEntities(int iEntity1, int iEntity2)
{
	float vecOrigin1[3];
	float vecOrigin2[3];
	
	if (IsValidClient(iEntity1))
		GetClientEyePosition(iEntity1, vecOrigin1);
	else
		GetEntPropVector(iEntity1, Prop_Send, "m_vecOrigin", vecOrigin1);
	
	GetEntPropVector(iEntity2, Prop_Send, "m_vecOrigin", vecOrigin2);
	
	Handle hTrace = TR_TraceRayFilterEx(vecOrigin1, vecOrigin2, MASK_ALL, RayType_EndPoint, Trace_DontHitEntity, iEntity1);
	
	bool bHit = TR_DidHit(hTrace);
	int iHit = TR_GetEntityIndex(hTrace);
	delete hTrace;
	
	if (!bHit || iHit != iEntity2)
		return true;
	
	return false;
}

stock bool IsEntityStuck(int iEntity)
{
	float vecOrigin[3], vecMins[3], vecMaxs[3];
	GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", vecOrigin);
	GetEntPropVector(iEntity, Prop_Send, "m_vecMins", vecMins);
	GetEntPropVector(iEntity, Prop_Send, "m_vecMaxs", vecMaxs);
	
	TR_TraceHullFilter(vecOrigin, vecOrigin, vecMins, vecMaxs, MASK_SOLID, Trace_DontHitEntity, iEntity);
	return (TR_DidHit());
}

stock void GetEntityCenterPoint(int iEntity, float vecResult[3])
{
	float vecOrigin[3], vecMins[3], vecMaxs[3];
	GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", vecOrigin);
	GetEntPropVector(iEntity, Prop_Send, "m_vecMins", vecMins);
	GetEntPropVector(iEntity, Prop_Send, "m_vecMaxs", vecMaxs);
	
	AddVectors(vecMins, vecMaxs, vecResult);
	ScaleVector(vecResult, 0.5);
	AddVectors(vecResult, vecOrigin, vecResult);
}

bool Trace_DontHitOtherEntities(int iEntity, int iMask, any iData)
{
	if (iEntity == iData)
		return true;
	
	if (iEntity > 0)
		return false;
	
	return true;
}

bool Trace_DontHitEntity(int iEntity, int iMask, any iData)
{
	if (iEntity == iData)
		return false;
	
	return true;
}

bool Trace_DontHitClients(int iEntity, int iMask, any iData)
{
	return iEntity <= 0 || iEntity > MaxClients;
}

bool Trace_DontHitTeammates(int iEntity, int iMask, any iData)
{
	if (iEntity <= 0 || iEntity > MaxClients)
		return true;
	
	return GetClientTeam(iEntity) != GetClientTeam(iData);
}

////////////////
// Particles
////////////////

stock int ShowParticle(const char[] sParticle, float flDuration, float vecPos[3], float vecAngles[3] = NULL_VECTOR)
{
	int iParticle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(iParticle))
	{
		TeleportEntity(iParticle, vecPos, vecAngles, NULL_VECTOR);
		DispatchKeyValue(iParticle, "effect_name", sParticle);
		ActivateEntity(iParticle);
		AcceptEntityInput(iParticle, "start");
		CreateTimer(flDuration, Timer_RemoveParticle, iParticle);
	}
	else
	{
		LogError("ShowParticle: could not create info_particle_system");
		return -1;
	}
	
	return iParticle;
}

stock void AttachParticle(int iEntity, const char[] sParticle)
{
	// find string table
	int iTable = FindStringTable("ParticleEffectNames");
	if (iTable == INVALID_STRING_TABLE)
		return;
	
	// find particle index
	char sBuffer[256];
	int iCount = GetStringTableNumStrings(iTable);
	int iIndex = INVALID_STRING_INDEX;
	for (int i; i < iCount; i++)
	{
		ReadStringTable(iTable, i, sBuffer, sizeof(sBuffer));
		if (StrEqual(sBuffer, sParticle, false))
		{
			iIndex = i;
			break;
		}
	}

	if (iIndex == INVALID_STRING_INDEX)
		return;
	
	TE_Start("TFParticleEffect");
	TE_WriteFloat("m_vecOrigin[0]", 100000.0);
	TE_WriteFloat("m_vecOrigin[1]", 100000.0);
	TE_WriteFloat("m_vecOrigin[2]", 100000.0);
	TE_WriteNum("m_iParticleSystemIndex", iIndex);

	TE_WriteNum("entindex", iEntity);
	TE_WriteNum("m_iAttachType", -1);
	TE_WriteNum("m_iAttachmentPointIndex", 6);
	TE_WriteNum("m_bResetParticles", false);

	TE_SendToAll(0.0);
}

stock void PrecacheParticle(char[] sParticleName)
{
	if (IsValidEntity(0))
	{
		int iParticle = CreateEntityByName("info_particle_system");
		if (IsValidEdict(iParticle))
		{
			char sName[32];
			GetEntPropString(0, Prop_Data, "m_iName", sName, sizeof(sName));
			DispatchKeyValue(iParticle, "targetname", "tf2particle");
			DispatchKeyValue(iParticle, "parentname", sName);
			DispatchKeyValue(iParticle, "effect_name", sParticleName);
			DispatchSpawn(iParticle);
			SetVariantString(sName);
			AcceptEntityInput(iParticle, "SetParent", 0, iParticle, 0);
			ActivateEntity(iParticle);
			AcceptEntityInput(iParticle, "start");
			CreateTimer(0.01, Timer_RemoveParticle, iParticle);
		}
	}
}

public Action Timer_RemoveParticle(Handle hTimer, int iParticle)
{
	if (iParticle >= 0 && IsValidEntity(iParticle))
	{
		char sClassname[32];
		GetEdictClassname(iParticle, sClassname, sizeof(sClassname));
		if (StrEqual(sClassname, "info_particle_system", false))
		{
			AcceptEntityInput(iParticle, "stop");
			RemoveEntity(iParticle);
			iParticle = -1;
		}
	}
	
	return Plugin_Continue;
}

/******************************************************************************************************/

stock void StrToLower(const char[] sInput, char[] sOutput, int iLength)
{
	iLength = strlen(sInput) > iLength ? iLength : strlen(sInput);
	for (int i = 0; i < iLength; i++)
		sOutput[i] = CharToLower(sInput[i]);
}

stock void GetClientName2(int iClient, char[] sName, int iLength)
{
	Forward_GetClientName(iClient, sName, iLength);
	
	//If name still empty or could not be found, use default name and team color instead
	if (sName[0] == '\0')
	{
		GetClientName(iClient, sName, iLength);
		Format(sName, iLength, "{teamcolor}%s", sName);
	}
}

stock void Shake(int iClient, float flAmplitude, float flDuration)
{
	BfWrite bf = UserMessageToBfWrite(StartMessageOne("Shake", iClient));
	bf.WriteByte(0); //0x0000 = start shake
	bf.WriteFloat(flAmplitude);
	bf.WriteFloat(1.0);
	bf.WriteFloat(flDuration);
	EndMessage();
}

public Action Timer_KillEntity(Handle hTimer, int iRef)
{
	int iEntity = EntRefToEntIndex(iRef);
	if (IsValidEntity(iEntity))
		RemoveEntity(iEntity);
	
	return Plugin_Continue;
}

//Yoinked from https://github.com/DFS-Servers/Super-Zombie-Fortress/blob/master/addons/sourcemod/scripting/include/szf_util_base.inc
stock void CPrintToChatTranslation(int iClient, int iCaller, char[] sText, bool bTeam = false, const char[] sParam1="", const char[] sParam2="", const char[] sParam3="", const char[] sParam4="")
{
	if (bTeam && !IsValidClient(iCaller))
		return;
	
	char sName[256], sMessage[256];
	if (0 < iCaller <= MaxClients)
	{
		GetClientName2(iCaller, sName, sizeof(sName));
		if (bTeam)
			Format(sMessage, sizeof(sMessage), "\x01(TEAM) %s\x01 : %s", sName, sText);
		else
			Format(sMessage, sizeof(sMessage), "\x01%s\x01 : %s\x01", sName, sText);
	}
	
	ReplaceString(sMessage, sizeof(sMessage), "{param1}", "%s1");
	ReplaceString(sMessage, sizeof(sMessage), "{param2}", "%s2");
	ReplaceString(sMessage, sizeof(sMessage), "{param3}", "%s3");
	ReplaceString(sMessage, sizeof(sMessage), "{param4}", "%s4");
	CReplaceColorCodes(sMessage, iCaller, _, sizeof(sMessage));
	
	int iClients[1];
	iClients[0] = iClient;
	SayText2(iClients, 1, iClient, true, sMessage, sParam1, sParam2, sParam3, sParam4);
}

stock void SayText2(int[] iClients, int iLength, int iEntity, bool bChat, const char[] sMessage, const char[] sParam1="", const char[] sParam2="", const char[] sParam3="", const char[] sParam4="")
{
	BfWrite bf = UserMessageToBfWrite(StartMessage("SayText2", iClients, iLength, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS)); 
	
	bf.WriteByte(iEntity);
	bf.WriteByte(bChat);
	
	bf.WriteString(sMessage); 
	
	bf.WriteString(sParam1); 
	bf.WriteString(sParam2); 
	bf.WriteString(sParam3);
	bf.WriteString(sParam4);
	
	EndMessage();
}

stock void CPrintToChatDebug(const char[] sFormat, any ...)
{
	if (!g_cvDebug.BoolValue)
		return;
	
	char sBuffer[MAX_BUFFER_LENGTH];
	VFormat(sBuffer, sizeof(sBuffer), sFormat, 2);
	CPrintToChatAll("{orange}[SZF Debug]{default} %s", sBuffer);
}

/******************************************************************************************************/

//SDKHooks_TakeDamage doesn't call OnTakeDamage, so we need to scale separately for 'indirect' damage
stock void DealDamage(int iAttacker, int iVictim, float flDamage)
{
	if (g_flZombieDamageScale < 1.0)
		flDamage *= g_flZombieDamageScale;
	
	SDKHooks_TakeDamage(iVictim, iAttacker, iAttacker, flDamage, DMG_PREVENT_PHYSICS_FORCE);
}

stock bool CanRecieveDamage(int iClient)
{
	if (iClient <= 0 || !IsClientInGame(iClient))
		return true;
	
	if (TF2_IsPlayerInCondition(iClient, TFCond_Ubercharged))
		return false;
	
	if (TF2_IsPlayerInCondition(iClient, TFCond_Bonked))
		return false;
	
	return true;
}