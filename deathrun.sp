#pragma semicolon 1
#pragma dynamic 131072
#pragma newdecls required

#include <sourcemod>
#include <dhooks>
#include <sdkhooks>
#include <sdktools>
#include <cstrike>
#include <clientprefs>
#include <clearhandle>
#include <intmap>
#include <sourcecolors>
#undef REQUIRE_PLUGIN
#include <adminstealth>
#include <entityIO>

// Bugs:
// Players can pass trigger filters from breakables.
// TrapType is working only with buttons.

// To do:
// check dr_princess rotating trap
// trap flags
// check replace trap entites
// traps logic (fireuser1, disable on output, breakables etc), check syntax
// add point hurt as trap?

public Plugin myinfo =
{
	name = "Deathrun",
	author = "Ilusion",
	description = "Deathrun gamemode.",
	version = "1.0",
	url = "https://github.com/Ilusion9/"
};

#define BRUSHSOLID_TOGGLE        0
#define BRUSHSOLID_NEVER         1
#define BRUSHSOLID_ALWAYS        2

#define COLLISION_GROUP_DEBRIS                    1
#define COLLISION_GROUP_DEBRIS_TRIGGER            2
#define COLLISION_GROUP_INTERACTIVE_DEBRIS        3
#define COLLISION_GROUP_INTERACTIVE               4
#define COLLISION_GROUP_PASSABLE_DOOR             5

#define EF_NODRAW        32

#define FSOLID_NOT_SOLID        4
#define FSOLID_TRIGGER          8

#define SF_AMBIENT_SOUND_EVERYWHERE        1

#define SF_BRUSH_ROTATE_X_AXIS        4
#define SF_BRUSH_ROTATE_Y_AXIS        8

#define SF_BUTTON_USE_ACTIVATES        1024
#define SF_BUTTON_NOT_SOLID            16384

#define SF_DOOR_NO_AUTO_RETURN        32

#define SF_GAME_PLAYER_EQUIP_USE_ONLY            1
#define SF_GAME_PLAYER_STRIP_ALL_WEAPONS         2
#define SF_GAME_PLAYER_STRIP_SAME_WEAPONS        4

#define SF_PHYSBOX_START_ASLEEP           4096
#define SF_PHYSBOX_MOTION_DISABLED        32768

#define SF_PROP_PHYSICS_START_ASLEEP           1
#define SF_PROP_PHYSICS_MOTION_DISABLED        8

#define SF_TRAIN_WAIT_RETRIGGER        1

#define SF_TRIGGER_ALLOW_CLIENTS        1
#define SF_TRIGGER_ALLOW_ALL            64

#define SOLID_NONE            0
#define SOLID_BBOX            2
#define SOLID_VPHYSICS        6

#define TS_AT_TOP            0
#define TS_AT_BOTTOM         1
#define TS_GOING_UP          2
#define TS_GOING_DOWN        3

#define FADE_IN              1
#define FADE_OUT             2
#define FADE_MODULATE        4
#define FADE_STAYOUT         8
#define FADE_PURGE           16

#define GLOW_STYLE_DEFAULT              0
#define GLOW_STYLE_SHIMMER              1
#define GLOW_STYLE_OUTLINE              2
#define GLOW_STYLE_OUTLINE_PULSE        3

#define END_KILL_TERRORIST                      (1 << 0)
#define END_TERRORIST_SPEED                     (1 << 1)
#define END_TERRORIST_KILLER_SPEED              (1 << 2)
#define END_RESTRICTED_ON_FREERUN               (1 << 3)
#define END_REVERSE_DEFAULT_WINNER              (1 << 4)
#define END_BLOCK_CONTROL_ON_BOT_WEAPONS        (1 << 5)

#define HUD_DISPLAY_BUTTONS             (1 << 0)
#define HUD_DISPLAY_SPEC_BUTTONS        (1 << 1)
#define HUD_DISPLAY_SPECTATORS          (1 << 2)
#define HUD_DISPLAY_DEFAULT             HUD_DISPLAY_SPEC_BUTTONS | HUD_DISPLAY_SPECTATORS

#define JOINTEAM_TERRORISTS_FULL        2

#define PLAYER_HAS_RECEIVED_LIFE               (1 << 0)
#define PLAYER_HAS_FINISHED_MAP                (1 << 1)
#define PLAYER_IS_HIDING_OTHER_PLAYERS         (1 << 2)
#define PLAYER_IS_TOUCHING_TRIGGER_HURT        (1 << 3)

#define ROUND_IS_FREERUN                       (1 << 0)
#define ROUND_IS_DEATHRUN                      (1 << 1)
#define ROUND_END_ZONE_SPAWNED                 (1 << 2)
#define ROUND_WARMUP_PERIOD                    (1 << 3)
#define ROUND_WARMUP_RESPAWNING_PLAYERS        (1 << 4)
#define ROUND_WARMUP_DISPLAY_ENDING_HUD        (1 << 5)
#define ROUND_MAP_FINISHED                     (1 << 6)
#define ROUND_END_CHOSEN                       (1 << 7)
#define ROUND_HAS_ENDED                        (1 << 8)

#define SPECMODE_NONE               0
#define SPECMODE_FIRSTPERSON        4
#define SPECMODE_THRIDPERSON        5
#define SPECMODE_FREELOOK           6

#define THINK_PLAYERS_AT_CT                    (1 << 0)
#define THINK_PLAYERS_ALIVE_AT_CT              (1 << 1)
#define THINK_WARMUP_RESPAWNING_PLAYERS        (1 << 2)

#define TIMER_THINK_INTERVAL        0.1

#define TRAP_ACTIVATOR_IGNORE_OUTPUTS                  (1 << 0)
#define TRAP_ACTIVATOR_HAS_USE_RESTRICTIONS            (1 << 1)
#define TRAP_ACTIVATOR_TERRORIST_CAN_USE               (1 << 2)
#define TRAP_ACTIVATOR_TERRORIST_KILLER_CAN_USE        (1 << 3)
#define TRAP_ACTIVATOR_RESTRICTED_ON_FREERUN           (1 << 4)

#define TRAP_IGNORE_PROXIMITY                       (1 << 0)
#define TRAP_IGNORE_PROXIMITY_FROM_TEMPLATE         (1 << 1)
#define TRAP_IGNORE_SPEED                           (1 << 2)
#define TRAP_IGNORE_REVERSE                         (1 << 3)
#define TRAP_IGNORE_OUTPUTS                         (1 << 4)
#define TRAP_IGNORE_BREAKABLES_ON_KILL              (1 << 5)
#define TRAP_IGNORE_BREAKABLES_ON_MOVE              (1 << 6)
#define TRAP_IGNORE_BREAKABLES_ON_FIRST_MOVE        (1 << 7)
#define TRAP_IGNORE_BREAKABLES_ON_SPEED             (1 << 8)
#define TRAP_IGNORE_BREAKABLES_ON_REVERSE           (1 << 9)
#define TRAP_ADD_IN_BREAKABLES_ON_MOVE              (1 << 10)
#define TRAP_ADD_IN_BREAKABLES_ON_FIRST_MOVE        (1 << 11)
#define TRAP_ADD_IN_BREAKABLES_ON_SPEED             (1 << 12)
#define TRAP_ADD_IN_BREAKABLES_ON_REVERSE           (1 << 13)
#define TRAP_REMOVE_FROM_PROXIMITY_ON_STOP          (1 << 14)
#define TRAP_SPAWN_ENABLED                          (1 << 15)
#define TRAP_SPAWN_OPEN                             (1 << 16)
#define TRAP_SPAWN_CLOSED                           (1 << 17)
#define TRAP_SPAWN_REVERSED                         (1 << 18)
#define TRAP_DISABLE_ON_STOP                        (1 << 19)
#define TRAP_IS_REPLACING_OTHER_TRAPS               (1 << 20)

#define TRAP_IS_ACTIVATED                             (1 << 0)
#define TRAP_IN_PROXIMITY                             (1 << 1)
#define TRAP_IN_BREAKABLES_ON_KILL                    (1 << 2)
#define TRAP_IN_BREAKABLES_ON_MOVE                    (1 << 3)
#define TRAP_IN_BREAKABLES_ON_FIRST_MOVE              (1 << 4)
#define TRAP_IN_BREAKABLES_ON_SPEED                   (1 << 5)
#define TRAP_IN_BREAKABLES_ON_REVERSE                 (1 << 6)
#define TRAP_IN_THINK_FUNCTION                        (1 << 7)
#define TRAP_IS_CHILD                                 (1 << 8)
#define TRAP_CHILD_IN_PROXIMITY                       (1 << 9)
#define TRAP_CHILD_IN_BREAKABLES_ON_KILL              (1 << 10)
#define TRAP_CHILD_IN_BREAKABLES_ON_MOVE              (1 << 11)
#define TRAP_CHILD_IN_BREAKABLES_ON_FIRST_MOVE        (1 << 12)
#define TRAP_CHILD_IN_BREAKABLES_ON_SPEED             (1 << 13)
#define TRAP_CHILD_IN_BREAKABLES_ON_REVERSE           (1 << 14)
#define TRAP_IS_TEMPLATE                              (1 << 15)
#define TRAP_HAS_SPAWN_DATA_SET                       (1 << 16)
#define TRAP_HAS_CONFIG_FLAGS_SET                     (1 << 17)
#define TRAP_LISTEN_TO_OUTPUTS                        (1 << 18)
#define TRAP_HAS_MOVED_SINCE_SPAWN                    (1 << 19)
#define TRAP_WAIT_TO_REACTIVATE                       (1 << 20)
#define TRAP_RECEIVED_REVERSE_INPUT                   (1 << 21)
#define TRAP_RECEIVED_SPEED_INPUT                     (1 << 22)

#define ZONE_SPAWNED              (1 << 0)
#define ZONE_RENDER_ALL           (1 << 1)
#define ZONE_RENDER_FRONT         (1 << 2)
#define ZONE_RENDER_BACK          (1 << 3)
#define ZONE_RENDER_TOP           (1 << 4)
#define ZONE_RENDER_BOTTOM        (1 << 5)
#define ZONE_RENDER_LEFT          (1 << 6)
#define ZONE_RENDER_RIGHT         (1 << 7)

enum ClassType
{
	ClassType_None,
	ClassType_CsRagdoll,
	ClassType_EnvBeam,
	ClassType_EnvEntityMaker,
	ClassType_EnvExplosion,
	ClassType_EnvFire,
	ClassType_EnvFireSource,
	ClassType_EnvGunFire,
	ClassType_EnvLaser,
	ClassType_EnvShake,
	ClassType_EnvSmokeStack,
	ClassType_FuncBreakable,
	ClassType_FuncBrush,
	ClassType_FuncButton,
	ClassType_FuncDoor,
	ClassType_FuncDoorRotating,
	ClassType_FuncMoveLinear,
	ClassType_FuncPhysBox,
	ClassType_FuncRotating,
	ClassType_FuncTankTrain,
	ClassType_FuncTrackTrain,
	ClassType_FuncTrain,
	ClassType_FuncWall,
	ClassType_FuncWallToggle,
	ClassType_FuncWaterAnalog,
	ClassType_GamePlayerEquip,
	ClassType_GameUI,
	ClassType_LogicBranch,
	ClassType_LogicCase,
	ClassType_LogicCompare,
	ClassType_LogicRelay,
	ClassType_LogicTimer,
	ClassType_MathCounter,
	ClassType_PointHurt,
	ClassType_PointTemplate,
	ClassType_PropDoorRotating,
	ClassType_PropDynamic,
	ClassType_PropPhysics,
	ClassType_TriggerHurt,
	ClassType_TriggerMultiple,
	ClassType_TriggerOnce,
	ClassType_TriggerPush,
	ClassType_TriggerTeleport
}

enum InputType
{
	InputType_None,
	InputType_Activate,
	InputType_Add,
	InputType_AddOutput,
	InputType_Break,
	InputType_Close,
	InputType_Compare,
	InputType_Deactivate,
	InputType_Disable,
	InputType_DisableMotion,
	InputType_Divide,
	InputType_Enable,
	InputType_EnableMotion,
	InputType_Explode,
	InputType_Extinguish,
	InputType_ExtinguishTemporary,
	InputType_ForceSpawn,
	InputType_ForceSpawnAtEntityOrigin,
	InputType_InValue,
	InputType_Kill,
	InputType_Lock,
	InputType_Multiply,
	InputType_Open,
	InputType_PickRandom,
	InputType_PickRandomShuffle,
	InputType_Press,
	InputType_PressIn,
	InputType_PressOut,
	InputType_RemoveHealth,
	InputType_Resume,
	InputType_Reverse,
	InputType_SetHealth,
	InputType_SetHitMin,
	InputType_SetHitMax,
	InputType_SetPosition,
	InputType_SetSpeed,
	InputType_SetSpeedReal,
	InputType_SetValue,
	InputType_Sleep,
	InputType_Start,
	InputType_StartBackward,
	InputType_StartFire,
	InputType_StartForward,
	InputType_StartShake,
	InputType_Stop,
	InputType_StopAtStartPos,
	InputType_Subtract,
	InputType_Test,
	InputType_Toggle,
	InputType_Trigger,
	InputType_TurnOn,
	InputType_TurnOff,
	InputType_Unlock,
	InputType_UpdateHealth,
	InputType_Wake
}

enum KillFeedType
{
	KillFeedType_None,
	KillFeedType_LifeTransfer,
	KillFeedType_Trap
}

enum OutputType
{
	OutputType_None,
	OutputType_OnClose,
	OutputType_OnEntityFailedSpawn,
	OutputType_OnEntitySpawned,
	OutputType_OnExtinguished,
	OutputType_OnFullyClosed,
	OutputType_OnFullyOpen,
	OutputType_OnIgnited,
	OutputType_OnIn,
	OutputType_OnOut
}

enum RespawnType
{
	RespawnType_None,
	RespawnType_Warmup
}

enum SpeedType
{
	SpeedType_Normal = 1,
	SpeedType_x3 = 3,
	SpeedType_x5 = 5
}

enum StateType
{
	StateType_None,
	StateType_Closed,
	StateType_Open,
	StateType_SetPosition
}

enum TrapType
{
	TrapType_None,
	TrapType_End,
	TrapType_Normal
}

enum ZoneType
{
	ZoneType_None,
	ZoneType_End,
	ZoneType_Hurt,
	ZoneType_Solid
}

enum struct BreakableInfo
{
	int hammerId;
	int entityRef;
	int activatorId;
	int parentHammer;
	float removeTime;
	float pointMin[3];
	float pointMax[3];
	char entityName[256];
}

enum struct DisconnectInfo
{
	int numWarmups;
	int lastRoundPlayed;
	int terroristRequests;
	int lastTerroristRound;
}

enum struct EndInfo
{
	int flags;
	int endId;
	char endName[256];
}

enum struct FinishInfo
{
	int finishMin;
	int finishSec;
	int finishMs;
	int finishPos;
}

enum struct HudInfo
{
	bool inCookies;
	int displayFlags;
}

enum struct MoveInfo
{
	int toTeam;
	float moveTime;
}

enum struct OutputActionInfo
{
	bool multipleTargets;
	int actionId;
	int numTargets;
	int activatorId;
	int callerReference;
	float fireTime;
	char target[256];
}

enum struct RangeInfo
{
	int rangeStart;
	int rangeEnd;
}

enum struct RemoveEntityInfo
{
	int reference;
	float removeTime;
}

enum struct RespawnInfo
{
	float respawnTime;
	RespawnType respawnType;
}

enum struct ShakeInfo
{
	int activatorId;
	float shakeTime;
}

enum struct SpeedInfo
{
	SpeedType speedType;
	SpeedType maxSpeedType;
}

enum struct TerroristInfo
{
	int numRequests;
	int lastRound;
	float lastTime;
}

enum struct TrapActivatorInfo
{
	int flags;
	int endId;
	int trapId;
	TrapType trapType;
}

enum struct TrapProximityInfo
{
	int inProximity;
	int activatorId;
}

enum struct TrapInfo
{
	int flags;
	int configFlags;
	int activatorId;
	float spawnSpeed;
	float spawnMins[3];
	float spawnMaxs[3];
	float spawnOrigin[3];
	ClassType classType;
	StateType nextState;
	StateType spawnState;
}

enum struct ZoneInfo
{
	int flags;
	float pointMin[3];
	float pointMax[3];
	ZoneType zoneType;
}

bool g_IsPluginLoadedLate;
bool g_IsStealthLibraryLoaded;
bool g_IsEntityIOLibraryLoaded;

int g_BeamModel;
int g_NumFinishers;
int g_OutputActionId;
int g_RoundFlags;
int g_TerroristId;
int g_TerroristKillerId;
int g_TotalRoundsPlayed;
int g_LastObserver[MAXPLAYERS + 1];
int g_NumSpectators[MAXPLAYERS + 1];
int g_NumWarmups[MAXPLAYERS + 1];
int g_PlayerFlags[MAXPLAYERS + 1];
int g_PlayerGlow[MAXPLAYERS + 1];
int g_TimerButtons[MAXPLAYERS + 1];

float g_WarmupDuration;
float g_EndZoneOrigin[3];
float g_LifeTransferDelay[MAXPLAYERS + 1];
float g_RefillAmmoTime[MAXPLAYERS + 1];
float g_RemoveProtectionTime[MAXPLAYERS + 1];

ArrayList g_List_BreakablesOnFirstMove;
ArrayList g_List_BreakablesOnKill;
ArrayList g_List_BreakablesOnMove;
ArrayList g_List_BreakablesOnReverse;
ArrayList g_List_BreakablesOnSpeed;
ArrayList g_List_ProximityTraps;
ArrayList g_List_RemoveEntities;
ArrayList g_List_ReplacedTraps;
ArrayList g_List_TerroristQueue;
ArrayList g_List_ThinkTraps;
ArrayList g_List_Zones;

ConVar g_Cvar_BotQuota;
ConVar g_Cvar_DeathAnimTime;
ConVar g_Cvar_RoundRestartDelay;

ConVar g_Cvar_CounterTerroristsMaxSpeed;
ConVar g_Cvar_DebugModeEnable;
ConVar g_Cvar_FreerunModeEnable;
ConVar g_Cvar_LifeTransferDelay;
ConVar g_Cvar_LifeTransferEnable;
ConVar g_Cvar_RandomTerroristEnable;
ConVar g_Cvar_RandomTerroristMinPlayers;
ConVar g_Cvar_RequestTerroristEnable;
ConVar g_Cvar_RespawnDelay;
ConVar g_Cvar_RoundTimeAllFinished;
ConVar g_Cvar_RoundTimeLastFinished;
ConVar g_Cvar_SpawnProtectionTime;
ConVar g_Cvar_TerroristMaxRequests;
ConVar g_Cvar_TerroristRoundsDelay;
ConVar g_Cvar_WarmupMaxRespawns;
ConVar g_Cvar_WarmupMaxTime;
ConVar g_Cvar_WarmupMinTime;
ConVar g_Cvar_WarmupTimeFactor;

Cookie g_Cookie_HudDisplay;
GlobalForward g_Forward_OnMapFinished;
Handle g_SDKCall_PassesTriggerFilters;

IntMap g_Map_BreakablesOnFirstMove;
IntMap g_Map_BreakablesOnKill;
IntMap g_Map_BreakablesOnMove;
IntMap g_Map_BreakablesOnReverse;
IntMap g_Map_BreakablesOnSpeed;
IntMap g_Map_CurrentEndActivators;
IntMap g_Map_Disconnections;
IntMap g_Map_Endings;
IntMap g_Map_OutputActions;
IntMap g_Map_Traps;

StringMap g_Map_ClassNames;
StringMap g_Map_EndActivators;
StringMap g_Map_Inputs;
StringMap g_Map_NumTraps;
StringMap g_Map_Outputs;
StringMap g_Map_ReplacedTraps;
StringMap g_Map_TrapActivators;
StringMap g_Map_TrapFlags;

EndInfo g_CurrentEndInfo;
KillFeedType g_KillFeedType[MAXPLAYERS + 1];

FinishInfo g_FinishInfo[MAXPLAYERS + 1];
HudInfo g_HudInfo[MAXPLAYERS + 1];
MoveInfo g_MoveInfo[MAXPLAYERS + 1];
RespawnInfo g_RespawnInfo[MAXPLAYERS + 1];
ShakeInfo g_ShakeInfo[MAXPLAYERS + 1];
SpeedInfo g_SpeedInfo[MAXPLAYERS + 1];
TerroristInfo g_TerroristInfo[MAXPLAYERS + 1];
TrapProximityInfo g_TrapProximityInfo[MAXPLAYERS + 1];

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_IsPluginLoadedLate = late;
	
	CreateNative("Deathrun_GetTerrorist", Native_GetTerrorist);
	CreateNative("Deathrun_GetTerroristKiller", Native_GetTerroristKiller);
	CreateNative("Deathrun_HasClientReceivedLife", Native_HasClientReceivedLife);
	
	RegPluginLibrary("deathrun");
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadGameData();
	LoadTranslations("common.phrases");
	
	g_IsStealthLibraryLoaded = LibraryExists("adminstealth");
	g_IsEntityIOLibraryLoaded = LibraryExists("entityIO");
	
	g_List_BreakablesOnFirstMove = new ArrayList();
	g_List_BreakablesOnKill = new ArrayList();
	g_List_BreakablesOnMove = new ArrayList();
	g_List_BreakablesOnReverse = new ArrayList();
	g_List_BreakablesOnSpeed = new ArrayList();
	g_List_ProximityTraps = new ArrayList();
	g_List_RemoveEntities = new ArrayList(sizeof(RemoveEntityInfo));
	g_List_ReplacedTraps = new ArrayList(ByteCountToCells(256));
	g_List_TerroristQueue = new ArrayList();
	g_List_ThinkTraps = new ArrayList();
	g_List_Zones = new ArrayList(sizeof(ZoneInfo));
	
	g_Cvar_BotQuota = FindConVar("bot_quota");	
	g_Cvar_DeathAnimTime = FindConVar("spec_freeze_deathanim_time");
	g_Cvar_RoundRestartDelay = FindConVar("mp_round_restart_delay");
	
	g_Cvar_BotQuota.AddChangeHook(ConVarChange_BotQuota);
	
	g_Cvar_CounterTerroristsMaxSpeed = CreateConVar("dr_counter_terrorists_max_speed", "1000", "Maximum speed (in units) allowed for Counter-Terrorists. (0 - disable)", FCVAR_NONE, true, 0.0);
	g_Cvar_DebugModeEnable = CreateConVar("dr_debug_mode_enable", "0", "Enable the debug mode?", FCVAR_NONE, true, 0.0, true, 1.0);
	g_Cvar_FreerunModeEnable = CreateConVar("dr_freerun_mode_enable", "1", "Allow Terrorists to enable the Freerun Mode?", FCVAR_NONE, true, 0.0, true, 1.0);
	g_Cvar_LifeTransferDelay = CreateConVar("dr_life_transfer_delay", "5", "After how many seconds players can transfer their lives again?", FCVAR_NONE, true, 0.0);
	g_Cvar_LifeTransferEnable = CreateConVar("dr_life_transfer_enable", "1", "Allow players to transfer their lives?", FCVAR_NONE, true, 0.0, true, 1.0);
	g_Cvar_RandomTerroristEnable = CreateConVar("dr_random_terrorist_enable", "1", "Choose a random Terrorist if no one requested to join?", FCVAR_NONE, true, 0.0, true, 1.0);
	g_Cvar_RandomTerroristMinPlayers = CreateConVar("dr_random_terrorist_min_players", "5", "Minimum players required to choose a random Terrorist.", FCVAR_NONE, true, 0.0);
	g_Cvar_RequestTerroristEnable = CreateConVar("dr_request_terrorist_enable", "1", "Allow players to request to join the Terrorists?", FCVAR_NONE, true, 0.0, true, 1.0);
	g_Cvar_RespawnDelay = CreateConVar("dr_respawn_delay", "1", "Amount of time (in seconds) to delay the respawn by.", FCVAR_NONE, true, 0.0);
	g_Cvar_RoundTimeAllFinished = CreateConVar("dr_round_time_all_finished", "120", "Change the round time to this value when all the remaining CTs have finished the map. (0 - disable)", FCVAR_NONE, true, 0.0);
	g_Cvar_RoundTimeLastFinished = CreateConVar("dr_round_time_last_finished", "60", "Change the round time to this value when the last player alive has finished the map. (0 - disable)", FCVAR_NONE, true, 0.0);
	g_Cvar_SpawnProtectionTime = CreateConVar("dr_spawn_protection_time", "1", "Time of spawn protection.", FCVAR_NONE, true, 0.0);
	g_Cvar_TerroristMaxRequests = CreateConVar("dr_terrorist_max_requests", "1", "Maximum requests a player can make to join the Terrorists. (0 - disable)", FCVAR_NONE, true, 0.0);
	g_Cvar_TerroristRoundsDelay = CreateConVar("dr_terrorist_rounds_delay", "2", "After how many rounds a player can join the Terrorists again?", FCVAR_NONE, true, 0.0);
	g_Cvar_WarmupMaxRespawns = CreateConVar("dr_warmup_max_respawns", "1", "Maximum respawns for players in the warmup period. (0 - disable)", FCVAR_NONE, true, 0.0);
	g_Cvar_WarmupMaxTime = CreateConVar("dr_warmup_max_time", "30", "Maximum time for the warmup period.", FCVAR_NONE, true, 0.0);
	g_Cvar_WarmupMinTime = CreateConVar("dr_warmup_min_time", "10", "Minimum time for the warmup period.", FCVAR_NONE, true, 0.0);
	g_Cvar_WarmupTimeFactor = CreateConVar("dr_warmup_time_factor", "0.6", "Players factor to decrease the warmup time by.", FCVAR_NONE, true, 0.0);
	
	AutoExecConfig(true, "deathrun");
	AutoExecConfig(false, "gamemode_deathrun_server", "");
	
	g_Cookie_HudDisplay = new Cookie("dr_hud_display", "Hud preferences in deathrun mode.", CookieAccess_Private);
	g_Forward_OnMapFinished = new GlobalForward("Deathrun_OnMapFinished", ET_Ignore, Param_Cell, Param_Cell, Param_Float);
	
	g_Map_BreakablesOnFirstMove = new IntMap();
	g_Map_BreakablesOnKill = new IntMap();
	g_Map_BreakablesOnMove = new IntMap();
	g_Map_BreakablesOnReverse = new IntMap();
	g_Map_BreakablesOnSpeed = new IntMap();
	g_Map_CurrentEndActivators = new IntMap();
	g_Map_Disconnections = new IntMap();
	g_Map_Endings = new IntMap();
	g_Map_OutputActions = new IntMap();
	g_Map_Traps = new IntMap();
	
	g_Map_ClassNames = new StringMap();
	g_Map_EndActivators = new StringMap();
	g_Map_Inputs = new StringMap();
	g_Map_NumTraps = new StringMap();
	g_Map_Outputs = new StringMap();
	g_Map_ReplacedTraps = new StringMap();
	g_Map_TrapActivators = new StringMap();
	g_Map_TrapFlags = new StringMap();
	
	g_Map_ClassNames.SetValue("cs_ragdoll", ClassType_CsRagdoll);
	g_Map_ClassNames.SetValue("env_beam", ClassType_EnvBeam);
	g_Map_ClassNames.SetValue("env_entity_maker", ClassType_EnvEntityMaker);
	g_Map_ClassNames.SetValue("env_explosion", ClassType_EnvExplosion);
	g_Map_ClassNames.SetValue("env_fire", ClassType_EnvFire);
	g_Map_ClassNames.SetValue("env_firesource", ClassType_EnvFireSource);
	g_Map_ClassNames.SetValue("env_gunfire", ClassType_EnvGunFire);
	g_Map_ClassNames.SetValue("env_laser", ClassType_EnvLaser);
	g_Map_ClassNames.SetValue("env_shake", ClassType_EnvShake);
	g_Map_ClassNames.SetValue("env_smokestack", ClassType_EnvSmokeStack);
	g_Map_ClassNames.SetValue("func_breakable", ClassType_FuncBreakable);
	g_Map_ClassNames.SetValue("func_brush", ClassType_FuncBrush);
	g_Map_ClassNames.SetValue("func_button", ClassType_FuncButton);
	g_Map_ClassNames.SetValue("func_door", ClassType_FuncDoor);
	g_Map_ClassNames.SetValue("func_door_rotating", ClassType_FuncDoorRotating);
	g_Map_ClassNames.SetValue("func_movelinear", ClassType_FuncMoveLinear);
	g_Map_ClassNames.SetValue("func_physbox", ClassType_FuncPhysBox);
	g_Map_ClassNames.SetValue("func_physbox_multiplayer", ClassType_FuncPhysBox);
	g_Map_ClassNames.SetValue("func_rotating", ClassType_FuncRotating);
	g_Map_ClassNames.SetValue("func_tanktrain", ClassType_FuncTankTrain);
	g_Map_ClassNames.SetValue("func_tracktrain", ClassType_FuncTrackTrain);
	g_Map_ClassNames.SetValue("func_train", ClassType_FuncTrain);
	g_Map_ClassNames.SetValue("func_wall", ClassType_FuncWall);
	g_Map_ClassNames.SetValue("func_wall_toggle", ClassType_FuncWallToggle);
	g_Map_ClassNames.SetValue("func_water_analog", ClassType_FuncWaterAnalog);
	g_Map_ClassNames.SetValue("game_player_equip", ClassType_GamePlayerEquip);
	g_Map_ClassNames.SetValue("game_ui", ClassType_GameUI);
	g_Map_ClassNames.SetValue("logic_branch", ClassType_LogicBranch);
	g_Map_ClassNames.SetValue("logic_case", ClassType_LogicCase);
	g_Map_ClassNames.SetValue("logic_compare", ClassType_LogicCompare);
	g_Map_ClassNames.SetValue("logic_relay", ClassType_LogicRelay);
	g_Map_ClassNames.SetValue("logic_timer", ClassType_LogicTimer);
	g_Map_ClassNames.SetValue("math_counter", ClassType_MathCounter);
	g_Map_ClassNames.SetValue("point_hurt", ClassType_PointHurt);
	g_Map_ClassNames.SetValue("point_template", ClassType_PointTemplate);
	g_Map_ClassNames.SetValue("prop_door_rotating", ClassType_PropDoorRotating);
	g_Map_ClassNames.SetValue("prop_dynamic", ClassType_PropDynamic);
	g_Map_ClassNames.SetValue("prop_dynamic_override", ClassType_PropDynamic);
	g_Map_ClassNames.SetValue("prop_physics", ClassType_PropPhysics);
	g_Map_ClassNames.SetValue("prop_physics_multiplayer", ClassType_PropPhysics);
	g_Map_ClassNames.SetValue("prop_physics_override", ClassType_PropPhysics);
	g_Map_ClassNames.SetValue("trigger_hurt", ClassType_TriggerHurt);
	g_Map_ClassNames.SetValue("trigger_multiple", ClassType_TriggerMultiple);
	g_Map_ClassNames.SetValue("trigger_once", ClassType_TriggerOnce);
	g_Map_ClassNames.SetValue("trigger_push", ClassType_TriggerPush);
	g_Map_ClassNames.SetValue("trigger_teleport", ClassType_TriggerTeleport);
	
	g_Map_Inputs.SetValue("activate", InputType_Activate);
	g_Map_Inputs.SetValue("add", InputType_Add);
	g_Map_Inputs.SetValue("addoutput", InputType_AddOutput);
	g_Map_Inputs.SetValue("break", InputType_Break);
	g_Map_Inputs.SetValue("close", InputType_Close);
	g_Map_Inputs.SetValue("compare", InputType_Compare);
	g_Map_Inputs.SetValue("deactivate", InputType_Deactivate);
	g_Map_Inputs.SetValue("disable", InputType_Disable);
	g_Map_Inputs.SetValue("disablemotion", InputType_DisableMotion);
	g_Map_Inputs.SetValue("divide", InputType_Divide);
	g_Map_Inputs.SetValue("enable", InputType_Enable);
	g_Map_Inputs.SetValue("enablemotion", InputType_EnableMotion);
	g_Map_Inputs.SetValue("explode", InputType_Explode);
	g_Map_Inputs.SetValue("extinguish", InputType_Extinguish);
	g_Map_Inputs.SetValue("extinguishtemporary", InputType_ExtinguishTemporary);
	g_Map_Inputs.SetValue("forcespawn", InputType_ForceSpawn);
	g_Map_Inputs.SetValue("forcespawnatentityorigin", InputType_ForceSpawnAtEntityOrigin);
	g_Map_Inputs.SetValue("invalue", InputType_InValue);
	g_Map_Inputs.SetValue("kill", InputType_Kill);
	g_Map_Inputs.SetValue("lock", InputType_Lock);
	g_Map_Inputs.SetValue("multiply", InputType_Multiply);
	g_Map_Inputs.SetValue("open", InputType_Open);
	g_Map_Inputs.SetValue("pickrandom", InputType_PickRandom);
	g_Map_Inputs.SetValue("pickrandomshuffle", InputType_PickRandomShuffle);
	g_Map_Inputs.SetValue("press", InputType_Press);
	g_Map_Inputs.SetValue("pressin", InputType_PressIn);
	g_Map_Inputs.SetValue("pressout", InputType_PressOut);
	g_Map_Inputs.SetValue("removehealth", InputType_RemoveHealth);
	g_Map_Inputs.SetValue("resume", InputType_Resume);
	g_Map_Inputs.SetValue("reverse", InputType_Reverse);
	g_Map_Inputs.SetValue("sethealth", InputType_SetHealth);
	g_Map_Inputs.SetValue("sethitmin", InputType_SetHitMin);
	g_Map_Inputs.SetValue("sethitmax", InputType_SetHitMax);
	g_Map_Inputs.SetValue("setposition", InputType_SetPosition);
	g_Map_Inputs.SetValue("setspeed", InputType_SetSpeed);
	g_Map_Inputs.SetValue("setspeedreal", InputType_SetSpeedReal);
	g_Map_Inputs.SetValue("setvalue", InputType_SetValue);
	g_Map_Inputs.SetValue("sleep", InputType_Sleep);
	g_Map_Inputs.SetValue("start", InputType_Start);
	g_Map_Inputs.SetValue("startbackward", InputType_StartBackward);
	g_Map_Inputs.SetValue("startfire", InputType_StartFire);
	g_Map_Inputs.SetValue("startforward", InputType_StartForward);
	g_Map_Inputs.SetValue("startshake", InputType_StartShake);
	g_Map_Inputs.SetValue("stop", InputType_Stop);
	g_Map_Inputs.SetValue("stopatstartpos", InputType_StopAtStartPos);
	g_Map_Inputs.SetValue("subtract", InputType_Subtract);
	g_Map_Inputs.SetValue("test", InputType_Test);
	g_Map_Inputs.SetValue("toggle", InputType_Toggle);
	g_Map_Inputs.SetValue("trigger", InputType_Trigger);
	g_Map_Inputs.SetValue("turnon", InputType_TurnOn);
	g_Map_Inputs.SetValue("turnoff", InputType_TurnOff);
	g_Map_Inputs.SetValue("updatehealth", InputType_UpdateHealth);
	g_Map_Inputs.SetValue("unlock", InputType_Unlock);
	g_Map_Inputs.SetValue("wake", InputType_Wake);
	
	g_Map_Outputs.SetValue("OnClose", OutputType_OnClose);
	g_Map_Outputs.SetValue("OnEntityFailedSpawn", OutputType_OnEntityFailedSpawn);
	g_Map_Outputs.SetValue("OnEntitySpawned", OutputType_OnEntitySpawned);
	g_Map_Outputs.SetValue("OnExtinguished", OutputType_OnExtinguished);
	g_Map_Outputs.SetValue("OnFullyClosed", OutputType_OnFullyClosed);
	g_Map_Outputs.SetValue("OnFullyOpen", OutputType_OnFullyOpen);
	g_Map_Outputs.SetValue("OnIgnited", OutputType_OnIgnited);
	g_Map_Outputs.SetValue("OnIn", OutputType_OnIn);
	g_Map_Outputs.SetValue("OnOut", OutputType_OnOut);
	
	HookEvent("player_connect_full", Event_PlayerConnect);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath_Pre, EventHookMode_Pre);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("player_use", Event_PlayerUse);
	HookEvent("player_jump", Event_PlayerJump);
	HookEvent("round_prestart", Event_RoundPreStart);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	
	AddNormalSoundHook(Sound_OnNormal);
	AddTempEntHook("Shotgun Shot", TempEnt_OnShotgunShot);
	
	HookEntityOutput("env_beam", "OnTouchedByEntity", Output_OnEntityOutput);
	HookEntityOutput("env_beam", "OnUser1", Output_OnEntityOutput);
	HookEntityOutput("env_beam", "OnUser2", Output_OnEntityOutput);
	HookEntityOutput("env_beam", "OnUser3", Output_OnEntityOutput);
	HookEntityOutput("env_beam", "OnUser4", Output_OnEntityOutput);
	HookEntityOutput("env_entity_maker", "OnEntityFailedSpawn", Output_OnEntityOutput);
	HookEntityOutput("env_entity_maker", "OnEntitySpawned", Output_OnEntityOutput);
	HookEntityOutput("env_entity_maker", "OnUser1", Output_OnEntityOutput);
	HookEntityOutput("env_entity_maker", "OnUser2", Output_OnEntityOutput);
	HookEntityOutput("env_entity_maker", "OnUser3", Output_OnEntityOutput);
	HookEntityOutput("env_entity_maker", "OnUser4", Output_OnEntityOutput);
	HookEntityOutput("env_explosion", "OnUser1", Output_OnEntityOutput);
	HookEntityOutput("env_explosion", "OnUser2", Output_OnEntityOutput);
	HookEntityOutput("env_explosion", "OnUser3", Output_OnEntityOutput);
	HookEntityOutput("env_explosion", "OnUser4", Output_OnEntityOutput);
	HookEntityOutput("env_fire", "OnExtinguished", Output_OnEntityOutput);
	HookEntityOutput("env_fire", "OnIgnited", Output_OnEntityOutput);
	HookEntityOutput("env_fire", "OnUser1", Output_OnEntityOutput);
	HookEntityOutput("env_fire", "OnUser2", Output_OnEntityOutput);
	HookEntityOutput("env_fire", "OnUser3", Output_OnEntityOutput);
	HookEntityOutput("env_fire", "OnUser4", Output_OnEntityOutput);
	HookEntityOutput("env_firesource", "OnUser1", Output_OnEntityOutput);
	HookEntityOutput("env_firesource", "OnUser2", Output_OnEntityOutput);
	HookEntityOutput("env_firesource", "OnUser3", Output_OnEntityOutput);
	HookEntityOutput("env_firesource", "OnUser4", Output_OnEntityOutput);
	HookEntityOutput("env_gunfire", "OnUser1", Output_OnEntityOutput);
	HookEntityOutput("env_gunfire", "OnUser2", Output_OnEntityOutput);
	HookEntityOutput("env_gunfire", "OnUser3", Output_OnEntityOutput);
	HookEntityOutput("env_gunfire", "OnUser4", Output_OnEntityOutput);
	HookEntityOutput("env_laser", "OnUser1", Output_OnEntityOutput);
	HookEntityOutput("env_laser", "OnUser2", Output_OnEntityOutput);
	HookEntityOutput("env_laser", "OnUser3", Output_OnEntityOutput);
	HookEntityOutput("env_laser", "OnUser4", Output_OnEntityOutput);
	HookEntityOutput("env_shake", "OnUser1", Output_OnEntityOutput);
	HookEntityOutput("env_shake", "OnUser2", Output_OnEntityOutput);
	HookEntityOutput("env_shake", "OnUser3", Output_OnEntityOutput);
	HookEntityOutput("env_shake", "OnUser4", Output_OnEntityOutput);
	HookEntityOutput("env_smokestack", "OnUser1", Output_OnEntityOutput);
	HookEntityOutput("env_smokestack", "OnUser2", Output_OnEntityOutput);
	HookEntityOutput("env_smokestack", "OnUser3", Output_OnEntityOutput);
	HookEntityOutput("env_smokestack", "OnUser4", Output_OnEntityOutput);
	HookEntityOutput("func_breakable", "OnBreak", Output_OnEntityOutput);
	HookEntityOutput("func_breakable", "OnHealthChanged", Output_OnEntityOutput);
	HookEntityOutput("func_breakable", "OnUser1", Output_OnEntityOutput);
	HookEntityOutput("func_breakable", "OnUser2", Output_OnEntityOutput);
	HookEntityOutput("func_breakable", "OnUser3", Output_OnEntityOutput);
	HookEntityOutput("func_breakable", "OnUser4", Output_OnEntityOutput);
	HookEntityOutput("func_brush", "OnUser1", Output_OnEntityOutput);
	HookEntityOutput("func_brush", "OnUser2", Output_OnEntityOutput);
	HookEntityOutput("func_brush", "OnUser3", Output_OnEntityOutput);
	HookEntityOutput("func_brush", "OnUser4", Output_OnEntityOutput);
	HookEntityOutput("func_button", "OnDamaged", Output_OnEntityOutput);
	HookEntityOutput("func_button", "OnIn", Output_OnEntityOutput);
	HookEntityOutput("func_button", "OnOut", Output_OnEntityOutput);
	HookEntityOutput("func_button", "OnPressed", Output_OnEntityOutput);
	HookEntityOutput("func_button", "OnUseLocked", Output_OnEntityOutput);
	HookEntityOutput("func_button", "OnUser1", Output_OnEntityOutput);
	HookEntityOutput("func_button", "OnUser2", Output_OnEntityOutput);
	HookEntityOutput("func_button", "OnUser3", Output_OnEntityOutput);
	HookEntityOutput("func_button", "OnUser4", Output_OnEntityOutput);
	HookEntityOutput("func_door", "OnBlockedClosing", Output_OnEntityOutput);
	HookEntityOutput("func_door", "OnBlockedOpening", Output_OnEntityOutput);
	HookEntityOutput("func_door", "OnClose", Output_OnEntityOutput);
	HookEntityOutput("func_door", "OnFullyClosed", Output_OnEntityOutput);
	HookEntityOutput("func_door", "OnFullyOpen", Output_OnEntityOutput);
	HookEntityOutput("func_door", "OnLockedUse", Output_OnEntityOutput);
	HookEntityOutput("func_door", "OnOpen", Output_OnEntityOutput);
	HookEntityOutput("func_door", "OnUnblockedClosing", Output_OnEntityOutput);
	HookEntityOutput("func_door", "OnUnblockedOpening", Output_OnEntityOutput);
	HookEntityOutput("func_door", "OnUser1", Output_OnEntityOutput);
	HookEntityOutput("func_door", "OnUser2", Output_OnEntityOutput);
	HookEntityOutput("func_door", "OnUser3", Output_OnEntityOutput);
	HookEntityOutput("func_door", "OnUser4", Output_OnEntityOutput);
	HookEntityOutput("func_door_rotating", "OnBlockedClosing", Output_OnEntityOutput);
	HookEntityOutput("func_door_rotating", "OnBlockedOpening", Output_OnEntityOutput);
	HookEntityOutput("func_door_rotating", "OnClose", Output_OnEntityOutput);
	HookEntityOutput("func_door_rotating", "OnFullyClosed", Output_OnEntityOutput);
	HookEntityOutput("func_door_rotating", "OnFullyOpen", Output_OnEntityOutput);
	HookEntityOutput("func_door_rotating", "OnLockedUse", Output_OnEntityOutput);
	HookEntityOutput("func_door_rotating", "OnOpen", Output_OnEntityOutput);
	HookEntityOutput("func_door_rotating", "OnUnblockedClosing", Output_OnEntityOutput);
	HookEntityOutput("func_door_rotating", "OnUnblockedOpening", Output_OnEntityOutput);
	HookEntityOutput("func_door_rotating", "OnUser1", Output_OnEntityOutput);
	HookEntityOutput("func_door_rotating", "OnUser2", Output_OnEntityOutput);
	HookEntityOutput("func_door_rotating", "OnUser3", Output_OnEntityOutput);
	HookEntityOutput("func_door_rotating", "OnUser4", Output_OnEntityOutput);
	HookEntityOutput("func_movelinear", "OnFullyClosed", Output_OnEntityOutput);
	HookEntityOutput("func_movelinear", "OnFullyOpen", Output_OnEntityOutput);
	HookEntityOutput("func_movelinear", "OnUser1", Output_OnEntityOutput);
	HookEntityOutput("func_movelinear", "OnUser2", Output_OnEntityOutput);
	HookEntityOutput("func_movelinear", "OnUser3", Output_OnEntityOutput);
	HookEntityOutput("func_movelinear", "OnUser4", Output_OnEntityOutput);
	HookEntityOutput("func_physbox", "OnAwakened", Output_OnEntityOutput);
	HookEntityOutput("func_physbox", "OnBreak", Output_OnEntityOutput);
	HookEntityOutput("func_physbox", "OnDamaged", Output_OnEntityOutput);
	HookEntityOutput("func_physbox", "OnHealthChanged", Output_OnEntityOutput);
	HookEntityOutput("func_physbox", "OnMotionEnabled", Output_OnEntityOutput);
	HookEntityOutput("func_physbox", "OnPhysGunDrop", Output_OnEntityOutput);
	HookEntityOutput("func_physbox", "OnPhysGunOnlyPickup", Output_OnEntityOutput);
	HookEntityOutput("func_physbox", "OnPhysGunPickup", Output_OnEntityOutput);
	HookEntityOutput("func_physbox", "OnPhysGunPunt", Output_OnEntityOutput);
	HookEntityOutput("func_physbox", "OnPlayerUse", Output_OnEntityOutput);
	HookEntityOutput("func_physbox", "OnUser1", Output_OnEntityOutput);
	HookEntityOutput("func_physbox", "OnUser2", Output_OnEntityOutput);
	HookEntityOutput("func_physbox", "OnUser3", Output_OnEntityOutput);
	HookEntityOutput("func_physbox", "OnUser4", Output_OnEntityOutput);
	HookEntityOutput("func_physbox_multiplayer", "OnAwakened", Output_OnEntityOutput);
	HookEntityOutput("func_physbox_multiplayer", "OnBreak", Output_OnEntityOutput);
	HookEntityOutput("func_physbox_multiplayer", "OnDamaged", Output_OnEntityOutput);
	HookEntityOutput("func_physbox_multiplayer", "OnHealthChanged", Output_OnEntityOutput);
	HookEntityOutput("func_physbox_multiplayer", "OnMotionEnabled", Output_OnEntityOutput);
	HookEntityOutput("func_physbox_multiplayer", "OnPhysGunDrop", Output_OnEntityOutput);
	HookEntityOutput("func_physbox_multiplayer", "OnPhysGunOnlyPickup", Output_OnEntityOutput);
	HookEntityOutput("func_physbox_multiplayer", "OnPhysGunPickup", Output_OnEntityOutput);
	HookEntityOutput("func_physbox_multiplayer", "OnPhysGunPunt", Output_OnEntityOutput);
	HookEntityOutput("func_physbox_multiplayer", "OnPlayerUse", Output_OnEntityOutput);
	HookEntityOutput("func_physbox_multiplayer", "OnUser1", Output_OnEntityOutput);
	HookEntityOutput("func_physbox_multiplayer", "OnUser2", Output_OnEntityOutput);
	HookEntityOutput("func_physbox_multiplayer", "OnUser3", Output_OnEntityOutput);
	HookEntityOutput("func_physbox_multiplayer", "OnUser4", Output_OnEntityOutput);
	HookEntityOutput("func_rotating", "OnGetSpeed", Output_OnEntityOutput);
	HookEntityOutput("func_rotating", "OnUser1", Output_OnEntityOutput);
	HookEntityOutput("func_rotating", "OnUser2", Output_OnEntityOutput);
	HookEntityOutput("func_rotating", "OnUser3", Output_OnEntityOutput);
	HookEntityOutput("func_rotating", "OnUser4", Output_OnEntityOutput);
	HookEntityOutput("func_tanktrain", "OnArrivedAtDestinationNode", Output_OnEntityOutput);
	HookEntityOutput("func_tanktrain", "OnDeath", Output_OnEntityOutput);
	HookEntityOutput("func_tanktrain", "OnStart", Output_OnEntityOutput);
	HookEntityOutput("func_tanktrain", "OnUser1", Output_OnEntityOutput);
	HookEntityOutput("func_tanktrain", "OnUser2", Output_OnEntityOutput);
	HookEntityOutput("func_tanktrain", "OnUser3", Output_OnEntityOutput);
	HookEntityOutput("func_tanktrain", "OnUser4", Output_OnEntityOutput);
	HookEntityOutput("func_tracktrain", "OnArrivedAtDestinationNode", Output_OnEntityOutput);
	HookEntityOutput("func_tracktrain", "OnStart", Output_OnEntityOutput);
	HookEntityOutput("func_tracktrain", "OnUser1", Output_OnEntityOutput);
	HookEntityOutput("func_tracktrain", "OnUser2", Output_OnEntityOutput);
	HookEntityOutput("func_tracktrain", "OnUser3", Output_OnEntityOutput);
	HookEntityOutput("func_tracktrain", "OnUser4", Output_OnEntityOutput);
	HookEntityOutput("func_train", "OnUser1", Output_OnEntityOutput);
	HookEntityOutput("func_train", "OnUser2", Output_OnEntityOutput);
	HookEntityOutput("func_train", "OnUser3", Output_OnEntityOutput);
	HookEntityOutput("func_train", "OnUser4", Output_OnEntityOutput);
	HookEntityOutput("func_wall", "OnUser1", Output_OnEntityOutput);
	HookEntityOutput("func_wall", "OnUser2", Output_OnEntityOutput);
	HookEntityOutput("func_wall", "OnUser3", Output_OnEntityOutput);
	HookEntityOutput("func_wall", "OnUser4", Output_OnEntityOutput);
	HookEntityOutput("func_wall_toggle", "OnUser1", Output_OnEntityOutput);
	HookEntityOutput("func_wall_toggle", "OnUser2", Output_OnEntityOutput);
	HookEntityOutput("func_wall_toggle", "OnUser3", Output_OnEntityOutput);
	HookEntityOutput("func_wall_toggle", "OnUser4", Output_OnEntityOutput);
	HookEntityOutput("func_water_analog", "OnFullyClosed", Output_OnEntityOutput);
	HookEntityOutput("func_water_analog", "OnFullyOpen", Output_OnEntityOutput);
	HookEntityOutput("func_water_analog", "OnUser1", Output_OnEntityOutput);
	HookEntityOutput("func_water_analog", "OnUser2", Output_OnEntityOutput);
	HookEntityOutput("func_water_analog", "OnUser3", Output_OnEntityOutput);
	HookEntityOutput("func_water_analog", "OnUser4", Output_OnEntityOutput);
	HookEntityOutput("game_ui", "AttackAxis", Output_OnEntityOutput);
	HookEntityOutput("game_ui", "Attack2Axis", Output_OnEntityOutput);
	HookEntityOutput("game_ui", "OnUser1", Output_OnEntityOutput);
	HookEntityOutput("game_ui", "OnUser2", Output_OnEntityOutput);
	HookEntityOutput("game_ui", "OnUser3", Output_OnEntityOutput);
	HookEntityOutput("game_ui", "OnUser4", Output_OnEntityOutput);
	HookEntityOutput("game_ui", "PlayerOff", Output_OnEntityOutput);
	HookEntityOutput("game_ui", "PlayerOn", Output_OnEntityOutput);
	HookEntityOutput("game_ui", "PressedAttack", Output_OnEntityOutput);
	HookEntityOutput("game_ui", "PressedAttack2", Output_OnEntityOutput);
	HookEntityOutput("game_ui", "PressedBack", Output_OnEntityOutput);
	HookEntityOutput("game_ui", "PressedForward", Output_OnEntityOutput);
	HookEntityOutput("game_ui", "PressedMoveLeft", Output_OnEntityOutput);
	HookEntityOutput("game_ui", "PressedMoveRight", Output_OnEntityOutput);
	HookEntityOutput("game_ui", "UnpressedAttack", Output_OnEntityOutput);
	HookEntityOutput("game_ui", "UnpressedAttack2", Output_OnEntityOutput);
	HookEntityOutput("game_ui", "UnpressedBack", Output_OnEntityOutput);
	HookEntityOutput("game_ui", "UnpressedForward", Output_OnEntityOutput);
	HookEntityOutput("game_ui", "UnpressedMoveLeft", Output_OnEntityOutput);
	HookEntityOutput("game_ui", "UnpressedMoveRight", Output_OnEntityOutput);
	HookEntityOutput("game_ui", "XAxis", Output_OnEntityOutput);
	HookEntityOutput("game_ui", "YAxis", Output_OnEntityOutput);
	HookEntityOutput("logic_branch", "OnTrue", Output_OnEntityOutput);
	HookEntityOutput("logic_branch", "OnFalse", Output_OnEntityOutput);
	HookEntityOutput("logic_branch", "OnUser1", Output_OnEntityOutput);
	HookEntityOutput("logic_branch", "OnUser2", Output_OnEntityOutput);
	HookEntityOutput("logic_branch", "OnUser3", Output_OnEntityOutput);
	HookEntityOutput("logic_branch", "OnUser4", Output_OnEntityOutput);
	HookEntityOutput("logic_case", "OnCase01", Output_OnEntityOutput);
	HookEntityOutput("logic_case", "OnCase02", Output_OnEntityOutput);
	HookEntityOutput("logic_case", "OnCase03", Output_OnEntityOutput);
	HookEntityOutput("logic_case", "OnCase04", Output_OnEntityOutput);
	HookEntityOutput("logic_case", "OnCase05", Output_OnEntityOutput);
	HookEntityOutput("logic_case", "OnCase06", Output_OnEntityOutput);
	HookEntityOutput("logic_case", "OnCase07", Output_OnEntityOutput);
	HookEntityOutput("logic_case", "OnCase08", Output_OnEntityOutput);
	HookEntityOutput("logic_case", "OnCase09", Output_OnEntityOutput);
	HookEntityOutput("logic_case", "OnCase10", Output_OnEntityOutput);
	HookEntityOutput("logic_case", "OnCase11", Output_OnEntityOutput);
	HookEntityOutput("logic_case", "OnCase12", Output_OnEntityOutput);
	HookEntityOutput("logic_case", "OnCase13", Output_OnEntityOutput);
	HookEntityOutput("logic_case", "OnCase14", Output_OnEntityOutput);
	HookEntityOutput("logic_case", "OnCase15", Output_OnEntityOutput);
	HookEntityOutput("logic_case", "OnDefault", Output_OnEntityOutput);
	HookEntityOutput("logic_case", "OnUser1", Output_OnEntityOutput);
	HookEntityOutput("logic_case", "OnUser2", Output_OnEntityOutput);
	HookEntityOutput("logic_case", "OnUser3", Output_OnEntityOutput);
	HookEntityOutput("logic_case", "OnUser4", Output_OnEntityOutput);
	HookEntityOutput("logic_compare", "OnEqualTo", Output_OnEntityOutput);
	HookEntityOutput("logic_compare", "OnGreaterThan", Output_OnEntityOutput);
	HookEntityOutput("logic_compare", "OnLessThan", Output_OnEntityOutput);
	HookEntityOutput("logic_compare", "OnNotEqualTo", Output_OnEntityOutput);
	HookEntityOutput("logic_compare", "OnUser1", Output_OnEntityOutput);
	HookEntityOutput("logic_compare", "OnUser2", Output_OnEntityOutput);
	HookEntityOutput("logic_compare", "OnUser3", Output_OnEntityOutput);
	HookEntityOutput("logic_compare", "OnUser4", Output_OnEntityOutput);
	HookEntityOutput("logic_relay", "OnSpawn", Output_OnEntityOutput);
	HookEntityOutput("logic_relay", "OnTrigger", Output_OnEntityOutput);
	HookEntityOutput("logic_relay", "OnUser1", Output_OnEntityOutput);
	HookEntityOutput("logic_relay", "OnUser2", Output_OnEntityOutput);
	HookEntityOutput("logic_relay", "OnUser3", Output_OnEntityOutput);
	HookEntityOutput("logic_relay", "OnUser4", Output_OnEntityOutput);
	HookEntityOutput("logic_timer", "OnTimer", Output_OnEntityOutput);
	HookEntityOutput("logic_timer", "OnTimerHigh", Output_OnEntityOutput);
	HookEntityOutput("logic_timer", "OnTimerLow", Output_OnEntityOutput);
	HookEntityOutput("logic_timer", "OnUser1", Output_OnEntityOutput);
	HookEntityOutput("logic_timer", "OnUser2", Output_OnEntityOutput);
	HookEntityOutput("logic_timer", "OnUser3", Output_OnEntityOutput);
	HookEntityOutput("logic_timer", "OnUser4", Output_OnEntityOutput);
	HookEntityOutput("math_counter", "OnChangedFromMax", Output_OnEntityOutput);
	HookEntityOutput("math_counter", "OnChangedFromMin", Output_OnEntityOutput);
	HookEntityOutput("math_counter", "OnGetValue", Output_OnEntityOutput);
	HookEntityOutput("math_counter", "OnHitMax", Output_OnEntityOutput);
	HookEntityOutput("math_counter", "OnHitMin", Output_OnEntityOutput);
	HookEntityOutput("math_counter", "OnUser1", Output_OnEntityOutput);
	HookEntityOutput("math_counter", "OnUser2", Output_OnEntityOutput);
	HookEntityOutput("math_counter", "OnUser3", Output_OnEntityOutput);
	HookEntityOutput("math_counter", "OnUser4", Output_OnEntityOutput);
	HookEntityOutput("math_counter", "OutValue", Output_OnEntityOutput);
	HookEntityOutput("point_template", "OnEntitySpawned", Output_OnEntityOutput);
	HookEntityOutput("point_template", "OnUser1", Output_OnEntityOutput);
	HookEntityOutput("point_template", "OnUser2", Output_OnEntityOutput);
	HookEntityOutput("point_template", "OnUser3", Output_OnEntityOutput);
	HookEntityOutput("point_template", "OnUser4", Output_OnEntityOutput);
	HookEntityOutput("prop_dynamic", "OnAnimationBegun", Output_OnEntityOutput);
	HookEntityOutput("prop_dynamic", "OnAnimationDone", Output_OnEntityOutput);
	HookEntityOutput("prop_dynamic", "OnBreak", Output_OnEntityOutput);
	HookEntityOutput("prop_dynamic", "OnHealthChanged", Output_OnEntityOutput);
	HookEntityOutput("prop_dynamic", "OnIgnite", Output_OnEntityOutput);
	HookEntityOutput("prop_dynamic", "OnPhysCannonAnimatePreStarted", Output_OnEntityOutput);
	HookEntityOutput("prop_dynamic", "OnPhysCannonAnimatePostStarted", Output_OnEntityOutput);
	HookEntityOutput("prop_dynamic", "OnPhysCannonAnimatePullStarted", Output_OnEntityOutput);
	HookEntityOutput("prop_dynamic", "OnPhysCannonDetach", Output_OnEntityOutput);
	HookEntityOutput("prop_dynamic", "OnPhysCannonPullAnimFinished", Output_OnEntityOutput);
	HookEntityOutput("prop_dynamic", "OnTakeDamage", Output_OnEntityOutput);
	HookEntityOutput("prop_dynamic", "OnUser1", Output_OnEntityOutput);
	HookEntityOutput("prop_dynamic", "OnUser2", Output_OnEntityOutput);
	HookEntityOutput("prop_dynamic", "OnUser3", Output_OnEntityOutput);
	HookEntityOutput("prop_dynamic", "OnUser4", Output_OnEntityOutput);
	HookEntityOutput("prop_dynamic_override", "OnAnimationBegun", Output_OnEntityOutput);
	HookEntityOutput("prop_dynamic_override", "OnAnimationDone", Output_OnEntityOutput);
	HookEntityOutput("prop_dynamic_override", "OnBreak", Output_OnEntityOutput);
	HookEntityOutput("prop_dynamic_override", "OnHealthChanged", Output_OnEntityOutput);
	HookEntityOutput("prop_dynamic_override", "OnIgnite", Output_OnEntityOutput);
	HookEntityOutput("prop_dynamic_override", "OnPhysCannonAnimatePreStarted", Output_OnEntityOutput);
	HookEntityOutput("prop_dynamic_override", "OnPhysCannonAnimatePostStarted", Output_OnEntityOutput);
	HookEntityOutput("prop_dynamic_override", "OnPhysCannonAnimatePullStarted", Output_OnEntityOutput);
	HookEntityOutput("prop_dynamic_override", "OnPhysCannonDetach", Output_OnEntityOutput);
	HookEntityOutput("prop_dynamic_override", "OnPhysCannonPullAnimFinished", Output_OnEntityOutput);
	HookEntityOutput("prop_dynamic_override", "OnTakeDamage", Output_OnEntityOutput);
	HookEntityOutput("prop_dynamic_override", "OnUser1", Output_OnEntityOutput);
	HookEntityOutput("prop_dynamic_override", "OnUser2", Output_OnEntityOutput);
	HookEntityOutput("prop_dynamic_override", "OnUser3", Output_OnEntityOutput);
	HookEntityOutput("prop_dynamic_override", "OnUser4", Output_OnEntityOutput);
	HookEntityOutput("prop_physics", "OnAwakened", Output_OnEntityOutput);
	HookEntityOutput("prop_physics", "OnBreak", Output_OnEntityOutput);
	HookEntityOutput("prop_physics", "OnHealthChanged", Output_OnEntityOutput);
	HookEntityOutput("prop_physics", "OnIgnite", Output_OnEntityOutput);
	HookEntityOutput("prop_physics", "OnMotionEnabled", Output_OnEntityOutput);
	HookEntityOutput("prop_physics", "OnOutOfWorld", Output_OnEntityOutput);
	HookEntityOutput("prop_physics", "OnPhysCannonAnimatePreStarted", Output_OnEntityOutput);
	HookEntityOutput("prop_physics", "OnPhysCannonAnimatePostStarted", Output_OnEntityOutput);
	HookEntityOutput("prop_physics", "OnPhysCannonAnimatePullStarted", Output_OnEntityOutput);
	HookEntityOutput("prop_physics", "OnPhysCannonDetach", Output_OnEntityOutput);
	HookEntityOutput("prop_physics", "OnPhysCannonPullAnimFinished", Output_OnEntityOutput);
	HookEntityOutput("prop_physics", "OnPhysGunDrop", Output_OnEntityOutput);
	HookEntityOutput("prop_physics", "OnPhysGunOnlyPickup", Output_OnEntityOutput);
	HookEntityOutput("prop_physics", "OnPhysGunPickup", Output_OnEntityOutput);
	HookEntityOutput("prop_physics", "OnPhysGunPunt", Output_OnEntityOutput);
	HookEntityOutput("prop_physics", "OnPlayerUse", Output_OnEntityOutput);
	HookEntityOutput("prop_physics", "OnPlayerPickup", Output_OnEntityOutput);
	HookEntityOutput("prop_physics", "OnTakeDamage", Output_OnEntityOutput);
	HookEntityOutput("prop_physics", "OnUser1", Output_OnEntityOutput);
	HookEntityOutput("prop_physics", "OnUser2", Output_OnEntityOutput);
	HookEntityOutput("prop_physics", "OnUser3", Output_OnEntityOutput);
	HookEntityOutput("prop_physics", "OnUser4", Output_OnEntityOutput);
	HookEntityOutput("prop_physics_multiplayer", "OnAwakened", Output_OnEntityOutput);
	HookEntityOutput("prop_physics_multiplayer", "OnBreak", Output_OnEntityOutput);
	HookEntityOutput("prop_physics_multiplayer", "OnHealthChanged", Output_OnEntityOutput);
	HookEntityOutput("prop_physics_multiplayer", "OnIgnite", Output_OnEntityOutput);
	HookEntityOutput("prop_physics_multiplayer", "OnMotionEnabled", Output_OnEntityOutput);
	HookEntityOutput("prop_physics_multiplayer", "OnOutOfWorld", Output_OnEntityOutput);
	HookEntityOutput("prop_physics_multiplayer", "OnPhysCannonAnimatePreStarted", Output_OnEntityOutput);
	HookEntityOutput("prop_physics_multiplayer", "OnPhysCannonAnimatePostStarted", Output_OnEntityOutput);
	HookEntityOutput("prop_physics_multiplayer", "OnPhysCannonAnimatePullStarted", Output_OnEntityOutput);
	HookEntityOutput("prop_physics_multiplayer", "OnPhysCannonDetach", Output_OnEntityOutput);
	HookEntityOutput("prop_physics_multiplayer", "OnPhysCannonPullAnimFinished", Output_OnEntityOutput);
	HookEntityOutput("prop_physics_multiplayer", "OnPhysGunDrop", Output_OnEntityOutput);
	HookEntityOutput("prop_physics_multiplayer", "OnPhysGunOnlyPickup", Output_OnEntityOutput);
	HookEntityOutput("prop_physics_multiplayer", "OnPhysGunPickup", Output_OnEntityOutput);
	HookEntityOutput("prop_physics_multiplayer", "OnPhysGunPunt", Output_OnEntityOutput);
	HookEntityOutput("prop_physics_multiplayer", "OnPlayerUse", Output_OnEntityOutput);
	HookEntityOutput("prop_physics_multiplayer", "OnPlayerPickup", Output_OnEntityOutput);
	HookEntityOutput("prop_physics_multiplayer", "OnTakeDamage", Output_OnEntityOutput);
	HookEntityOutput("prop_physics_multiplayer", "OnUser1", Output_OnEntityOutput);
	HookEntityOutput("prop_physics_multiplayer", "OnUser2", Output_OnEntityOutput);
	HookEntityOutput("prop_physics_multiplayer", "OnUser3", Output_OnEntityOutput);
	HookEntityOutput("prop_physics_multiplayer", "OnUser4", Output_OnEntityOutput);
	HookEntityOutput("prop_physics_override", "OnAwakened", Output_OnEntityOutput);
	HookEntityOutput("prop_physics_override", "OnBreak", Output_OnEntityOutput);
	HookEntityOutput("prop_physics_override", "OnHealthChanged", Output_OnEntityOutput);
	HookEntityOutput("prop_physics_override", "OnIgnite", Output_OnEntityOutput);
	HookEntityOutput("prop_physics_override", "OnMotionEnabled", Output_OnEntityOutput);
	HookEntityOutput("prop_physics_override", "OnOutOfWorld", Output_OnEntityOutput);
	HookEntityOutput("prop_physics_override", "OnPhysCannonAnimatePreStarted", Output_OnEntityOutput);
	HookEntityOutput("prop_physics_override", "OnPhysCannonAnimatePostStarted", Output_OnEntityOutput);
	HookEntityOutput("prop_physics_override", "OnPhysCannonAnimatePullStarted", Output_OnEntityOutput);
	HookEntityOutput("prop_physics_override", "OnPhysCannonDetach", Output_OnEntityOutput);
	HookEntityOutput("prop_physics_override", "OnPhysCannonPullAnimFinished", Output_OnEntityOutput);
	HookEntityOutput("prop_physics_override", "OnPhysGunDrop", Output_OnEntityOutput);
	HookEntityOutput("prop_physics_override", "OnPhysGunOnlyPickup", Output_OnEntityOutput);
	HookEntityOutput("prop_physics_override", "OnPhysGunPickup", Output_OnEntityOutput);
	HookEntityOutput("prop_physics_override", "OnPhysGunPunt", Output_OnEntityOutput);
	HookEntityOutput("prop_physics_override", "OnPlayerUse", Output_OnEntityOutput);
	HookEntityOutput("prop_physics_override", "OnPlayerPickup", Output_OnEntityOutput);
	HookEntityOutput("prop_physics_override", "OnTakeDamage", Output_OnEntityOutput);
	HookEntityOutput("prop_physics_override", "OnUser1", Output_OnEntityOutput);
	HookEntityOutput("prop_physics_override", "OnUser2", Output_OnEntityOutput);
	HookEntityOutput("prop_physics_override", "OnUser3", Output_OnEntityOutput);
	HookEntityOutput("prop_physics_override", "OnUser4", Output_OnEntityOutput);
	HookEntityOutput("trigger_hurt", "OnHurt", Output_OnEntityOutput);
	HookEntityOutput("trigger_hurt", "OnHurtPlayer", Output_OnEntityOutput);
	HookEntityOutput("trigger_hurt", "OnEndTouch", Output_OnEntityOutput);
	HookEntityOutput("trigger_hurt", "OnEndTouchAll", Output_OnEntityOutput);
	HookEntityOutput("trigger_hurt", "OnNotTouching", Output_OnEntityOutput);
	HookEntityOutput("trigger_hurt", "OnStartTouch", Output_OnEntityOutput);
	HookEntityOutput("trigger_hurt", "OnStartTouchAll", Output_OnEntityOutput);
	HookEntityOutput("trigger_hurt", "OnTouching", Output_OnEntityOutput);
	HookEntityOutput("trigger_hurt", "OnUser1", Output_OnEntityOutput);
	HookEntityOutput("trigger_hurt", "OnUser2", Output_OnEntityOutput);
	HookEntityOutput("trigger_hurt", "OnUser3", Output_OnEntityOutput);
	HookEntityOutput("trigger_hurt", "OnUser4", Output_OnEntityOutput);
	HookEntityOutput("trigger_multiple", "OnEndTouch", Output_OnEntityOutput);
	HookEntityOutput("trigger_multiple", "OnEndTouchAll", Output_OnEntityOutput);
	HookEntityOutput("trigger_multiple", "OnNotTouching", Output_OnEntityOutput);
	HookEntityOutput("trigger_multiple", "OnStartTouch", Output_OnEntityOutput);
	HookEntityOutput("trigger_multiple", "OnStartTouchAll", Output_OnEntityOutput);
	HookEntityOutput("trigger_multiple", "OnTouching", Output_OnEntityOutput);
	HookEntityOutput("trigger_multiple", "OnTrigger", Output_OnEntityOutput);
	HookEntityOutput("trigger_multiple", "OnUser1", Output_OnEntityOutput);
	HookEntityOutput("trigger_multiple", "OnUser2", Output_OnEntityOutput);
	HookEntityOutput("trigger_multiple", "OnUser3", Output_OnEntityOutput);
	HookEntityOutput("trigger_multiple", "OnUser4", Output_OnEntityOutput);
	HookEntityOutput("trigger_once", "OnEndTouch", Output_OnEntityOutput);
	HookEntityOutput("trigger_once", "OnEndTouchAll", Output_OnEntityOutput);
	HookEntityOutput("trigger_once", "OnNotTouching", Output_OnEntityOutput);
	HookEntityOutput("trigger_once", "OnStartTouch", Output_OnEntityOutput);
	HookEntityOutput("trigger_once", "OnStartTouchAll", Output_OnEntityOutput);
	HookEntityOutput("trigger_once", "OnTouching", Output_OnEntityOutput);
	HookEntityOutput("trigger_once", "OnTrigger", Output_OnEntityOutput);
	HookEntityOutput("trigger_once", "OnUser1", Output_OnEntityOutput);
	HookEntityOutput("trigger_once", "OnUser2", Output_OnEntityOutput);
	HookEntityOutput("trigger_once", "OnUser3", Output_OnEntityOutput);
	HookEntityOutput("trigger_once", "OnUser4", Output_OnEntityOutput);
	HookEntityOutput("trigger_push", "OnEndTouch", Output_OnEntityOutput);
	HookEntityOutput("trigger_push", "OnEndTouchAll", Output_OnEntityOutput);
	HookEntityOutput("trigger_push", "OnNotTouching", Output_OnEntityOutput);
	HookEntityOutput("trigger_push", "OnStartTouch", Output_OnEntityOutput);
	HookEntityOutput("trigger_push", "OnStartTouchAll", Output_OnEntityOutput);
	HookEntityOutput("trigger_push", "OnTouching", Output_OnEntityOutput);
	HookEntityOutput("trigger_push", "OnUser1", Output_OnEntityOutput);
	HookEntityOutput("trigger_push", "OnUser2", Output_OnEntityOutput);
	HookEntityOutput("trigger_push", "OnUser3", Output_OnEntityOutput);
	HookEntityOutput("trigger_push", "OnUser4", Output_OnEntityOutput);
	HookEntityOutput("trigger_teleport", "OnEndTouch", Output_OnEntityOutput);
	HookEntityOutput("trigger_teleport", "OnEndTouchAll", Output_OnEntityOutput);
	HookEntityOutput("trigger_teleport", "OnNotTouching", Output_OnEntityOutput);
	HookEntityOutput("trigger_teleport", "OnStartTouch", Output_OnEntityOutput);
	HookEntityOutput("trigger_teleport", "OnStartTouchAll", Output_OnEntityOutput);
	HookEntityOutput("trigger_teleport", "OnTouching", Output_OnEntityOutput);
	HookEntityOutput("trigger_teleport", "OnUser1", Output_OnEntityOutput);
	HookEntityOutput("trigger_teleport", "OnUser2", Output_OnEntityOutput);
	HookEntityOutput("trigger_teleport", "OnUser3", Output_OnEntityOutput);
	HookEntityOutput("trigger_teleport", "OnUser4", Output_OnEntityOutput);
	
	AddCommandListener(CommandListener_JoinTeam, "jointeam");
	
	RegConsoleCmd("sm_t", Command_Terrorist);
	RegConsoleCmd("sm_kb", Command_KillBot);
	RegConsoleCmd("sm_hud", Command_Hud);
	RegConsoleCmd("sm_life", Command_Life, "sm_life <#userid|name>");
	RegConsoleCmd("sm_free", Command_Free);
	RegConsoleCmd("sm_hide", Command_Hide);
	RegConsoleCmd("sm_speed", Command_Speed);
	RegAdminCmd("sm_finish", Command_Finish, ADMFLAG_RCON);

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
		{
			continue;
		}
		
		OnClientConnected(i);
		OnClientPutInServer(i);
		
		if (AreClientCookiesCached(i))
		{
			OnClientCookiesCached(i);
		}
	}
	
	if (g_IsPluginLoadedLate && !view_as<bool>(g_RoundFlags & ROUND_HAS_ENDED))
	{
		CS_TerminateRound(g_Cvar_RoundRestartDelay ? g_Cvar_RoundRestartDelay.FloatValue : 3.0, CSRoundEnd_Draw, true);
	}
}

public void OnPluginEnd()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
		{
			continue;
		}
		
		RemoveEntityGlow(i);
		RemoveClientProtection(i);
		SaveClientCookies(i);
	}
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "adminstealth", true))
	{
		g_IsStealthLibraryLoaded = true;
	}
	else if (StrEqual(name, "entityIO", true))
	{
		g_IsEntityIOLibraryLoaded = true;
	}
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "adminstealth", true))
	{
		g_IsStealthLibraryLoaded = false;
	}
	else if (StrEqual(name, "entityIO", true))
	{
		g_IsEntityIOLibraryLoaded = false;
	}
}

public void OnMapStart()
{
	g_NumFinishers = 0;
	g_OutputActionId = 0;
	g_RoundFlags = 0;
	g_TerroristId = 0;
	g_TerroristKillerId = 0;
	g_TotalRoundsPlayed = 0;
	
	g_WarmupDuration = 0.0;
	g_EndZoneOrigin[0] = 0.0;
	g_EndZoneOrigin[1] = 0.0;
	g_EndZoneOrigin[2] = 0.0;
	
	AddFileToDownloadsTable("materials/panorama/images/icons/equipment/trap.svg");
	
	PrecacheSound("buttons/button8.wav");
	PrecacheSound("player/pl_respawn.wav");
	PrecacheSound("survival/rocketalarmclose.wav");
	PrecacheSound("ui/armsrace_become_leader_team.wav");
	
	PrecacheModel("models/error.mdl");
	g_BeamModel = PrecacheModel("sprites/laserbeam.vmt");
	
	CreateTimer(TIMER_THINK_INTERVAL, Timer_Think, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public void OnConfigsExecuted()
{
	RequestFrame(Frame_OnConfigsExecuted);
}

public void OnMapEnd()
{
	ClearArray_Ex(g_List_BreakablesOnFirstMove);
	ClearArray_Ex(g_List_BreakablesOnKill);
	ClearArray_Ex(g_List_BreakablesOnMove);
	ClearArray_Ex(g_List_BreakablesOnReverse);
	ClearArray_Ex(g_List_BreakablesOnSpeed);
	ClearArray_Ex(g_List_ProximityTraps);
	ClearArray_Ex(g_List_RemoveEntities);
	ClearArray_Ex(g_List_ReplacedTraps);
	ClearArray_Ex(g_List_TerroristQueue);
	ClearArray_Ex(g_List_ThinkTraps);
	ClearArray_Ex(g_List_Zones);
	
	ClearTrie_Ex(view_as<StringMap>(g_Map_BreakablesOnFirstMove));
	ClearTrie_Ex(view_as<StringMap>(g_Map_BreakablesOnKill));
	ClearTrie_Ex(view_as<StringMap>(g_Map_BreakablesOnMove));
	ClearTrie_Ex(view_as<StringMap>(g_Map_BreakablesOnReverse));
	ClearTrie_Ex(view_as<StringMap>(g_Map_BreakablesOnSpeed));
	ClearTrie_Ex(view_as<StringMap>(g_Map_CurrentEndActivators));
	ClearTrie_Ex(view_as<StringMap>(g_Map_Disconnections));
	ClearTrie_Ex(view_as<StringMap>(g_Map_Endings));
	ClearTrie_Ex(view_as<StringMap>(g_Map_OutputActions));
	ClearTrie_Ex(view_as<StringMap>(g_Map_Traps));
	
	ClearTrie_Ex(g_Map_EndActivators);
	ClearTrie_Ex(g_Map_NumTraps);
	ClearTrie_Ex(g_Map_ReplacedTraps);
	ClearTrie_Ex(g_Map_TrapActivators);
	ClearTrie_Ex(g_Map_TrapFlags);
}

public void OnEntityCreated(int entity, const char[] classname)
{
	ClassType classType;
	if (g_Map_ClassNames.GetValue(classname, classType))
	{
		switch (classType)
		{
			case ClassType_CsRagdoll:
			{
				float gameTime = GetGameTime();
				RemoveEntityInfo removeEntityInfo;
				
				removeEntityInfo.removeTime = gameTime + g_Cvar_DeathAnimTime.FloatValue + 1.0;
				removeEntityInfo.reference = EntIndexToEntRef_Ex(entity);
				
				AddEntityInRemoveList(removeEntityInfo);
			}
			
			case ClassType_FuncButton:
			{
				SDKHook(entity, SDKHook_Spawn, SDK_ButtonSpawn);
				SDKHook(entity, SDKHook_Use, SDK_ButtonUse);
			}
			
			case ClassType_GamePlayerEquip:
			{
				SDKHook(entity, SDKHook_Spawn, SDK_GamePlayerEquipSpawn);
			}
			
			case ClassType_PropDoorRotating:
			{
				SDKHook(entity, SDKHook_Spawn, SDK_PropDoorSpawn);
			}
			
			case ClassType_TriggerHurt:
			{
				SDKHook(entity, SDKHook_Touch, SDK_HurtTouch);
				SDKHook(entity, SDKHook_EndTouchPost, SDK_HurtEndTouch_Post);
			}
			
			case ClassType_TriggerMultiple, ClassType_TriggerOnce:
			{
				SDKHook(entity, SDKHook_Spawn, SDK_TriggerSpawn);
			}
			
			case ClassType_TriggerTeleport:
			{
				SDKHook(entity, SDKHook_Spawn, SDK_TriggerSpawn);
				SDKHook(entity, SDKHook_EndTouchPost, SDK_TeleportEndTouch_Post);
			}
		}
	}
	else if (!strncmp(classname, "weapon_", 7, true))
	{
		SDKHook(entity, SDKHook_ReloadPost, SDK_OnWeaponReload_Post);
	}
}

public void OnEntityDestroyed(int entity)
{
	if (!IsValidEntity(entity))
	{
		return;
	}
	
	int reference = EntIndexToEntRef_Ex(entity);
	
	g_Map_Traps.Remove(reference);
	RemoveCellFromArrayList(reference, g_List_ProximityTraps);
}

public void OnClientConnected(int client)
{
	float gameTime = GetGameTime();
	
	g_LastObserver[client] = 0;
	g_NumSpectators[client] = 0;
	g_NumWarmups[client] = 0;
	g_PlayerFlags[client] = 0;
	g_TimerButtons[client] = 0;
	
	g_PlayerGlow[client] = INVALID_ENT_REFERENCE;
	
	g_LifeTransferDelay[client] = 0.0;
	g_RefillAmmoTime[client] = 0.0;
	g_RemoveProtectionTime[client] = 0.0;
	
	g_KillFeedType[client] = KillFeedType_None;
	
	g_HudInfo[client].inCookies = false;
	g_HudInfo[client].displayFlags = HUD_DISPLAY_DEFAULT;
	
	g_MoveInfo[client].moveTime = 0.0;
	g_MoveInfo[client].toTeam = CS_TEAM_NONE;
	
	g_SpeedInfo[client].speedType = SpeedType_Normal;
	g_SpeedInfo[client].maxSpeedType = SpeedType_Normal;
	
	g_ShakeInfo[client].activatorId = 0;
	g_ShakeInfo[client].shakeTime = 0.0;
	
	g_FinishInfo[client].finishMin = 0;
	g_FinishInfo[client].finishSec = 0;
	g_FinishInfo[client].finishMs = 0;
	g_FinishInfo[client].finishPos = 0;
	
	g_RespawnInfo[client].respawnTime = 0.0;
	g_RespawnInfo[client].respawnType = RespawnType_None;
	
	g_TerroristInfo[client].numRequests = 0;
	g_TerroristInfo[client].lastRound = 0;
	g_TerroristInfo[client].lastTime = gameTime;
	
	g_TrapProximityInfo[client].inProximity = false;
	g_TrapProximityInfo[client].activatorId = 0;
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_TraceAttack, SDK_TraceAttack);
	SDKHook(client, SDKHook_OnTakeDamage, SDK_OnTakeDamage);
	SDKHook(client, SDKHook_SetTransmit, SDK_PlayerTransmit);
}

public void OnClientCookiesCached(int client)
{
	if (g_Cookie_HudDisplay)
	{
		char buffer[256];
		g_Cookie_HudDisplay.Get(client, buffer, sizeof(buffer));
		
		if (buffer[0])
		{
			g_HudInfo[client].displayFlags = StringToInt(buffer);
			g_HudInfo[client].inCookies = true;
		}
	}
}

public void OnClientDisconnect(int client)
{
	SaveClientCookies(client);
	if (IsValveWarmupPeriod())
	{
		return;
	}
	
	int numFinishers;
	int userId = GetClientUserId(client);
	bool allCTsFinished = IsMapFinishedByAllCTs(numFinishers, client);
	
	if (!view_as<bool>(g_RoundFlags & ROUND_HAS_ENDED))
	{
		if (userId == g_TerroristId)
		{
			g_TerroristId = 0;
			g_RoundFlags &= ~ROUND_IS_FREERUN;
			
			int terroristKiller = GetTerroristKiller();
			if (terroristKiller)
			{
				HideDuelHudFromAll();
			}
			
			if (allCTsFinished)
			{
				OnMapFinishedByAllCTs(numFinishers);
			}
		}
		else if (userId == g_TerroristKillerId)
		{
			FindNextTerroristKiller();
		}
		else if (allCTsFinished)
		{
			OnMapFinishedByAllCTs(numFinishers);
		}
	}
	
	RemoveCellFromArrayList(userId, g_List_TerroristQueue);
	
	int accountId = GetSteamAccountID(client);
	if (accountId)
	{
		DisconnectInfo disconInfo;
		disconInfo.numWarmups = g_NumWarmups[client];
		disconInfo.lastRoundPlayed = g_TotalRoundsPlayed;
		
		disconInfo.terroristRequests = g_TerroristInfo[client].numRequests;
		disconInfo.lastTerroristRound = g_TerroristInfo[client].lastRound;
		
		g_Map_Disconnections.SetArray(accountId, disconInfo, sizeof(DisconnectInfo));
	}
}

public void ConVarChange_BotQuota(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (g_Cvar_BotQuota.IntValue != 1)
	{
		g_Cvar_BotQuota.SetInt(1);
	}
}

public void Event_PlayerConnect(Event event, const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client || !IsClientInGame(client))
	{
		return;
	}
	
	float gameTime = GetGameTime();
	
	g_MoveInfo[client].moveTime = gameTime + 1.5;
	g_MoveInfo[client].toTeam = CS_TEAM_CT;
	
	SetEntPropFloat(client, Prop_Send, "m_fForceTeam", 3600.0);
	
	if (IsValveWarmupPeriod())
	{
		return;
	}
	
	int accountId = GetSteamAccountID(client);
	if (accountId)
	{
		DisconnectInfo disconInfo;
		if (g_Map_Disconnections.GetArray(accountId, disconInfo, sizeof(DisconnectInfo)))
		{
			g_TerroristInfo[client].numRequests = disconInfo.terroristRequests;
			g_TerroristInfo[client].lastRound = disconInfo.lastTerroristRound;
			
			if (disconInfo.lastRoundPlayed == g_TotalRoundsPlayed)
			{
				g_NumWarmups[client] = disconInfo.numWarmups;
			}
			
			g_Map_Disconnections.Remove(accountId);
		}
	}
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) 
{
	int clientTeam = event.GetInt("teamnum");
	if (clientTeam < CS_TEAM_T)
	{
		return;
	}
	
	int userId = event.GetInt("userid");
	int client = GetClientOfUserId(userId);
	
	if (!client || !IsClientInGame(client))
	{
		return;
	}
	
	float gameTime = GetGameTime();
	
	g_LastObserver[client] = 0;
	g_NumSpectators[client] = 0;
	g_TimerButtons[client] = 0;
	
	g_PlayerFlags[client] &= ~PLAYER_HAS_RECEIVED_LIFE;
	g_PlayerFlags[client] &= ~PLAYER_HAS_FINISHED_MAP;
	g_PlayerFlags[client] &= ~PLAYER_IS_HIDING_OTHER_PLAYERS;
	g_PlayerFlags[client] &= ~PLAYER_IS_TOUCHING_TRIGGER_HURT;
	
	g_LifeTransferDelay[client] = 0.0;
	g_RefillAmmoTime[client] = 0.0;
	g_RemoveProtectionTime[client] = 0.0;
	
	g_KillFeedType[client] = KillFeedType_None;
	
	g_FinishInfo[client].finishMin = 0;
	g_FinishInfo[client].finishMs = 0;
	g_FinishInfo[client].finishPos = 0;
	g_FinishInfo[client].finishSec = 0;
	
	g_RespawnInfo[client].respawnTime = 0.0;
	g_RespawnInfo[client].respawnType = RespawnType_None;
	
	g_ShakeInfo[client].activatorId = 0;
	g_ShakeInfo[client].shakeTime = 0.0;
	
	g_SpeedInfo[client].maxSpeedType = SpeedType_Normal;
	g_SpeedInfo[client].speedType = SpeedType_Normal;
	
	g_TrapProximityInfo[client].inProximity = false;
	g_TrapProximityInfo[client].activatorId = 0;
	
	PrintHintText(client, "{position:1}");
	PrintHintText(client, "{position:2}");
	PrintHintText(client, "{position:3}");
	PrintHintText(client, "{position:4}");
	
	RemoveClientWeapons(client);
	SetEntProp(client, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_INTERACTIVE_DEBRIS);
	
	if (g_Cvar_SpawnProtectionTime.FloatValue > 0.0)
	{
		SetClientProtection(client);
		g_RemoveProtectionTime[client] = gameTime + g_Cvar_SpawnProtectionTime.FloatValue;
	}
	else
	{
		RemoveClientProtection(client);
	}
	
	int weapon = GivePlayerItem(client, "weapon_knife");
	if (weapon != -1)
	{
		SetEntPropString(weapon, Prop_Data, "m_iszName", "spawn_knife");
	}
	
	if (clientTeam == CS_TEAM_CT)
	{
		weapon = GivePlayerItem(client, "weapon_hkp2000");
		if (weapon != -1)
		{
			SetEntPropString(weapon, Prop_Data, "m_iszName", "spawn_secondary");
		}
	}
	else
	{
		if (userId == g_TerroristId)
		{
			if (!view_as<bool>(g_RoundFlags & ROUND_HAS_ENDED))
			{
				if (!g_RemoveProtectionTime[client])
				{
					SetEntityGlow(client, 224, 175, 86, 255);
					SetEntityRenderColor(client, 224, 175, 86, 255);
				}
				
				if (view_as<bool>(g_RoundFlags & ROUND_MAP_FINISHED))
				{
					int terroristKiller = GetTerroristKiller();
					if (terroristKiller)
					{
						DisplayDuelHudToAll(client, terroristKiller);
					}
				}
				
				RequestFrame(Frame_OnTerroristSpawn, userId);
			}
		}
		else if (!IsFakeClient(client))
		{
			g_MoveInfo[client].moveTime = gameTime + 1.0;
			g_MoveInfo[client].toTeam = CS_TEAM_CT;
		}
	}
}

public Action Event_PlayerDeath_Pre(Event event, const char[] name, bool dontBroadcast) 
{
	int userId = event.GetInt("userid");	
	int client = GetClientOfUserId(userId);
	
	if (!client || !IsClientInGame(client))
	{
		return Plugin_Continue;
	}
	
	if (g_KillFeedType[client] == KillFeedType_LifeTransfer)
	{
		event.BroadcastDisabled = true;
		return Plugin_Changed;
	}
	
	if (event.GetInt("attacker"))
	{
		if (g_KillFeedType[client] == KillFeedType_Trap)
		{
			event.SetString("weapon", "trap");
			return Plugin_Changed;
		}
		
		char weapon[256];
		event.GetString("weapon", weapon, sizeof(weapon));
		
		if (StrEqual(weapon, "point_hurt", true))
		{
			event.SetString("weapon", "trap");
			return Plugin_Changed;
		}
	}
	else
	{
		if (IsValveWarmupPeriod() 
			|| GetClientTeam(client) == CS_TEAM_CT 
				&& view_as<bool>(g_RoundFlags & ROUND_WARMUP_PERIOD) 
				&& CanPlayerRespawnInWarmup(client))
		{
			event.BroadcastDisabled = true;
			if (!IsFakeClient(client))
			{
				event.FireToClient(client);
			}
			
			return Plugin_Changed;
		}
	}
	
	return Plugin_Continue;
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) 
{
	int userId = event.GetInt("userid");	
	int client = GetClientOfUserId(userId);
	
	if (!client || !IsClientInGame(client))
	{
		return;
	}
	
	int clientTeam = GetClientTeam(client);
	int attackerId = event.GetInt("attacker");	
	float gameTime = GetGameTime();
	
	g_PlayerFlags[client] &= ~PLAYER_IS_HIDING_OTHER_PLAYERS;
	
	PrintHintText(client, "{position:1}");
	PrintHintText(client, "{position:2}");
	PrintHintText(client, "{position:3}");
	PrintHintText(client, "{position:4}");
	
	RemoveEntityGlow(client);
	
	int numFinishers;
	bool allCTsFinished = IsMapFinishedByAllCTs(numFinishers, client);
	
	if (clientTeam == CS_TEAM_T)
	{
		if (view_as<bool>(g_RoundFlags & ROUND_MAP_FINISHED) && !view_as<bool>(g_RoundFlags & ROUND_HAS_ENDED))
		{
			if (userId == g_TerroristId)
			{
				HideDuelHudFromAll();
				if (allCTsFinished)
				{
					OnMapFinishedByAllCTs(numFinishers);
				}
			}
		}
	}
	else if (clientTeam == CS_TEAM_CT)
	{
		if (view_as<bool>(g_RoundFlags & ROUND_WARMUP_PERIOD) && CanPlayerRespawnInWarmup(client))
		{
			g_RespawnInfo[client].respawnTime = gameTime + g_Cvar_RespawnDelay.FloatValue;
			g_RespawnInfo[client].respawnType = RespawnType_Warmup;
		}
		
		if (view_as<bool>(g_RoundFlags & ROUND_MAP_FINISHED) && !view_as<bool>(g_RoundFlags & ROUND_HAS_ENDED))
		{
			if (userId == g_TerroristKillerId)
			{
				FindNextTerroristKiller();
			}
			else if (allCTsFinished)
			{
				OnMapFinishedByAllCTs(numFinishers);
			}
		}
	}
	
	if (!attackerId || attackerId == userId)
	{
		RequestFrame(Frame_FixClientScore, userId);
	}
}

public void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast) 
{
	if (event.GetBool("disconnect"))
	{
		return;
	}
	
	int userId = event.GetInt("userid");	
	int client = GetClientOfUserId(userId);
	
	if (!client || !IsClientInGame(client))
	{
		return;
	}
	
	int toTeam = event.GetInt("team");
	int oldTeam = event.GetInt("oldteam");
	float gameTime = GetGameTime();
	
	g_RefillAmmoTime[client] = 0.0;
	g_RemoveProtectionTime[client] = 0.0;
	
	g_MoveInfo[client].moveTime = 0.0;
	g_MoveInfo[client].toTeam = CS_TEAM_NONE;
	
	g_RespawnInfo[client].respawnTime = 0.0;
	g_RespawnInfo[client].respawnType = RespawnType_None;
	
	RemoveEntityGlow(client);
	
	if (oldTeam == CS_TEAM_NONE && view_as<bool>(g_RoundFlags & ROUND_MAP_FINISHED) && !IsFakeClient(client))
	{
		CreateTimer(1.0, Timer_DisplayDuelHud, userId);
	}
	
	if (toTeam == CS_TEAM_CT)
	{
		if (userId == g_TerroristId)
		{
			g_TerroristId = 0;
		}
		else if (view_as<bool>(g_RoundFlags & ROUND_WARMUP_PERIOD) && CanPlayerRespawnInWarmup(client))
		{
			g_RespawnInfo[client].respawnTime = gameTime + 0.2;
			g_RespawnInfo[client].respawnType = RespawnType_Warmup;
		}
	}
	else if (toTeam == CS_TEAM_SPECTATOR)
	{
		if (userId == g_TerroristId)
		{
			g_TerroristId = 0;
		}
		
		RemoveCellFromArrayList(userId, g_List_TerroristQueue);
	}
}

public void Event_PlayerUse(Event event, const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client || !IsClientInGame(client))
	{
		return;
	}
	
	if (view_as<bool>(g_RoundFlags & ROUND_END_CHOSEN) 
		&& view_as<bool>(g_CurrentEndInfo.flags & END_BLOCK_CONTROL_ON_BOT_WEAPONS))
	{
		return;
	}
	
	int entity = event.GetInt("entity");
	if (!IsEntityClient(entity) || !IsFakeClient(entity))
	{
		return;
	}
	
	for (int i = 0; i < GetEntPropArraySize(entity, Prop_Send, "m_hMyWeapons"); i++) 
	{
		int weapon = GetEntPropEnt(entity, Prop_Send, "m_hMyWeapons", i); 
		if (weapon == -1 || IsWeaponKnife(weapon))
        {
			continue;
		}
		
		CS_DropWeapon(entity, weapon, true);
	}
}

public void Event_PlayerJump(Event event, const char[] name, bool dontBroadcast)
{
	RequestFrame(Frame_OnPlayerJump, event.GetInt("userid"));
}

public void Event_RoundPreStart(Event event, const char[] name, bool dontBroadcast)
{
	g_NumFinishers = 0;
	g_OutputActionId = 0;
	g_RoundFlags = 0;
	g_TerroristId = 0;
	g_TerroristKillerId = 0;
	
	g_WarmupDuration = 0.0;
	
	g_CurrentEndInfo.flags = 0;
	g_CurrentEndInfo.endId = 0;
	g_CurrentEndInfo.endName[0] = 0;
	
	ClearArray_Ex(g_List_BreakablesOnFirstMove);
	ClearArray_Ex(g_List_BreakablesOnKill);
	ClearArray_Ex(g_List_BreakablesOnMove);
	ClearArray_Ex(g_List_BreakablesOnReverse);
	ClearArray_Ex(g_List_BreakablesOnSpeed);
	ClearArray_Ex(g_List_ProximityTraps);
	ClearArray_Ex(g_List_ThinkTraps);
	
	ClearTrie_Ex(view_as<StringMap>(g_Map_BreakablesOnFirstMove));
	ClearTrie_Ex(view_as<StringMap>(g_Map_BreakablesOnKill));
	ClearTrie_Ex(view_as<StringMap>(g_Map_BreakablesOnMove));
	ClearTrie_Ex(view_as<StringMap>(g_Map_BreakablesOnReverse));
	ClearTrie_Ex(view_as<StringMap>(g_Map_BreakablesOnSpeed));
	ClearTrie_Ex(view_as<StringMap>(g_Map_CurrentEndActivators));
	ClearTrie_Ex(view_as<StringMap>(g_Map_OutputActions));
	ClearTrie_Ex(view_as<StringMap>(g_Map_Traps));
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
		{
			continue;
		}
		
		g_NumWarmups[i] = 0;
		
		g_RespawnInfo[i].respawnTime = 0.0;
		g_RespawnInfo[i].respawnType = RespawnType_None;
		
		if (IsFakeClient(i) || GetClientTeam(i) != CS_TEAM_T)
		{
			continue;
		}
		
		CS_SwitchTeam(i, CS_TEAM_CT);
	}
	
	if (IsValveWarmupPeriod())
	{
		g_TotalRoundsPlayed = 0;
		return;
	}
	
	g_TotalRoundsPlayed++;
	float gameTime = GetGameTime();
	
	if (g_Cvar_WarmupMaxTime.IntValue > 0)
	{
		float warmupTime = g_Cvar_WarmupMaxTime.FloatValue;
		if (g_Cvar_WarmupTimeFactor.FloatValue > 0.0)
		{
			warmupTime -= GetTeamClientCount(CS_TEAM_CT) * g_Cvar_WarmupTimeFactor.FloatValue;
		}
		
		if (warmupTime < g_Cvar_WarmupMinTime.FloatValue)
		{
			warmupTime = g_Cvar_WarmupMinTime.FloatValue;
		}
		
		if (warmupTime > 0.0)
		{
			g_WarmupDuration = gameTime + warmupTime;
			g_RoundFlags |= (ROUND_WARMUP_PERIOD | ROUND_WARMUP_RESPAWNING_PLAYERS);
			
			CPrintToChatAll("\x04[Deathrun]\x01 The warmup period of\x04 %02d:%02d\x01 has started.", RoundToCeil(warmupTime) / 60, RoundToCeil(warmupTime) % 60);
		}
	}
	
	int newTerrorist = GetTerroristFromQueue();
	if (newTerrorist)
	{
		g_TerroristInfo[newTerrorist].numRequests++;
	}
	else
	{
		newTerrorist = GetRandomTerrorist();
	}
	
	if (newTerrorist)
	{
		g_TerroristId = GetClientUserId(newTerrorist);
		
		g_TerroristInfo[newTerrorist].lastRound = g_TotalRoundsPlayed;
		g_TerroristInfo[newTerrorist].lastTime = gameTime;
		
		CS_SwitchTeam(newTerrorist, CS_TEAM_T);
	}
	else if (g_Cvar_DebugModeEnable.BoolValue)
	{
		int fakeTerrorist = GetFakeTerrorist();
		if (fakeTerrorist)
		{
			g_TerroristId = GetClientUserId(fakeTerrorist);
		}
	}
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	ZoneInfo zoneInfo;	
	for (int i = 0; i < g_List_Zones.Length; i++)
	{
		g_List_Zones.GetArray(i, zoneInfo);
		if (zoneInfo.zoneType == ZoneType_End)
		{
			int entity = CreateTriggerEntity(zoneInfo.pointMin, zoneInfo.pointMax);
			if (entity != -1)
			{
				zoneInfo.flags |= ZONE_SPAWNED;
				SDKHook(entity, SDKHook_StartTouchPost, SDK_EndZoneStartTouch);
				
				if (!view_as<bool>(g_RoundFlags & ROUND_END_ZONE_SPAWNED))
				{
					g_RoundFlags |= ROUND_END_ZONE_SPAWNED;
					GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", g_EndZoneOrigin);
				}
			}
			else
			{
				zoneInfo.flags &= ~ZONE_SPAWNED;
			}
		}
		else if (zoneInfo.zoneType == ZoneType_Hurt)
		{
			int entity = CreateHurtEntity(zoneInfo.pointMin, zoneInfo.pointMax);
			if (entity != -1)
			{
				zoneInfo.flags |= ZONE_SPAWNED;
			}
			else
			{
				zoneInfo.flags &= ~ZONE_SPAWNED;
			}
		}
		else if (zoneInfo.zoneType == ZoneType_Solid)
		{
			int entity = CreateSolidEntity(zoneInfo.pointMin, zoneInfo.pointMax);
			if (entity != -1)
			{
				zoneInfo.flags |= ZONE_SPAWNED;
			}
			else
			{
				zoneInfo.flags &= ~ZONE_SPAWNED;
			}
		}
		
		g_List_Zones.SetArray(i, zoneInfo);
	}
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	g_RoundFlags |= ROUND_HAS_ENDED;
	
	g_RoundFlags &= ~ROUND_WARMUP_PERIOD;
	g_RoundFlags &= ~ROUND_WARMUP_RESPAWNING_PLAYERS;
	g_RoundFlags &= ~ROUND_WARMUP_DISPLAY_ENDING_HUD;
}

public Action Sound_OnNormal(int clients[64], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags)
{
	int client = entity;
	if (!IsEntityClient(client))
	{
		char className[256];
		GetEntityClassname(entity, className, sizeof(className));
		
		if (strncmp(className, "weapon_", 7, true))
		{
			return Plugin_Continue;
		}
		
		client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
		if (!IsEntityClient(client))
		{
			return Plugin_Continue;
		}
	}
	
	if (!IsClientInGame(client))
	{
		return Plugin_Continue;
	}
	
	int clientTeam = GetClientTeam(client);
	if (clientTeam < CS_TEAM_CT)
	{
		return Plugin_Continue;
	}
	
	int newTotal = 0;
	int userId = GetClientUserId(client);
	int newClients[64];
	
	bool footsteps = !strncmp(sample[1], "player/footsteps", 16, true) || 
		!strncmp(sample[2], "player/land", 11, true) || 
		!strncmp(sample[1], "player/death", 12, true);
	
	for (int i = 0; i < numClients; i++)
	{
		int receiver = clients[i];
		if (!IsClientInGame(receiver))
		{
			continue;
		}
		
		if (client != receiver)
		{
			if (IsPlayerAlive(receiver))
			{
				if (view_as<bool>(g_PlayerFlags[receiver] & PLAYER_IS_HIDING_OTHER_PLAYERS) && userId != g_TerroristKillerId)
				{
					continue;
				}
				
				if (footsteps && !view_as<bool>(g_PlayerFlags[receiver] & PLAYER_HAS_FINISHED_MAP) && GetClientTeam(receiver) == CS_TEAM_CT)
				{
					continue;
				}
			}
			else if (footsteps)
			{
				int observerTarget = GetClientObserverTarget(receiver);
				if (observerTarget 
					&& client != observerTarget 
					&& !view_as<bool>(g_PlayerFlags[observerTarget] & PLAYER_HAS_FINISHED_MAP)
					&& GetClientTeam(observerTarget) == CS_TEAM_CT)
				{
					continue;
				}
			}
		}
		
		newClients[newTotal++] = receiver;
	}
	
	numClients = newTotal;
	clients = newClients;
	
	return Plugin_Changed;
}

public Action TempEnt_OnShotgunShot(const char[] te_name, const int[] Players, int numClients, float delay)
{	
	int client = TE_ReadNum("m_iPlayer") + 1;
	if (!IsEntityClient(client) || !IsClientInGame(client))
	{
		return Plugin_Continue;
	}
	
	int clientTeam = GetClientTeam(client);
	if (clientTeam < CS_TEAM_CT)
	{
		return Plugin_Continue;
	}
	
	int newTotal = 0;
	int userId = GetClientUserId(client);
	int[] newClients = new int[numClients];
	
	for (int i = 0; i < numClients; i++)
	{
		int receiver = Players[i];
		if (!IsClientInGame(receiver))
		{
			continue;
		}
		
		if (client != receiver 
			&& view_as<bool>(g_PlayerFlags[receiver] & PLAYER_IS_HIDING_OTHER_PLAYERS) 
			&& userId != g_TerroristKillerId)
		{
			continue;
		}
		
		newClients[newTotal++] = receiver;
	}
	
	if (newTotal == numClients)
	{
		return Plugin_Continue;
	}
	
	if (newTotal == 0)
	{
		return Plugin_Handled;
	}
	
	float vecOrigin[3];
	TE_Start("Shotgun Shot");
	TE_ReadVector("m_vecOrigin", vecOrigin);
	TE_WriteVector("m_vecOrigin", vecOrigin);
	TE_WriteFloat("m_vecAngles[0]", TE_ReadFloat("m_vecAngles[0]"));
	TE_WriteFloat("m_vecAngles[1]", TE_ReadFloat("m_vecAngles[1]"));
	TE_WriteNum("m_weapon", TE_ReadNum("m_weapon"));
	TE_WriteNum("m_iMode", TE_ReadNum("m_iMode"));
	TE_WriteNum("m_iSeed", TE_ReadNum("m_iSeed"));
	TE_WriteNum("m_iPlayer", client - 1);
	TE_WriteFloat("m_fInaccuracy", TE_ReadFloat("m_fInaccuracy"));
	TE_WriteFloat("m_flRecoilIndex", TE_ReadFloat("m_flRecoilIndex"));
	TE_WriteFloat("m_fSpread", TE_ReadFloat("m_fSpread"));
	TE_WriteNum("m_nItemDefIndex", TE_ReadNum("m_nItemDefIndex"));
	TE_WriteNum("m_iSoundType", TE_ReadNum("m_iSoundType"));
	TE_Send(newClients, newTotal, delay);
	return Plugin_Handled;
}

public void Output_OnEntityOutput(const char[] output, int caller, int activator, float delay)
{
	if (!IsValidEntity(caller))
	{
		return;
	}
	
	bool isTrap;
	bool listenToOutputs;
	int reference = EntIndexToEntRef_Ex(caller);
	
	TrapInfo trapInfo;	
	if (g_Map_Traps.GetArray(reference, trapInfo, sizeof(TrapInfo)))
	{
		isTrap = true;
		listenToOutputs = view_as<bool>(trapInfo.flags & TRAP_LISTEN_TO_OUTPUTS);
	}
	
	OnEntityOutput(caller, output, isTrap, trapInfo);
	
	TrapActivatorInfo trapActivatorInfo;
	if (IsEntityClient(activator) 
		&& IsEntityActivatingTrap(caller, trapActivatorInfo) 
		&& !view_as<bool>(trapActivatorInfo.flags & TRAP_ACTIVATOR_IGNORE_OUTPUTS))
	{
		ListenToTrapOutputs(caller, output, GetClientUserId(activator));
	}
	else if (listenToOutputs || isTrap && view_as<bool>(trapInfo.flags & TRAP_LISTEN_TO_OUTPUTS))
	{
		ListenToTrapOutputs(caller, output, trapInfo.activatorId);
	}
}

public Action CommandListener_JoinTeam(int client, const char[] command, int args)
{
	if (!IsEntityClient(client) || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	
	char arg[128];
	GetCmdArg(1, arg, sizeof(arg));
	
	int toTeam;
	if (!StringToIntEx(arg, toTeam) || toTeam < CS_TEAM_NONE || toTeam > CS_TEAM_CT)
	{
		return Plugin_Handled;
	}
	
	int clientTeam = GetClientTeam(client);
	if (clientTeam == CS_TEAM_NONE)
	{
		toTeam = CS_TEAM_CT;
	}
	
	if (toTeam == clientTeam)
	{
		return Plugin_Handled;
	}
	
	switch (toTeam)
	{
		case CS_TEAM_T:
		{
			Event newEvent = CreateEvent("jointeam_failed");
			if (newEvent)
			{
				newEvent.SetInt("userid", GetClientUserId(client));
				newEvent.SetInt("reason", JOINTEAM_TERRORISTS_FULL);
				
				newEvent.FireToClient(client);
				newEvent.Cancel();
			}
			
			return Plugin_Handled;
		}
	}
	
	if (clientTeam > CS_TEAM_SPECTATOR && IsPlayerAlive(client))
	{
		ForcePlayerSuicide(client);
	}
	
	ChangeClientTeam(client, toTeam);
	return Plugin_Handled;
}

public Action Command_Terrorist(int client, int args)
{
	if (!client || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	
	if (!g_Cvar_RequestTerroristEnable.BoolValue)
	{
		CReplyToCommand(client, "\x04[Deathrun]\x01 The feature to request to join the\x10 Terrorists\x01 is not available.");
		return Plugin_Handled;
	}
	
	int userId = GetClientUserId(client);
	if (g_List_TerroristQueue.FindValue(userId) == -1)
	{
		if (g_Cvar_TerroristMaxRequests.IntValue > 0 
			&& g_TerroristInfo[client].numRequests >= g_Cvar_TerroristMaxRequests.IntValue)
		{
			CReplyToCommand(client, "\x04[Deathrun]\x01 You can no longer request to join the\x10 Terrorists\x01 on this map.");
			return Plugin_Handled;
		}
		
		int pos = GetClientPositionInQueue(client) + 1;
		if (pos < g_List_TerroristQueue.Length)
		{
			g_List_TerroristQueue.ShiftUp(pos);
			g_List_TerroristQueue.Set(pos, userId);
		}
		else
		{
			g_List_TerroristQueue.Push(userId);
		}
	}
	
	CReplyToCommand(client, "\x04[Deathrun]\x01 You will join the\x10 Terrorists\x01 in the next rounds.");	
	return Plugin_Handled;
}

public Action Command_KillBot(int client, int args)
{
	if (!client || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	
	if (IsValveWarmupPeriod())
	{
		CReplyToCommand(client, "\x04[Deathrun]\x01 You cannot kill the\x10 BOT\x01 before the game starts.");
		return Plugin_Handled;
	}
	
	int userId = GetClientUserId(client);
	if (userId != g_TerroristKillerId)
	{
		CReplyToCommand(client, "\x04[Deathrun]\x01 You must be the\x0B Terrorist Killer\x01 to kill the\x10 BOT.");
		return Plugin_Handled;
	}
	
	int fakeTerrorist = GetFakeTerrorist();
	if (!fakeTerrorist)
	{
		CReplyToCommand(client, "\x04[Deathrun]\x01 The\x10 BOT\x01 is not in-game.");
		return Plugin_Handled;
	}
	
	if (!IsPlayerAlive(fakeTerrorist))
	{
		CReplyToCommand(client, "\x04[Deathrun]\x01 The\x10 BOT\x01 is not alive.");
		return Plugin_Handled;
	}
	
	if (GetClientTeam(fakeTerrorist) != CS_TEAM_T)
	{
		CReplyToCommand(client, "\x04[Deathrun]\x01 The\x10 BOT\x01 is not at\x10 Terrorists.");
		return Plugin_Handled;
	}
	
	int currentTerrorist = GetTerrorist();
	if (currentTerrorist && IsPlayerAlive(currentTerrorist))
	{
		CReplyToCommand(client, "\x04[Deathrun]\x01 You must wait for the\x10 Terrorist\x01 to die in order to kill the\x10 BOT.");
		return Plugin_Handled;
	}
	
	SDKHooks_TakeDamage(fakeTerrorist, client, client, 1000.0);
	return Plugin_Handled;
}

public Action Command_Hud(int client, int args)
{
	if (!client || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	
	if (!AreClientCookiesCached(client))
	{
		CReplyToCommand(client, "\x04[Deathrun]\x01 You must wait for your\x10 HUD Preferences\x01 to be loaded.");
		return Plugin_Handled;
	}
	
	DisplayHudPreferencesMenu(client);
	return Plugin_Handled;
}

public Action Command_Life(int client, int args)
{
	if (!client || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	
	if (!g_Cvar_LifeTransferEnable.BoolValue)
	{
		CReplyToCommand(client, "\x04[Deathrun]\x01 The feature to transfer lives is unavailable.");
		return Plugin_Handled;
	}
	
	if (IsValveWarmupPeriod())
	{
		CReplyToCommand(client, "\x04[Deathrun]\x01 You cannot transfer your life before the game starts.");
		return Plugin_Handled;
	}
	
	if (GetClientTeam(client) != CS_TEAM_CT)
	{
		CReplyToCommand(client, "\x04[Deathrun]\x01 You must be a\x0B Counter-Terrorist\x01 to transfer your life.");
		return Plugin_Handled;
	}
	
	if (!IsPlayerAlive(client))
	{
		CReplyToCommand(client, "\x04[Deathrun]\x01 You must be alive to transfer your life.");
		return Plugin_Handled;
	}
	
	if (view_as<bool>(g_PlayerFlags[client] & PLAYER_HAS_FINISHED_MAP))
	{
		CReplyToCommand(client, "\x04[Deathrun]\x01 You cannot transfer your life after finishing the map.");
		return Plugin_Handled;
	}
	
	float timeLeft = g_LifeTransferDelay[client] - GetGameTime();
	if (timeLeft > 0.0)
	{
		char formatTime[128];
		FormatTimeDuration(formatTime, sizeof(formatTime), timeLeft);
		
		CReplyToCommand(client, "\x04[Deathrun]\x01 You can transfer your life in\x04 %s.", formatTime);
		return Plugin_Handled;
	}
	
	if (args)
	{
		if (GetEntityMoveType(client) != MOVETYPE_WALK)
		{
			CReplyToCommand(client, "\x04[Deathrun]\x01 You must be on ground to transfer your life.");
			return Plugin_Handled;
		}
		
		int clientFlags = GetEntityFlags(client);
		if (!view_as<bool>(clientFlags & FL_ONGROUND))
		{
			CReplyToCommand(client, "\x04[Deathrun]\x01 You must be on ground to transfer your life.");
			return Plugin_Handled;
		}
		
		if (view_as<bool>(clientFlags & FL_DUCKING))
		{
			CReplyToCommand(client, "\x04[Deathrun]\x01 You cannot transfer your life while crouching.");
			return Plugin_Handled;
		}
		
		if (GetClientVelocity(client))
		{
			CReplyToCommand(client, "\x04[Deathrun]\x01 You cannot transfer your life while moving.");
			return Plugin_Handled;
		}
		
		if (view_as<bool>(g_PlayerFlags[client] & PLAYER_IS_TOUCHING_TRIGGER_HURT))
		{
			CReplyToCommand(client, "\x04[Deathrun]\x01 You cannot transfer your life here.");
			return Plugin_Handled;
		}
		
		char arg[128];
		GetCmdArg(1, arg, sizeof(arg));
		
		int target = FindTarget_Ex(client, arg, COMMAND_FILTER_NO_IMMUNITY | COMMAND_FILTER_NO_BOTS);
		if (target == -1)
		{
			return Plugin_Handled;
		}
		
		if (GetClientTeam(target) != CS_TEAM_CT)
		{
			CReplyToCommand(client, "\x04[Deathrun]\x01 You can transfer your life only to\x0B Counter-Terrorists.");
			return Plugin_Handled;
		}
		
		if (g_TerroristInfo[target].lastRound == g_TotalRoundsPlayed)
		{
			CReplyToCommand(client, "\x04[Deathrun]\x01 You cannot transfer your life to\x10 Ex-Terrorists\x01 from this round.");
			return Plugin_Handled;
		}
		
		if (IsPlayerAlive(target) || g_RespawnInfo[target].respawnTime)
		{
			CReplyToCommand(client, "\x04[Deathrun]\x01 You can transfer your life only to dead players.");
			return Plugin_Handled;
		}
		
		TransferClientLife(client, target);
	}
	else
	{
		DisplayLifeTransferMenu(client);
	}
	
	return Plugin_Handled;
}

public Action Command_Free(int client, int args)
{
	if (!client || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	
	if (!g_Cvar_FreerunModeEnable.BoolValue)
	{
		CReplyToCommand(client, "\x04[Deathrun]\x01 The feature to enable the\x10 Freerun Mode\x01 is unavailable.");
		return Plugin_Handled;
	}
	
	if (g_Cvar_DebugModeEnable.BoolValue)
	{
		g_RoundFlags |= ROUND_IS_FREERUN;
		
		char clientName[MAX_NAME_LENGTH];
		GetClientName_Ex(client, clientName, sizeof(clientName));
		CPrintToChatAll_Ex(client, false, "\x04[Deathrun]\x03 %s\x01 enabled the\x04 Freerun Mode.", clientName);
		
		return Plugin_Handled;
	}
	
	int userId = GetClientUserId(client);
	if (userId != g_TerroristId)
	{
		CReplyToCommand(client, "\x04[Deathrun]\x01 You must be the\x10 Terrorist\x01 to enable the\x10 Freerun Mode.");
		return Plugin_Handled;
	}
	
	if (!IsPlayerAlive(client))
	{
		CReplyToCommand(client, "\x04[Deathrun]\x01 You must be alive to enable the\x10 Freerun Mode.");
		return Plugin_Handled;
	}
	
	if (view_as<bool>(g_RoundFlags & ROUND_IS_FREERUN))
	{
		CReplyToCommand(client, "\x04[Deathrun]\x01 The\x10 Freerun Mode\x01 is already enabled.");
		return Plugin_Handled;
	}
	
	if (view_as<bool>(g_RoundFlags & ROUND_IS_DEATHRUN))
	{
		CReplyToCommand(client, "\x04[Deathrun]\x01 You cannot enable the\x10 Freerun Mode\x01 in\x07 Deathrun Mode.");
		return Plugin_Handled;
	}
	
	int numTraps;
	char key[128];
	
	IntToString(view_as<int>(TrapType_Normal), key, sizeof(key));
	g_Map_NumTraps.GetValue(key, numTraps);
	
	if (!numTraps)
	{
		CReplyToCommand(client, "\x04[Deathrun]\x01 You cannot enable the\x10 Freerun Mode\x01 on this map.");
		return Plugin_Handled;
	}
	
	g_RoundFlags |= ROUND_IS_FREERUN;
	
	char clientName[MAX_NAME_LENGTH];
	GetClientName_Ex(client, clientName, sizeof(clientName));
	CPrintToChatAll_Ex(client, false, "\x04[Deathrun]\x03 %s\x01 enabled the\x04 Freerun Mode.", clientName);
	
	return Plugin_Handled;
}

public Action Command_Speed(int client, int args)
{
	if (!client 
		|| !IsClientInGame(client) 
		|| !IsPlayerAlive(client) 
		|| g_SpeedInfo[client].maxSpeedType == SpeedType_Normal)
	{
		return Plugin_Handled;
	}
	
	if (g_SpeedInfo[client].speedType == SpeedType_Normal)
	{
		g_SpeedInfo[client].speedType = SpeedType_x3;
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 3.0);
	}
	else if (g_SpeedInfo[client].speedType == SpeedType_x3)
	{
		if (g_SpeedInfo[client].maxSpeedType == SpeedType_x5)
		{
			g_SpeedInfo[client].speedType = SpeedType_x5;
			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 5.0);
		}
		else
		{
			g_SpeedInfo[client].speedType = SpeedType_Normal;
			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
		}
	}
	else
	{
		g_SpeedInfo[client].speedType = SpeedType_Normal;
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
	}
	
	return Plugin_Handled;
}

public Action Command_Hide(int client, int args)
{
	if (!client || !IsClientInGame(client) || !IsPlayerAlive(client))
	{
		return Plugin_Handled;
	}
	
	g_PlayerFlags[client] ^= PLAYER_IS_HIDING_OTHER_PLAYERS;
	return Plugin_Handled;
}

public Action Command_Finish(int client, int args)
{
	if (!client || !IsClientInGame(client) || !IsPlayerAlive(client))
	{
		return Plugin_Handled;
	}
	
	if (view_as<bool>(g_RoundFlags & ROUND_END_ZONE_SPAWNED))
	{
		TeleportClientToFinish(client);
	}
	
	return Plugin_Handled;
}

public void OnGameFrame()
{
	if (g_List_ThinkTraps.Length)
	{
		TrapInfo trapInfo;
		for (int i = g_List_ThinkTraps.Length - 1; i >= 0; i--)
		{
			int reference = g_List_ThinkTraps.Get(i);			
			if (!g_Map_Traps.GetArray(reference, trapInfo, sizeof(TrapInfo)))
			{
				g_List_ThinkTraps.Erase(i);
				continue;
			}
			
			int entity = EntRefToEntIndex(reference);
			if (!IsValidEntity(entity))
			{
				g_List_ThinkTraps.Erase(i);
				continue;
			}
			
			CheckTrapStatus(entity, reference, trapInfo);
		}
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i) || GetClientTeam(i) < CS_TEAM_T)
		{
			continue;
		}
		
		if (IsClientInTrapProximity(i, g_TrapProximityInfo[i].activatorId))
		{
			g_TrapProximityInfo[i].inProximity = true;
		}
		else if (g_TrapProximityInfo[i].inProximity 
			&& !view_as<bool>(g_PlayerFlags[i] & PLAYER_IS_TOUCHING_TRIGGER_HURT) 
			&& IsClientOnGround(i))
		{
			g_TrapProximityInfo[i].inProximity = false;
			g_TrapProximityInfo[i].activatorId = 0;
		}
	}
}

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
	g_TimerButtons[client] |= buttons;
}

public Action CS_OnCSWeaponDrop(int client, int weapon)
{
	if (!IsValidEntity(weapon) || IsClientInGame(client) && GetClientHealth(client) > 0)
	{
		return Plugin_Continue;
	}
	
	char weaponName[256];
	GetEntPropString(weapon, Prop_Data, "m_iszName", weaponName, sizeof(weaponName));

	if (weaponName[0] && StrEqual(weaponName, "spawn_secondary", true))
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action CS_OnTerminateRound(float& delay, CSRoundEndReason& reason)
{
	if (reason == CSRoundEnd_TerroristWin)
	{
		if (GetRoundTimeleft() > 0.0)
		{
			if (g_Cvar_DebugModeEnable.BoolValue)
			{
				PrintToChatAll("Terminate round: T Win");
			}
			
			if (view_as<bool>(g_RoundFlags & ROUND_WARMUP_RESPAWNING_PLAYERS))
			{
				if (g_Cvar_DebugModeEnable.BoolValue)
				{
					PrintToChatAll("Block terminate round: T win - warmup respawning");
				}
				
				DecreaseTeamScore(CS_TEAM_T);
				return Plugin_Stop;
			}
		}
	}
	else if (reason == CSRoundEnd_Draw)
	{
		if (GetRoundTimeleft() > 0.0)
		{
			if (g_Cvar_DebugModeEnable.BoolValue)
			{
				PrintToChatAll("Terminate round: Draw");
			}
			
			if (view_as<bool>(g_RoundFlags & ROUND_WARMUP_RESPAWNING_PLAYERS))
			{
				if (g_Cvar_DebugModeEnable.BoolValue)
				{
					PrintToChatAll("Block terminate round: draw - warmup respawning");
				}
				
				return Plugin_Stop;
			}
		}
		
		if (view_as<bool>(g_RoundFlags & ROUND_END_CHOSEN) 
			&& view_as<bool>(g_CurrentEndInfo.flags & END_REVERSE_DEFAULT_WINNER))
		{
			reason = CSRoundEnd_CTWin;
			IncreaseTeamScore(CS_TEAM_CT);
		}
		else
		{
			reason = CSRoundEnd_TerroristWin;
			IncreaseTeamScore(CS_TEAM_T);
		}
		
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

public Action EntityIO_OnEntityInput(int entity, char input[256], int& activator, int& caller, EntityIO_VariantInfo variantInfo, int actionId)
{
	bool inputFromTrap;
	int activatorId;
	
	OutputActionInfo outputActionInfo;
	if (g_Map_OutputActions.GetArray(actionId, outputActionInfo, sizeof(OutputActionInfo)))
	{
		inputFromTrap = true;
		activatorId = outputActionInfo.activatorId;
		
		if (StrEqual(outputActionInfo.target, "!self", false) || StrEqual(outputActionInfo.target, "!activator", false))
		{
			g_Map_OutputActions.Remove(actionId);
		}
		else
		{
			if (!outputActionInfo.multipleTargets)
			{				
				int ent = -1;
				while ((ent = FindEntityByName(ent, outputActionInfo.target)) != -1)
				{
					outputActionInfo.numTargets++;
				}
			}
			
			outputActionInfo.numTargets--;
			if (outputActionInfo.numTargets > 0)
			{
				outputActionInfo.multipleTargets = true;
				g_Map_OutputActions.SetArray(actionId, outputActionInfo, sizeof(OutputActionInfo));
			}
			else
			{
				g_Map_OutputActions.Remove(actionId);
			}
		}
	}
	
	OnEntityInput(entity, input, variantInfo, inputFromTrap, activatorId);
	return Plugin_Continue;
}

public int Menu_LifeTransfer(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	else if (action == MenuAction_Select)
	{
		if (!IsClientInGame(param1))
		{
			return 0;
		}
		
		if (!g_Cvar_LifeTransferEnable.BoolValue)
		{
			CPrintToChat(param1, "\x04[Deathrun]\x01 The feature to transfer lives is unavailable.");
			return 0;
		}
		
		if (IsValveWarmupPeriod())
		{
			CPrintToChat(param1, "\x04[Deathrun]\x01 You cannot transfer your life before the game starts.");
			return 0;
		}
		
		if (GetClientTeam(param1) != CS_TEAM_CT)
		{
			CPrintToChat(param1, "\x04[Deathrun]\x01 You must be a\x0B Counter-Terrorist\x01 to transfer your life.");
			return 0;
		}
		
		if (!IsPlayerAlive(param1))
		{
			CPrintToChat(param1, "\x04[Deathrun]\x01 You must be alive to transfer your life.");
			return 0;
		}
		
		if (view_as<bool>(g_PlayerFlags[param1] & PLAYER_HAS_FINISHED_MAP))
		{
			CPrintToChat(param1, "\x04[Deathrun]\x01 You cannot transfer your life after finishing the map.");
			return 0;
		}
		
		char arg[128];			
		menu.GetItem(param2, arg, sizeof(arg));
		
		if (StrEqual(arg, "#refresh", true))
		{
			DisplayLifeTransferMenu(param1);
		}
		else
		{
			if (GetEntityMoveType(param1) != MOVETYPE_WALK)
			{
				CPrintToChat(param1, "\x04[Deathrun]\x01 You must be on ground to transfer your life.");
				return 0;
			}
			
			int clientFlags = GetEntityFlags(param1);
			if (!view_as<bool>(clientFlags & FL_ONGROUND))
			{
				CPrintToChat(param1, "\x04[Deathrun]\x01 You must be on ground to transfer your life.");
				return 0;
			}
			
			if (view_as<bool>(clientFlags & FL_DUCKING))
			{
				CPrintToChat(param1, "\x04[Deathrun]\x01 You cannot transfer your life while crouching.");
				return 0;
			}
			
			if (GetClientVelocity(param1))
			{
				CPrintToChat(param1, "\x04[Deathrun]\x01 You cannot transfer your life while moving.");
				return 0;
			}
			
			if (view_as<bool>(g_PlayerFlags[param1] & PLAYER_IS_TOUCHING_TRIGGER_HURT))
			{
				CPrintToChat(param1, "\x04[Deathrun]\x01 You cannot transfer your life here.");
				return 0;
			}
			
			int userId = StringToInt(arg);
			int target = GetClientOfUserId(userId);
			
			if (!target)
			{
				CPrintToChat(param1, "[SM] %t", "Player no longer available");
				return 0;
			}
			
			if (!IsClientInGame(target))
			{
				CPrintToChat(param1, "[SM] %t", "Target is not in game");
				return 0;
			}
			
			if (GetClientTeam(target) != CS_TEAM_CT)
			{
				CPrintToChat(param1, "\x04[Deathrun]\x01 You can transfer your life only to\x0B Counter-Terrorists.");
				return 0;
			}
			
			if (g_TerroristInfo[target].lastRound == g_TotalRoundsPlayed)
			{
				CPrintToChat(param1, "\x04[Deathrun]\x01 You cannot transfer your life to\x10 Ex-Terrorists\x01 from this round.");
				return 0;
			}
			
			if (IsPlayerAlive(target) || g_RespawnInfo[target].respawnTime)
			{
				CPrintToChat(param1, "\x04[Deathrun]\x01 You can transfer your life only to dead players.");
				return 0;
			}
			
			TransferClientLife(param1, target);
		}
	}
	
	return 0;
}

public int Menu_HudPreferences(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	else if (action == MenuAction_Select)
	{
		char arg[128];
		menu.GetItem(param2, arg, sizeof(arg));
		
		if (StrEqual(arg, "#buttons", true))
		{
			g_HudInfo[param1].inCookies = true;
			g_HudInfo[param1].displayFlags ^= HUD_DISPLAY_BUTTONS;
		}
		else if (StrEqual(arg, "#spectator_buttons", true))
		{
			g_HudInfo[param1].inCookies = true;
			g_HudInfo[param1].displayFlags ^= HUD_DISPLAY_SPEC_BUTTONS;
		}
		else if (StrEqual(arg, "#spectators", true))
		{
			if (view_as<bool>(g_HudInfo[param1].displayFlags & HUD_DISPLAY_SPECTATORS))
			{
				PrintHintText(param1, "{position:4}");
			}
			
			g_HudInfo[param1].inCookies = true;
			g_HudInfo[param1].displayFlags ^= HUD_DISPLAY_SPECTATORS;
		}
		else if (StrEqual(arg, "#reset_all", true))
		{
			g_HudInfo[param1].displayFlags = HUD_DISPLAY_DEFAULT;
		}
		
		DisplayHudPreferencesMenu(param1);
	}
	
	return 0;
}

public void SDK_ButtonSpawn(int entity)
{
	int spawnFlags = GetEntProp(entity, Prop_Data, "m_spawnflags");
	if (!view_as<bool>(spawnFlags & SF_BUTTON_USE_ACTIVATES))
	{
		return;
	}
	
	DispatchKeyValue(entity, "sounds", "9");
	DispatchKeyValue(entity, "locked_sound", "");
	DispatchKeyValue(entity, "unlocked_sound", "");
	DispatchKeyValue(entity, "locked_sentence", "");
	DispatchKeyValue(entity, "unlocked_sentence", "");
	DispatchKeyValue(entity, "min_use_angle", "-1.0");
	
	TrapActivatorInfo trapActivatorInfo;
	if (IsEntityActivatingTrap(entity, trapActivatorInfo))
	{
		SetEntProp(entity, Prop_Data, "m_spawnflags", spawnFlags & ~SF_BUTTON_NOT_SOLID);
		SetEntProp(entity, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_INTERACTIVE_DEBRIS);
	}
}

public void SDK_GamePlayerEquipSpawn(int entity)
{
	for (int i = 0; i < GetEntPropArraySize(entity, Prop_Data, "m_weaponNames"); i++)
	{
		SetEntProp(entity, Prop_Data, "m_weaponCount", 0, _, i);
	}
}

public void SDK_PropDoorSpawn(int entity)
{
	if (!IsEntityActivatingEnd(entity))
	{
		return;
	}
	
	SDKHook(entity, SDKHook_Use, SDK_OnPropDoorUse);
}

public void SDK_TriggerSpawn(int entity, int client)
{
	if (!IsEntityActivatingEnd(entity))
	{
		return;
	}
	
	SDKHook(entity, SDKHook_StartTouch, SDK_EndOptionStartTouch);
	SDKHook(entity, SDKHook_Touch, SDK_EndOptionTouch);
	SDKHook(entity, SDKHook_EndTouch, SDK_EndOptionTouch);
}

public Action SDK_ButtonUse(int entity, int activator, int caller, UseType type, float value)
{
	if (!IsEntityClient(activator))
	{
		return Plugin_Continue;
	}
	
	if (view_as<bool>(GetEntProp(entity, Prop_Data, "m_bLocked")) 
		|| GetEntProp(entity, Prop_Data, "m_toggle_state") != TS_AT_BOTTOM)
	{
		PlaySoundToClient(activator, "buttons/button8.wav", 0.8);
		return Plugin_Continue;
	}
	
	TrapActivatorInfo trapActivatorInfo;
	int userId = GetClientUserId(activator);
	
	if (IsEntityActivatingTrap(entity, trapActivatorInfo))
	{
		if (view_as<bool>(trapActivatorInfo.flags & TRAP_ACTIVATOR_HAS_USE_RESTRICTIONS) 
			&& trapActivatorInfo.trapType != TrapType_Normal)
		{
			if (view_as<bool>(trapActivatorInfo.flags & TRAP_ACTIVATOR_TERRORIST_CAN_USE) 
				&& view_as<bool>(trapActivatorInfo.flags & TRAP_ACTIVATOR_TERRORIST_KILLER_CAN_USE))
			{
				if (userId != g_TerroristId && userId != g_TerroristKillerId)
				{
					CPrintToChat(activator, "\x04[Deathrun]\x01 You must be the\x10 Terrorist\x01 or the\x0B Terrorist Killer\x01 to use this button.");
					PlaySoundToClient(activator, "buttons/button8.wav", 0.8);
					
					return Plugin_Handled;
				}
			}
			else if (view_as<bool>(trapActivatorInfo.flags & TRAP_ACTIVATOR_TERRORIST_CAN_USE))
			{
				if (userId != g_TerroristId)
				{
					CPrintToChat(activator, "\x04[Deathrun]\x01 You must be the\x10 Terrorist\x01 to use this button.");
					PlaySoundToClient(activator, "buttons/button8.wav", 0.8);
					
					return Plugin_Handled;
				}
			}
			else if (view_as<bool>(trapActivatorInfo.flags & TRAP_ACTIVATOR_TERRORIST_KILLER_CAN_USE))
			{
				if (userId != g_TerroristKillerId)
				{
					CPrintToChat(activator, "\x04[Deathrun]\x01 You must be the\x0B Terrorist Killer\x01 to use this button.");
					PlaySoundToClient(activator, "buttons/button8.wav", 0.8);
					
					return Plugin_Handled;
				}
			}
		}
		
		if (view_as<bool>(g_RoundFlags & ROUND_IS_FREERUN) 
			&& view_as<bool>(trapActivatorInfo.flags & TRAP_ACTIVATOR_RESTRICTED_ON_FREERUN))
		{
			CPrintToChat(activator, "\x04[Deathrun]\x01 You cannot use this button in\x04 Freerun Mode.");
			PlaySoundToClient(activator, "buttons/button8.wav", 0.8);
			
			return Plugin_Handled;
		}
		
		if (trapActivatorInfo.trapType == TrapType_End)
		{
			if (!view_as<bool>(g_PlayerFlags[activator] & PLAYER_HAS_FINISHED_MAP))
			{
				CPrintToChat(activator, "\x04[Deathrun]\x01 You must finish the map before using this button.");
				PlaySoundToClient(activator, "buttons/button8.wav", 0.8);
				
				return Plugin_Handled;
			}
			
			if (!view_as<bool>(g_RoundFlags & ROUND_END_CHOSEN) || trapActivatorInfo.endId != g_CurrentEndInfo.endId)
			{
				EndInfo endInfo;
				g_Map_Endings.GetArray(trapActivatorInfo.endId, endInfo, sizeof(EndInfo));
				
				if (userId != g_TerroristKillerId)
				{
					CPrintToChat(activator, "\x04[Deathrun]\x01 You must wait for the\x0B Terrorist Killer\x01 to choose\x04 %s\x01 as the end before using this button.", endInfo.endName);
				}
				else
				{
					CPrintToChat(activator, "\x04[Deathrun]\x01 You must choose\x04 %s\x01 as the end before using this button.", endInfo.endName);
				}
				
				PlaySoundToClient(activator, "buttons/button8.wav", 0.8);
				return Plugin_Handled;
			}
			
			if (trapActivatorInfo.trapId)
			{
				int numTraps;
				char buffer[128];
				
				FormatEx(buffer, sizeof(buffer), "%d:%d", view_as<int>(trapActivatorInfo.trapType), trapActivatorInfo.endId);
				g_Map_NumTraps.GetValue(buffer, numTraps);
				
				char clientName[MAX_NAME_LENGTH];
				GetClientName_Ex(activator, clientName, sizeof(clientName));
				
				CPrintToChatAll_Ex(activator, false, "\x04[Deathrun]\x03 %s\x01 activated a trap\x04 [%s :: #%d/%d].", clientName, g_CurrentEndInfo.endName, trapActivatorInfo.trapId, numTraps);
			}
		}
		else if (trapActivatorInfo.trapType == TrapType_Normal)
		{
			if (userId != g_TerroristId)
			{
				CPrintToChat(activator, "\x04[Deathrun]\x01 You must be the\x10 Terrorist\x01 to use this button.");
				PlaySoundToClient(activator, "buttons/button8.wav", 0.8);
				
				return Plugin_Handled;
			}
			
			if (view_as<bool>(g_RoundFlags & ROUND_IS_FREERUN))
			{
				CPrintToChat(activator, "\x04[Deathrun]\x01 You cannot use this button in\x04 Freerun Mode.");
				PlaySoundToClient(activator, "buttons/button8.wav", 0.8);
				
				return Plugin_Handled;
			}
			
			if (trapActivatorInfo.trapId)
			{
				int numTraps;
				char key[128];
				
				IntToString(view_as<int>(trapActivatorInfo.trapType), key, sizeof(key));
				g_Map_NumTraps.GetValue(key, numTraps);
				
				char clientName[MAX_NAME_LENGTH];
				GetClientName_Ex(activator, clientName, sizeof(clientName));
				CPrintToChatAll_Ex(activator, false, "\x04[Deathrun]\x03 %s\x01 activated a trap\x04 [#%d/%d].", clientName, trapActivatorInfo.trapId, numTraps);
			}
			
			if (!view_as<bool>(g_RoundFlags & ROUND_IS_DEATHRUN))
			{
				g_RoundFlags |= ROUND_IS_DEATHRUN;
				PlaySoundToAll("survival/rocketalarmclose.wav");
			}
		}
	}
	
	if (!view_as<bool>(g_RoundFlags & ROUND_END_ZONE_SPAWNED) || view_as<bool>(g_RoundFlags & ROUND_HAS_ENDED))
	{
		return Plugin_Continue;
	}
	
	int endId;
	if (IsEntityActivatingEnd(entity, endId) && !OnClientActivateEnd(activator, entity, endId))
	{
		PlaySoundToClient(activator, "buttons/button8.wav", 0.8);
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action SDK_OnPropDoorUse(int entity, int activator, int caller, UseType type, float value)
{
	if (!IsEntityClient(activator) 
		|| !view_as<bool>(g_RoundFlags & ROUND_END_ZONE_SPAWNED) 
		|| view_as<bool>(g_RoundFlags & ROUND_HAS_ENDED))
	{
		return Plugin_Continue;
	}
	
	int endId;
	if (IsEntityActivatingEnd(entity, endId) && !OnClientActivateEnd(activator, entity, endId))
	{
		PlaySoundToClient(activator, "buttons/button8.wav", 0.8);
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public void SDK_HurtTouch(int entity, int client)
{
	if (!IsEntityClient(client) 
		|| view_as<bool>(g_PlayerFlags[client] & PLAYER_IS_TOUCHING_TRIGGER_HURT) 
		|| !CanEntityDamageClients(entity, ClassType_TriggerHurt) 
		|| !CanClientPassTriggerFilter(entity, client))
	{
		return;
	}
	
	g_PlayerFlags[client] |= PLAYER_IS_TOUCHING_TRIGGER_HURT;
}

public void SDK_HurtEndTouch_Post(int entity, int client)
{
	if (!IsEntityClient(client) 
		|| !view_as<bool>(g_PlayerFlags[client] & PLAYER_IS_TOUCHING_TRIGGER_HURT) 
		|| !CanEntityDamageClients(entity, ClassType_TriggerHurt) 
		|| !CanClientPassTriggerFilter(entity, client))
	{
		return;
	}
	
	g_PlayerFlags[client] &= ~PLAYER_IS_TOUCHING_TRIGGER_HURT;
}

public Action SDK_EndOptionStartTouch(int entity, int client)
{
	if (!IsEntityClient(client) 
		|| !CanClientPassTriggerFilter(entity, client) 
		|| !view_as<bool>(g_RoundFlags & ROUND_END_ZONE_SPAWNED) 
		|| view_as<bool>(g_RoundFlags & ROUND_HAS_ENDED))
	{
		return Plugin_Continue;
	}
	
	int endId;
	if (IsEntityActivatingEnd(entity, endId) && !OnClientActivateEnd(client, entity, endId))
	{
		if (view_as<bool>(g_PlayerFlags[client] & PLAYER_HAS_FINISHED_MAP))
		{
			TeleportClientToFinish(client);
		}
		
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action SDK_EndOptionTouch(int entity, int client)
{
	if (!IsEntityClient(client) 
		|| !CanClientPassTriggerFilter(entity, client) 
		|| !view_as<bool>(g_RoundFlags & ROUND_END_ZONE_SPAWNED) 
		|| view_as<bool>(g_RoundFlags & ROUND_HAS_ENDED))
	{
		return Plugin_Continue;
	}
	
	int endId;
	if (!IsEntityActivatingEnd(entity, endId))
	{
		return Plugin_Continue;
	}
	
	if (!view_as<bool>(g_PlayerFlags[client] & PLAYER_HAS_FINISHED_MAP))
	{
		return Plugin_Handled;
	}
	
	EndInfo endInfo;
	if (endId)
	{
		g_Map_Endings.GetArray(endId, endInfo, sizeof(EndInfo));
	}
	
	bool isChosen;
	int userId = GetClientUserId(client);	
	int reference = EntIndexToEntRef_Ex(entity);
	
	if (!g_Map_CurrentEndActivators.GetValue(reference, isChosen))
	{
		if (view_as<bool>(g_RoundFlags & ROUND_END_CHOSEN))
		{
			if (endId != g_CurrentEndInfo.endId)
			{
				return Plugin_Handled;
			}
		}
		else if (userId != g_TerroristKillerId)
		{
			return Plugin_Handled;
		}
	}
	
	if (view_as<bool>(g_RoundFlags & ROUND_IS_FREERUN) 
		&& view_as<bool>(endInfo.flags & END_RESTRICTED_ON_FREERUN))
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public void SDK_TeleportEndTouch_Post(int entity, int client)
{
	if (!IsEntityClient(client))
	{
		return;
	}
	
	TrapInfo trapInfo;
	int reference = EntIndexToEntRef_Ex(entity);
	
	if (!g_Map_Traps.GetArray(reference, trapInfo, sizeof(TrapInfo)))
	{
		return;
	}
	
	if (view_as<bool>(trapInfo.flags & TRAP_IS_ACTIVATED) || view_as<bool>(trapInfo.flags & TRAP_IS_CHILD))
	{
		g_TrapProximityInfo[client].inProximity = true;
		g_TrapProximityInfo[client].activatorId = trapInfo.activatorId;
	}
}

public void SDK_OnWeaponReload_Post(int weapon, bool bSuccessful)
{
	if (!bSuccessful)
	{
		return;
	}
	
	int client = GetEntPropEnt(weapon, Prop_Data, "m_hOwnerEntity");
	if (!IsEntityClient(client) || !IsClientInGame(client) || !IsPlayerAlive(client))
	{
		return;
	}
	
	g_RefillAmmoTime[client] = GetEntPropFloat(client, Prop_Send, "m_flNextAttack") + 1.0;
}

public Action SDK_TraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
	if (!IsClientInGame(victim) || !IsEntityClient(attacker) || !IsClientInGame(attacker))
	{
		return Plugin_Continue;
	}
	
	int weapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
	if (weapon == -1)
	{
		return Plugin_Continue;
	}
	
	if (GetClientTeam(victim) == GetClientTeam(attacker))
	{
		return Plugin_Handled;
	}
	
	if (view_as<bool>(g_RoundFlags & ROUND_END_ZONE_SPAWNED))
	{
		int victimId = GetClientUserId(victim);
		int attackerId = GetClientUserId(attacker);
		
		if (attackerId != g_TerroristKillerId && victimId != g_TerroristKillerId)
		{
			return Plugin_Handled;
		}
		
		if (IsFakeClient(victim))
		{
			int currentTerrorist = GetTerrorist();
			if (currentTerrorist && IsPlayerAlive(currentTerrorist) && currentTerrorist != victim)
			{
				return Plugin_Handled;
			}
		}
	}
	
	if (view_as<bool>(damagetype & DMG_BULLET))
	{
		char weaponName[256];
		GetEntPropString(weapon, Prop_Data, "m_iszName", weaponName, sizeof(weaponName));
		
		if (weaponName[0] && StrEqual(weaponName, "spawn_secondary", true))
		{
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

public Action SDK_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if (!IsClientInGame(victim))
	{
		return Plugin_Continue;
	}
	
	// Handle this in TraceAttack
	if (inflictor != victim && IsEntityClient(inflictor))
	{
		return Plugin_Continue;
	}
	
	if (attacker != victim && IsEntityClient(attacker))
	{
		if (!IsClientInGame(attacker))
		{
			return Plugin_Continue;
		}
		
		if (GetClientTeam(victim) == GetClientTeam(attacker))
		{
			if (inflictor != -1)
			{
				char className[256];
				GetEntityClassname(inflictor, className, sizeof(className));
				
				ClassType classType;
				if (g_Map_ClassNames.GetValue(className, classType) && classType == ClassType_PointHurt)
				{
					return Plugin_Continue;
				}
			}
			
			return Plugin_Handled;
		}
		
		if (view_as<bool>(g_RoundFlags & ROUND_END_ZONE_SPAWNED))
		{
			int victimId = GetClientUserId(victim);
			int attackerId = GetClientUserId(attacker);
			
			if (attackerId != g_TerroristKillerId && victimId != g_TerroristKillerId)
			{
				return Plugin_Handled;
			}
			
			if (IsFakeClient(victim))
			{
				int currentTerrorist = GetTerrorist();
				if (currentTerrorist && IsPlayerAlive(currentTerrorist) && currentTerrorist != victim)
				{
					return Plugin_Handled;
				}
			}
		}
		
		return Plugin_Continue;
	}
	
	if (view_as<bool>(damagetype & DMG_FALL) && !attacker && victim == GetTerrorist())
	{
		return Plugin_Handled;
	}
	
	int victimHealth = GetClientHealth(victim);
	
	if (attacker != -1)
	{
		TrapInfo trapInfo;
		int reference = EntIndexToEntRef_Ex(attacker);
		
		if (g_Map_Traps.GetArray(reference, trapInfo, sizeof(TrapInfo)) && 
			(view_as<bool>(trapInfo.flags & TRAP_IS_ACTIVATED) || view_as<bool>(trapInfo.flags & TRAP_IS_CHILD)))
		{
			int activator = GetClientOfUserId(trapInfo.activatorId);
			if (activator)
			{
				attacker = activator;
				inflictor = 0;
				
				if (damage >= victimHealth)
				{
					g_KillFeedType[victim] = KillFeedType_Trap;
				}
				
				return Plugin_Changed;
			}
		}
	}
	
	if (inflictor != -1)
	{
		TrapInfo trapInfo;
		int reference = EntIndexToEntRef_Ex(inflictor);
		
		if (g_Map_Traps.GetArray(reference, trapInfo, sizeof(TrapInfo)) && 
			(view_as<bool>(trapInfo.flags & TRAP_IS_ACTIVATED) || view_as<bool>(trapInfo.flags & TRAP_IS_CHILD)))
		{
			int activator = GetClientOfUserId(trapInfo.activatorId);
			if (activator)
			{
				attacker = activator;
				inflictor = 0;
				
				if (damage >= victimHealth)
				{
					g_KillFeedType[victim] = KillFeedType_Trap;
				}
				
				return Plugin_Changed;
			}
		}
	}
	
	if (g_TrapProximityInfo[victim].inProximity)
	{
		int activator = GetClientOfUserId(g_TrapProximityInfo[victim].activatorId);
		if (activator)
		{			
			attacker = activator;
			inflictor = 0;
			
			if (damage >= victimHealth)
			{
				g_KillFeedType[victim] = KillFeedType_Trap;
			}
			
			return Plugin_Changed;
		}
	}
	
	float gameTime = GetGameTime();
	if (g_ShakeInfo[victim].shakeTime > gameTime)
	{
		int activator = GetClientOfUserId(g_ShakeInfo[victim].activatorId);
		if (activator)
		{
			attacker = activator;
			inflictor = 0;
			
			if (damage >= victimHealth)
			{
				g_KillFeedType[victim] = KillFeedType_Trap;
			}
			
			return Plugin_Changed;
		}
	}
	
	return Plugin_Continue;
}

public Action SDK_PlayerTransmit(int entity, int client)
{
	if (client != entity 
		&& view_as<bool>(g_PlayerFlags[client] & PLAYER_IS_HIDING_OTHER_PLAYERS) 
		&& IsClientInGame(entity) 
		&& IsPlayerAlive(entity) 
		&& GetClientTeam(entity) == CS_TEAM_CT 
		&& GetClientUserId(entity) != g_TerroristKillerId)
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action SDK_OnGlowTransmit(int entity, int client) 
{
	if (IsPlayerAlive(client))
	{
		if (client == GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity"))
		{
			return Plugin_Handled;
		}
	}
	else if (GetEntProp(client, Prop_Send, "m_iObserverMode") == 4)
	{
		int observerTarget = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
		if (observerTarget != -1 && observerTarget == GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity"))
		{
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

public void SDK_EndZoneStartTouch(int entity, int client)
{
	if (!IsEntityClient(client) 
		|| view_as<bool>(g_PlayerFlags[client] & PLAYER_HAS_FINISHED_MAP) 
		|| !IsClientInGame(client) 
		|| GetClientTeam(client) != CS_TEAM_CT)
	{
		return;
	}
	
	if (IsValveWarmupPeriod())
	{
		CS_RespawnPlayer(client);
		return;
	}
	
	float gameTime = GetGameTime();
	float finishTime = gameTime - GetRoundStartTime();
	
	g_PlayerFlags[client] |= PLAYER_HAS_FINISHED_MAP;
	
	g_FinishInfo[client].finishMin = RoundToZero(finishTime) / 60;
	g_FinishInfo[client].finishSec = RoundToZero(finishTime) % 60;
	g_FinishInfo[client].finishMs = RoundToZero(finishTime * 100) % 100;
	g_FinishInfo[client].finishPos = ++g_NumFinishers;
	
	RemoveClientWeaponByName(client, "spawn_secondary");
	
	char clientName[MAX_NAME_LENGTH];
	GetClientName_Ex(client, clientName, sizeof(clientName));
	
	CPrintToChatAll_Ex(client, false, "\x04[Deathrun]\x03 %s\x01 finished the map\x04 [#%d]\x01 in\x05 %02d:%02d:%02d.", clientName, g_FinishInfo[client].finishPos, g_FinishInfo[client].finishMin, g_FinishInfo[client].finishSec, g_FinishInfo[client].finishMs);
	
	Call_StartForward(g_Forward_OnMapFinished);
	Call_PushCell(client);
	Call_PushCell(g_FinishInfo[client].finishPos);
	Call_PushFloat(finishTime);
	Call_Finish();
	
	if (view_as<bool>(g_RoundFlags & ROUND_HAS_ENDED))
	{
		return;
	}
	
	int numFinishers;
	int currentTerrorist = GetTerrorist();
	bool allCTsFinished = IsMapFinishedByAllCTs(numFinishers);
	
	if (!GetTerroristKiller())
	{
		g_TerroristKillerId = GetClientUserId(client);
		CPrintToChatAll_Ex(client, false, "\x04[Deathrun]\x03 %s\x04 [#%d]\x01 is now the\x0B Terrorist Killer.", clientName, g_FinishInfo[client].finishPos);
		
		FadeScreen(client, 0.5, 0.0, 114, 155, 221, 160);
		PlaySoundToClient(client, "ui/armsrace_become_leader_team.wav");
		
		if (!g_RemoveProtectionTime[client])
		{
			SetEntityGlow(client, 114, 155, 221, 255);
			SetEntityRenderColor(client, 114, 155, 221, 255);
		}
		
		if (!view_as<bool>(g_RoundFlags & ROUND_END_CHOSEN))
		{
			switch (g_Map_Endings.Size)
			{
				case 0:
				{
					g_RoundFlags |= ROUND_END_CHOSEN;
					
					if (currentTerrorist && IsPlayerAlive(currentTerrorist) 
						&& g_SpeedInfo[currentTerrorist].maxSpeedType != SpeedType_Normal)
					{
						char terroristName[MAX_NAME_LENGTH];
						GetClientName_Ex(currentTerrorist, terroristName, sizeof(terroristName));
						
						CPrintToChatAll_Ex(currentTerrorist, false, "\x04[Deathrun]\x03 %s\x01 can no longer use\x07 [x%d]\x01 speed.", terroristName, view_as<int>(g_SpeedInfo[currentTerrorist].maxSpeedType));
						
						g_SpeedInfo[currentTerrorist].speedType = SpeedType_Normal;
						g_SpeedInfo[currentTerrorist].maxSpeedType = SpeedType_Normal;
						
						SetEntPropFloat(currentTerrorist, Prop_Data, "m_flLaggedMovementValue", 1.0);
					}
				}
				
				case 1:
				{
					IntMapSnapshot listEnds = g_Map_Endings.Snapshot();
					int key = listEnds.GetKey(0);
					delete listEnds;
					
					EndInfo endInfo;
					g_Map_Endings.GetArray(key, endInfo, sizeof(EndInfo));
					
					g_RoundFlags |= ROUND_END_CHOSEN;
					g_CurrentEndInfo = endInfo;
					
					if (currentTerrorist && IsPlayerAlive(currentTerrorist))
					{
						char terroristName[MAX_NAME_LENGTH];
						GetClientName_Ex(currentTerrorist, terroristName, sizeof(terroristName));
						
						if (g_SpeedInfo[currentTerrorist].maxSpeedType != SpeedType_Normal)
						{
							CPrintToChatAll_Ex(currentTerrorist, false, "\x04[Deathrun]\x03 %s\x01 can no longer use\x07 [x%d]\x01 speed.", terroristName, view_as<int>(g_SpeedInfo[currentTerrorist].maxSpeedType));
							
							g_SpeedInfo[currentTerrorist].speedType = SpeedType_Normal;
							g_SpeedInfo[currentTerrorist].maxSpeedType = SpeedType_Normal;
							
							SetEntPropFloat(currentTerrorist, Prop_Data, "m_flLaggedMovementValue", 1.0);
						}
						
						if (view_as<bool>(endInfo.flags & END_TERRORIST_SPEED))
						{
							g_SpeedInfo[currentTerrorist].speedType = SpeedType_Normal;
							g_SpeedInfo[currentTerrorist].maxSpeedType = SpeedType_x3;
							CPrintToChatAll_Ex(currentTerrorist, false, "\x04[Deathrun]\x03 %s\x01 can use\x04 [x%d]\x01 speed.", terroristName, view_as<int>(g_SpeedInfo[currentTerrorist].maxSpeedType));
						}
					}
				}
			}
		}
		
		if (view_as<bool>(g_RoundFlags & ROUND_END_CHOSEN) 
			&& view_as<bool>(g_CurrentEndInfo.flags & END_TERRORIST_KILLER_SPEED))
		{
			g_SpeedInfo[client].speedType = SpeedType_Normal;
			g_SpeedInfo[client].maxSpeedType = SpeedType_x3;
			CPrintToChatAll_Ex(client, false, "\x04[Deathrun]\x03 %s\x01 can use\x04 [x%d]\x01 speed.", clientName, view_as<int>(g_SpeedInfo[client].maxSpeedType));
		}
		
		if (currentTerrorist && IsPlayerAlive(currentTerrorist))
		{
			DisplayDuelHudToAll(currentTerrorist, client);
		}
	}
	
	if (allCTsFinished)
	{
		OnMapFinishedByAllCTs(numFinishers);
	}
	
	if (!view_as<bool>(g_RoundFlags & ROUND_MAP_FINISHED) 
		&& view_as<bool>(g_RoundFlags & ROUND_WARMUP_PERIOD))
	{
		g_RoundFlags &= ~ROUND_WARMUP_PERIOD;
		g_RoundFlags |= ROUND_WARMUP_DISPLAY_ENDING_HUD;
		
		CPrintToChatAll("\x04[Deathrun]\x01 The warmup period has ended at\x07 %02d:%02d.", RoundToCeil(g_WarmupDuration - gameTime) / 60, RoundToCeil(g_WarmupDuration - gameTime) % 60);
		g_WarmupDuration = gameTime;
	}
	
	g_RoundFlags |= ROUND_MAP_FINISHED;
}

public Action Timer_Think(Handle timer, any data)
{
	bool valveWarmup = IsValveWarmupPeriod();
	float gameTime = GetGameTime();
	float roundTime = gameTime - GetRoundStartTime();
	
	int flags;
	int timerMin = RoundToZero(roundTime) / 60;
	int timerSec = RoundToZero(roundTime) % 60;
	int timerMs = RoundToZero(roundTime * 100) % 100;
	int numSpectators[MAXPLAYERS + 1];
	
	if (view_as<bool>(g_RoundFlags & ROUND_WARMUP_PERIOD) && gameTime >= g_WarmupDuration)
	{
		g_RoundFlags &= ~ROUND_WARMUP_PERIOD;
		g_RoundFlags |= ROUND_WARMUP_DISPLAY_ENDING_HUD;
		CPrintToChatAll("\x04[Deathrun]\x01 The warmup period has ended.");
	}
	
	if (view_as<bool>(g_RoundFlags & ROUND_WARMUP_DISPLAY_ENDING_HUD) && gameTime >= g_WarmupDuration + 3.0)
	{
		g_RoundFlags &= ~ROUND_WARMUP_DISPLAY_ENDING_HUD;
	}
	
	if (g_List_RemoveEntities.Length)
	{
		RemoveEntityInfo removeEntityInfo;
		for (int i = g_List_RemoveEntities.Length - 1; i >= 0; i--)
		{
			g_List_RemoveEntities.GetArray(i, removeEntityInfo);
			if (removeEntityInfo.removeTime > gameTime)
			{
				break;
			}
			
			int entity = EntRefToEntIndex(removeEntityInfo.reference);
			if (IsValidEntity(entity))
			{
				RemoveEntity(entity);
			}
			
			g_List_RemoveEntities.Erase(i);
		}
	}
	
	if (g_List_Zones.Length)
	{
		ZoneInfo zoneInfo;
		for (int i = 0; i < g_List_Zones.Length; i++)
		{
			g_List_Zones.GetArray(i, zoneInfo);
			if (!view_as<bool>(zoneInfo.flags & ZONE_SPAWNED))
			{
				continue;
			}
			
			if (!view_as<bool>(zoneInfo.flags & ZONE_RENDER_ALL) 
				&& !view_as<bool>(zoneInfo.flags & ZONE_RENDER_TOP) 
				&& !view_as<bool>(zoneInfo.flags & ZONE_RENDER_BOTTOM) 
				&& !view_as<bool>(zoneInfo.flags & ZONE_RENDER_FRONT) 
				&& !view_as<bool>(zoneInfo.flags & ZONE_RENDER_BACK) 
				&& !view_as<bool>(zoneInfo.flags & ZONE_RENDER_LEFT) 
				&& !view_as<bool>(zoneInfo.flags & ZONE_RENDER_RIGHT))
			{
				continue;
			}
			
			if (zoneInfo.zoneType == ZoneType_End)
			{
				RenderZoneToAll(zoneInfo.pointMin, zoneInfo.pointMax, g_BeamModel, TIMER_THINK_INTERVAL + 0.1, 2.0, view_as<int>({0, 255, 0, 255}), zoneInfo.flags);
			}
			else
			{
				RenderZoneToAll(zoneInfo.pointMin, zoneInfo.pointMax, g_BeamModel, TIMER_THINK_INTERVAL + 0.1, 2.0, view_as<int>({255, 0, 0, 255}), zoneInfo.flags);
			}
		}
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
		{
			continue;
		}
		
		int clientTeam = GetClientTeam(i);
		if (g_MoveInfo[i].moveTime && gameTime >= g_MoveInfo[i].moveTime)
		{
			if (IsPlayerAlive(i))
			{
				ForcePlayerSuicide(i);
			}
			
			ChangeClientTeam(i, g_MoveInfo[i].toTeam);
			
			g_MoveInfo[i].moveTime = 0.0;
			g_MoveInfo[i].toTeam = CS_TEAM_NONE;
		}
		
		if (clientTeam < CS_TEAM_SPECTATOR)
		{
			continue;
		}
		
		int userId = GetClientUserId(i);
		if (IsPlayerAlive(i))
		{
			if (clientTeam == CS_TEAM_CT)
			{
				if (view_as<bool>(g_PlayerFlags[i] & PLAYER_HAS_FINISHED_MAP))
				{
					PrintHintText(i, "{position:1}Time: %02d:%02d:%02d [#%d]", g_FinishInfo[i].finishMin, g_FinishInfo[i].finishSec, g_FinishInfo[i].finishMs, g_FinishInfo[i].finishPos);
				}
				else if (view_as<bool>(g_RoundFlags & ROUND_END_ZONE_SPAWNED) && !valveWarmup)
				{
					PrintHintText(i, "{position:1}Time: %02d:%02d:%02d", timerMin, timerSec, timerMs);
				}
				
				flags |= (THINK_PLAYERS_AT_CT | THINK_PLAYERS_ALIVE_AT_CT);
			}
			
			PrintHintText(i, "{position:2}Speed: %03d u/s", RoundToZero(GetClientVelocity(i) * GetClientVelocityFactor(i)));
			PrintHintText(i, "{position:3}Hide Players: %s", view_as<bool>(g_PlayerFlags[i] & PLAYER_IS_HIDING_OTHER_PLAYERS) ? "On" : "Off");
			
			if (view_as<bool>(g_HudInfo[i].displayFlags & HUD_DISPLAY_SPECTATORS))
			{
				PrintHintText(i, "{position:4}Spectators: %d", g_NumSpectators[i]);
			}
			
			if (g_SpeedInfo[i].maxSpeedType != SpeedType_Normal)
			{
				SetHudTextParams(-1.0, 0.60, TIMER_THINK_INTERVAL + 0.1, 95, 254, 95, 1, 0, 0.0, 0.0, 0.0);
				ShowHudText(i, 2, "[x%d]", view_as<int>(g_SpeedInfo[i].speedType));
			}
			
			if (view_as<bool>(g_HudInfo[i].displayFlags & HUD_DISPLAY_BUTTONS))
			{
				SetHudTextParams(-1.0, 0.64, TIMER_THINK_INTERVAL + 0.1, 255, 255, 255, 1, 0, 0.0, 0.0, 0.0);
				ShowHudText(i, 3, "%s  %s  %s  %s      %s  %s", 
					view_as<bool>(g_TimerButtons[i] & IN_MOVELEFT) ? "A" : "—", 
					view_as<bool>(g_TimerButtons[i] & IN_FORWARD) ? "W" : "—", 
					view_as<bool>(g_TimerButtons[i] & IN_BACK) ? "S" : "—", 
					view_as<bool>(g_TimerButtons[i] & IN_MOVERIGHT) ? "D" : "—", 
					view_as<bool>(g_TimerButtons[i] & IN_DUCK) ? "C" : "—", 
					view_as<bool>(g_TimerButtons[i] & IN_JUMP) ? "J" : "—");
			}
			
			if (g_RefillAmmoTime[i] && gameTime >= g_RefillAmmoTime[i])
			{
				RefillClientAmmo(i);
				g_RefillAmmoTime[i] = 0.0;
			}
			
			if (g_RemoveProtectionTime[i] && gameTime >= g_RemoveProtectionTime[i])
			{
				RemoveClientProtection(i);
				
				if (userId == g_TerroristId)
				{
					SetEntityGlow(i, 224, 175, 86, 255);
					SetEntityRenderColor(i, 224, 175, 86, 255);
				}
				else if (userId == g_TerroristKillerId)
				{
					SetEntityGlow(i, 114, 155, 221, 255);
					SetEntityRenderColor(i, 114, 155, 221, 255);
				}
				
				g_RemoveProtectionTime[i] = 0.0;
			}
		}
		else
		{
			if (clientTeam == CS_TEAM_CT)
			{
				flags |= THINK_PLAYERS_AT_CT;
			}
			
			int observerMode = GetClientObserverMode(i);
			if (observerMode == SPECMODE_FIRSTPERSON || observerMode == SPECMODE_THRIDPERSON)
			{
				int observerTarget = GetClientObserverTarget(i);
				if (observerTarget != g_LastObserver[i])
				{
					PrintHintText(i, "{position:1}");
					PrintHintText(i, "{position:2}");
				}
				
				if (observerTarget)
				{
					if (view_as<bool>(g_PlayerFlags[observerTarget] & PLAYER_HAS_FINISHED_MAP))
					{
						PrintHintText(i, "{position:1}Time: %02d:%02d:%02d [#%d]", g_FinishInfo[observerTarget].finishMin, g_FinishInfo[observerTarget].finishSec, g_FinishInfo[observerTarget].finishMs, g_FinishInfo[observerTarget].finishPos);
					}
					else
					{
						if (view_as<bool>(g_RoundFlags & ROUND_END_ZONE_SPAWNED) 
							&& !valveWarmup 
							&& GetClientTeam(observerTarget) == CS_TEAM_CT)
						{
							PrintHintText(i, "{position:1}Time: %02d:%02d:%02d", timerMin, timerSec, timerMs);
						}
					}
					
					PrintHintText(i, "{position:2}Speed: %03d u/s", RoundToZero(GetClientVelocity(observerTarget) * GetClientVelocityFactor(observerTarget)));
					
					if (view_as<bool>(g_HudInfo[i].displayFlags & HUD_DISPLAY_SPEC_BUTTONS))
					{
						SetHudTextParams(-1.0, 0.64, TIMER_THINK_INTERVAL + 0.1, 255, 255, 255, 1, 0, 0.0, 0.0, 0.0);
						ShowHudText(i, 3, "%s  %s  %s  %s      %s  %s", 
							view_as<bool>(g_TimerButtons[observerTarget] & IN_MOVELEFT) ? "A" : "—", 
							view_as<bool>(g_TimerButtons[observerTarget] & IN_FORWARD) ? "W" : "—", 
							view_as<bool>(g_TimerButtons[observerTarget] & IN_BACK) ? "S" : "—", 
							view_as<bool>(g_TimerButtons[observerTarget] & IN_MOVERIGHT) ? "D" : "—", 
							view_as<bool>(g_TimerButtons[observerTarget] & IN_DUCK) ? "C" : "—", 
							view_as<bool>(g_TimerButtons[observerTarget] & IN_JUMP) ? "J" : "—");
					}
					
					if (!g_IsStealthLibraryLoaded || !AdminStealth_IsClientInStealth(i))
					{
						numSpectators[observerTarget]++;
					}
				}
				
				g_LastObserver[i] = observerTarget;
			}
			else if (g_LastObserver[i])
			{
				PrintHintText(i, "{position:1}");
				PrintHintText(i, "{position:2}");
				
				g_LastObserver[i] = 0;
			}
		}
		
		if (g_RespawnInfo[i].respawnTime)
		{
			if (g_RespawnInfo[i].respawnType == RespawnType_Warmup)
			{
				flags |= THINK_WARMUP_RESPAWNING_PLAYERS;
			}
			
			if (gameTime >= g_RespawnInfo[i].respawnTime)
			{
				g_NumWarmups[i]++;
				
				g_RespawnInfo[i].respawnTime = 0.0;
				g_RespawnInfo[i].respawnType = RespawnType_None;
				
				CS_RespawnPlayer(i);
			}
			
			if (clientTeam == CS_TEAM_CT)
			{
				flags |= THINK_PLAYERS_ALIVE_AT_CT;
			}
		}
		
		if (view_as<bool>(g_RoundFlags & ROUND_WARMUP_PERIOD))
		{
			SetHudTextParams(-1.0,  0.22, TIMER_THINK_INTERVAL + 0.1, 255, 255, 255, 1, 0, 0.0, 0.0, 0.0);
			
			if (g_Cvar_WarmupMaxRespawns.IntValue > 0 && clientTeam == CS_TEAM_CT)
			{
				ShowHudText(i, 1, "WARMUP %02d:%02d [%d]", RoundToCeil(g_WarmupDuration - gameTime) / 60, RoundToCeil(g_WarmupDuration - gameTime) % 60, g_Cvar_WarmupMaxRespawns.IntValue - g_NumWarmups[i]);
			}
			else
			{
				ShowHudText(i, 1, "WARMUP %02d:%02d", RoundToCeil(g_WarmupDuration - gameTime) / 60, RoundToCeil(g_WarmupDuration - gameTime) % 60);
			}
		}
		else if (view_as<bool>(g_RoundFlags & ROUND_WARMUP_DISPLAY_ENDING_HUD))
		{
			SetHudTextParams(-1.0,  0.22, TIMER_THINK_INTERVAL + 0.1, 255, 255, 255, 1, 0, 0.0, 0.0, 0.0);
			ShowHudText(i, 1, "WARMUP END");
		}
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		g_TimerButtons[i] = 0;
		g_NumSpectators[i] = numSpectators[i];
	}
	
	if (view_as<bool>(g_RoundFlags & ROUND_WARMUP_RESPAWNING_PLAYERS) 
		&& !view_as<bool>(flags & THINK_WARMUP_RESPAWNING_PLAYERS))
	{
		if (view_as<bool>(flags & THINK_PLAYERS_AT_CT) 
			&& !view_as<bool>(flags & THINK_PLAYERS_ALIVE_AT_CT))
		{
			if (view_as<bool>(g_RoundFlags & ROUND_WARMUP_PERIOD))
			{
				g_RoundFlags &= ~ROUND_WARMUP_PERIOD;
				g_RoundFlags |= ROUND_WARMUP_DISPLAY_ENDING_HUD;
			}
			
			IncreaseTeamScore(CS_TEAM_T);
			CS_TerminateRound(g_Cvar_RoundRestartDelay ? g_Cvar_RoundRestartDelay.FloatValue : 3.0, CSRoundEnd_TerroristWin, true);
			
			if (g_Cvar_DebugModeEnable.BoolValue)
			{
				PrintToChatAll("End warmup in think function");
			}
		}
		
		if (!view_as<bool>(g_RoundFlags & ROUND_WARMUP_PERIOD))
		{
			g_RoundFlags &= ~ROUND_WARMUP_RESPAWNING_PLAYERS;
		}
	}
	
	if (g_Cvar_DebugModeEnable.BoolValue)
	{
		RenderTrapsToAll();
	}
	
	return Plugin_Continue;
}

public Action Timer_DisplayDuelHud(Handle timer, any data)
{
	int client = GetClientOfUserId(view_as<int>(data));
	if (!client || !IsClientInGame(client))
	{
		return Plugin_Stop;
	}
	
	if (view_as<bool>(g_RoundFlags & ROUND_MAP_FINISHED) && !view_as<bool>(g_RoundFlags & ROUND_HAS_ENDED))
	{
		int currentTerrorist = GetTerrorist();
		int terroristKiller = GetTerroristKiller();
		
		if (currentTerrorist && IsPlayerAlive(currentTerrorist) && terroristKiller)
		{
			DisplayDuelHud(client, currentTerrorist, terroristKiller);
		}
	}
	
	return Plugin_Stop;
}

public void Frame_OnConfigsExecuted()
{
	g_Cvar_BotQuota.SetInt(1);
	
	SetConVar("bot_stop", "1");
	SetConVar("bot_controllable", "0");
	
	ClearArray_Ex(g_List_Zones);
	ClearArray_Ex(g_List_ReplacedTraps);
	
	ClearTrie_Ex(g_Map_TrapFlags);
	ClearTrie_Ex(g_Map_TrapActivators);
	ClearTrie_Ex(g_Map_EndActivators);
	ClearTrie_Ex(g_Map_ReplacedTraps);
	
	char path[PLATFORM_MAX_PATH];
	KeyValues kv = new KeyValues("Map Config");
	
	GetCurrentMap(path, sizeof(path));
	BuildPath(Path_SM, path, sizeof(path), "configs/deathrun/%s.cfg", path);
	
	if (kv.ImportFromFile(path))
	{
		if (kv.JumpToKey("Endings"))
		{
			if (kv.GotoFirstSubKey(false))
			{
				int numRestrictedOnFreerun;
				
				do
				{
					EndInfo endInfo;
					int endId = kv.GetNum("id");
					
					if (g_Map_Endings.GetArray(endId, endInfo, sizeof(EndInfo)))
					{
						LogError("(Ends) ID already defined in Ends (ID: %d).", endId);
						continue;
					}
					
					endInfo.endId = endId;
					kv.GetString("name", endInfo.endName, sizeof(EndInfo::endName));
					
					if (kv.GetNum("kill_terrorist"))
					{
						endInfo.flags |= END_KILL_TERRORIST;
					}
					
					if (kv.GetNum("terrorist_speed"))
					{
						endInfo.flags |= END_TERRORIST_SPEED;
					}
					
					if (kv.GetNum("terrorist_killer_speed"))
					{
						endInfo.flags |= END_TERRORIST_KILLER_SPEED;
					}
					
					if (kv.GetNum("restricted_on_freerun"))
					{
						numRestrictedOnFreerun++;
						endInfo.flags |= END_RESTRICTED_ON_FREERUN;
					}
					
					if (kv.GetNum("reverse_default_winner"))
					{
						endInfo.flags |= END_REVERSE_DEFAULT_WINNER;
					}
					
					if (kv.GetNum("block_control_on_bot_weapons"))
					{
						endInfo.flags |= END_BLOCK_CONTROL_ON_BOT_WEAPONS;
					}
					
					g_Map_Endings.SetArray(endInfo.endId, endInfo, sizeof(EndInfo));
				}
				while (kv.GotoNextKey(false));
				
				if (numRestrictedOnFreerun >= g_Map_Endings.Size)
				{
					EndInfo endInfo;
					IntMapSnapshot listEnds = g_Map_Endings.Snapshot();
					
					for (int i = 0; i < listEnds.Length; i++)
					{
						int key = listEnds.GetKey(i);
						g_Map_Endings.GetArray(key, endInfo, sizeof(EndInfo));
						
						endInfo.flags &= ~END_RESTRICTED_ON_FREERUN;
						g_Map_Endings.SetArray(key, endInfo, sizeof(EndInfo));
					}
					
					delete listEnds;
					LogError("(Ends) No end available in Freerun Mode (this feature will be disabled).");
				}
			}
			
			kv.Rewind();
		}
		
		if (kv.JumpToKey("Trap Activators"))
		{
			if (kv.GotoFirstSubKey(false))
			{
				do
				{
					char key[256];
					kv.GetString("name", key, sizeof(key));				
					
					if (key[0])
					{
						StringToLower(key);
						Format(key, sizeof(key), "n:%s", key);
					}
					else
					{
						kv.GetString("hammer", key, sizeof(key));
						if (!key[0])
						{
							continue;
						}
						
						Format(key, sizeof(key), "h:%s", key);
					}
					
					TrapActivatorInfo trapActivatorInfo;
					trapActivatorInfo.trapId = kv.GetNum("id");
					trapActivatorInfo.trapType = TrapType_None;
					
					char type[256];
					kv.GetString("type", type, sizeof(type));
					
					if (StrEqual(type, "end", false))
					{
						int endId = kv.GetNum("end");
						if (endId)
						{
							EndInfo endInfo;
							if (!g_Map_Endings.GetArray(endId, endInfo, sizeof(EndInfo)))
							{
								LogError("(End Activators) Cannot find ID in Ends (ID: %d)", endId);
								continue;
							}
						}
						
						trapActivatorInfo.endId = endId;
						trapActivatorInfo.trapType = TrapType_End;
					}
					else if (StrEqual(type, "normal", false))
					{
						trapActivatorInfo.trapType = TrapType_Normal;
					}
					
					if (kv.GetNum("ignore_outputs"))
					{
						trapActivatorInfo.flags |= TRAP_ACTIVATOR_IGNORE_OUTPUTS;
					}
					
					if (kv.GetNum("restricted_on_freerun"))
					{
						trapActivatorInfo.flags |= TRAP_ACTIVATOR_RESTRICTED_ON_FREERUN;
					}
					
					if (kv.JumpToKey("activators"))
					{
						if (kv.GetNum("terrorist"))
						{
							trapActivatorInfo.flags |= TRAP_ACTIVATOR_TERRORIST_CAN_USE;
							trapActivatorInfo.flags |= TRAP_ACTIVATOR_HAS_USE_RESTRICTIONS;
						}
						
						if (kv.GetNum("terrorist_killer"))
						{
							trapActivatorInfo.flags |= TRAP_ACTIVATOR_TERRORIST_KILLER_CAN_USE;
							trapActivatorInfo.flags |= TRAP_ACTIVATOR_HAS_USE_RESTRICTIONS;
						}
						
						kv.GoBack();
					}
					
					if (trapActivatorInfo.trapId)
					{
						if (trapActivatorInfo.trapType == TrapType_End 
							|| trapActivatorInfo.trapType == TrapType_Normal)
						{
							char numKey[128];
							if (trapActivatorInfo.trapType == TrapType_End)
							{
								FormatEx(numKey, sizeof(numKey), "%d:%d", view_as<int>(trapActivatorInfo.trapType), trapActivatorInfo.endId);
							}
							else if (trapActivatorInfo.trapType == TrapType_Normal)
							{
								IntToString(view_as<int>(trapActivatorInfo.trapType), numKey, sizeof(numKey));
							}
							
							int numTraps;
							g_Map_NumTraps.GetValue(numKey, numTraps);
							
							if (trapActivatorInfo.trapId > numTraps)
							{
								g_Map_NumTraps.SetValue(numKey, trapActivatorInfo.trapId);
							}
						}
					}
					
					g_Map_TrapActivators.SetArray(key, trapActivatorInfo, sizeof(TrapActivatorInfo));
				}
				while (kv.GotoNextKey(false));
			}
			
			kv.Rewind();
		}
		
		if (kv.JumpToKey("Trap Flags"))
		{
			if (kv.GotoFirstSubKey(false))
			{
				do
				{
					char key[256];
					kv.GetString("name", key, sizeof(key));				
					
					if (key[0])
					{
						StringToLower(key);
						Format(key, sizeof(key), "n:%s", key);
					}
					else
					{
						kv.GetString("hammer", key, sizeof(key));
						if (!key[0])
						{
							continue;
						}
						
						Format(key, sizeof(key), "h:%s", key);
					}
					
					int flags;
					if (kv.GetNum("ignore_proximity"))
					{
						flags |= TRAP_IGNORE_PROXIMITY;
					}
					
					if (kv.GetNum("ignore_proximity_from_template"))
					{
						flags |= TRAP_IGNORE_PROXIMITY_FROM_TEMPLATE;
					}
					
					if (kv.GetNum("ignore_speed"))
					{
						flags |= TRAP_IGNORE_SPEED;
					}
					
					if (kv.GetNum("ignore_reverse"))
					{
						flags |= TRAP_IGNORE_REVERSE;
					}
					
					if (kv.GetNum("ignore_outputs"))
					{
						flags |= TRAP_IGNORE_OUTPUTS;
					}
					
					if (kv.GetNum("ignore_breakables_on_kill"))
					{
						flags |= TRAP_IGNORE_BREAKABLES_ON_KILL;
					}
					
					if (kv.GetNum("ignore_breakables_on_move"))
					{
						flags |= TRAP_IGNORE_BREAKABLES_ON_MOVE;
					}
					
					if (kv.GetNum("ignore_breakables_on_first_move"))
					{
						flags |= TRAP_IGNORE_BREAKABLES_ON_FIRST_MOVE;
					}
					
					if (kv.GetNum("ignore_breakables_on_speed"))
					{
						flags |= TRAP_IGNORE_BREAKABLES_ON_SPEED;
					}
					
					if (kv.GetNum("ignore_breakables_on_reverse"))
					{
						flags |= TRAP_IGNORE_BREAKABLES_ON_REVERSE;
					}
					
					if (kv.GetNum("add_in_breakables_on_move"))
					{
						flags |= TRAP_ADD_IN_BREAKABLES_ON_MOVE;
					}
					
					if (kv.GetNum("add_in_breakables_on_first_move"))
					{
						flags |= TRAP_ADD_IN_BREAKABLES_ON_FIRST_MOVE;
					}
					
					if (kv.GetNum("add_in_breakables_on_speed"))
					{
						flags |= TRAP_ADD_IN_BREAKABLES_ON_SPEED;
					}
					
					if (kv.GetNum("add_in_breakables_on_reverse"))
					{
						flags |= TRAP_ADD_IN_BREAKABLES_ON_REVERSE;
					}
					
					if (kv.GetNum("remove_from_proximity_on_stop"))
					{
						flags |= TRAP_REMOVE_FROM_PROXIMITY_ON_STOP;
					}
					
					if (kv.GetNum("replace_other_traps"))
					{
						flags |= TRAP_IS_REPLACING_OTHER_TRAPS;
					}
					
					if (kv.GetNum("spawn_enabled"))
					{
						flags |= TRAP_SPAWN_ENABLED;
					}
					
					if (kv.GetNum("spawn_open"))
					{
						flags |= TRAP_SPAWN_OPEN;
					}
					
					if (kv.GetNum("spawn_closed"))
					{
						flags |= TRAP_SPAWN_CLOSED;
					}
					
					if (kv.GetNum("spawn_reversed"))
					{
						flags |= TRAP_SPAWN_REVERSED;
					}
					
					if (kv.GetNum("disable_on_stop"))
					{
						flags |= TRAP_DISABLE_ON_STOP;
					}
					
					g_Map_TrapFlags.SetValue(key, flags);
				
				}
				while (kv.GotoNextKey(false));
			}
			
			kv.Rewind();
		}
		
		if (kv.JumpToKey("Replaced Traps"))
		{
			if (kv.GotoFirstSubKey(false))
			{
				do
				{
					char key[256];
					kv.GetString("name", key, sizeof(key));				
					
					if (key[0])
					{
						StringToLower(key);
						Format(key, sizeof(key), "n:%s", key);
					}
					else
					{
						kv.GetString("hammer", key, sizeof(key));
						if (!key[0])
						{
							continue;
						}
						
						Format(key, sizeof(key), "h:%s", key);
					}
					
					if (kv.JumpToKey("replace"))
					{
						RangeInfo rangeInfo;
						rangeInfo.rangeStart = g_List_ReplacedTraps.Length;
						
						if (kv.GotoFirstSubKey(false))
						{
							do
							{
								char value[256];
								kv.GetString("name", value, sizeof(value));				
								
								if (value[0])
								{
									StringToLower(value);
									Format(value, sizeof(value), "n:%s", value);
								}
								else
								{
									kv.GetString("hammer", value, sizeof(value));
									if (!value[0])
									{
										continue;
									}
									
									Format(value, sizeof(value), "h:%s", value);
								}
								
								g_List_ReplacedTraps.PushString(value);
								
							}
							while (kv.GotoNextKey(false));
							
							kv.GoBack();
						}
						
						if (g_List_ReplacedTraps.Length != rangeInfo.rangeStart)
						{
							rangeInfo.rangeEnd = g_List_ReplacedTraps.Length;
							g_Map_ReplacedTraps.SetArray(key, rangeInfo, sizeof(RangeInfo));
						}
						
						kv.GoBack();
					}
				
				}
				while (kv.GotoNextKey(false));
			}
			
			kv.Rewind();
		}
		
		if (kv.JumpToKey("End Activators"))
		{
			if (kv.GotoFirstSubKey(false))
			{
				do
				{
					char key[256];
					kv.GetString("name", key, sizeof(key));				
					
					if (key[0])
					{
						StringToLower(key);
						Format(key, sizeof(key), "n:%s", key);
					}
					else
					{
						kv.GetString("hammer", key, sizeof(key));
						if (!key[0])
						{
							continue;
						}
						
						Format(key, sizeof(key), "h:%s", key);
					}
					
					int endId = kv.GetNum("end");
					if (endId)
					{
						EndInfo endInfo;
						if (!g_Map_Endings.GetArray(endId, endInfo, sizeof(EndInfo)))
						{
							LogError("(End Activators) Cannot find ID in Ends (ID: %d)", endId);
							continue;
						}
					}
					
					g_Map_EndActivators.SetValue(key, endId);
				}
				while (kv.GotoNextKey(false));
			}
			
			kv.Rewind();
		}
		
		if (kv.JumpToKey("Zones"))
		{
			if (kv.GotoFirstSubKey(false))
			{
				do
				{
					float pointMin[3];
					float pointMax[3];
					ZoneInfo zoneInfo;
					
					kv.GetVector("point_a", pointMin);
					kv.GetVector("point_b", pointMax);
					
					for (int i = 0; i < 3; i++)
					{
						zoneInfo.pointMin[i] = pointMax[i] > pointMin[i] ? pointMin[i] : pointMax[i];
						zoneInfo.pointMax[i] = pointMax[i] > pointMin[i] ? pointMax[i] : pointMin[i];
					}
					
					if (kv.GetNum("render_all"))
					{
						zoneInfo.flags |= ZONE_RENDER_ALL;
					}
					
					if (kv.GetNum("render_top"))
					{
						zoneInfo.flags |= ZONE_RENDER_TOP;
					}
					
					if (kv.GetNum("render_bottom"))
					{
						zoneInfo.flags |= ZONE_RENDER_BOTTOM;
					}
					
					if (kv.GetNum("render_front"))
					{
						zoneInfo.flags |= ZONE_RENDER_FRONT;
					}
					
					if (kv.GetNum("render_back"))
					{
						zoneInfo.flags |= ZONE_RENDER_BACK;
					}
					
					if (kv.GetNum("render_left"))
					{
						zoneInfo.flags |= ZONE_RENDER_LEFT;
					}
					
					if (kv.GetNum("render_right"))
					{
						zoneInfo.flags |= ZONE_RENDER_RIGHT;
					}
					
					char type[256];
					kv.GetString("type", type, sizeof(type));
					
					if (StrEqual(type, "end", false))
					{
						zoneInfo.zoneType = ZoneType_End;
					}
					else if (StrEqual(type, "hurt", false))
					{
						zoneInfo.zoneType = ZoneType_Hurt;
					}
					else if (StrEqual(type, "solid", false))
					{
						zoneInfo.zoneType = ZoneType_Solid;
					}
					else
					{
						LogError("Zone without type specified.");
						continue;
					}
					
					g_List_Zones.PushArray(zoneInfo);
					
				}
				while (kv.GotoNextKey(false));
			}
			
			kv.Rewind();
		}
		
		if (kv.JumpToKey("ConVars"))
		{
			if (kv.GotoFirstSubKey(false))
			{
				do
				{
					char key[256];
					kv.GetString("convar", key, sizeof(key));
					
					if (!key[0])
					{
						continue;
					}
					
					char value[256];
					kv.GetString("value", value, sizeof(value));
					
					SetConVar(key, value);
				
				}
				while (kv.GotoNextKey(false));
			}
			
			kv.Rewind();
		}
	}
	
	delete kv;
}

public void Frame_OnPlayerJump(any data)
{
	int client = GetClientOfUserId(view_as<int>(data));
	if (!client || !IsClientInGame(client) || !IsPlayerAlive(client))
	{
		return;
	}
	
	if (GetClientTeam(client) == CS_TEAM_CT && g_Cvar_CounterTerroristsMaxSpeed.FloatValue > 0.0)
	{
		SetClientMaxVelocity(client, g_Cvar_CounterTerroristsMaxSpeed.FloatValue);
	}
}

public void Frame_FixClientScore(any data)
{
	int client = GetClientOfUserId(view_as<int>(data));
	if (!client || !IsClientInGame(client))
	{
		return;
	}
	
	SetEntProp(client, Prop_Data, "m_iFrags", GetClientFrags(client) + 1);
	SetEntProp(client, Prop_Data, "m_iDeaths", GetClientDeaths(client) - 1);
}

public void Frame_OnTerroristSpawn(any data)
{
	int client = GetClientOfUserId(view_as<int>(data));
	if (!client || !IsClientInGame(client) || !IsPlayerAlive(client) || GetClientTeam(client) != CS_TEAM_T)
	{
		return;
	}
	
	char terroristName[MAX_NAME_LENGTH];
	GetClientName_Ex(client, terroristName, sizeof(terroristName));
	CPrintToChatAll_Ex(client, false, "\x04[Deathrun]\x03 %s\x01 is now the\x10 Terrorist.", terroristName);
	
	if (view_as<bool>(g_RoundFlags & ROUND_END_ZONE_SPAWNED) 
		&& !view_as<bool>(g_RoundFlags & ROUND_END_CHOSEN))
	{
		g_SpeedInfo[client].speedType = SpeedType_x3;
		g_SpeedInfo[client].maxSpeedType = SpeedType_x5;
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 3.0);
		
		CPrintToChatAll_Ex(client, false, "\x04[Deathrun]\x03 %s\x01 can use\x04 [x%d]\x01 speed.", terroristName, view_as<int>(g_SpeedInfo[client].maxSpeedType));
	}
}

public bool TR_FilterPlayers(int entity, int mask, any data)
{
	if (IsEntityClient(entity))
	{
		return false;
	}
	
	return true;
}

void LoadGameData()
{
	Handle configFile = LoadGameConfigFile("deathrun.games");
	if (!configFile)
	{
		SetFailState("Failed to load \"deathrun.games\" gamedata.");
	}
	
	int filterOffset = GameConfGetOffset(configFile, "CBaseTrigger::PassesTriggerFilters");
	if (filterOffset == -1)
	{
		SetFailState("Failed to load \"CBaseTrigger::PassesTriggerFilters\" offset.");
	}
	
	delete configFile;
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetVirtual(filterOffset);
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_SDKCall_PassesTriggerFilters = EndPrepSDKCall();
	
	if (!g_SDKCall_PassesTriggerFilters)
	{
		SetFailState("Failed to prepare \"CBaseTrigger::PassesTriggerFilters\" call.");
	}
}

void OnEntityOutput(int entity, const char[] output, bool isTrap, TrapInfo trapInfo)
{
	char className[256];
	GetEntityClassname(entity, className, sizeof(className));
	
	ClassType classType;
	if (!g_Map_ClassNames.GetValue(className, classType))
	{
		return;
	}
	
	OutputType outputType;
	if (!g_Map_Outputs.GetValue(output, outputType))
	{
		return;
	}
	
	int reference = EntIndexToEntRef_Ex(entity);
	
	switch (classType)
	{
		case ClassType_EnvEntityMaker:
		{
			if (outputType == OutputType_OnEntitySpawned)
			{
				char templateName[256];
				GetEntPropString(entity, Prop_Data, "m_iszTemplate", templateName, sizeof(templateName));
				
				int ent = FindEntityByName(-1, templateName);
				if (ent != -1)
				{
					char templateClassName[256];
					GetEntityClassname(ent, templateClassName, sizeof(templateClassName));
					
					ClassType templateClassType;
					if (!g_Map_ClassNames.GetValue(templateClassName, templateClassType) 
						|| templateClassType != ClassType_PointTemplate)
					{
						return;
					}
					
					OnTemplateSpawned(ent, view_as<bool>(trapInfo.flags & TRAP_IS_ACTIVATED), trapInfo.activatorId);
				}
				
				if (!view_as<bool>(trapInfo.flags & TRAP_IS_ACTIVATED))
				{
					return;
				}
				
				trapInfo.flags &= ~TRAP_IS_ACTIVATED;
				trapInfo.flags &= ~TRAP_LISTEN_TO_OUTPUTS;
				
				g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
			}
			else if (outputType == OutputType_OnEntityFailedSpawn)
			{
				if (!view_as<bool>(trapInfo.flags & TRAP_IS_ACTIVATED))
				{
					return;
				}
				
				trapInfo.flags &= ~TRAP_IS_ACTIVATED;
				trapInfo.flags &= ~TRAP_LISTEN_TO_OUTPUTS;
				
				g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
			}
		}
		
		case ClassType_EnvFire:
		{
			if (!isTrap)
			{
				return;
			}
			
			if (outputType == OutputType_OnIgnited)
			{
				if (view_as<bool>(trapInfo.flags & TRAP_IS_ACTIVATED))
				{
					trapInfo.flags &= ~TRAP_IS_ACTIVATED;
					trapInfo.flags &= ~TRAP_LISTEN_TO_OUTPUTS;
					
					RemoveEntityFromProximity(entity, trapInfo, TRAP_IN_PROXIMITY);
					
					if (view_as<bool>(trapInfo.flags & TRAP_IS_CHILD))
					{
						AddEntityInProximity(reference, trapInfo, TRAP_CHILD_IN_PROXIMITY);
					}
				}
				else
				{
					trapInfo.flags |= TRAP_IS_ACTIVATED;
					if (!view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
					{
						AddEntityInProximity(reference, trapInfo, TRAP_IN_PROXIMITY);
					}
				}
				
				g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
			}
			else if (outputType == OutputType_OnExtinguished)
			{
				if (view_as<bool>(trapInfo.flags & TRAP_IS_ACTIVATED))
				{
					trapInfo.flags &= ~TRAP_IS_ACTIVATED;
					trapInfo.flags &= ~TRAP_LISTEN_TO_OUTPUTS;
					
					if (!view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
					{
						RemoveEntityFromProximity(entity, trapInfo, TRAP_IN_PROXIMITY | TRAP_CHILD_IN_PROXIMITY);
					}
				}
				else
				{
					trapInfo.flags |= TRAP_IS_ACTIVATED;
					
					if (view_as<bool>(trapInfo.flags & TRAP_IS_CHILD))
					{
						RemoveEntityFromProximity(entity, trapInfo, TRAP_CHILD_IN_PROXIMITY);
					}
				}
				
				g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
			}
		}
		
		case ClassType_FuncButton:
		{
			if (outputType == OutputType_OnIn)
			{
				SetEntPropFloat(entity, Prop_Data, "m_flUseLookAtAngle", 1.0);
			}
			else if (outputType == OutputType_OnOut)
			{
				if (!GetEntProp(entity, Prop_Data, "m_bLocked"))
				{
					SetEntPropFloat(entity, Prop_Data, "m_flUseLookAtAngle", -1.0);
				}
			}
		}
		
		case ClassType_FuncDoor, ClassType_FuncDoorRotating, ClassType_FuncMoveLinear, ClassType_FuncWaterAnalog:
		{
			if (!isTrap)
			{
				return;
			}
			
			if (outputType == OutputType_OnClose)
			{
				if (!view_as<bool>(trapInfo.flags & TRAP_WAIT_TO_REACTIVATE))
				{
					return;
				}
				
				trapInfo.flags &= ~TRAP_WAIT_TO_REACTIVATE;
				
				if (!view_as<bool>(trapInfo.flags & TRAP_IS_ACTIVATED) 
					&& !view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED) 
					&& !view_as<bool>(trapInfo.flags & TRAP_IS_TEMPLATE))
				{
					if (!view_as<bool>(trapInfo.configFlags & TRAP_IGNORE_OUTPUTS))
					{
						trapInfo.flags |= TRAP_LISTEN_TO_OUTPUTS;
					}
					
					trapInfo.flags |= TRAP_IS_ACTIVATED;
					
					if (IsEntitySolid(entity) && CanPlayersTouchEntity(entity, classType))
					{
						AddEntityInProximity(reference, trapInfo, TRAP_IN_PROXIMITY);
						
						if (view_as<bool>(trapInfo.configFlags & TRAP_ADD_IN_BREAKABLES_ON_FIRST_MOVE))
						{
							int flags = TRAP_IN_BREAKABLES_ON_FIRST_MOVE;
							if (view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
							{
								flags |= TRAP_SPAWN_ENABLED;
							}
							
							AddEntityInBreakables(entity, trapInfo, flags);
						}
						else if (view_as<bool>(trapInfo.configFlags & TRAP_ADD_IN_BREAKABLES_ON_MOVE))
						{
							int flags = TRAP_IN_BREAKABLES_ON_MOVE;
							if (view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
							{
								flags |= TRAP_SPAWN_ENABLED;
							}
							
							AddEntityInBreakables(entity, trapInfo, flags);
						}
					}
					
					int flags = TRAP_CHILD_IN_PROXIMITY;
					if (view_as<bool>(trapInfo.configFlags & TRAP_ADD_IN_BREAKABLES_ON_FIRST_MOVE))
					{
						flags |= TRAP_CHILD_IN_BREAKABLES_ON_FIRST_MOVE;
					}
					else if (view_as<bool>(trapInfo.configFlags & TRAP_ADD_IN_BREAKABLES_ON_MOVE))
					{
						flags |= TRAP_CHILD_IN_BREAKABLES_ON_MOVE;
					}
					
					if (view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
					{
						flags |= TRAP_SPAWN_ENABLED;
					}
					
					ActivateTrapChildren(entity, trapInfo.activatorId, flags);
				}
				else
				{
					if (view_as<bool>(trapInfo.configFlags & TRAP_REMOVE_FROM_PROXIMITY_ON_STOP) 
						|| view_as<bool>(trapInfo.configFlags & TRAP_ADD_IN_BREAKABLES_ON_MOVE))
					{
						if (IsEntitySolid(entity) && CanPlayersTouchEntity(entity, classType))
						{
							if (view_as<bool>(trapInfo.configFlags & TRAP_REMOVE_FROM_PROXIMITY_ON_STOP))
							{
								AddEntityInProximity(reference, trapInfo, TRAP_IN_PROXIMITY);
							}
							
							if (view_as<bool>(trapInfo.configFlags & TRAP_ADD_IN_BREAKABLES_ON_MOVE))
							{
								int flags = TRAP_IN_BREAKABLES_ON_MOVE;
								if (view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
								{
									flags |= TRAP_SPAWN_ENABLED;
								}
								
								AddEntityInBreakables(entity, trapInfo, flags);
							}
						}
						
						int flags;
						if (view_as<bool>(trapInfo.configFlags & TRAP_REMOVE_FROM_PROXIMITY_ON_STOP))
						{
							flags |= TRAP_CHILD_IN_PROXIMITY;
						}
						
						if (view_as<bool>(trapInfo.configFlags & TRAP_ADD_IN_BREAKABLES_ON_MOVE))
						{
							flags |= TRAP_CHILD_IN_BREAKABLES_ON_MOVE;
						}
						
						if (view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
						{
							flags |= TRAP_SPAWN_ENABLED;
						}
						
						ActivateTrapChildren(entity, trapInfo.activatorId, flags);
					}
				}
				
				g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
			}
			else if (outputType == OutputType_OnFullyOpen || outputType == OutputType_OnFullyClosed)
			{
				if (!view_as<bool>(trapInfo.flags & TRAP_IS_ACTIVATED))
				{
					return;
				}
				
				RemoveEntityFromThinkTraps(reference, trapInfo);
				
				if (outputType == OutputType_OnFullyOpen && trapInfo.nextState != StateType_Open 
					|| outputType == OutputType_OnFullyClosed && trapInfo.nextState != StateType_Closed)
				{
					return;
				}
				
				if (outputType == OutputType_OnFullyOpen 
					&& (trapInfo.classType == ClassType_FuncDoor || trapInfo.classType == ClassType_FuncDoorRotating) 
					&& !view_as<bool>(GetEntProp(entity, Prop_Data, "m_spawnflags") & SF_DOOR_NO_AUTO_RETURN) 
					&& GetEntPropFloat(entity, Prop_Data, "m_flWait") != -1.0)
				{
					trapInfo.nextState = StateType_Closed;
					trapInfo.flags |= TRAP_WAIT_TO_REACTIVATE;
				}
				
				if (view_as<bool>(trapInfo.configFlags & TRAP_DISABLE_ON_STOP) 
					|| view_as<bool>(trapInfo.configFlags & TRAP_IS_REPLACING_OTHER_TRAPS))
				{
					trapInfo.flags &= ~TRAP_IS_ACTIVATED;
					trapInfo.flags &= ~TRAP_LISTEN_TO_OUTPUTS;
					
					RemoveEntityFromProximity(entity, trapInfo, TRAP_IN_PROXIMITY);
					RemoveEntityFromBreakables(entity, trapInfo, TRAP_IN_BREAKABLES_ON_MOVE | TRAP_IN_BREAKABLES_ON_FIRST_MOVE);
					
					DeactivateTrapChildren(entity, TRAP_CHILD_IN_PROXIMITY | TRAP_CHILD_IN_BREAKABLES_ON_MOVE | TRAP_CHILD_IN_BREAKABLES_ON_FIRST_MOVE);
					if (view_as<bool>(trapInfo.configFlags & TRAP_IS_REPLACING_OTHER_TRAPS))
					{
						RemoveReplacedEntitiesFromBreakables(entity);
					}
				}
				else if (!view_as<bool>(trapInfo.flags & TRAP_IS_TEMPLATE))
				{
					if (!view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED) 
						&& (outputType == OutputType_OnFullyClosed && trapInfo.spawnState == StateType_Closed 
							|| outputType == OutputType_OnFullyOpen && trapInfo.spawnState == StateType_Open 
							|| trapInfo.classType == ClassType_FuncDoorRotating && HasEntitySpawnAngles(entity, trapInfo.classType)))
					{
						trapInfo.flags &= ~TRAP_IS_ACTIVATED;
						trapInfo.flags &= ~TRAP_LISTEN_TO_OUTPUTS;
						
						RemoveEntityFromProximity(entity, trapInfo, TRAP_IN_PROXIMITY);
						RemoveEntityFromBreakables(entity, trapInfo, TRAP_IN_BREAKABLES_ON_MOVE | TRAP_IN_BREAKABLES_ON_FIRST_MOVE);
						
						DeactivateTrapChildren(entity, TRAP_CHILD_IN_PROXIMITY | TRAP_CHILD_IN_BREAKABLES_ON_MOVE | TRAP_CHILD_IN_BREAKABLES_ON_FIRST_MOVE);
					}
					else if (view_as<bool>(trapInfo.configFlags & TRAP_REMOVE_FROM_PROXIMITY_ON_STOP))
					{
						RemoveEntityFromProximity(entity, trapInfo, TRAP_IN_PROXIMITY);
						DeactivateTrapChildren(entity, TRAP_CHILD_IN_PROXIMITY);
					}
				}
				
				g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
			}
		}
		
		case ClassType_PointTemplate:
		{
			if (outputType == OutputType_OnEntitySpawned)
			{
				OnTemplateSpawned(entity, view_as<bool>(trapInfo.flags & TRAP_IS_ACTIVATED), trapInfo.activatorId);
			}
		}
	}
}

void OnEntityInput(int entity, const char[] input, EntityIO_VariantInfo variantInfo, bool isTrap, int activatorId)
{
	char className[256];
	GetEntityClassname(entity, className, sizeof(className));
	
	ClassType classType;
	if (!g_Map_ClassNames.GetValue(className, classType))
	{
		return;
	}
	
	char inputName[256];
	strcopy(inputName, sizeof(inputName), input);
	StringToLower(inputName);
	
	InputType inputType;
	if (!g_Map_Inputs.GetValue(inputName, inputType))
	{
		return;
	}
	
	TrapInfo trapInfo;
	int reference = EntIndexToEntRef_Ex(entity);
	
	g_Map_Traps.GetArray(reference, trapInfo, sizeof(TrapInfo));
	
	if (isTrap)
	{
		trapInfo.classType = classType;
		trapInfo.activatorId = activatorId;
		
		if (!view_as<bool>(trapInfo.flags & TRAP_HAS_CONFIG_FLAGS_SET))
		{
			trapInfo.flags |= TRAP_HAS_CONFIG_FLAGS_SET;
			GetEntityTrapFlags(entity, trapInfo.configFlags);
		}
	}
	
	switch (classType)
	{
		case ClassType_EnvEntityMaker:
		{
			if (inputType == InputType_Kill)
			{
				if (!isTrap)
				{
					return;
				}
				
				DeactivateTrapChildren(entity, TRAP_CHILD_IN_PROXIMITY);
				ActivateTrapChildren(entity, activatorId, TRAP_CHILD_IN_BREAKABLES_ON_KILL);
			}
			else if (inputType == InputType_ForceSpawn || inputType == InputType_ForceSpawnAtEntityOrigin)
			{
				if (view_as<bool>(trapInfo.flags & TRAP_IS_ACTIVATED) || !isTrap)
				{
					return;
				}
				
				if (!view_as<bool>(trapInfo.flags & TRAP_HAS_SPAWN_DATA_SET))
				{
					trapInfo.flags |= TRAP_HAS_SPAWN_DATA_SET;
				}
				
				if (!view_as<bool>(trapInfo.configFlags & TRAP_IGNORE_OUTPUTS))
				{
					trapInfo.flags |= TRAP_LISTEN_TO_OUTPUTS;
				}
				
				trapInfo.flags |= TRAP_IS_ACTIVATED;
				g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
			}
		}
		
		case ClassType_EnvExplosion:
		{
			if (inputType == InputType_Kill)
			{
				if (!isTrap)
				{
					return;
				}
				
				DeactivateTrapChildren(entity, TRAP_CHILD_IN_PROXIMITY);
				ActivateTrapChildren(entity, trapInfo.activatorId, TRAP_CHILD_IN_BREAKABLES_ON_KILL);
			}
			else if (inputType == InputType_Explode)
			{
				if (view_as<bool>(trapInfo.flags & TRAP_IS_ACTIVATED))
				{
					if (!isTrap)
					{
						trapInfo.flags &= ~TRAP_IS_ACTIVATED;
						trapInfo.flags &= ~TRAP_LISTEN_TO_OUTPUTS;
					}
				}
				else
				{
					if (!isTrap)
					{
						return;
					}
					
					if (!view_as<bool>(trapInfo.flags & TRAP_HAS_SPAWN_DATA_SET))
					{
						trapInfo.flags |= TRAP_HAS_SPAWN_DATA_SET;
					}
					
					if (!view_as<bool>(trapInfo.configFlags & TRAP_IGNORE_OUTPUTS))
					{
						trapInfo.flags |= TRAP_LISTEN_TO_OUTPUTS;
					}
					
					trapInfo.flags |= TRAP_IS_ACTIVATED;
				}
				
				g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
			}
		}
		
		// To do: activatorId
		case ClassType_EnvFire:
		{
			if (inputType == InputType_Kill)
			{
				if (!isTrap)
				{
					return;
				}
				
				RemoveEntityFromProximity(entity, trapInfo, TRAP_IN_PROXIMITY | TRAP_CHILD_IN_PROXIMITY);
				DeactivateTrapChildren(entity, TRAP_CHILD_IN_PROXIMITY);
				
				ActivateTrapChildren(entity, trapInfo.activatorId, TRAP_CHILD_IN_BREAKABLES_ON_KILL);
				g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
			}
			else if (inputType == InputType_StartFire)
			{
				if (!isTrap)
				{
					return;
				}
				
				if (view_as<bool>(trapInfo.flags & TRAP_IS_ACTIVATED) 
					|| !view_as<bool>(GetEntProp(entity, Prop_Data, "m_bEnabled")) 
					|| IsEntityEnabled(entity, trapInfo.classType))
				{
					return;
				}
				
				if (!view_as<bool>(trapInfo.flags & TRAP_HAS_SPAWN_DATA_SET))
				{
					trapInfo.flags |= TRAP_HAS_SPAWN_DATA_SET;
				}
				
				if (!view_as<bool>(trapInfo.configFlags & TRAP_IGNORE_OUTPUTS))
				{
					trapInfo.flags |= TRAP_LISTEN_TO_OUTPUTS;
				}
				
				g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
			}
			else if (inputType == InputType_Extinguish || inputType == InputType_ExtinguishTemporary)
			{
				if (!isTrap)
				{
					return;
				}
				
				if (view_as<bool>(trapInfo.flags & TRAP_IS_ACTIVATED) || !IsEntityEnabled(entity, trapInfo.classType))
				{
					return;
				}
				
				if (!view_as<bool>(trapInfo.flags & TRAP_HAS_SPAWN_DATA_SET))
				{
					trapInfo.configFlags |= TRAP_SPAWN_ENABLED;
					trapInfo.flags |= TRAP_HAS_SPAWN_DATA_SET;
				}
				
				if (!view_as<bool>(trapInfo.configFlags & TRAP_IGNORE_OUTPUTS))
				{
					trapInfo.flags |= TRAP_LISTEN_TO_OUTPUTS;
				}
				
				g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
			}
		}
		
		case ClassType_EnvFireSource, ClassType_EnvGunFire:
		{
			if (inputType == InputType_Kill)
			{
				if (!isTrap)
				{
					return;
				}
				
				DeactivateTrapChildren(entity, TRAP_CHILD_IN_PROXIMITY);
				ActivateTrapChildren(entity, trapInfo.activatorId, TRAP_CHILD_IN_BREAKABLES_ON_KILL);
				
				g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
			}
			else if (inputType == InputType_Enable)
			{
				if (IsEntityEnabled(entity, trapInfo.classType))
				{
					return;
				}
				
				if (view_as<bool>(trapInfo.flags & TRAP_IS_ACTIVATED))
				{
					if (view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
					{
						trapInfo.flags &= ~TRAP_IS_ACTIVATED;
					}
				}
				else
				{
					if (!isTrap)
					{
						return;
					}
					
					if (view_as<bool>(trapInfo.flags & TRAP_HAS_SPAWN_DATA_SET))
					{
						if (view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
						{
							return;
						}
					}
					else
					{
						trapInfo.flags |= TRAP_HAS_SPAWN_DATA_SET;
					}
					
					if (!view_as<bool>(trapInfo.configFlags & TRAP_IGNORE_OUTPUTS))
					{
						trapInfo.flags |= TRAP_LISTEN_TO_OUTPUTS;
					}
					
					trapInfo.flags |= TRAP_IS_ACTIVATED;
					
					if (trapInfo.classType == ClassType_EnvFireSource)
					{
						FindEnvFiresourceTargets(entity, inputType, trapInfo.activatorId);
					}
				}
				
				g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
			}
			else if (inputType == InputType_Disable)
			{
				if (!IsEntityEnabled(entity, trapInfo.classType))
				{
					return;
				}
				
				if (view_as<bool>(trapInfo.flags & TRAP_IS_ACTIVATED))
				{
					if (!view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
					{
						trapInfo.flags &= ~TRAP_IS_ACTIVATED;
						trapInfo.flags &= ~TRAP_LISTEN_TO_OUTPUTS;
					}
				}
				else
				{
					if (!isTrap)
					{
						return;
					}
					
					if (view_as<bool>(trapInfo.flags & TRAP_HAS_SPAWN_DATA_SET))
					{
						if (!view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
						{
							return;
						}
					}
					else
					{
						trapInfo.configFlags |= TRAP_SPAWN_ENABLED;
						trapInfo.flags |= TRAP_HAS_SPAWN_DATA_SET;
					}
					
					trapInfo.flags |= TRAP_IS_ACTIVATED;
					
					if (trapInfo.classType == ClassType_EnvFireSource)
					{
						FindEnvFiresourceTargets(entity, inputType, trapInfo.activatorId);
					}
				}
				
				g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
			}
		}
		
		case ClassType_EnvBeam, ClassType_EnvLaser, ClassType_EnvSmokeStack:
		{
			bool isEntityEnabled = IsEntityEnabled(entity, trapInfo.classType);
			if (inputType == InputType_Toggle)
			{
				inputType = isEntityEnabled ? InputType_TurnOff : InputType_TurnOn;
			}
			
			if (inputType == InputType_Kill)
			{
				if (!isTrap)
				{
					return;
				}
				
				RemoveEntityFromProximity(entity, trapInfo, TRAP_IN_PROXIMITY | TRAP_CHILD_IN_PROXIMITY);
				DeactivateTrapChildren(entity, TRAP_CHILD_IN_PROXIMITY);
				
				ActivateTrapChildren(entity, trapInfo.activatorId, TRAP_CHILD_IN_BREAKABLES_ON_KILL);
				g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
			}
			else if (inputType == InputType_TurnOn)
			{
				if (isEntityEnabled)
				{
					return;
				}
				
				if (view_as<bool>(trapInfo.flags & TRAP_IS_ACTIVATED))
				{
					if (view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
					{
						trapInfo.flags &= ~TRAP_IS_ACTIVATED;						
						if (view_as<bool>(trapInfo.flags & TRAP_IS_CHILD))
						{
							AddEntityInProximity(reference, trapInfo, TRAP_CHILD_IN_PROXIMITY);
						}
					}
				}
				else
				{
					if (!isTrap)
					{
						return;
					}
					
					if (view_as<bool>(trapInfo.flags & TRAP_HAS_SPAWN_DATA_SET))
					{
						if (view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
						{
							return;
						}
					}
					else
					{
						trapInfo.flags |= TRAP_HAS_SPAWN_DATA_SET;
					}
					
					if (!view_as<bool>(trapInfo.configFlags & TRAP_IGNORE_OUTPUTS))
					{
						trapInfo.flags |= TRAP_LISTEN_TO_OUTPUTS;
					}
					
					trapInfo.flags |= TRAP_IS_ACTIVATED;	
					
					if (trapInfo.classType == ClassType_EnvSmokeStack || CanEntityDamageClients(entity, trapInfo.classType))
					{
						AddEntityInProximity(reference, trapInfo, TRAP_IN_PROXIMITY);
					}
				}
				
				g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
			}
			else if (inputType == InputType_TurnOff)
			{
				if (!isEntityEnabled)
				{
					return;
				}
				
				if (view_as<bool>(trapInfo.flags & TRAP_IS_ACTIVATED))
				{
					if (!view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
					{
						trapInfo.flags &= ~TRAP_IS_ACTIVATED;						
						RemoveEntityFromProximity(entity, trapInfo, TRAP_IN_PROXIMITY | TRAP_CHILD_IN_PROXIMITY);
					}
				}
				else
				{
					if (view_as<bool>(trapInfo.flags & TRAP_HAS_SPAWN_DATA_SET))
					{
						if (!view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
						{
							return;
						}
					}
					else
					{
						trapInfo.configFlags |= TRAP_SPAWN_ENABLED;
						trapInfo.flags |= TRAP_HAS_SPAWN_DATA_SET;
					}
					
					trapInfo.flags |= TRAP_IS_ACTIVATED;
					
					if (view_as<bool>(trapInfo.flags & TRAP_IS_CHILD))
					{
						RemoveEntityFromProximity(entity, trapInfo, TRAP_CHILD_IN_PROXIMITY);
					}
				}
				
				g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
			}
		}
		
		case ClassType_EnvShake:
		{
			if (inputType == InputType_Kill)
			{
				if (!isTrap)
				{
					return;
				}
				
				DeactivateTrapChildren(entity, TRAP_CHILD_IN_PROXIMITY);
				ActivateTrapChildren(entity, trapInfo.activatorId, TRAP_CHILD_IN_BREAKABLES_ON_KILL);
				
				g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
			}
			else if (inputType == InputType_StartShake)
			{
				if (view_as<bool>(trapInfo.flags & TRAP_IS_ACTIVATED))
				{
					if (!isTrap)
					{
						trapInfo.flags &= ~TRAP_IS_ACTIVATED;
						trapInfo.flags &= ~TRAP_LISTEN_TO_OUTPUTS;
					}
				}
				else
				{
					if (!isTrap)
					{
						return;
					}
					
					if (!view_as<bool>(trapInfo.flags & TRAP_HAS_SPAWN_DATA_SET))
					{
						trapInfo.flags |= TRAP_HAS_SPAWN_DATA_SET;
					}
					
					if (!view_as<bool>(trapInfo.configFlags & TRAP_IGNORE_OUTPUTS))
					{
						trapInfo.flags |= TRAP_LISTEN_TO_OUTPUTS;
					}
					
					trapInfo.flags |= TRAP_IS_ACTIVATED;
					FindEnvShakeTargets(entity, trapInfo.activatorId);
				}
			}
		}
		
		case ClassType_FuncWall:
		{
			if (!isTrap)
			{
				return;
			}
			
			if (inputType == InputType_Kill)
			{
				RemoveEntityFromProximity(entity, trapInfo, TRAP_IN_PROXIMITY | TRAP_CHILD_IN_PROXIMITY);
				DeactivateTrapChildren(entity, TRAP_CHILD_IN_PROXIMITY); 
				
				if (!view_as<bool>(trapInfo.flags & TRAP_IS_TEMPLATE))
				{
					if (IsEntitySolid(entity) && CanPlayersTouchEntity(entity, classType))
					{
						AddEntityInBreakables(entity, trapInfo, TRAP_IN_BREAKABLES_ON_KILL);
					}
					
					ActivateTrapChildren(entity, trapInfo.activatorId, TRAP_CHILD_IN_BREAKABLES_ON_KILL);
				}
				
				g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
			}
		}
		
		// To do: activatorId
		case ClassType_FuncBreakable, 
			ClassType_PropDynamic, 
			ClassType_FuncPhysBox, 
			ClassType_PropPhysics:
		{
			if (!isTrap)
			{
				return;
			}
			
			if (inputType == InputType_Kill 
				|| inputType == InputType_Break 
				|| inputType == InputType_RemoveHealth 
				|| inputType == InputType_SetHealth 
				|| inputType == InputType_UpdateHealth)
			{
				if (inputType == InputType_RemoveHealth 
					|| inputType == InputType_SetHealth 
					|| inputType == InputType_UpdateHealth)
				{
					if (trapInfo.classType == ClassType_PropPhysics)
					{
						return;
					}
					
					int health;
					if (variantInfo.variantType == EntityIO_VariantType_Float)
					{
						health = variantInfo.iValue;
					}
					else if (variantInfo.variantType == EntityIO_VariantType_String)
					{
						if (!StringToIntEx(variantInfo.sValue, health))
						{
							LogError("(Func_Breakable::InputType_SetHealth) Cannot convert string to int (%s)", variantInfo.sValue);					
						}
					}
					else
					{
						LogError("(Func_Breakable::InputType_SetHealth) Param type is not float (%d)", variantInfo.variantType);					
						return;
					}
					
					if (inputType == InputType_SetHealth)
					{
						if (health > 0)
						{
							return;
						}
					}
					else
					{
						int currentHealth = GetEntProp(entity, Prop_Data, "m_iHealth");
						if (inputType == InputType_RemoveHealth)
						{
							if (currentHealth - health > 0)
							{
								return;
							}
						}
						else
						{
							if (currentHealth + health > 0)
							{
								return;
							}
						}
					}
				}
				
				if (inputType != InputType_Kill)
				{
					if (!view_as<bool>(trapInfo.flags & TRAP_HAS_SPAWN_DATA_SET))
					{
						trapInfo.flags |= TRAP_HAS_SPAWN_DATA_SET;
					}
					
					if (!view_as<bool>(trapInfo.configFlags & TRAP_IGNORE_OUTPUTS))
					{
						trapInfo.flags |= TRAP_LISTEN_TO_OUTPUTS;
					}
				}
				
				RemoveEntityFromProximity(entity, trapInfo, TRAP_IN_PROXIMITY | TRAP_CHILD_IN_PROXIMITY);
				DeactivateTrapChildren(entity, TRAP_CHILD_IN_PROXIMITY); 
				
				if (!view_as<bool>(trapInfo.flags & TRAP_IS_TEMPLATE))
				{
					if (IsEntitySolid(entity) && CanPlayersTouchEntity(entity, classType))
					{
						AddEntityInBreakables(entity, trapInfo, TRAP_IN_BREAKABLES_ON_KILL);
					}
					
					ActivateTrapChildren(entity, trapInfo.activatorId, TRAP_CHILD_IN_BREAKABLES_ON_KILL);
				}
				
				g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
			}
			else if (inputType == InputType_EnableMotion || inputType == InputType_Wake)
			{
				if (trapInfo.classType == ClassType_FuncBreakable 
					|| trapInfo.classType == ClassType_PropDynamic)
				{
					return;
				}
				
				if (inputType == InputType_EnableMotion)
				{
					if (IsEntityEnabled(entity, trapInfo.classType))
					{
						return;
					}
				}
				else
				{
					int spawnFlags = GetEntProp(entity, Prop_Data, "m_spawnflags");
					if (trapInfo.classType == ClassType_FuncPhysBox)
					{
						if (!view_as<bool>(spawnFlags & SF_PHYSBOX_START_ASLEEP) || view_as<bool>(spawnFlags & SF_PHYSBOX_MOTION_DISABLED))
						{
							return;
						}
					}
					else
					{
						if (!view_as<bool>(spawnFlags & SF_PROP_PHYSICS_START_ASLEEP) || view_as<bool>(spawnFlags & SF_PROP_PHYSICS_MOTION_DISABLED))
						{
							return;
						}
					}
				}
				
				if (view_as<bool>(trapInfo.flags & TRAP_IS_ACTIVATED))
				{
					if (view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
					{
						if (!view_as<bool>(trapInfo.flags & TRAP_IS_TEMPLATE))
						{
							trapInfo.flags &= ~TRAP_IS_ACTIVATED;
						}
						else if (view_as<bool>(trapInfo.configFlags & TRAP_REMOVE_FROM_PROXIMITY_ON_STOP) 
							|| view_as<bool>(trapInfo.configFlags & TRAP_ADD_IN_BREAKABLES_ON_MOVE))
						{
							if (IsEntitySolid(entity) && CanPlayersTouchEntity(entity, classType))
							{
								if (view_as<bool>(trapInfo.configFlags & TRAP_REMOVE_FROM_PROXIMITY_ON_STOP))
								{
									AddEntityInProximity(reference, trapInfo, TRAP_IN_PROXIMITY);
								}
								
								if (view_as<bool>(trapInfo.configFlags & TRAP_ADD_IN_BREAKABLES_ON_MOVE))
								{
									int flags = TRAP_IN_BREAKABLES_ON_MOVE;
									if (view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
									{
										flags |= TRAP_SPAWN_ENABLED;
									}
									
									AddEntityInBreakables(entity, trapInfo, flags);
								}
							}
							
							int flags;
							if (view_as<bool>(trapInfo.configFlags & TRAP_REMOVE_FROM_PROXIMITY_ON_STOP))
							{
								flags |= TRAP_CHILD_IN_PROXIMITY;
							}
							
							if (view_as<bool>(trapInfo.configFlags & TRAP_ADD_IN_BREAKABLES_ON_MOVE))
							{
								flags |= TRAP_CHILD_IN_BREAKABLES_ON_MOVE;
							}
							
							if (view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
							{
								flags |= TRAP_SPAWN_ENABLED;
							}
							
							ActivateTrapChildren(entity, trapInfo.activatorId, flags);
						}
					}
				}
				else
				{
					if (view_as<bool>(trapInfo.flags & TRAP_IS_TEMPLATE))
					{
						return;
					}
					
					if (view_as<bool>(trapInfo.flags & TRAP_HAS_SPAWN_DATA_SET))
					{
						if (view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
						{
							return;
						}
					}
					else
					{
						trapInfo.flags |= TRAP_HAS_SPAWN_DATA_SET;
					}
					
					if (!view_as<bool>(trapInfo.configFlags & TRAP_IGNORE_OUTPUTS))
					{
						trapInfo.flags |= TRAP_LISTEN_TO_OUTPUTS;
					}
					
					trapInfo.flags |= TRAP_IS_ACTIVATED;
					
					if (IsEntitySolid(entity) && CanPlayersTouchEntity(entity, classType))
					{
						AddEntityInProximity(reference, trapInfo, TRAP_IN_PROXIMITY);
						if (view_as<bool>(trapInfo.configFlags & TRAP_ADD_IN_BREAKABLES_ON_FIRST_MOVE))
						{
							AddEntityInBreakables(entity, trapInfo, TRAP_IN_BREAKABLES_ON_FIRST_MOVE);
						}
					}
					
					int flags = TRAP_CHILD_IN_PROXIMITY;
					if (view_as<bool>(trapInfo.configFlags & TRAP_ADD_IN_BREAKABLES_ON_FIRST_MOVE))
					{
						flags |= TRAP_CHILD_IN_BREAKABLES_ON_FIRST_MOVE;
					}
					
					ActivateTrapChildren(entity, trapInfo.activatorId, flags);
				}
				
				g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
			}
			else if (inputType == InputType_DisableMotion || inputType == InputType_Sleep)
			{
				if (trapInfo.classType == ClassType_FuncBreakable 
					|| trapInfo.classType == ClassType_PropDynamic)
				{
					return;
				}
				
				if (inputType == InputType_EnableMotion)
				{
					if (!IsEntityEnabled(entity, trapInfo.classType))
					{
						return;
					}
				}
				else
				{
					int spawnFlags = GetEntProp(entity, Prop_Data, "m_spawnflags");
					if (trapInfo.classType == ClassType_FuncPhysBox)
					{
						if (view_as<bool>(spawnFlags & SF_PHYSBOX_START_ASLEEP))
						{
							return;
						}
					}
					else
					{
						if (view_as<bool>(spawnFlags & SF_PROP_PHYSICS_START_ASLEEP))
						{
							return;
						}
					}
				}
				
				if (view_as<bool>(trapInfo.flags & TRAP_IS_ACTIVATED))
				{
					if (!view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
					{
						if (view_as<bool>(trapInfo.configFlags & TRAP_IS_REPLACING_OTHER_TRAPS) 
							|| view_as<bool>(trapInfo.configFlags & TRAP_DISABLE_ON_STOP))
						{
							trapInfo.flags &= ~TRAP_IS_ACTIVATED;
							trapInfo.flags &= ~TRAP_LISTEN_TO_OUTPUTS;
							
							RemoveEntityFromProximity(entity, trapInfo, TRAP_IN_PROXIMITY);
							DeactivateTrapChildren(entity, TRAP_CHILD_IN_PROXIMITY | TRAP_IN_BREAKABLES_ON_FIRST_MOVE);
						}
						else if (view_as<bool>(trapInfo.configFlags & TRAP_REMOVE_FROM_PROXIMITY_ON_STOP))
						{
							RemoveEntityFromProximity(entity, trapInfo, TRAP_IN_PROXIMITY);							
							DeactivateTrapChildren(entity, TRAP_CHILD_IN_PROXIMITY);
						}
					}
				}
				else
				{
					if (view_as<bool>(trapInfo.flags & TRAP_IS_TEMPLATE))
					{
						return;
					}
					
					if (view_as<bool>(trapInfo.flags & TRAP_HAS_SPAWN_DATA_SET))
					{
						if (!view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
						{
							return;
						}
					}
					else
					{
						trapInfo.configFlags |= TRAP_SPAWN_ENABLED;
						trapInfo.flags |= TRAP_HAS_SPAWN_DATA_SET;
					}
					
					if (!view_as<bool>(trapInfo.configFlags & TRAP_IGNORE_OUTPUTS))
					{
						trapInfo.flags |= TRAP_LISTEN_TO_OUTPUTS;
					}
					
					trapInfo.flags |= TRAP_IS_ACTIVATED;
				}
				
				g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
			}
		}
		
		case ClassType_FuncBrush, ClassType_FuncWallToggle:
		{
			bool receivedToggleInput;
			bool isEntityEnabled = IsEntityEnabled(entity, trapInfo.classType);
			
			if (inputType == InputType_Toggle)
			{
				receivedToggleInput = true;
				inputType = isEntityEnabled ? InputType_Disable : InputType_Enable;
			}
			
			if (inputType == InputType_Kill)
			{
				if (!isTrap)
				{
					return;
				}
				
				RemoveEntityFromProximity(entity, trapInfo, TRAP_IN_PROXIMITY | TRAP_CHILD_IN_PROXIMITY);
				DeactivateTrapChildren(entity, TRAP_CHILD_IN_PROXIMITY);
				
				if (!view_as<bool>(trapInfo.flags & TRAP_IS_TEMPLATE))
				{
					if (view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED) 
						|| !view_as<bool>(trapInfo.flags & TRAP_IS_ACTIVATED) && IsEntitySolid(entity) && CanPlayersTouchEntity(entity, classType))
					{
						AddEntityInBreakables(entity, trapInfo, TRAP_IN_BREAKABLES_ON_KILL);
						
						if (g_Cvar_DebugModeEnable.BoolValue)
						{
							char entityName[256];
							GetEntPropString(entity, Prop_Data, "m_iName", entityName, sizeof(entityName));
							StringToLower(entityName);
							
							PrintToServer("Func_Brush | Func_Wall_Toggle :: %s :: Kill :: Add in breakables", entityName);
						}
					}
					
					ActivateTrapChildren(entity, trapInfo.activatorId, TRAP_CHILD_IN_BREAKABLES_ON_KILL);
				}
				
				g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
			}
			else if (inputType == InputType_Enable)
			{
				if (trapInfo.classType == ClassType_FuncWallToggle && !receivedToggleInput || isEntityEnabled)
				{
					if (g_Cvar_DebugModeEnable.BoolValue)
					{
						char entityName[256];
						GetEntPropString(entity, Prop_Data, "m_iName", entityName, sizeof(entityName));
						StringToLower(entityName);
						
						PrintToServer("Func_Brush | Func_Wall_Toggle :: %s :: Enable :: Already enabled", entityName);
					}
					
					return;
				}
				
				if (view_as<bool>(trapInfo.flags & TRAP_IS_ACTIVATED))
				{
					if (view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
					{
						trapInfo.flags &= ~TRAP_IS_ACTIVATED;						
						RemoveEntityFromBreakables(entity, trapInfo, TRAP_IN_BREAKABLES_ON_KILL);
						
						if (g_Cvar_DebugModeEnable.BoolValue)
						{
							char entityName[256];
							GetEntPropString(entity, Prop_Data, "m_iName", entityName, sizeof(entityName));
							StringToLower(entityName);
							
							PrintToServer("Func_Brush | Func_Wall_Toggle :: %s :: Enable :: Trap is activated :: Disable trap", entityName);
						}
						
						if (view_as<bool>(trapInfo.flags & TRAP_IS_CHILD))
						{
							AddEntityInProximity(reference, trapInfo, TRAP_CHILD_IN_PROXIMITY);
							
							if (g_Cvar_DebugModeEnable.BoolValue)
							{
								char entityName[256];
								GetEntPropString(entity, Prop_Data, "m_iName", entityName, sizeof(entityName));
								StringToLower(entityName);
								
								PrintToServer("Func_Brush | Func_Wall_Toggle :: %s :: Enable :: Trap is activated :: Add trap in proximity as child", entityName);
							}
						}
					}
				}
				else
				{
					if (!isTrap)
					{
						if (g_Cvar_DebugModeEnable.BoolValue)
						{
							char entityName[256];
							GetEntPropString(entity, Prop_Data, "m_iName", entityName, sizeof(entityName));
							StringToLower(entityName);
							
							PrintToServer("Func_Brush | Func_Wall_Toggle :: %s :: Enable :: Is not trap", entityName);
						}
						
						return;
					}
					
					if (view_as<bool>(trapInfo.flags & TRAP_HAS_SPAWN_DATA_SET))
					{
						if (view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
						{
							return;
						}
					}
					else
					{
						trapInfo.flags |= TRAP_HAS_SPAWN_DATA_SET;
					}
					
					if (!view_as<bool>(trapInfo.configFlags & TRAP_IGNORE_OUTPUTS))
					{
						trapInfo.flags |= TRAP_LISTEN_TO_OUTPUTS;
					}
					
					trapInfo.flags |= TRAP_IS_ACTIVATED;
					
					if (view_as<bool>(trapInfo.configFlags & TRAP_IS_REPLACING_OTHER_TRAPS))
					{
						RemoveReplacedEntitiesFromBreakables(entity);
						
						if (g_Cvar_DebugModeEnable.BoolValue)
						{
							char entityName[256];
							GetEntPropString(entity, Prop_Data, "m_iName", entityName, sizeof(entityName));
							StringToLower(entityName);
							
							PrintToServer("Func_Brush | Func_Wall_Toggle :: %s :: Enable :: Trap is not activated :: Remove replaced traps", entityName);
						}
					}
					else
					{
						if (trapInfo.classType == ClassType_FuncWallToggle)
						{
							AddEntityInProximity(reference, trapInfo, TRAP_IN_PROXIMITY);
							
							if (g_Cvar_DebugModeEnable.BoolValue)
							{
								char entityName[256];
								GetEntPropString(entity, Prop_Data, "m_iName", entityName, sizeof(entityName));
								StringToLower(entityName);
								
								PrintToServer("Func_Brush | Func_Wall_Toggle :: %s :: Enable :: Trap is not activated :: Add in proximity", entityName);
							}
						}
						else
						{
							int solidity = GetEntProp(entity, Prop_Data, "m_iSolidity");
							if (solidity == BRUSHSOLID_TOGGLE)
							{
								AddEntityInProximity(reference, trapInfo, TRAP_IN_PROXIMITY);
								
								if (g_Cvar_DebugModeEnable.BoolValue)
								{
									char entityName[256];
									GetEntPropString(entity, Prop_Data, "m_iName", entityName, sizeof(entityName));
									StringToLower(entityName);
									
									PrintToServer("Func_Brush | Func_Wall_Toggle :: %s :: Enable :: Trap is not activated :: Add in proximity", entityName);
								}
							}
						}
					}
				}
				
				g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
			}
			else if (inputType == InputType_Disable)
			{
				if (trapInfo.classType == ClassType_FuncWallToggle && !receivedToggleInput || !isEntityEnabled)
				{
					if (g_Cvar_DebugModeEnable.BoolValue)
					{
						char entityName[256];
						GetEntPropString(entity, Prop_Data, "m_iName", entityName, sizeof(entityName));
						StringToLower(entityName);
						
						PrintToServer("Func_Brush | Func_Wall_Toggle :: %s :: Enable :: Already disabled", entityName);
					}
					
					return;
				}
				
				if (view_as<bool>(trapInfo.flags & TRAP_IS_ACTIVATED))
				{
					if (!view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
					{
						trapInfo.flags &= ~TRAP_IS_ACTIVATED;
						trapInfo.flags &= ~TRAP_LISTEN_TO_OUTPUTS;
						
						RemoveEntityFromProximity(entity, trapInfo, TRAP_IN_PROXIMITY | TRAP_CHILD_IN_PROXIMITY);
						
						if (g_Cvar_DebugModeEnable.BoolValue)
						{
							char entityName[256];
							GetEntPropString(entity, Prop_Data, "m_iName", entityName, sizeof(entityName));
							StringToLower(entityName);
							
							PrintToServer("Func_Brush | Func_Wall_Toggle :: %s :: Disable :: Trap is activated :: Remove from proximity", entityName);
						}
					}
				}
				else
				{
					if (!isTrap)
					{
						if (g_Cvar_DebugModeEnable.BoolValue)
						{
							char entityName[256];
							GetEntPropString(entity, Prop_Data, "m_iName", entityName, sizeof(entityName));
							StringToLower(entityName);
							
							PrintToServer("Func_Brush | Func_Wall_Toggle :: %s :: Enable :: Is not trap", entityName);
						}
						
						return;
					}
					
					if (view_as<bool>(trapInfo.flags & TRAP_HAS_SPAWN_DATA_SET))
					{
						if (!view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
						{
							return;
						}
					}
					else
					{
						trapInfo.configFlags |= TRAP_SPAWN_ENABLED;
						trapInfo.flags |= TRAP_HAS_SPAWN_DATA_SET;
					}
					
					trapInfo.flags |= TRAP_IS_ACTIVATED;
					
					if (view_as<bool>(trapInfo.flags & TRAP_IS_CHILD))
					{
						RemoveEntityFromProximity(entity, trapInfo, TRAP_CHILD_IN_PROXIMITY);
					}
					
					if (trapInfo.classType == ClassType_FuncWallToggle)
					{
						AddEntityInBreakables(entity, trapInfo, TRAP_IN_BREAKABLES_ON_KILL);
						
						if (g_Cvar_DebugModeEnable.BoolValue)
						{
							char entityName[256];
							GetEntPropString(entity, Prop_Data, "m_iName", entityName, sizeof(entityName));
							StringToLower(entityName);
							
							PrintToServer("Func_Brush | Func_Wall_Toggle :: %s :: Disable :: Trap is activated :: Add in breakables", entityName);
						}
					}
					else
					{
						int solidity = GetEntProp(entity, Prop_Data, "m_iSolidity");
						if (solidity == BRUSHSOLID_TOGGLE)
						{
							AddEntityInBreakables(entity, trapInfo, TRAP_IN_BREAKABLES_ON_KILL);
							
							if (g_Cvar_DebugModeEnable.BoolValue)
							{
								char entityName[256];
								GetEntPropString(entity, Prop_Data, "m_iName", entityName, sizeof(entityName));
								StringToLower(entityName);
								
								PrintToServer("Func_Brush | Func_Wall_Toggle :: %s :: Disable :: Trap is activated :: Add in breakables", entityName);
							}
						}
					}
				}
				
				g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
			}
		}
		
		case ClassType_FuncButton:
		{
			if (inputType == InputType_Kill)
			{
				if (!isTrap)
				{
					return;
				}
				
				DeactivateTrapChildren(entity, TRAP_CHILD_IN_PROXIMITY);
				ActivateTrapChildren(entity, trapInfo.activatorId, TRAP_CHILD_IN_BREAKABLES_ON_KILL);
				
				g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
			}
			else if (inputType == InputType_Press || inputType == InputType_PressIn || inputType == InputType_PressOut)
			{
				if (view_as<bool>(trapInfo.flags & TRAP_IS_ACTIVATED))
				{
					if (!isTrap)
					{
						trapInfo.flags &= ~TRAP_IS_ACTIVATED;
						trapInfo.flags &= ~TRAP_LISTEN_TO_OUTPUTS;
					}
				}
				else
				{
					if (!isTrap)
					{
						return;
					}
					
					if (!view_as<bool>(trapInfo.flags & TRAP_HAS_SPAWN_DATA_SET))
					{
						trapInfo.flags |= TRAP_HAS_SPAWN_DATA_SET;
					}
					
					if (!view_as<bool>(trapInfo.configFlags & TRAP_IGNORE_OUTPUTS))
					{
						trapInfo.flags |= TRAP_LISTEN_TO_OUTPUTS;
					}
					
					trapInfo.flags |= TRAP_IS_ACTIVATED;
				}
				
				g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
			}
			else if (inputType == InputType_Lock)
			{
				SetEntPropFloat(entity, Prop_Data, "m_flUseLookAtAngle", 1.0);
			}
			else if (inputType == InputType_Unlock)
			{
				if (GetEntProp(entity, Prop_Data, "m_toggle_state") == TS_AT_BOTTOM)
				{
					SetEntPropFloat(entity, Prop_Data, "m_flUseLookAtAngle", -1.0);
				}
			}
		}
		
		// To do: activatorId
		case ClassType_FuncDoor, ClassType_FuncDoorRotating, ClassType_FuncMoveLinear, ClassType_FuncWaterAnalog:
		{
			if (!isTrap)
			{
				return;
			}
			
			if (inputType == InputType_Kill)
			{
				RemoveEntityFromProximity(entity, trapInfo, TRAP_IN_PROXIMITY | TRAP_CHILD_IN_PROXIMITY);
				DeactivateTrapChildren(entity, TRAP_CHILD_IN_PROXIMITY); 
				
				if (!view_as<bool>(trapInfo.flags & TRAP_IS_TEMPLATE))
				{
					if (IsEntitySolid(entity) && CanPlayersTouchEntity(entity, classType))
					{
						AddEntityInBreakables(entity, trapInfo, TRAP_IN_BREAKABLES_ON_KILL);
					}
					
					ActivateTrapChildren(entity, trapInfo.activatorId, TRAP_CHILD_IN_BREAKABLES_ON_KILL);
				}
				
				g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
			}
			else if (inputType == InputType_SetSpeed)
			{
				if (!view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
				{
					return;
				}
				
				float newSpeed;
				if (variantInfo.variantType == EntityIO_VariantType_Float)
				{
					newSpeed = variantInfo.flValue;
				}
				else if (variantInfo.variantType == EntityIO_VariantType_String)
				{
					if (!StringToFloatEx(variantInfo.sValue, newSpeed))
					{
						LogError("(Func_Door::InputType_SetSpeed) Cannot convert string to float (%s)", variantInfo.sValue);					
					}
				}
				else
				{
					LogError("(Func_Door::InputType_SetSpeed) Param type is not float (%d)", variantInfo.variantType);					
					return;
				}
				
				float currentSpeed = GetEntitySpeed(entity);
				if (newSpeed == currentSpeed)
				{
					return;
				}
				
				if (view_as<bool>(trapInfo.flags & TRAP_IS_ACTIVATED))
				{
					if (view_as<bool>(trapInfo.flags & TRAP_RECEIVED_SPEED_INPUT)
						&& newSpeed == trapInfo.spawnSpeed)
					{
						trapInfo.flags &= ~TRAP_IS_ACTIVATED;
						trapInfo.flags &= ~TRAP_LISTEN_TO_OUTPUTS;
						trapInfo.flags &= ~TRAP_RECEIVED_SPEED_INPUT;
						
						RemoveEntityFromProximity(entity, trapInfo, TRAP_IN_PROXIMITY);
						DeactivateTrapChildren(entity, TRAP_CHILD_IN_PROXIMITY);
					}
					else
					{
						if (!view_as<bool>(trapInfo.configFlags & TRAP_IGNORE_SPEED))
						{
							trapInfo.flags |= TRAP_RECEIVED_SPEED_INPUT;
						}
					}
					
					if (view_as<bool>(trapInfo.configFlags & TRAP_ADD_IN_BREAKABLES_ON_SPEED))
					{
						if (IsEntitySolid(entity) && CanPlayersTouchEntity(entity, classType))
						{
							AddEntityInBreakables(entity, trapInfo, TRAP_IN_BREAKABLES_ON_SPEED);
						}
						
						ActivateTrapChildren(entity, trapInfo.activatorId, TRAP_IN_BREAKABLES_ON_SPEED);
					}
				}
				else
				{
					if ((trapInfo.classType == ClassType_FuncDoor || trapInfo.classType == ClassType_FuncDoorRotating) 
						&& view_as<bool>(GetEntProp(entity, Prop_Data, "m_bLocked")))
					{
						return;
					}
					
					if (!view_as<bool>(trapInfo.flags & TRAP_HAS_SPAWN_DATA_SET))
					{
						trapInfo.flags |= TRAP_HAS_SPAWN_DATA_SET;
						trapInfo.spawnSpeed = currentSpeed;
					}
					
					if (!view_as<bool>(trapInfo.configFlags & TRAP_IGNORE_SPEED))
					{
						trapInfo.flags |= TRAP_RECEIVED_SPEED_INPUT;
					}
					
					if (!view_as<bool>(trapInfo.configFlags & TRAP_IGNORE_OUTPUTS))
					{
						trapInfo.flags |= TRAP_LISTEN_TO_OUTPUTS;
					}
					
					trapInfo.flags |= TRAP_IS_ACTIVATED;
					
					if (IsEntitySolid(entity) && CanPlayersTouchEntity(entity, classType))
					{
						AddEntityInProximity(reference, trapInfo, TRAP_IN_PROXIMITY);
						if (view_as<bool>(trapInfo.configFlags & TRAP_ADD_IN_BREAKABLES_ON_SPEED))
						{
							AddEntityInBreakables(entity, trapInfo, TRAP_IN_BREAKABLES_ON_SPEED);
						}
					}
					
					int flags = TRAP_CHILD_IN_PROXIMITY;
					if (view_as<bool>(trapInfo.configFlags & TRAP_ADD_IN_BREAKABLES_ON_SPEED))
					{
						flags |= TRAP_CHILD_IN_BREAKABLES_ON_SPEED;
					}
					
					ActivateTrapChildren(entity, trapInfo.activatorId, flags);
				}
				
				g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
			}
			else if (inputType == InputType_SetPosition)
			{
				if (view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED) 
					|| trapInfo.classType != ClassType_FuncMoveLinear && trapInfo.classType != ClassType_FuncWaterAnalog)
				{
					return;
				}
				
				float moveDistance;
				if (variantInfo.variantType == EntityIO_VariantType_Float)
				{
					moveDistance = variantInfo.flValue;
				}
				else if (variantInfo.variantType == EntityIO_VariantType_String)
				{
					if (!StringToFloatEx(variantInfo.sValue, moveDistance))
					{
						LogError("(Func_Movelinear::InputType_SetPosition) Cannot convert string to float (%s)", variantInfo.sValue);					
					}
				}
				else
				{
					LogError("(Func_Movelinear::InputType_SetPosition) Param type is not float (%d)", variantInfo.variantType);					
					return;
				}
				
				float vecOrigin[3];
				float vecPosition1[3];
				float vecPosition2[3];
				
				GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vecOrigin);
				GetEntPropVector(entity, Prop_Data, "m_vecPosition1", vecPosition1);
				GetEntPropVector(entity, Prop_Data, "m_vecPosition2", vecPosition2);
				
				float vecTarget[3];
				for (int i = 0; i < 3; i++)
				{
					vecTarget[i] = vecPosition1[i] + moveDistance * (vecPosition2[i] - vecPosition1[i]);
				}
				
				if (!RoundToZero(GetVectorDistance(vecOrigin, vecTarget)))
				{
					return;
				}
				
				if (view_as<bool>(trapInfo.flags & TRAP_IS_ACTIVATED))
				{
					if (view_as<bool>(trapInfo.configFlags & TRAP_REMOVE_FROM_PROXIMITY_ON_STOP) 
						|| view_as<bool>(trapInfo.configFlags & TRAP_ADD_IN_BREAKABLES_ON_MOVE))
					{
						if (IsEntitySolid(entity) && CanPlayersTouchEntity(entity, classType))
						{
							if (view_as<bool>(trapInfo.configFlags & TRAP_REMOVE_FROM_PROXIMITY_ON_STOP))
							{
								AddEntityInProximity(reference, trapInfo, TRAP_IN_PROXIMITY);
							}
							
							if (view_as<bool>(trapInfo.configFlags & TRAP_ADD_IN_BREAKABLES_ON_MOVE))
							{
								int flags = TRAP_IN_BREAKABLES_ON_MOVE;
								if (view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
								{
									flags |= TRAP_SPAWN_ENABLED;
								}
								
								AddEntityInBreakables(entity, trapInfo, flags);
							}
						}
						
						int flags;
						if (view_as<bool>(trapInfo.configFlags & TRAP_REMOVE_FROM_PROXIMITY_ON_STOP))
						{
							flags |= TRAP_CHILD_IN_PROXIMITY;
						}
						
						if (view_as<bool>(trapInfo.configFlags & TRAP_ADD_IN_BREAKABLES_ON_MOVE))
						{
							flags |= TRAP_CHILD_IN_BREAKABLES_ON_MOVE;
						}
						
						if (view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
						{
							flags |= TRAP_SPAWN_ENABLED;
						}
						
						ActivateTrapChildren(entity, trapInfo.activatorId, flags);
					}
				}
				else
				{
					if (!view_as<bool>(trapInfo.flags & TRAP_HAS_SPAWN_DATA_SET))
					{
						trapInfo.flags |= TRAP_HAS_SPAWN_DATA_SET;
						trapInfo.spawnSpeed = GetEntitySpeed(entity);
						
						if (view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_OPEN) 
							|| !RoundToZero(GetVectorDistance(vecOrigin, vecPosition2)))
						{
							trapInfo.spawnState = StateType_Open;
						}
						else if (view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_CLOSED) 
							|| !RoundToZero(GetVectorDistance(vecOrigin, vecPosition1)))
						{
							trapInfo.spawnState = StateType_Closed;
						}
						else
						{
							trapInfo.spawnState = StateType_SetPosition;
							trapInfo.spawnOrigin = vecOrigin;
						}
					}
					
					if (!view_as<bool>(trapInfo.configFlags & TRAP_IGNORE_OUTPUTS))
					{
						trapInfo.flags |= TRAP_LISTEN_TO_OUTPUTS;
					}
					
					trapInfo.flags |= TRAP_IS_ACTIVATED;
					
					if (IsEntitySolid(entity) && CanPlayersTouchEntity(entity, classType))
					{
						AddEntityInProximity(reference, trapInfo, TRAP_IN_PROXIMITY);
						
						if (view_as<bool>(trapInfo.configFlags & TRAP_ADD_IN_BREAKABLES_ON_FIRST_MOVE))
						{
							int flags = TRAP_IN_BREAKABLES_ON_FIRST_MOVE;
							if (view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
							{
								flags |= TRAP_SPAWN_ENABLED;
							}
							
							AddEntityInBreakables(entity, trapInfo, flags);
						}
						else if (view_as<bool>(trapInfo.configFlags & TRAP_ADD_IN_BREAKABLES_ON_MOVE))
						{
							int flags = TRAP_IN_BREAKABLES_ON_MOVE;
							if (view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
							{
								flags |= TRAP_SPAWN_ENABLED;
							}
							
							AddEntityInBreakables(entity, trapInfo, flags);
						}
					}
					
					int flags = TRAP_CHILD_IN_PROXIMITY;
					if (view_as<bool>(trapInfo.configFlags & TRAP_ADD_IN_BREAKABLES_ON_FIRST_MOVE))
					{
						flags |= TRAP_CHILD_IN_BREAKABLES_ON_FIRST_MOVE;
					}
					else if (view_as<bool>(trapInfo.configFlags & TRAP_ADD_IN_BREAKABLES_ON_MOVE))
					{
						flags |= TRAP_CHILD_IN_BREAKABLES_ON_MOVE;
					}
					
					if (view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
					{
						flags |= TRAP_SPAWN_ENABLED;
					}
					
					ActivateTrapChildren(entity, trapInfo.activatorId, flags);
				}
				
				if (moveDistance != 0.0 && moveDistance != 1.0)
				{
					AddEntityInThinkTraps(reference, trapInfo);
				}
				else
				{
					RemoveEntityFromThinkTraps(reference, trapInfo);
				}
				
				g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
			}
			else if (inputType == InputType_Open || inputType == InputType_Close || inputType == InputType_Toggle)
			{
				if (view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED) 
					|| inputType == InputType_Toggle && trapInfo.classType != ClassType_FuncDoor && trapInfo.classType != ClassType_FuncDoorRotating)
				{
					return;
				}
				
				StateType stateType;
				if (trapInfo.classType == ClassType_FuncDoor || trapInfo.classType == ClassType_FuncDoorRotating)
				{
					if (view_as<bool>(GetEntProp(entity, Prop_Data, "m_bLocked")))
					{
						return;
					}
					
					int toggleState = GetEntProp(entity, Prop_Data, "m_toggle_state");
					if (inputType == InputType_Close)
					{
						if (toggleState == TS_AT_BOTTOM || toggleState == TS_GOING_DOWN)
						{
							return;
						}
						
						stateType = StateType_Open;
						trapInfo.nextState = StateType_Closed;
					}
					else if (inputType == InputType_Open)
					{
						if (toggleState == TS_AT_TOP || toggleState == TS_GOING_UP)
						{
							return;
						}
						
						stateType = StateType_Closed;
						trapInfo.nextState = StateType_Open;
					}
					else
					{
						if (toggleState == TS_AT_TOP || toggleState == TS_GOING_DOWN)
						{
							stateType = StateType_Open;
							trapInfo.nextState = StateType_Closed;
						}
						else if (toggleState == TS_AT_BOTTOM || toggleState == TS_GOING_UP)
						{
							stateType = StateType_Closed;
							trapInfo.nextState = StateType_Open;
						}
					}
				}
				else
				{
					float origin[3];
					float position1[3];
					float position2[3];
					
					GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", origin);
					GetEntPropVector(entity, Prop_Data, "m_vecPosition1", position1);
					GetEntPropVector(entity, Prop_Data, "m_vecPosition2", position2);
					
					if (inputType == InputType_Close)
					{
						if (!RoundToZero(GetVectorDistance(origin, position1)))
						{
							return;
						}
						
						if (view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_OPEN))
						{
							trapInfo.spawnState = StateType_Open;
							trapInfo.nextState = StateType_Closed;
						}
						else if (!RoundToZero(GetVectorDistance(origin, position2)))
						{
							stateType = StateType_Open;
							trapInfo.nextState = StateType_Closed;
						}
						else
						{
							stateType = StateType_SetPosition;
							trapInfo.nextState = StateType_Closed;
						}
					}
					else if (inputType == InputType_Open)
					{
						if (!RoundToZero(GetVectorDistance(origin, position2)))
						{
							return;
						}
						
						if (view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_CLOSED))
						{
							trapInfo.spawnState = StateType_Closed;
							trapInfo.nextState = StateType_Open;
						}
						else if (!RoundToZero(GetVectorDistance(origin, position1)))
						{
							stateType = StateType_Closed;
							trapInfo.nextState = StateType_Open;
						}
						else
						{
							stateType = StateType_SetPosition;
							trapInfo.nextState = StateType_Open;
						}
					}
				}
				
				trapInfo.flags &= ~TRAP_WAIT_TO_REACTIVATE;
				
				if (view_as<bool>(trapInfo.flags & TRAP_IS_ACTIVATED))
				{
					if (view_as<bool>(trapInfo.configFlags & TRAP_REMOVE_FROM_PROXIMITY_ON_STOP) 
						|| view_as<bool>(trapInfo.configFlags & TRAP_ADD_IN_BREAKABLES_ON_MOVE))
					{
						if (IsEntitySolid(entity) && CanPlayersTouchEntity(entity, classType))
						{
							if (view_as<bool>(trapInfo.configFlags & TRAP_REMOVE_FROM_PROXIMITY_ON_STOP))
							{
								AddEntityInProximity(reference, trapInfo, TRAP_IN_PROXIMITY);
							}
							
							if (view_as<bool>(trapInfo.configFlags & TRAP_ADD_IN_BREAKABLES_ON_MOVE))
							{
								int flags = TRAP_IN_BREAKABLES_ON_MOVE;
								if (view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
								{
									flags |= TRAP_SPAWN_ENABLED;
								}
								
								AddEntityInBreakables(entity, trapInfo, flags);
							}
						}
						
						int flags;
						if (view_as<bool>(trapInfo.configFlags & TRAP_REMOVE_FROM_PROXIMITY_ON_STOP))
						{
							flags |= TRAP_CHILD_IN_PROXIMITY;
						}
						
						if (view_as<bool>(trapInfo.configFlags & TRAP_ADD_IN_BREAKABLES_ON_MOVE))
						{
							flags |= TRAP_CHILD_IN_BREAKABLES_ON_MOVE;
						}
						
						if (view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
						{
							flags |= TRAP_SPAWN_ENABLED;
						}
						
						ActivateTrapChildren(entity, trapInfo.activatorId, flags);
					}
				}
				else
				{
					if (!view_as<bool>(trapInfo.flags & TRAP_HAS_SPAWN_DATA_SET))
					{
						trapInfo.flags |= TRAP_HAS_SPAWN_DATA_SET;
						
						trapInfo.spawnState = stateType;
						trapInfo.spawnSpeed = GetEntitySpeed(entity);
					}
					
					if (!view_as<bool>(trapInfo.configFlags & TRAP_IGNORE_OUTPUTS))
					{
						trapInfo.flags |= TRAP_LISTEN_TO_OUTPUTS;
					}
					
					trapInfo.flags |= TRAP_IS_ACTIVATED;
					
					if (IsEntitySolid(entity) && CanPlayersTouchEntity(entity, classType))
					{
						AddEntityInProximity(reference, trapInfo, TRAP_IN_PROXIMITY);
						
						if (view_as<bool>(trapInfo.configFlags & TRAP_ADD_IN_BREAKABLES_ON_FIRST_MOVE))
						{
							int flags = TRAP_IN_BREAKABLES_ON_FIRST_MOVE;
							if (view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
							{
								flags |= TRAP_SPAWN_ENABLED;
							}
							
							AddEntityInBreakables(entity, trapInfo, flags);
						}
						else if (view_as<bool>(trapInfo.configFlags & TRAP_ADD_IN_BREAKABLES_ON_MOVE))
						{
							int flags = TRAP_IN_BREAKABLES_ON_MOVE;
							if (view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
							{
								flags |= TRAP_SPAWN_ENABLED;
							}
							
							AddEntityInBreakables(entity, trapInfo, flags);
						}
					}
					
					int flags = TRAP_CHILD_IN_PROXIMITY;
					if (view_as<bool>(trapInfo.configFlags & TRAP_ADD_IN_BREAKABLES_ON_FIRST_MOVE))
					{
						flags |= TRAP_CHILD_IN_BREAKABLES_ON_FIRST_MOVE;
					}
					else if (view_as<bool>(trapInfo.configFlags & TRAP_ADD_IN_BREAKABLES_ON_MOVE))
					{
						flags |= TRAP_CHILD_IN_BREAKABLES_ON_MOVE;
					}
					
					if (view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
					{
						flags |= TRAP_SPAWN_ENABLED;
					}
					
					ActivateTrapChildren(entity, trapInfo.activatorId, flags);
				}
				
				RemoveEntityFromThinkTraps(reference, trapInfo);
				g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
			}
		}
		
		// To do: activatorId
		case ClassType_FuncRotating:
		{
			if (!isTrap)
			{
				return;
			}
			
			bool isReversing;
			bool isReversed = !IsDirForward(entity, trapInfo.classType);
			float currentSpeed = FloatAbs(GetEntitySpeed(entity));
			float maxSpeed = GetEntPropFloat(entity, Prop_Data, "m_flMaxSpeed");
			
			bool isEntityMoving = view_as<bool>(currentSpeed != 0.0);
			float newSpeed = currentSpeed;
			
			if (inputType == InputType_Toggle)
			{
				inputType = isEntityMoving ? InputType_Stop : InputType_Start;
			}
			else if (inputType == InputType_StartForward)
			{
				if (currentSpeed && isReversed)
				{
					inputType = InputType_Reverse;
				}
			}
			else if (inputType == InputType_StartBackward)
			{
				if (currentSpeed && !isReversed)
				{
					inputType = InputType_Reverse;
				}
			}
			else if (inputType == InputType_SetSpeed)
			{
				if (variantInfo.variantType == EntityIO_VariantType_Float)
				{
					newSpeed = variantInfo.flValue;
				}
				else if (variantInfo.variantType == EntityIO_VariantType_String)
				{
					if (!StringToFloatEx(variantInfo.sValue, newSpeed))
					{
						LogError("(Func_Rotating::InputType_SetSpeed) Cannot convert string to float (%s)", variantInfo.sValue);					
					}
				}
				else
				{
					LogError("(Func_Movelinear::InputType_SetPosition) Param type is not float (%d)", variantInfo.variantType);
					return;
				}
				
				if (newSpeed < 0.0)
				{
					isReversing = true;
					newSpeed = FloatAbs(newSpeed);
				}
				
				SetUpperBound(newSpeed, 1.0);
				newSpeed *= maxSpeed;
				
				if (newSpeed && !currentSpeed)
				{
					inputType = isReversing ? InputType_StartBackward : InputType_StartForward;
				}
				else if (currentSpeed && !newSpeed)
				{
					inputType = InputType_Stop;
				}
			}
			
			if (inputType == InputType_Kill)
			{
				RemoveEntityFromProximity(entity, trapInfo, TRAP_IN_PROXIMITY | TRAP_CHILD_IN_PROXIMITY);
				DeactivateTrapChildren(entity, TRAP_CHILD_IN_PROXIMITY); 
				
				if (!view_as<bool>(trapInfo.flags & TRAP_IS_TEMPLATE))
				{
					if (IsEntitySolid(entity) && CanPlayersTouchEntity(entity, classType))
					{
						AddEntityInBreakables(entity, trapInfo, TRAP_IN_BREAKABLES_ON_KILL);
					}
					
					ActivateTrapChildren(entity, trapInfo.activatorId, TRAP_CHILD_IN_BREAKABLES_ON_KILL);
				}
				
				RemoveEntityFromThinkTraps(reference, trapInfo);
				g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
			}
			else if (inputType == InputType_Start || inputType == InputType_StartBackward || inputType == InputType_StartForward)
			{
				if (inputType == InputType_Start)
				{
					isReversing = isReversed;
				}
				else if (inputType == InputType_StartBackward)
				{
					isReversing = true;
				}
				
				if (currentSpeed == maxSpeed && isReversing == isReversed)
				{
					return;
				}
				
				if (view_as<bool>(trapInfo.flags & TRAP_IS_ACTIVATED))
				{
					if (view_as<bool>(trapInfo.flags & TRAP_RECEIVED_REVERSE_INPUT) 
						&& isReversing == view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_REVERSED))
					{
						trapInfo.flags &= ~TRAP_RECEIVED_REVERSE_INPUT;
					}
					
					if (view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED) 
						&& !view_as<bool>(trapInfo.flags & TRAP_IS_TEMPLATE) 
						&& !view_as<bool>(trapInfo.flags & TRAP_RECEIVED_REVERSE_INPUT) 
						&& maxSpeed == trapInfo.spawnSpeed)
					{
						trapInfo.flags &= ~TRAP_IS_ACTIVATED;
						trapInfo.flags &= ~TRAP_LISTEN_TO_OUTPUTS;
						
						RemoveEntityFromProximity(entity, trapInfo, TRAP_IN_PROXIMITY);
						RemoveEntityFromBreakables(entity, trapInfo, TRAP_IN_BREAKABLES_ON_MOVE | TRAP_IN_BREAKABLES_ON_FIRST_MOVE);
						
						DeactivateTrapChildren(entity, TRAP_CHILD_IN_PROXIMITY | TRAP_CHILD_IN_BREAKABLES_ON_MOVE | TRAP_CHILD_IN_BREAKABLES_ON_FIRST_MOVE);
						
						if (view_as<bool>(trapInfo.configFlags & TRAP_ADD_IN_BREAKABLES_ON_MOVE))
						{
							if (IsEntitySolid(entity) && CanPlayersTouchEntity(entity, classType))
							{
								AddEntityInBreakables(entity, trapInfo, TRAP_IN_BREAKABLES_ON_MOVE | TRAP_SPAWN_ENABLED);
							}
							
							ActivateTrapChildren(entity, trapInfo.activatorId, TRAP_CHILD_IN_BREAKABLES_ON_MOVE | TRAP_SPAWN_ENABLED);
						}
					}
					else
					{
						if (!view_as<bool>(trapInfo.configFlags & TRAP_IGNORE_REVERSE))
						{
							trapInfo.flags |= (isReversing != isReversed) ? TRAP_RECEIVED_REVERSE_INPUT : 0;
						}
						
						if (view_as<bool>(trapInfo.configFlags & TRAP_REMOVE_FROM_PROXIMITY_ON_STOP) 
							|| view_as<bool>(trapInfo.configFlags & TRAP_ADD_IN_BREAKABLES_ON_MOVE))
						{
							if (IsEntitySolid(entity) && CanPlayersTouchEntity(entity, classType))
							{
								if (view_as<bool>(trapInfo.configFlags & TRAP_REMOVE_FROM_PROXIMITY_ON_STOP))
								{
									AddEntityInProximity(reference, trapInfo, TRAP_IN_PROXIMITY);
								}
								
								if (view_as<bool>(trapInfo.configFlags & TRAP_ADD_IN_BREAKABLES_ON_MOVE))
								{
									int flags = TRAP_IN_BREAKABLES_ON_MOVE;
									if (view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
									{
										flags |= TRAP_SPAWN_ENABLED;
									}
									
									AddEntityInBreakables(entity, trapInfo, flags);
								}
							}
							
							int flags;
							if (view_as<bool>(trapInfo.configFlags & TRAP_REMOVE_FROM_PROXIMITY_ON_STOP))
							{
								flags |= TRAP_CHILD_IN_PROXIMITY;
							}
							
							if (view_as<bool>(trapInfo.configFlags & TRAP_ADD_IN_BREAKABLES_ON_MOVE))
							{
								flags |= TRAP_CHILD_IN_BREAKABLES_ON_MOVE;
							}
							
							if (view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
							{
								flags |= TRAP_SPAWN_ENABLED;
							}
							
							ActivateTrapChildren(entity, trapInfo.activatorId, flags);
						}
					}
					
					RemoveEntityFromThinkTraps(reference, trapInfo);
				}
				else
				{
					if (!view_as<bool>(trapInfo.flags & TRAP_HAS_SPAWN_DATA_SET))
					{
						trapInfo.flags |= TRAP_HAS_SPAWN_DATA_SET;
						
						trapInfo.configFlags |= isReversed ? TRAP_SPAWN_REVERSED : 0;
						trapInfo.configFlags |= isEntityMoving ? TRAP_SPAWN_ENABLED : 0;
						
						trapInfo.spawnSpeed = currentSpeed;
					}
					
					if (!view_as<bool>(trapInfo.configFlags & TRAP_IGNORE_REVERSE))
					{
						trapInfo.flags |= (isReversing != isReversed) ? TRAP_RECEIVED_REVERSE_INPUT : 0;
					}
					
					if (!view_as<bool>(trapInfo.configFlags & TRAP_IGNORE_OUTPUTS))
					{
						trapInfo.flags |= TRAP_LISTEN_TO_OUTPUTS;
					}
					
					trapInfo.flags |= TRAP_IS_ACTIVATED;
					
					if (IsEntitySolid(entity) && CanPlayersTouchEntity(entity, classType))
					{
						AddEntityInProximity(reference, trapInfo, TRAP_IN_PROXIMITY);
						
						if (view_as<bool>(trapInfo.configFlags & TRAP_ADD_IN_BREAKABLES_ON_FIRST_MOVE))
						{
							int flags = TRAP_IN_BREAKABLES_ON_FIRST_MOVE;
							if (view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
							{
								flags |= TRAP_SPAWN_ENABLED;
							}
							
							AddEntityInBreakables(entity, trapInfo, flags);
						}
						else if (view_as<bool>(trapInfo.configFlags & TRAP_ADD_IN_BREAKABLES_ON_MOVE))
						{
							int flags = TRAP_IN_BREAKABLES_ON_MOVE;
							if (view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
							{
								flags |= TRAP_SPAWN_ENABLED;
							}
							
							AddEntityInBreakables(entity, trapInfo, flags);
						}
					}
					
					int flags = TRAP_CHILD_IN_PROXIMITY;
					if (view_as<bool>(trapInfo.configFlags & TRAP_ADD_IN_BREAKABLES_ON_FIRST_MOVE))
					{
						flags |= TRAP_CHILD_IN_BREAKABLES_ON_FIRST_MOVE;
					}
					else if (view_as<bool>(trapInfo.configFlags & TRAP_ADD_IN_BREAKABLES_ON_MOVE))
					{
						flags |= TRAP_CHILD_IN_BREAKABLES_ON_MOVE;
					}
					
					if (view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
					{
						flags |= TRAP_SPAWN_ENABLED;
					}
					
					ActivateTrapChildren(entity, trapInfo.activatorId, flags);
				}
				
				g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
			}
			else if (inputType == InputType_Stop || inputType == InputType_StopAtStartPos)
			{
				if (!isEntityMoving || inputType == InputType_StopAtStartPos && view_as<bool>(GetEntProp(entity, Prop_Data, "m_bStopAtStartPos")))
				{
					return;
				}
				
				if (view_as<bool>(trapInfo.flags & TRAP_IS_ACTIVATED))
				{
					if (inputType == InputType_Stop)
					{
						if (view_as<bool>(trapInfo.configFlags & TRAP_IS_REPLACING_OTHER_TRAPS) 
							|| view_as<bool>(trapInfo.configFlags & TRAP_DISABLE_ON_STOP)
							|| !view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED) 
								&& !view_as<bool>(trapInfo.flags & TRAP_IS_TEMPLATE) 
								&& HasEntitySpawnAngles(entity, trapInfo.classType))
						{
							trapInfo.flags &= ~TRAP_IS_ACTIVATED;
							trapInfo.flags &= ~TRAP_LISTEN_TO_OUTPUTS;
							
							RemoveEntityFromProximity(entity, trapInfo, TRAP_IN_PROXIMITY);
							RemoveEntityFromBreakables(entity, trapInfo, TRAP_IN_BREAKABLES_ON_MOVE | TRAP_IN_BREAKABLES_ON_FIRST_MOVE);
							
							DeactivateTrapChildren(entity, TRAP_CHILD_IN_PROXIMITY | TRAP_CHILD_IN_BREAKABLES_ON_MOVE | TRAP_CHILD_IN_BREAKABLES_ON_FIRST_MOVE);
							
							if (view_as<bool>(trapInfo.configFlags & TRAP_IS_REPLACING_OTHER_TRAPS))
							{
								RemoveReplacedEntitiesFromBreakables(entity);
							}
						}
						else if (view_as<bool>(trapInfo.configFlags & TRAP_REMOVE_FROM_PROXIMITY_ON_STOP))
						{
							RemoveEntityFromProximity(entity, trapInfo, TRAP_IN_PROXIMITY);
							DeactivateTrapChildren(entity, TRAP_CHILD_IN_PROXIMITY);
						}
						
						RemoveEntityFromThinkTraps(reference, trapInfo);
					}
					else if (!view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
					{
						AddEntityInThinkTraps(reference, trapInfo);
					}
				}
				else
				{
					if (!view_as<bool>(trapInfo.flags & TRAP_HAS_SPAWN_DATA_SET))
					{
						trapInfo.flags |= TRAP_HAS_SPAWN_DATA_SET;
						
						trapInfo.configFlags |= TRAP_SPAWN_ENABLED;
						trapInfo.configFlags |= isReversed ? TRAP_SPAWN_REVERSED : 0;
						
						trapInfo.spawnSpeed = currentSpeed;
					}
					
					if (!view_as<bool>(trapInfo.configFlags & TRAP_IGNORE_OUTPUTS))
					{
						trapInfo.flags |= TRAP_LISTEN_TO_OUTPUTS;
					}
					
					trapInfo.flags |= TRAP_IS_ACTIVATED;
					
					if (IsEntitySolid(entity) && CanPlayersTouchEntity(entity, classType))
					{
						AddEntityInProximity(reference, trapInfo, TRAP_IN_PROXIMITY);
					}
					
					ActivateTrapChildren(entity, trapInfo.activatorId, TRAP_CHILD_IN_PROXIMITY);
					
					if (inputType == InputType_StopAtStartPos && view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
					{
						AddEntityInThinkTraps(reference, trapInfo);
					}
				}
				
				g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
			}
			else if (inputType == InputType_Reverse)
			{
				if (view_as<bool>(trapInfo.flags & TRAP_IS_ACTIVATED))
				{
					if (view_as<bool>(trapInfo.flags & TRAP_RECEIVED_REVERSE_INPUT))
					{
						if (isReversed != view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_REVERSED))
						{
							trapInfo.flags &= ~TRAP_RECEIVED_REVERSE_INPUT;
						}
					}
					else if (!view_as<bool>(trapInfo.configFlags & TRAP_IGNORE_REVERSE))
					{
						if (isReversed == view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_REVERSED))
						{
							trapInfo.flags |= TRAP_RECEIVED_REVERSE_INPUT;
						}
					}
					
					if (isEntityMoving)
					{
						if (view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED) 
							&& !view_as<bool>(trapInfo.flags & TRAP_IS_TEMPLATE) 
							&& !view_as<bool>(trapInfo.flags & TRAP_RECEIVED_SPEED_INPUT)
							&& !view_as<bool>(trapInfo.flags & TRAP_RECEIVED_REVERSE_INPUT))
						{
							trapInfo.flags &= ~TRAP_IS_ACTIVATED;
							trapInfo.flags &= ~TRAP_LISTEN_TO_OUTPUTS;
							
							RemoveEntityFromProximity(entity, trapInfo, TRAP_IN_PROXIMITY);
							RemoveEntityFromBreakables(entity, trapInfo, TRAP_IN_BREAKABLES_ON_MOVE | TRAP_IN_BREAKABLES_ON_FIRST_MOVE);
							
							DeactivateTrapChildren(entity, TRAP_CHILD_IN_PROXIMITY | TRAP_CHILD_IN_BREAKABLES_ON_MOVE | TRAP_CHILD_IN_BREAKABLES_ON_FIRST_MOVE);
						}
						
						if (view_as<bool>(trapInfo.configFlags & TRAP_ADD_IN_BREAKABLES_ON_REVERSE))
						{
							if (IsEntitySolid(entity) && CanPlayersTouchEntity(entity, classType))
							{
								AddEntityInBreakables(entity, trapInfo, TRAP_IN_BREAKABLES_ON_REVERSE);
							}
							
							ActivateTrapChildren(entity, trapInfo.activatorId, TRAP_CHILD_IN_BREAKABLES_ON_REVERSE);
						}
					}
					
					RemoveEntityFromThinkTraps(reference, trapInfo);
				}
				else
				{
					if (!isEntityMoving)
					{
						return;
					}
					
					if (!view_as<bool>(trapInfo.flags & TRAP_HAS_SPAWN_DATA_SET))
					{
						trapInfo.flags |= TRAP_HAS_SPAWN_DATA_SET;
						
						trapInfo.configFlags |= TRAP_SPAWN_ENABLED;
						trapInfo.configFlags |= isReversed ? TRAP_SPAWN_REVERSED : 0;
						
						trapInfo.spawnSpeed = currentSpeed;
					}
					
					if (!view_as<bool>(trapInfo.configFlags & TRAP_IGNORE_REVERSE))
					{
						trapInfo.flags |= TRAP_RECEIVED_REVERSE_INPUT;
					}
					
					if (!view_as<bool>(trapInfo.configFlags & TRAP_IGNORE_OUTPUTS))
					{
						trapInfo.flags |= TRAP_LISTEN_TO_OUTPUTS;
					}
					
					trapInfo.flags |= TRAP_IS_ACTIVATED;
					
					if (IsEntitySolid(entity) && CanPlayersTouchEntity(entity, classType))
					{
						AddEntityInProximity(reference, trapInfo, TRAP_IN_PROXIMITY);
						if (view_as<bool>(trapInfo.configFlags & TRAP_ADD_IN_BREAKABLES_ON_REVERSE))
						{
							AddEntityInBreakables(entity, trapInfo, TRAP_IN_BREAKABLES_ON_REVERSE);
						}
						
					}
					
					int flags = TRAP_CHILD_IN_PROXIMITY;
					if (view_as<bool>(trapInfo.configFlags & TRAP_ADD_IN_BREAKABLES_ON_REVERSE))
					{
						flags |= TRAP_CHILD_IN_BREAKABLES_ON_REVERSE;
					}
					
					ActivateTrapChildren(entity, trapInfo.activatorId, flags);
				}
				
				g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
			}
			else if (inputType == InputType_SetSpeed)
			{
				if (newSpeed == currentSpeed && isReversing == isReversed)
				{
					return;
				}
				
				if (view_as<bool>(trapInfo.flags & TRAP_IS_ACTIVATED))
				{
					if (view_as<bool>(trapInfo.flags & TRAP_RECEIVED_REVERSE_INPUT) 
						&& isReversing == view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_REVERSED))
					{
						trapInfo.flags &= ~TRAP_RECEIVED_REVERSE_INPUT;
					}
					
					if (view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED) 
						&& !view_as<bool>(trapInfo.flags & TRAP_IS_TEMPLATE) 
						&& !view_as<bool>(trapInfo.flags & TRAP_RECEIVED_REVERSE_INPUT) 
						&& newSpeed == trapInfo.spawnSpeed)
					{
						trapInfo.flags &= ~TRAP_IS_ACTIVATED;
						trapInfo.flags &= ~TRAP_LISTEN_TO_OUTPUTS;
						trapInfo.flags &= ~TRAP_RECEIVED_SPEED_INPUT;
						
						RemoveEntityFromProximity(entity, trapInfo, TRAP_IN_PROXIMITY);
						RemoveEntityFromBreakables(entity, trapInfo, TRAP_IN_BREAKABLES_ON_MOVE | TRAP_IN_BREAKABLES_ON_FIRST_MOVE);
						
						DeactivateTrapChildren(entity, TRAP_CHILD_IN_PROXIMITY | TRAP_CHILD_IN_BREAKABLES_ON_MOVE | TRAP_CHILD_IN_BREAKABLES_ON_FIRST_MOVE);
					}
					else
					{
						if (!view_as<bool>(trapInfo.configFlags & TRAP_IGNORE_SPEED))
						{
							trapInfo.flags |= TRAP_RECEIVED_SPEED_INPUT;
						}
						
						if (!view_as<bool>(trapInfo.configFlags & TRAP_IGNORE_REVERSE))
						{
							trapInfo.flags |= (isReversing != isReversed) ? TRAP_RECEIVED_REVERSE_INPUT : 0;
						}
					}
					
					if (view_as<bool>(trapInfo.configFlags & TRAP_ADD_IN_BREAKABLES_ON_SPEED))
					{
						if (IsEntitySolid(entity) && CanPlayersTouchEntity(entity, classType))
						{
							AddEntityInBreakables(entity, trapInfo, TRAP_IN_BREAKABLES_ON_SPEED);
						}
						
						ActivateTrapChildren(entity, trapInfo.activatorId, TRAP_CHILD_IN_BREAKABLES_ON_SPEED);
					}
					
					RemoveEntityFromThinkTraps(reference, trapInfo);
				}
				else
				{
					if (!view_as<bool>(trapInfo.flags & TRAP_HAS_SPAWN_DATA_SET))
					{
						trapInfo.flags |= TRAP_HAS_SPAWN_DATA_SET;
						
						trapInfo.configFlags |= TRAP_SPAWN_ENABLED;
						trapInfo.configFlags |= isReversed ? TRAP_SPAWN_REVERSED : 0;
						
						trapInfo.spawnSpeed = currentSpeed;
					}
					
					if (!view_as<bool>(trapInfo.configFlags & TRAP_IGNORE_SPEED))
					{
						trapInfo.flags |= TRAP_RECEIVED_SPEED_INPUT;
					}
					
					if (!view_as<bool>(trapInfo.configFlags & TRAP_IGNORE_REVERSE))
					{
						trapInfo.flags |= (isReversing != isReversed) ? TRAP_RECEIVED_REVERSE_INPUT : 0;
					}
					
					if (!view_as<bool>(trapInfo.configFlags & TRAP_IGNORE_OUTPUTS))
					{
						trapInfo.flags |= TRAP_LISTEN_TO_OUTPUTS;
					}
					
					trapInfo.flags |= TRAP_IS_ACTIVATED;
					
					if (IsEntitySolid(entity) && CanPlayersTouchEntity(entity, classType))
					{
						AddEntityInProximity(reference, trapInfo, TRAP_IN_PROXIMITY);
						if (view_as<bool>(trapInfo.configFlags & TRAP_ADD_IN_BREAKABLES_ON_SPEED))
						{
							AddEntityInBreakables(entity, trapInfo, TRAP_IN_BREAKABLES_ON_SPEED);
						}
						
					}
					
					int flags = TRAP_CHILD_IN_PROXIMITY;
					if (view_as<bool>(trapInfo.configFlags & TRAP_ADD_IN_BREAKABLES_ON_SPEED))
					{
						flags |= TRAP_CHILD_IN_BREAKABLES_ON_SPEED;
					}
					
					ActivateTrapChildren(entity, trapInfo.activatorId, flags);
				}
				
				g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
			}
		}
		
		// To do: activatorId
		case ClassType_FuncTrain:
		{
			if (!isTrap)
			{
				return;
			}
			
			bool isEntityMoving = IsEntityMoving(entity, trapInfo.classType);
			if (inputType == InputType_Toggle)
			{
				inputType = isEntityMoving ? InputType_Stop : InputType_Start;
			}
			
			if (inputType == InputType_Kill)
			{
				RemoveEntityFromProximity(entity, trapInfo, TRAP_IN_PROXIMITY | TRAP_CHILD_IN_PROXIMITY);
				DeactivateTrapChildren(entity, TRAP_CHILD_IN_PROXIMITY); 
				
				if (!view_as<bool>(trapInfo.flags & TRAP_IS_TEMPLATE))
				{
					if (IsEntitySolid(entity) && CanPlayersTouchEntity(entity, classType))
					{
						AddEntityInBreakables(entity, trapInfo, TRAP_IN_BREAKABLES_ON_KILL);
					}
					
					ActivateTrapChildren(entity, trapInfo.activatorId, TRAP_CHILD_IN_BREAKABLES_ON_KILL);
				}
				
				RemoveEntityFromThinkTraps(reference, trapInfo);
				g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
			}
			else if (inputType == InputType_Start)
			{
				if (isEntityMoving)
				{
					return;
				}
				
				if (view_as<bool>(trapInfo.flags & TRAP_IS_ACTIVATED))
				{
					if (view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED) 
						&& !view_as<bool>(trapInfo.flags & TRAP_IS_TEMPLATE) 
						&& trapInfo.spawnSpeed == GetEntitySpeed(entity))
					{
						trapInfo.flags &= ~TRAP_IS_ACTIVATED;
						trapInfo.flags &= ~TRAP_LISTEN_TO_OUTPUTS;
						
						RemoveEntityFromProximity(entity, trapInfo, TRAP_IN_PROXIMITY);
						RemoveEntityFromBreakables(entity, trapInfo, TRAP_IN_BREAKABLES_ON_MOVE | TRAP_IN_BREAKABLES_ON_FIRST_MOVE);
						
						DeactivateTrapChildren(entity, TRAP_CHILD_IN_PROXIMITY | TRAP_CHILD_IN_BREAKABLES_ON_FIRST_MOVE | TRAP_CHILD_IN_BREAKABLES_ON_FIRST_MOVE);
						
						if (view_as<bool>(trapInfo.configFlags & TRAP_ADD_IN_BREAKABLES_ON_MOVE))
						{
							if (IsEntitySolid(entity) && CanPlayersTouchEntity(entity, classType))
							{
								AddEntityInBreakables(entity, trapInfo, TRAP_IN_BREAKABLES_ON_MOVE | TRAP_SPAWN_ENABLED);
							}
							
							ActivateTrapChildren(entity, trapInfo.activatorId, TRAP_CHILD_IN_BREAKABLES_ON_MOVE | TRAP_SPAWN_ENABLED);
						}
						
						RemoveEntityFromThinkTraps(reference, trapInfo);
					}
					else
					{
						if (view_as<bool>(trapInfo.configFlags & TRAP_REMOVE_FROM_PROXIMITY_ON_STOP) 
							|| view_as<bool>(trapInfo.configFlags & TRAP_ADD_IN_BREAKABLES_ON_MOVE))
						{
							if (IsEntitySolid(entity) && CanPlayersTouchEntity(entity, classType))
							{
								if (view_as<bool>(trapInfo.configFlags & TRAP_REMOVE_FROM_PROXIMITY_ON_STOP))
								{
									AddEntityInProximity(reference, trapInfo, TRAP_IN_PROXIMITY);
								}
								
								if (view_as<bool>(trapInfo.configFlags & TRAP_ADD_IN_BREAKABLES_ON_MOVE))
								{
									int flags = TRAP_IN_BREAKABLES_ON_MOVE;
									if (view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
									{
										flags |= TRAP_SPAWN_ENABLED;
									}
									
									AddEntityInBreakables(entity, trapInfo, flags);
								}
							}
							
							int flags;
							if (view_as<bool>(trapInfo.configFlags & TRAP_REMOVE_FROM_PROXIMITY_ON_STOP))
							{
								flags |= TRAP_CHILD_IN_PROXIMITY;
							}
							
							if (view_as<bool>(trapInfo.configFlags & TRAP_ADD_IN_BREAKABLES_ON_MOVE))
							{
								flags |= TRAP_CHILD_IN_BREAKABLES_ON_MOVE;
							}
							
							if (view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
							{
								flags |= TRAP_SPAWN_ENABLED;
							}
							
							ActivateTrapChildren(entity, trapInfo.activatorId, flags);
						}
						
						if (!view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
						{
							AddEntityInThinkTraps(reference, trapInfo);
						}
					}
				}
				else
				{
					if (!view_as<bool>(trapInfo.flags & TRAP_HAS_SPAWN_DATA_SET))
					{
						trapInfo.flags |= TRAP_HAS_SPAWN_DATA_SET;
						GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", trapInfo.spawnOrigin);
					}
					
					if (!view_as<bool>(trapInfo.configFlags & TRAP_IGNORE_OUTPUTS))
					{
						trapInfo.flags |= TRAP_LISTEN_TO_OUTPUTS;
					}
					
					trapInfo.flags |= TRAP_IS_ACTIVATED;
					
					if (IsEntitySolid(entity) && CanPlayersTouchEntity(entity, classType))
					{
						AddEntityInProximity(reference, trapInfo, TRAP_IN_PROXIMITY);
						
						if (view_as<bool>(trapInfo.configFlags & TRAP_ADD_IN_BREAKABLES_ON_FIRST_MOVE))
						{
							int flags = TRAP_IN_BREAKABLES_ON_FIRST_MOVE;
							if (view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
							{
								flags |= TRAP_SPAWN_ENABLED;
							}
							
							AddEntityInBreakables(entity, trapInfo, flags);
						}
						else if (view_as<bool>(trapInfo.configFlags & TRAP_ADD_IN_BREAKABLES_ON_MOVE))
						{
							int flags = TRAP_IN_BREAKABLES_ON_MOVE;
							if (view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
							{
								flags |= TRAP_SPAWN_ENABLED;
							}
							
							AddEntityInBreakables(entity, trapInfo, flags);
						}
					}
					
					int flags = TRAP_CHILD_IN_PROXIMITY;
					if (view_as<bool>(trapInfo.configFlags & TRAP_ADD_IN_BREAKABLES_ON_FIRST_MOVE))
					{
						flags |= TRAP_CHILD_IN_BREAKABLES_ON_FIRST_MOVE;
					}
					else if (view_as<bool>(trapInfo.configFlags & TRAP_ADD_IN_BREAKABLES_ON_MOVE))
					{
						flags |= TRAP_CHILD_IN_BREAKABLES_ON_MOVE;
					}
					
					if (view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
					{
						flags |= TRAP_SPAWN_ENABLED;
					}
					
					ActivateTrapChildren(entity, trapInfo.activatorId, flags);
					
					if (!view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
					{
						AddEntityInThinkTraps(reference, trapInfo);
					}
				}
				
				g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
			}
			else if (inputType == InputType_Stop)
			{
				if (!isEntityMoving)
				{
					return;
				}
				
				if (view_as<bool>(trapInfo.flags & TRAP_IS_ACTIVATED))
				{
					if (view_as<bool>(trapInfo.configFlags & TRAP_IS_REPLACING_OTHER_TRAPS) 
						|| view_as<bool>(trapInfo.configFlags & TRAP_DISABLE_ON_STOP) 
						|| !view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED) 
							&& !view_as<bool>(trapInfo.flags & TRAP_IS_TEMPLATE) 
							&& IsEntityInSpawnPosition(entity, trapInfo.spawnOrigin))
					{
						trapInfo.flags &= ~TRAP_IS_ACTIVATED;
						trapInfo.flags &= ~TRAP_LISTEN_TO_OUTPUTS;
						
						RemoveEntityFromProximity(entity, trapInfo, TRAP_IN_PROXIMITY);
						RemoveEntityFromBreakables(entity, trapInfo, TRAP_IN_BREAKABLES_ON_MOVE | TRAP_IN_BREAKABLES_ON_FIRST_MOVE);
						
						DeactivateTrapChildren(entity, TRAP_CHILD_IN_PROXIMITY | TRAP_CHILD_IN_BREAKABLES_ON_MOVE | TRAP_CHILD_IN_BREAKABLES_ON_FIRST_MOVE);
						
						if (view_as<bool>(trapInfo.configFlags & TRAP_IS_REPLACING_OTHER_TRAPS))
						{
							RemoveReplacedEntitiesFromBreakables(entity);
						}
					}
					else if (view_as<bool>(trapInfo.configFlags & TRAP_REMOVE_FROM_PROXIMITY_ON_STOP))
					{
						RemoveEntityFromProximity(entity, trapInfo, TRAP_IN_PROXIMITY);
						DeactivateTrapChildren(entity, TRAP_CHILD_IN_PROXIMITY);
					}
					
					RemoveEntityFromThinkTraps(reference, trapInfo);
				}
				else
				{
					if (!view_as<bool>(trapInfo.flags & TRAP_HAS_SPAWN_DATA_SET))
					{
						trapInfo.configFlags |= TRAP_SPAWN_ENABLED;
						trapInfo.flags |= TRAP_HAS_SPAWN_DATA_SET;
						
						trapInfo.spawnSpeed = GetEntitySpeed(entity);
					}
					
					if (!view_as<bool>(trapInfo.configFlags & TRAP_IGNORE_OUTPUTS))
					{
						trapInfo.flags |= TRAP_LISTEN_TO_OUTPUTS;
					}
					
					trapInfo.flags |= TRAP_IS_ACTIVATED;
					
					if (IsEntitySolid(entity) && CanPlayersTouchEntity(entity, classType))
					{
						AddEntityInProximity(reference, trapInfo, TRAP_IN_PROXIMITY);
					}
					
					ActivateTrapChildren(entity, trapInfo.activatorId, TRAP_CHILD_IN_PROXIMITY);
				}
				
				g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
			}
		}
		
		// To do: activatorId
		case ClassType_FuncTankTrain, ClassType_FuncTrackTrain:
		{
			bool receivedToggleInput;
			bool isReversed = !IsDirForward(entity, trapInfo.classType);
			float currentSpeed = FloatAbs(GetEntitySpeed(entity));
			float maxSpeed = GetEntPropFloat(entity, Prop_Data, "m_maxSpeed");
			
			bool isEntityMoving = view_as<bool>(currentSpeed != 0.0);
			float newSpeed = currentSpeed;
			
			if (inputType == InputType_Toggle)
			{
				receivedToggleInput = true;
				inputType = isEntityMoving ? InputType_Stop : InputType_Start;
			}
			else if (inputType == InputType_StartForward)
			{
				if (currentSpeed && isReversed)
				{
					inputType = InputType_Reverse;
				}
			}
			else if (inputType == InputType_StartBackward)
			{
				if (currentSpeed && !isReversed)
				{
					inputType = InputType_Reverse;
				}
			}
			else if (inputType == InputType_SetSpeed || inputType == InputType_SetSpeedReal)
			{
				if (variantInfo.variantType == EntityIO_VariantType_Float)
				{
					newSpeed = variantInfo.flValue;
				}
				else if (variantInfo.variantType == EntityIO_VariantType_String)
				{
					if (!StringToFloatEx(variantInfo.sValue, newSpeed))
					{
						LogError("(Func_TankTrain::InputType_SetSpeed) Cannot convert string to float (%s)", variantInfo.sValue);					
					}
				}
				else
				{
					LogError("(Func_TankTrain::InputType_SetSpeed) Param type is not float (%d)", variantInfo.variantType);					
					return;
				}
				
				if (inputType == InputType_SetSpeed)
				{
					SetUpperBound(newSpeed, 1.0);
					SetLowerBound(newSpeed, 0.0);
					newSpeed *= maxSpeed;
				}
				else
				{
					SetUpperBound(newSpeed, maxSpeed);
					SetLowerBound(newSpeed, 0.0);
				}
				
				if (newSpeed && !currentSpeed)
				{
					inputType = isReversed ? InputType_StartBackward : InputType_StartForward;
				}
				else if (currentSpeed && !newSpeed)
				{
					inputType = InputType_Stop;
				}
			}
			
			if (inputType != InputType_Stop && !isTrap)
			{
				if (g_Cvar_DebugModeEnable.BoolValue)
				{
					char entityName[256];
					GetEntPropString(entity, Prop_Data, "m_iName", entityName, sizeof(entityName));
					StringToLower(entityName);
					
					PrintToServer("Func_TankTrain | Func_TrackTrain :: %s :: Is not trap", entityName);
				}
				
				return;
			}
			
			if (inputType == InputType_Kill)
			{
				RemoveEntityFromProximity(entity, trapInfo, TRAP_IN_PROXIMITY | TRAP_CHILD_IN_PROXIMITY);
				DeactivateTrapChildren(entity, TRAP_CHILD_IN_PROXIMITY); 
				
				if (!view_as<bool>(trapInfo.flags & TRAP_IS_TEMPLATE))
				{
					if (IsEntitySolid(entity) && CanPlayersTouchEntity(entity, classType))
					{
						AddEntityInBreakables(entity, trapInfo, TRAP_IN_BREAKABLES_ON_KILL);
					}
					
					ActivateTrapChildren(entity, trapInfo.activatorId, TRAP_CHILD_IN_BREAKABLES_ON_KILL);
				}
				
				g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
			}
 			else if (inputType == InputType_Start || inputType == InputType_Resume || inputType == InputType_StartBackward || inputType == InputType_StartForward)
			{
				if (inputType == InputType_Start && !receivedToggleInput)
				{
					return;
				}
				
				bool isReversing;
				newSpeed = (inputType != InputType_Resume) ? maxSpeed : GetEntPropFloat(entity, Prop_Data, "m_oldSpeed");
				
				if (inputType == InputType_Resume)
				{
					if (isEntityMoving)
					{
						return;
					}
					
					isReversing = isReversed;
				}
				else
				{
					if (inputType == InputType_StartBackward)
					{
						isReversing = true;
					}
					
					if (currentSpeed == newSpeed && isReversing == isReversed)
					{
						return;
					}
				}
				
				if (view_as<bool>(trapInfo.flags & TRAP_IS_ACTIVATED))
				{
					if (view_as<bool>(trapInfo.flags & TRAP_RECEIVED_REVERSE_INPUT) 
						&& isReversing == view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_REVERSED))
					{
						trapInfo.flags &= ~TRAP_RECEIVED_REVERSE_INPUT;
					}
					
					if (view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED) 
						&& !view_as<bool>(trapInfo.flags & TRAP_IS_TEMPLATE) 
						&& !view_as<bool>(trapInfo.flags & TRAP_RECEIVED_REVERSE_INPUT) 
						&& (!view_as<bool>(trapInfo.flags & TRAP_RECEIVED_SPEED_INPUT) || newSpeed == trapInfo.spawnSpeed))
					{
						trapInfo.flags &= ~TRAP_IS_ACTIVATED;
						trapInfo.flags &= ~TRAP_LISTEN_TO_OUTPUTS;
						
						RemoveEntityFromProximity(entity, trapInfo, TRAP_IN_PROXIMITY);
						RemoveEntityFromBreakables(entity, trapInfo, TRAP_IN_BREAKABLES_ON_MOVE | TRAP_IN_BREAKABLES_ON_FIRST_MOVE);
						
						DeactivateTrapChildren(entity, TRAP_CHILD_IN_PROXIMITY | TRAP_CHILD_IN_BREAKABLES_ON_MOVE | TRAP_CHILD_IN_BREAKABLES_ON_FIRST_MOVE);
						
						if (view_as<bool>(trapInfo.configFlags & TRAP_ADD_IN_BREAKABLES_ON_MOVE))
						{
							if (IsEntitySolid(entity) && CanPlayersTouchEntity(entity, classType))
							{
								AddEntityInBreakables(entity, trapInfo, TRAP_IN_BREAKABLES_ON_MOVE | TRAP_SPAWN_ENABLED);
							}
							
							ActivateTrapChildren(entity, trapInfo.activatorId, TRAP_CHILD_IN_BREAKABLES_ON_MOVE | TRAP_SPAWN_ENABLED);
						}
					}
					else
					{
						if (!view_as<bool>(trapInfo.configFlags & TRAP_IGNORE_REVERSE))
						{
							trapInfo.flags |= (isReversing != isReversed) ? TRAP_RECEIVED_REVERSE_INPUT : 0;
						}
						
						if (view_as<bool>(trapInfo.configFlags & TRAP_REMOVE_FROM_PROXIMITY_ON_STOP) 
							|| view_as<bool>(trapInfo.configFlags & TRAP_ADD_IN_BREAKABLES_ON_MOVE))
						{
							if (IsEntitySolid(entity) && CanPlayersTouchEntity(entity, classType))
							{
								if (view_as<bool>(trapInfo.configFlags & TRAP_REMOVE_FROM_PROXIMITY_ON_STOP))
								{
									AddEntityInProximity(reference, trapInfo, TRAP_IN_PROXIMITY);
								}
								
								if (view_as<bool>(trapInfo.configFlags & TRAP_ADD_IN_BREAKABLES_ON_MOVE))
								{
									int flags = TRAP_IN_BREAKABLES_ON_MOVE;
									if (view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
									{
										flags |= TRAP_SPAWN_ENABLED;
									}
									
									AddEntityInBreakables(entity, trapInfo, flags);
								}
							}
							
							int flags;
							if (view_as<bool>(trapInfo.configFlags & TRAP_REMOVE_FROM_PROXIMITY_ON_STOP))
							{
								flags |= TRAP_CHILD_IN_PROXIMITY;
							}
							
							if (view_as<bool>(trapInfo.configFlags & TRAP_ADD_IN_BREAKABLES_ON_MOVE))
							{
								flags |= TRAP_CHILD_IN_BREAKABLES_ON_MOVE;
							}
							
							if (view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
							{
								flags |= TRAP_SPAWN_ENABLED;
							}
							
							ActivateTrapChildren(entity, trapInfo.activatorId, flags);
						}
						
						if (!view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
						{
							AddEntityInThinkTraps(reference, trapInfo);
						}
					}
				}
				else
				{
					if (!view_as<bool>(trapInfo.flags & TRAP_HAS_SPAWN_DATA_SET))
					{
						trapInfo.flags |= TRAP_HAS_SPAWN_DATA_SET;
						
						trapInfo.configFlags |= isReversed ? TRAP_SPAWN_REVERSED : 0;
						trapInfo.configFlags |= isEntityMoving ? TRAP_SPAWN_ENABLED : 0;
						
						trapInfo.spawnSpeed = currentSpeed;
						GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", trapInfo.spawnOrigin);
					}
					
					if (!view_as<bool>(trapInfo.configFlags & TRAP_IGNORE_REVERSE))
					{
						trapInfo.flags |= (isReversing != isReversed) ? TRAP_RECEIVED_REVERSE_INPUT : 0;
					}
					
					if (!view_as<bool>(trapInfo.configFlags & TRAP_IGNORE_OUTPUTS))
					{
						trapInfo.flags |= TRAP_LISTEN_TO_OUTPUTS;
					}
					
					trapInfo.flags |= TRAP_IS_ACTIVATED;
					
					if (IsEntitySolid(entity) && CanPlayersTouchEntity(entity, classType))
					{
						AddEntityInProximity(reference, trapInfo, TRAP_IN_PROXIMITY);
						
						if (view_as<bool>(trapInfo.configFlags & TRAP_ADD_IN_BREAKABLES_ON_FIRST_MOVE))
						{
							int flags = TRAP_IN_BREAKABLES_ON_FIRST_MOVE;
							if (view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
							{
								flags |= TRAP_SPAWN_ENABLED;
							}
							
							AddEntityInBreakables(entity, trapInfo, flags);
						}
						else if (view_as<bool>(trapInfo.configFlags & TRAP_ADD_IN_BREAKABLES_ON_MOVE))
						{
							int flags = TRAP_IN_BREAKABLES_ON_MOVE;
							if (view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
							{
								flags |= TRAP_SPAWN_ENABLED;
							}
							
							AddEntityInBreakables(entity, trapInfo, flags);
						}
					}
					
					int flags = TRAP_CHILD_IN_PROXIMITY;
					if (view_as<bool>(trapInfo.configFlags & TRAP_ADD_IN_BREAKABLES_ON_FIRST_MOVE))
					{
						flags |= TRAP_CHILD_IN_BREAKABLES_ON_FIRST_MOVE;
					}
					else if (view_as<bool>(trapInfo.configFlags & TRAP_ADD_IN_BREAKABLES_ON_MOVE))
					{
						flags |= TRAP_CHILD_IN_BREAKABLES_ON_MOVE;
					}
					
					if (view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
					{
						flags |= TRAP_SPAWN_ENABLED;
					}
					
					ActivateTrapChildren(entity, trapInfo.activatorId, flags);
					
					if (!view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
					{
						AddEntityInThinkTraps(reference, trapInfo);
					}
				}
				
				g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
			}
			else if (inputType == InputType_Stop)
			{
				if (!isEntityMoving)
				{
					if (g_Cvar_DebugModeEnable.BoolValue)
					{
						char entityName[256];
						GetEntPropString(entity, Prop_Data, "m_iName", entityName, sizeof(entityName));
						StringToLower(entityName);
						
						PrintToServer("Func_TankTrain | Func_TrackTrain :: %s :: Stop :: Not moving", entityName);
					}
					
					return;
				}
				
				if (view_as<bool>(trapInfo.flags & TRAP_IS_ACTIVATED))
				{
					if (view_as<bool>(trapInfo.configFlags & TRAP_IS_REPLACING_OTHER_TRAPS) 
						|| view_as<bool>(trapInfo.configFlags & TRAP_DISABLE_ON_STOP) 
						|| !view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED) 
							&& !view_as<bool>(trapInfo.flags & TRAP_IS_TEMPLATE) 
							&& IsEntityInSpawnPosition(entity, trapInfo.spawnOrigin))
					{
						trapInfo.flags &= ~TRAP_IS_ACTIVATED;
						trapInfo.flags &= ~TRAP_LISTEN_TO_OUTPUTS;
						
						RemoveEntityFromProximity(entity, trapInfo, TRAP_IN_PROXIMITY);
						RemoveEntityFromBreakables(entity, trapInfo, TRAP_IN_BREAKABLES_ON_MOVE | TRAP_IN_BREAKABLES_ON_FIRST_MOVE);
						
						DeactivateTrapChildren(entity, TRAP_CHILD_IN_PROXIMITY | TRAP_CHILD_IN_BREAKABLES_ON_MOVE | TRAP_CHILD_IN_BREAKABLES_ON_FIRST_MOVE);
						
						if (view_as<bool>(trapInfo.configFlags & TRAP_IS_REPLACING_OTHER_TRAPS))
						{
							RemoveReplacedEntitiesFromBreakables(entity);
						}
					}
					else if (view_as<bool>(trapInfo.configFlags & TRAP_REMOVE_FROM_PROXIMITY_ON_STOP))
					{
						RemoveEntityFromProximity(entity, trapInfo, TRAP_IN_PROXIMITY);
						DeactivateTrapChildren(entity, TRAP_CHILD_IN_PROXIMITY);
						
						if (g_Cvar_DebugModeEnable.BoolValue)
						{
							char entityName[256];
							GetEntPropString(entity, Prop_Data, "m_iName", entityName, sizeof(entityName));
							StringToLower(entityName);
							
							float vecOrigin[3];
							GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vecOrigin);
							
							PrintToServer("Func_TankTrain | Func_TrackTrain :: %s :: Stop :: Remove only from proximity", entityName);
							PrintToServer("Func_TankTrain | Func_TrackTrain :: %s :: Spawn origin (%f, %f, %f) :: Origin (%f, %f, %f)", entityName, trapInfo.spawnOrigin[0], trapInfo.spawnOrigin[1], trapInfo.spawnOrigin[2], vecOrigin[0], vecOrigin[1], vecOrigin[2]);
						}
					}
					
					RemoveEntityFromThinkTraps(reference, trapInfo);
				}
				else
				{
					if (!isTrap)
					{
						return;
					}
					
					if (!view_as<bool>(trapInfo.flags & TRAP_HAS_SPAWN_DATA_SET))
					{
						trapInfo.flags |= TRAP_HAS_SPAWN_DATA_SET;
						
						trapInfo.configFlags |= TRAP_SPAWN_ENABLED;
						trapInfo.configFlags |= isReversed ? TRAP_SPAWN_REVERSED : 0;
						
						trapInfo.spawnSpeed = currentSpeed;
					}
					
					if (!view_as<bool>(trapInfo.configFlags & TRAP_IGNORE_OUTPUTS))
					{
						trapInfo.flags |= TRAP_LISTEN_TO_OUTPUTS;
					}
					
					trapInfo.flags |= TRAP_IS_ACTIVATED;
					
					if (IsEntitySolid(entity) && CanPlayersTouchEntity(entity, classType))
					{
						AddEntityInProximity(reference, trapInfo, TRAP_IN_PROXIMITY);
					}
					
					ActivateTrapChildren(entity, trapInfo.activatorId, TRAP_CHILD_IN_PROXIMITY);
				}
				
				g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
			}
			else if (inputType == InputType_Reverse)
			{
				if (g_Cvar_DebugModeEnable.BoolValue)
				{
					PrintToServer("Func_TankTrain or Func_TrackTrain::InputType_Reverse");
				}
				
				if (view_as<bool>(trapInfo.flags & TRAP_IS_ACTIVATED))
				{
					if (g_Cvar_DebugModeEnable.BoolValue)
					{
						PrintToServer("Func_TankTrain or Func_TrackTrain::InputType_Reverse - trap activated");
					}
					
					if (view_as<bool>(trapInfo.flags & TRAP_RECEIVED_REVERSE_INPUT))
					{
						if (g_Cvar_DebugModeEnable.BoolValue)
						{
							PrintToServer("Func_TankTrain or Func_TrackTrain::InputType_Reverse - trap activated - received reverse input");
						}
						
						if (isReversed != view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_REVERSED))
						{
							if (g_Cvar_DebugModeEnable.BoolValue)
							{
								PrintToServer("Func_TankTrain or Func_TrackTrain::InputType_Reverse - trap activated - received reverse input - remove flag");
							}
							
							trapInfo.flags &= ~TRAP_RECEIVED_REVERSE_INPUT;
						}
					}
					else if (!view_as<bool>(trapInfo.configFlags & TRAP_IGNORE_REVERSE))
					{
						if (isReversed == view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_REVERSED))
						{
							if (g_Cvar_DebugModeEnable.BoolValue)
							{
								PrintToServer("Func_TankTrain or Func_TrackTrain::InputType_Reverse - trap activated - add received reverse flag");
							}
							
							trapInfo.flags |= TRAP_RECEIVED_REVERSE_INPUT;
						}
					}
					
					if (isEntityMoving)
					{
						if (g_Cvar_DebugModeEnable.BoolValue)
						{
							PrintToServer("Func_TankTrain or Func_TrackTrain::InputType_Reverse - trap activated - entity is moving");
						}
						
						if (view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED) 
							&& !view_as<bool>(trapInfo.flags & TRAP_IS_TEMPLATE) 
							&& !view_as<bool>(trapInfo.flags & TRAP_RECEIVED_SPEED_INPUT) 
							&& !view_as<bool>(trapInfo.flags & TRAP_RECEIVED_REVERSE_INPUT))
						{
							if (g_Cvar_DebugModeEnable.BoolValue)
							{
								PrintToServer("Func_TankTrain or Func_TrackTrain::InputType_Reverse - trap activated - deactivate trap");
							}
							
							trapInfo.flags &= ~TRAP_IS_ACTIVATED;
							trapInfo.flags &= ~TRAP_LISTEN_TO_OUTPUTS;
							
							RemoveEntityFromProximity(entity, trapInfo, TRAP_IN_PROXIMITY);
							RemoveEntityFromBreakables(entity, trapInfo, TRAP_IN_BREAKABLES_ON_MOVE | TRAP_IN_BREAKABLES_ON_FIRST_MOVE);
							
							DeactivateTrapChildren(entity, TRAP_CHILD_IN_PROXIMITY | TRAP_CHILD_IN_BREAKABLES_ON_MOVE | TRAP_CHILD_IN_BREAKABLES_ON_FIRST_MOVE);
						}
						else
						{
							if (!view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
							{
								if (g_Cvar_DebugModeEnable.BoolValue)
								{
									PrintToServer("Func_TankTrain or Func_TrackTrain::InputType_Reverse - connot deactivate - not spawn enabled");
								}
							}
							
							if (view_as<bool>(trapInfo.flags & TRAP_IS_TEMPLATE))
							{
								if (g_Cvar_DebugModeEnable.BoolValue)
								{
									PrintToServer("Func_TankTrain or Func_TrackTrain::InputType_Reverse - connot deactivate - spawned by template");
								}
							}
							
							if (view_as<bool>(trapInfo.flags & TRAP_RECEIVED_SPEED_INPUT))
							{
								if (g_Cvar_DebugModeEnable.BoolValue)
								{
									PrintToServer("Func_TankTrain or Func_TrackTrain::InputType_Reverse - connot deactivate - has speed input");
								}
							}
							
							if (view_as<bool>(trapInfo.flags & TRAP_RECEIVED_REVERSE_INPUT))
							{
								if (g_Cvar_DebugModeEnable.BoolValue)
								{
									PrintToServer("Func_TankTrain or Func_TrackTrain::InputType_Reverse - connot deactivate - has reverse input");
								}
							}
						}
						
						if (view_as<bool>(trapInfo.configFlags & TRAP_ADD_IN_BREAKABLES_ON_REVERSE))
						{
							if (g_Cvar_DebugModeEnable.BoolValue)
							{
								PrintToServer("Func_TankTrain or Func_TrackTrain::InputType_Reverse - trap activated - add in breakables");
							}
							
							if (IsEntitySolid(entity) && CanPlayersTouchEntity(entity, classType))
							{
								AddEntityInBreakables(entity, trapInfo, TRAP_IN_BREAKABLES_ON_REVERSE);
							}
							
							ActivateTrapChildren(entity, trapInfo.activatorId, TRAP_CHILD_IN_BREAKABLES_ON_REVERSE);
						}
					}
				}
				else
				{
					if (!isEntityMoving)
					{
						if (g_Cvar_DebugModeEnable.BoolValue)
						{
							PrintToServer("Func_TankTrain or Func_TrackTrain::InputType_Reverse - trap deactivated - entity not moving");
						}
						
						return;
					}
					
					if (!view_as<bool>(trapInfo.flags & TRAP_HAS_SPAWN_DATA_SET))
					{
						trapInfo.flags |= TRAP_HAS_SPAWN_DATA_SET;
						
						trapInfo.configFlags |= TRAP_SPAWN_ENABLED;						
						trapInfo.configFlags |= isReversed ? TRAP_SPAWN_REVERSED : 0;
						
						trapInfo.spawnSpeed = currentSpeed;
					}
					
					if (!view_as<bool>(trapInfo.configFlags & TRAP_IGNORE_REVERSE))
					{
						trapInfo.flags |= TRAP_RECEIVED_REVERSE_INPUT;
					}
					
					if (!view_as<bool>(trapInfo.configFlags & TRAP_IGNORE_OUTPUTS))
					{
						trapInfo.flags |= TRAP_LISTEN_TO_OUTPUTS;
					}
					
					if (g_Cvar_DebugModeEnable.BoolValue)
					{
						PrintToServer("Func_TankTrain or Func_TrackTrain::InputType_Reverse - trap deactivated - activate");
					}
					
					trapInfo.flags |= TRAP_IS_ACTIVATED;
					
					if (IsEntitySolid(entity) && CanPlayersTouchEntity(entity, classType))
					{
						if (g_Cvar_DebugModeEnable.BoolValue)
						{
							PrintToServer("Func_TankTrain or Func_TrackTrain::InputType_Reverse - trap deactivated - add in proximity");
						}
						
						AddEntityInProximity(reference, trapInfo, TRAP_IN_PROXIMITY);
						if (view_as<bool>(trapInfo.configFlags & TRAP_ADD_IN_BREAKABLES_ON_REVERSE))
						{
							if (g_Cvar_DebugModeEnable.BoolValue)
							{
								PrintToServer("Func_TankTrain or Func_TrackTrain::InputType_Reverse - trap deactivated - add in breakables");
							}
							
							AddEntityInBreakables(entity, trapInfo, TRAP_IN_BREAKABLES_ON_REVERSE);
						}
					}
					
					int flags = TRAP_CHILD_IN_PROXIMITY;
					if (view_as<bool>(trapInfo.configFlags & TRAP_ADD_IN_BREAKABLES_ON_REVERSE))
					{
						flags |= TRAP_CHILD_IN_BREAKABLES_ON_REVERSE;
					}
					
					ActivateTrapChildren(entity, trapInfo.activatorId, flags);
				}
				
				g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
			}
			else if (inputType == InputType_SetSpeed || inputType == InputType_SetSpeedReal)
			{
				if (g_Cvar_DebugModeEnable.BoolValue)
				{
					PrintToServer("Func_TankTrain or Func_TrackTrain::InputType_SetSpeed or InputType_SetSpeedReal");
				}
				
				if (newSpeed == currentSpeed)
				{
					if (g_Cvar_DebugModeEnable.BoolValue)
					{
						PrintToServer("Func_TankTrain or Func_TrackTrain::InputType_SetSpeed or InputType_SetSpeedReal - new speed is equal to current speed");
					}
					
					return;
				}
				
				if (view_as<bool>(trapInfo.flags & TRAP_IS_ACTIVATED))
				{
					if (view_as<bool>(trapInfo.flags & TRAP_RECEIVED_SPEED_INPUT))
					{
						if (g_Cvar_DebugModeEnable.BoolValue)
						{
							PrintToServer("Func_TankTrain or Func_TrackTrain::InputType_SetSpeed or InputType_SetSpeedReal - trap activated - received speed input");
						}
						
						if (newSpeed == trapInfo.spawnSpeed)
						{
							if (g_Cvar_DebugModeEnable.BoolValue)
							{
								PrintToServer("Func_TankTrain or Func_TrackTrain::InputType_SetSpeed or InputType_SetSpeedReal - trap activated - received speed input - remove flag");
							}
							
							trapInfo.flags &= ~TRAP_RECEIVED_SPEED_INPUT;
						}
					}
					else if (!view_as<bool>(trapInfo.configFlags & TRAP_IGNORE_SPEED))
					{
						if (newSpeed != trapInfo.spawnSpeed)
						{
							if (g_Cvar_DebugModeEnable.BoolValue)
							{
								PrintToServer("Func_TankTrain or Func_TrackTrain::InputType_SetSpeed or InputType_SetSpeedReal - trap activated - add received speed flag");
							}
							
							trapInfo.flags |= TRAP_RECEIVED_SPEED_INPUT;
						}
					}
					
					if (view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED) 
						&& !view_as<bool>(trapInfo.flags & TRAP_IS_TEMPLATE) 
						&& !view_as<bool>(trapInfo.flags & TRAP_RECEIVED_REVERSE_INPUT) 
						&& !view_as<bool>(trapInfo.flags & TRAP_RECEIVED_SPEED_INPUT))
					{
						trapInfo.flags &= ~TRAP_IS_ACTIVATED;
						trapInfo.flags &= ~TRAP_LISTEN_TO_OUTPUTS;
						trapInfo.flags &= ~TRAP_RECEIVED_SPEED_INPUT;
						
						RemoveEntityFromProximity(entity, trapInfo, TRAP_IN_PROXIMITY);
						RemoveEntityFromBreakables(entity, trapInfo, TRAP_IN_BREAKABLES_ON_MOVE | TRAP_IN_BREAKABLES_ON_FIRST_MOVE);
						
						DeactivateTrapChildren(entity, TRAP_CHILD_IN_PROXIMITY | TRAP_CHILD_IN_BREAKABLES_ON_MOVE | TRAP_CHILD_IN_BREAKABLES_ON_FIRST_MOVE);
					}
					
					if (view_as<bool>(trapInfo.configFlags & TRAP_ADD_IN_BREAKABLES_ON_SPEED))
					{
						if (IsEntitySolid(entity) && CanPlayersTouchEntity(entity, classType))
						{
							AddEntityInBreakables(entity, trapInfo, TRAP_IN_BREAKABLES_ON_SPEED);
						}
						
						ActivateTrapChildren(entity, trapInfo.activatorId, TRAP_CHILD_IN_BREAKABLES_ON_SPEED);
					}
				}
				else
				{
					if (!view_as<bool>(trapInfo.flags & TRAP_HAS_SPAWN_DATA_SET))
					{
						trapInfo.flags |= TRAP_HAS_SPAWN_DATA_SET;
						
						trapInfo.configFlags |= TRAP_SPAWN_ENABLED;
						trapInfo.configFlags |= isReversed ? TRAP_SPAWN_REVERSED : 0;
						
						trapInfo.spawnSpeed = currentSpeed;
					}
					
					if (!view_as<bool>(trapInfo.configFlags & TRAP_IGNORE_SPEED))
					{
						trapInfo.flags |= TRAP_RECEIVED_SPEED_INPUT;
					}
					
					if (!view_as<bool>(trapInfo.configFlags & TRAP_IGNORE_OUTPUTS))
					{
						trapInfo.flags |= TRAP_LISTEN_TO_OUTPUTS;
					}
					
					trapInfo.flags |= TRAP_IS_ACTIVATED;
					
					if (IsEntitySolid(entity) && CanPlayersTouchEntity(entity, classType))
					{
						AddEntityInProximity(reference, trapInfo, TRAP_IN_PROXIMITY);
						if (view_as<bool>(trapInfo.configFlags & TRAP_ADD_IN_BREAKABLES_ON_SPEED))
						{
							AddEntityInBreakables(entity, trapInfo, TRAP_IN_BREAKABLES_ON_SPEED);
						}
						
					}
					
					int flags = TRAP_CHILD_IN_PROXIMITY;
					if (view_as<bool>(trapInfo.configFlags & TRAP_ADD_IN_BREAKABLES_ON_SPEED))
					{
						flags |= TRAP_CHILD_IN_BREAKABLES_ON_SPEED;
					}
					
					ActivateTrapChildren(entity, trapInfo.activatorId, flags);
				}
				
				g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
			}
		}
		
		case ClassType_GameUI:
		{
			if (inputType == InputType_Kill)
			{
				if (!isTrap)
				{
					return;
				}
				
				DeactivateTrapChildren(entity, TRAP_CHILD_IN_PROXIMITY);
				ActivateTrapChildren(entity, trapInfo.activatorId, TRAP_CHILD_IN_BREAKABLES_ON_KILL);
				
				g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
			}
			else if (inputType == InputType_Activate)
			{
				if (IsEntityEnabled(entity, trapInfo.classType))
				{
					return;
				}
				
				if (view_as<bool>(trapInfo.flags & TRAP_IS_ACTIVATED))
				{
					if (view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
					{
						trapInfo.flags &= ~TRAP_IS_ACTIVATED;
					}
				}
				else
				{
					if (!isTrap)
					{
						return;
					}
					
					if (view_as<bool>(trapInfo.flags & TRAP_HAS_SPAWN_DATA_SET))
					{
						if (view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
						{
							return;
						}
					}
					else
					{
						trapInfo.flags |= TRAP_HAS_SPAWN_DATA_SET;
					}
					
					if (!view_as<bool>(trapInfo.configFlags & TRAP_IGNORE_OUTPUTS))
					{
						trapInfo.flags |= TRAP_LISTEN_TO_OUTPUTS;
					}
					
					trapInfo.flags |= TRAP_IS_ACTIVATED;
				}
				
				g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
			}
			else if (inputType == InputType_Deactivate)
			{
				if (!IsEntityEnabled(entity, trapInfo.classType))
				{
					return;
				}
				
				if (view_as<bool>(trapInfo.flags & TRAP_IS_ACTIVATED))
				{
					if (!view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
					{
						trapInfo.flags &= ~TRAP_IS_ACTIVATED;
						trapInfo.flags &= ~TRAP_LISTEN_TO_OUTPUTS;
					}
				}
				else
				{
					if (!isTrap)
					{
						return;
					}
					
					if (view_as<bool>(trapInfo.flags & TRAP_HAS_SPAWN_DATA_SET))
					{
						if (!view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
						{
							return;
						}
					}
					else
					{
						trapInfo.configFlags |= TRAP_SPAWN_ENABLED;
						trapInfo.flags |= TRAP_HAS_SPAWN_DATA_SET;
					}
					
					trapInfo.flags |= TRAP_IS_ACTIVATED;
				}
				
				g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
			}
		}
		
		case ClassType_LogicBranch:
		{
			if (inputType == InputType_Kill)
			{
				if (!isTrap)
				{
					return;
				}
				
				DeactivateTrapChildren(entity, TRAP_CHILD_IN_PROXIMITY);
				ActivateTrapChildren(entity, trapInfo.activatorId, TRAP_CHILD_IN_BREAKABLES_ON_KILL);
				
				g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
			}
			else if (inputType == InputType_Test)
			{
				if (view_as<bool>(trapInfo.flags & TRAP_IS_ACTIVATED))
				{
					if (!isTrap)
					{
						trapInfo.flags &= ~TRAP_IS_ACTIVATED;
						trapInfo.flags &= ~TRAP_LISTEN_TO_OUTPUTS;
					}
				}
				else
				{
					if (!isTrap)
					{
						return;
					}
					
					if (!view_as<bool>(trapInfo.flags & TRAP_HAS_SPAWN_DATA_SET))
					{
						trapInfo.flags |= TRAP_HAS_SPAWN_DATA_SET;
					}
					
					if (!view_as<bool>(trapInfo.configFlags & TRAP_IGNORE_OUTPUTS))
					{
						trapInfo.flags |= TRAP_LISTEN_TO_OUTPUTS;
					}
					
					trapInfo.flags |= TRAP_IS_ACTIVATED;
				}
				
				g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
			}
		}
		
		case ClassType_LogicCase:
		{
			if (inputType == InputType_Kill)
			{
				if (!isTrap)
				{
					return;
				}
				
				DeactivateTrapChildren(entity, TRAP_CHILD_IN_PROXIMITY);
				ActivateTrapChildren(entity, trapInfo.activatorId, TRAP_CHILD_IN_BREAKABLES_ON_KILL);
				
				g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
			}
			else if (inputType == InputType_InValue || inputType == InputType_PickRandom || inputType == InputType_PickRandomShuffle)
			{
				if (view_as<bool>(trapInfo.flags & TRAP_IS_ACTIVATED))
				{
					if (!isTrap)
					{
						trapInfo.flags &= ~TRAP_IS_ACTIVATED;
						trapInfo.flags &= ~TRAP_LISTEN_TO_OUTPUTS;
					}
				}
				else
				{
					if (!isTrap)
					{
						return;
					}
					
					if (!view_as<bool>(trapInfo.flags & TRAP_HAS_SPAWN_DATA_SET))
					{
						trapInfo.flags |= TRAP_HAS_SPAWN_DATA_SET;
					}
					
					if (!view_as<bool>(trapInfo.configFlags & TRAP_IGNORE_OUTPUTS))
					{
						trapInfo.flags |= TRAP_LISTEN_TO_OUTPUTS;
					}
					
					trapInfo.flags |= TRAP_IS_ACTIVATED;
				}
				
				g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
			}
		}
		
		case ClassType_LogicCompare:
		{
			if (inputType == InputType_Kill)
			{
				if (!isTrap)
				{
					return;
				}
				
				DeactivateTrapChildren(entity, TRAP_CHILD_IN_PROXIMITY);
				ActivateTrapChildren(entity, trapInfo.activatorId, TRAP_CHILD_IN_BREAKABLES_ON_KILL);
				
				g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
			}
			else if (inputType == InputType_Compare)
			{
				if (view_as<bool>(trapInfo.flags & TRAP_IS_ACTIVATED))
				{
					if (!isTrap)
					{
						trapInfo.flags &= ~TRAP_IS_ACTIVATED;
						trapInfo.flags &= ~TRAP_LISTEN_TO_OUTPUTS;
					}
				}
				else
				{
					if (!isTrap)
					{
						return;
					}
					
					if (!view_as<bool>(trapInfo.flags & TRAP_HAS_SPAWN_DATA_SET))
					{
						trapInfo.flags |= TRAP_HAS_SPAWN_DATA_SET;
					}
					
					if (!view_as<bool>(trapInfo.configFlags & TRAP_IGNORE_OUTPUTS))
					{
						trapInfo.flags |= TRAP_LISTEN_TO_OUTPUTS;
					}
					
					trapInfo.flags |= TRAP_IS_ACTIVATED;
				}
				
				g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
			}
		}
		
		case ClassType_LogicRelay:
		{
			if (inputType == InputType_Kill)
			{
				if (!isTrap)
				{
					return;
				}
				
				DeactivateTrapChildren(entity, TRAP_CHILD_IN_PROXIMITY);
				ActivateTrapChildren(entity, trapInfo.activatorId, TRAP_CHILD_IN_BREAKABLES_ON_KILL);
				
				g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
			}
			else if (inputType == InputType_Trigger)
			{
				if (!IsEntityEnabled(entity, trapInfo.classType))
				{
					return;
				}
				
				if (view_as<bool>(trapInfo.flags & TRAP_IS_ACTIVATED))
				{
					if (!isTrap)
					{
						trapInfo.flags &= ~TRAP_IS_ACTIVATED;
						trapInfo.flags &= ~TRAP_LISTEN_TO_OUTPUTS;
					}
				}
				else
				{
					if (!isTrap)
					{
						return;
					}
					
					if (!view_as<bool>(trapInfo.flags & TRAP_HAS_SPAWN_DATA_SET))
					{
						trapInfo.flags |= TRAP_HAS_SPAWN_DATA_SET;
					}
					
					if (!view_as<bool>(trapInfo.configFlags & TRAP_IGNORE_OUTPUTS))
					{
						trapInfo.flags |= TRAP_LISTEN_TO_OUTPUTS;
					}
					
					trapInfo.flags |= TRAP_IS_ACTIVATED;
				}
				
				g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
			}
		}
		
		case ClassType_LogicTimer:
		{
			bool isEntityEnabled = IsEntityEnabled(entity, trapInfo.classType);
			if (inputType == InputType_Toggle)
			{
				inputType = isEntityEnabled ? InputType_Disable : InputType_Enable;
			}
			
			if (inputType == InputType_Kill)
			{
				if (!isTrap)
				{
					return;
				}
				
				DeactivateTrapChildren(entity, TRAP_CHILD_IN_PROXIMITY);
				ActivateTrapChildren(entity, trapInfo.activatorId, TRAP_CHILD_IN_BREAKABLES_ON_KILL);
				
				g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
			}
			else if (inputType == InputType_Enable)
			{
				if (isEntityEnabled)
				{
					return;
				}
				
				if (view_as<bool>(trapInfo.flags & TRAP_IS_ACTIVATED))
				{
					if (view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
					{
						trapInfo.flags &= ~TRAP_IS_ACTIVATED;
					}
				}
				else
				{
					if (!isTrap)
					{
						return;
					}
					
					if (view_as<bool>(trapInfo.flags & TRAP_HAS_SPAWN_DATA_SET))
					{
						if (view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
						{
							return;
						}
					}
					else
					{
						trapInfo.flags |= TRAP_HAS_SPAWN_DATA_SET;
					}
					
					if (!view_as<bool>(trapInfo.configFlags & TRAP_IGNORE_OUTPUTS))
					{
						trapInfo.flags |= TRAP_LISTEN_TO_OUTPUTS;
					}
					
					trapInfo.flags |= TRAP_IS_ACTIVATED;
				}
				
				g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
			}
			else if (inputType == InputType_Disable)
			{
				if (!isEntityEnabled)
				{
					return;
				}
				
				if (view_as<bool>(trapInfo.flags & TRAP_IS_ACTIVATED))
				{
					if (!view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
					{
						trapInfo.flags &= ~TRAP_IS_ACTIVATED;
						trapInfo.flags &= ~TRAP_LISTEN_TO_OUTPUTS;
					}
				}
				else
				{
					if (!isTrap)
					{
						return;
					}
					
					if (view_as<bool>(trapInfo.flags & TRAP_HAS_SPAWN_DATA_SET))
					{
						if (!view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
						{
							return;
						}
					}
					else
					{
						trapInfo.configFlags |= TRAP_SPAWN_ENABLED;
						trapInfo.flags |= TRAP_HAS_SPAWN_DATA_SET;
					}
					
					trapInfo.flags |= TRAP_IS_ACTIVATED;
				}
				
				g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
			}
		}
		
		case ClassType_MathCounter:
		{
			if (inputType == InputType_Kill)
			{
				if (!isTrap)
				{
					return;
				}
				
				DeactivateTrapChildren(entity, TRAP_CHILD_IN_PROXIMITY);
				ActivateTrapChildren(entity, trapInfo.activatorId, TRAP_CHILD_IN_BREAKABLES_ON_KILL);
				
				g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
			}
			else if (inputType == InputType_Add 
				|| inputType == InputType_Divide 
				|| inputType == InputType_Multiply 
				|| inputType == InputType_SetValue 
				|| inputType == InputType_Subtract 
				|| inputType == InputType_SetHitMax 
				|| inputType == InputType_SetHitMin)
			{
				if (g_Cvar_DebugModeEnable.BoolValue)
				{
					PrintToServer("Math_Counter :: Input");
				}
				
				if (!IsEntityEnabled(entity, trapInfo.classType))
				{
					return;
				}
				
				if (g_Cvar_DebugModeEnable.BoolValue)
				{
					PrintToServer("Math_Counter :: Enabled");
				}
				
				if (view_as<bool>(trapInfo.flags & TRAP_IS_ACTIVATED))
				{
					if (g_Cvar_DebugModeEnable.BoolValue)
					{
						PrintToServer("Math_Counter :: Disable trap");
					}
					
					if (!isTrap)
					{
						trapInfo.flags &= ~TRAP_IS_ACTIVATED;
						trapInfo.flags &= ~TRAP_LISTEN_TO_OUTPUTS;
					}
				}
				else
				{
					if (!isTrap)
					{
						return;
					}
					
					if (!view_as<bool>(trapInfo.flags & TRAP_HAS_SPAWN_DATA_SET))
					{
						trapInfo.flags |= TRAP_HAS_SPAWN_DATA_SET;
					}
					
					if (!view_as<bool>(trapInfo.configFlags & TRAP_IGNORE_OUTPUTS))
					{
						trapInfo.flags |= TRAP_LISTEN_TO_OUTPUTS;
					}
					
					trapInfo.flags |= TRAP_IS_ACTIVATED;
					
					if (g_Cvar_DebugModeEnable.BoolValue)
					{
						PrintToServer("Math_Counter :: Enable trap");
					}
				}
				
				g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
			}
		}
		
		case ClassType_PointTemplate:
		{
			if (inputType == InputType_Kill)
			{
				if (!isTrap)
				{
					return;
				}
				
				DeactivateTrapChildren(entity, TRAP_CHILD_IN_PROXIMITY);
				ActivateTrapChildren(entity, trapInfo.activatorId, TRAP_CHILD_IN_BREAKABLES_ON_KILL);
				
				g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
			}
			else if (inputType == InputType_ForceSpawn)
			{
				if (!isTrap)
				{
					return;
				}
				
				if (!view_as<bool>(trapInfo.flags & TRAP_HAS_SPAWN_DATA_SET))
				{
					trapInfo.flags |= TRAP_HAS_SPAWN_DATA_SET;
				}
				
				if (!view_as<bool>(trapInfo.configFlags & TRAP_IGNORE_OUTPUTS))
				{
					trapInfo.flags |= TRAP_LISTEN_TO_OUTPUTS;
				}
				
				trapInfo.flags |= TRAP_IS_ACTIVATED;
				g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
			}
		}
		
		case ClassType_TriggerHurt:
		{
			bool isEntityEnabled = IsEntityEnabled(entity, trapInfo.classType);
			if (inputType == InputType_Toggle)
			{
				inputType = isEntityEnabled ? InputType_Disable : InputType_Enable;
			}
			
			if (inputType == InputType_Kill)
			{
				if (!isTrap)
				{
					return;
				}
				
				RemoveEntityFromProximity(entity, trapInfo, TRAP_IN_PROXIMITY | TRAP_CHILD_IN_PROXIMITY);
				DeactivateTrapChildren(entity, TRAP_CHILD_IN_PROXIMITY);
				
				if (!view_as<bool>(trapInfo.flags & TRAP_IS_TEMPLATE))
				{
					if (CanPlayersTouchEntity(entity, classType) 
						&& CanEntityHealClients(entity, trapInfo.classType))
					{
						if (view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED) 
							|| !view_as<bool>(trapInfo.flags & TRAP_IS_ACTIVATED) && isEntityEnabled)
						{
							AddEntityInBreakables(entity, trapInfo, TRAP_IN_BREAKABLES_ON_KILL);
						}
					}
					
					ActivateTrapChildren(entity, trapInfo.activatorId, TRAP_CHILD_IN_BREAKABLES_ON_KILL);
				}
				
				g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
			}
			else if (inputType == InputType_Enable)
			{
				if (isEntityEnabled)
				{
					return;
				}
				
				if (view_as<bool>(trapInfo.flags & TRAP_IS_ACTIVATED))
				{
					if (view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
					{
						trapInfo.flags &= ~TRAP_IS_ACTIVATED;						
						RemoveEntityFromBreakables(entity, trapInfo, TRAP_IN_BREAKABLES_ON_KILL);
						
						if (view_as<bool>(trapInfo.flags & TRAP_IS_CHILD))
						{
							AddEntityInProximity(reference, trapInfo, TRAP_CHILD_IN_PROXIMITY);
						}
					}
				}
				else
				{
					if (!isTrap)
					{
						return;
					}
					
					if (view_as<bool>(trapInfo.flags & TRAP_HAS_SPAWN_DATA_SET))
					{
						if (view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
						{
							return;
						}
					}
					else
					{
						trapInfo.flags |= TRAP_HAS_SPAWN_DATA_SET;
					}
					
					if (!view_as<bool>(trapInfo.configFlags & TRAP_IGNORE_OUTPUTS))
					{
						trapInfo.flags |= TRAP_LISTEN_TO_OUTPUTS;
					}
					
					trapInfo.flags |= TRAP_IS_ACTIVATED;
					
					if (CanPlayersTouchEntity(entity, classType) && CanEntityDamageClients(entity, trapInfo.classType))
					{
						AddEntityInProximity(reference, trapInfo, TRAP_IN_PROXIMITY);
					}
				}
				
				g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
			}
			else if (inputType == InputType_Disable)
			{
				if (!isEntityEnabled)
				{
					return;
				}
				
				if (view_as<bool>(trapInfo.flags & TRAP_IS_ACTIVATED))
				{
					if (!view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
					{
						trapInfo.flags &= ~TRAP_IS_ACTIVATED;
						if (!isTrap)
						{
							trapInfo.flags &= ~TRAP_LISTEN_TO_OUTPUTS;
						}
						
						RemoveEntityFromProximity(entity, trapInfo, TRAP_IN_PROXIMITY | TRAP_CHILD_IN_PROXIMITY);
					}
				}
				else if (!isTrap)
				{
					if (!view_as<bool>(trapInfo.flags & TRAP_HAS_SPAWN_DATA_SET))
					{
						return;
					}
					
					trapInfo.flags &= ~TRAP_LISTEN_TO_OUTPUTS;
				}
				else
				{
					if (view_as<bool>(trapInfo.flags & TRAP_HAS_SPAWN_DATA_SET))
					{
						if (!view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
						{
							return;
						}
					}
					else
					{
						trapInfo.configFlags |= TRAP_SPAWN_ENABLED;
						trapInfo.flags |= TRAP_HAS_SPAWN_DATA_SET;
					}
					
					trapInfo.flags |= TRAP_IS_ACTIVATED;
					
					if (view_as<bool>(trapInfo.flags & TRAP_IS_CHILD))
					{
						RemoveEntityFromProximity(entity, trapInfo, TRAP_CHILD_IN_PROXIMITY);
					}
					
					if (CanPlayersTouchEntity(entity, classType) && CanEntityHealClients(entity, trapInfo.classType))
					{
						AddEntityInBreakables(entity, trapInfo, TRAP_IN_BREAKABLES_ON_KILL);
					}
				}
				
				g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
			}
		}
		
		case ClassType_TriggerMultiple, ClassType_TriggerOnce:
		{
			bool isEntityEnabled = IsEntityEnabled(entity, trapInfo.classType);
			if (inputType == InputType_Toggle)
			{
				inputType = isEntityEnabled ? InputType_Disable : InputType_Enable;
			}
			
			if (inputType == InputType_Kill)
			{
				if (!isTrap)
				{
					return;
				}
				
				DeactivateTrapChildren(entity, TRAP_CHILD_IN_PROXIMITY);
				ActivateTrapChildren(entity, trapInfo.activatorId, TRAP_CHILD_IN_BREAKABLES_ON_KILL);
				
				g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
			}
			else if (inputType == InputType_Enable)
			{
				if (isEntityEnabled)
				{
					return;
				}
				
				if (view_as<bool>(trapInfo.flags & TRAP_IS_ACTIVATED))
				{
					if (view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
					{
						trapInfo.flags &= ~TRAP_IS_ACTIVATED;
					}
				}
				else
				{
					if (!isTrap)
					{
						return;
					}
					
					if (view_as<bool>(trapInfo.flags & TRAP_HAS_SPAWN_DATA_SET))
					{
						if (view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
						{
							return;
						}
					}
					else
					{
						trapInfo.flags |= TRAP_HAS_SPAWN_DATA_SET;
					}
					
					if (!view_as<bool>(trapInfo.configFlags & TRAP_IGNORE_OUTPUTS))
					{
						trapInfo.flags |= TRAP_LISTEN_TO_OUTPUTS;
					}
					
					trapInfo.flags |= TRAP_IS_ACTIVATED;
				}
				
				g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
			}
			else if (inputType == InputType_Disable)
			{
				if (!isEntityEnabled)
				{
					return;
				}
				
				if (view_as<bool>(trapInfo.flags & TRAP_IS_ACTIVATED))
				{
					if (!view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
					{
						trapInfo.flags &= ~TRAP_IS_ACTIVATED;
						if (!isTrap)
						{
							trapInfo.flags &= ~TRAP_LISTEN_TO_OUTPUTS;
						}
					}
				}
				else if (!isTrap)
				{
					if (!view_as<bool>(trapInfo.flags & TRAP_HAS_SPAWN_DATA_SET))
					{
						return;
					}
					
					trapInfo.flags &= ~TRAP_LISTEN_TO_OUTPUTS;
				}
				else
				{
					if (view_as<bool>(trapInfo.flags & TRAP_HAS_SPAWN_DATA_SET))
					{
						if (!view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
						{
							return;
						}
					}
					else
					{
						trapInfo.configFlags |= TRAP_SPAWN_ENABLED;
						trapInfo.flags |= TRAP_HAS_SPAWN_DATA_SET;
					}
					
					trapInfo.flags |= TRAP_IS_ACTIVATED;
				}
				
				g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
			}
		}
		
		case ClassType_TriggerPush, ClassType_TriggerTeleport:
		{
			bool isEntityEnabled = IsEntityEnabled(entity, trapInfo.classType);
			if (inputType == InputType_Toggle)
			{
				inputType = isEntityEnabled ? InputType_Disable : InputType_Enable;
			}
			
			if (inputType == InputType_Kill)
			{
				if (!isTrap)
				{
					return;
				}
				
				RemoveEntityFromProximity(entity, trapInfo, TRAP_IN_PROXIMITY | TRAP_CHILD_IN_PROXIMITY);
				DeactivateTrapChildren(entity, TRAP_CHILD_IN_PROXIMITY);
				
				if (!view_as<bool>(trapInfo.flags & TRAP_IS_TEMPLATE))
				{
					if (CanPlayersTouchEntity(entity, classType) 
						&& (trapInfo.classType == ClassType_TriggerPush || HasEntityValidDestination(entity)))
					{
						if (view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED) 
							|| !view_as<bool>(trapInfo.flags & TRAP_IS_ACTIVATED) && isEntityEnabled)
						{
							AddEntityInBreakables(entity, trapInfo, TRAP_IN_BREAKABLES_ON_KILL);
						}
					}
					
					ActivateTrapChildren(entity, trapInfo.activatorId, TRAP_CHILD_IN_BREAKABLES_ON_KILL);
				}
				
				g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
			}
			else if (inputType == InputType_Enable)
			{
				if (isEntityEnabled)
				{
					return;
				}
				
				if (view_as<bool>(trapInfo.flags & TRAP_IS_ACTIVATED))
				{
					if (view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
					{
						trapInfo.flags &= ~TRAP_IS_ACTIVATED;
						RemoveEntityFromBreakables(entity, trapInfo, TRAP_IN_BREAKABLES_ON_KILL);
						
						if (view_as<bool>(trapInfo.flags & TRAP_IS_CHILD))
						{
							AddEntityInProximity(reference, trapInfo, TRAP_CHILD_IN_PROXIMITY);
						}
					}
				}
				else
				{
					if (!isTrap)
					{
						return;
					}
					
					if (view_as<bool>(trapInfo.flags & TRAP_HAS_SPAWN_DATA_SET))
					{
						if (view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
						{
							return;
						}
					}
					else
					{
						trapInfo.flags |= TRAP_HAS_SPAWN_DATA_SET;
					}
					
					if (!view_as<bool>(trapInfo.configFlags & TRAP_IGNORE_OUTPUTS))
					{
						trapInfo.flags |= TRAP_LISTEN_TO_OUTPUTS;
					}
					
					trapInfo.flags |= TRAP_IS_ACTIVATED;
					
					if (CanPlayersTouchEntity(entity, classType))
					{
						AddEntityInProximity(reference, trapInfo, TRAP_IN_PROXIMITY);
					}
				}
				
				g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
			}
			else if (inputType == InputType_Disable)
			{
				if (!isEntityEnabled)
				{
					return;
				}
				
				if (view_as<bool>(trapInfo.flags & TRAP_IS_ACTIVATED))
				{
					if (!view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
					{
						trapInfo.flags &= ~TRAP_IS_ACTIVATED;
						if (!isTrap)
						{
							trapInfo.flags &= ~TRAP_LISTEN_TO_OUTPUTS;
						}
						
						RemoveEntityFromProximity(entity, trapInfo, TRAP_IN_PROXIMITY | TRAP_CHILD_IN_PROXIMITY);
					}
				}
				else if (!isTrap)
				{
					if (!view_as<bool>(trapInfo.flags & TRAP_HAS_SPAWN_DATA_SET))
					{
						return;
					}
					
					trapInfo.flags &= ~TRAP_LISTEN_TO_OUTPUTS;
				}
				else
				{
					if (view_as<bool>(trapInfo.flags & TRAP_HAS_SPAWN_DATA_SET))
					{
						if (!view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED))
						{
							return;
						}
					}
					else
					{
						trapInfo.configFlags |= TRAP_SPAWN_ENABLED;
						trapInfo.flags |= TRAP_HAS_SPAWN_DATA_SET;
					}
					
					trapInfo.flags |= TRAP_IS_ACTIVATED;
					
					if (view_as<bool>(trapInfo.flags & TRAP_IS_CHILD))
					{
						RemoveEntityFromProximity(entity, trapInfo, TRAP_CHILD_IN_PROXIMITY);
					}
					
					if (CanPlayersTouchEntity(entity, classType) 
						&& (trapInfo.classType == ClassType_TriggerPush || HasEntityValidDestination(entity)))
					{
						AddEntityInBreakables(entity, trapInfo, TRAP_IN_BREAKABLES_ON_KILL);
					}
				}
				
				g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
			}
		}
	}
}

void OnTemplateSpawned(int entity, bool isTrap, int activatorId)
{
	char buffer[256];
	char templateName[256];
	
	for (int i = 0; i < 16; i++)
	{
		FormatEx(buffer, sizeof(buffer), "m_iszTemplateEntityNames[%d]", i);
		GetEntPropString(entity, Prop_Data, buffer, templateName, sizeof(templateName)); 
		
		if (!templateName[0])
		{
			continue;
		}
		
		StringToLower(templateName);
		
		int ent = -1;
		while ((ent = FindEntityByName(ent, templateName)) != -1)
		{
			OnTemplateEntitySpawned(ent, isTrap, activatorId);
		}
	}
}

void OnTemplateEntitySpawned(int entity, bool spawnedByTrap, int activatorId)
{
	char className[256];
	GetEntityClassname(entity, className, sizeof(className));
	
	ClassType classType;
	if (!g_Map_ClassNames.GetValue(className, classType))
	{
		return;
	}
	
	bool removeFromBreakables;
	int hammerId = GetEntProp(entity, Prop_Data, "m_iHammerID");
	
	if (RemoveEntityHammerIDFromBreakables(hammerId, g_Map_BreakablesOnKill, g_List_BreakablesOnKill))
	{
		removeFromBreakables = true;
	}
	
	if (RemoveEntityHammerIDFromBreakables(hammerId, g_Map_BreakablesOnMove, g_List_BreakablesOnMove))
	{
		removeFromBreakables = true;
	}
	
	if (RemoveEntityHammerIDFromBreakables(hammerId, g_Map_BreakablesOnFirstMove, g_List_BreakablesOnFirstMove))
	{
		removeFromBreakables = true;
	}
	
	if (RemoveReplacedEntitiesFromBreakables(entity) || removeFromBreakables || !spawnedByTrap)
	{
		return;
	}
	
	TrapInfo trapInfo;
	int reference = EntIndexToEntRef_Ex(entity);
	
	trapInfo.classType = classType;
	trapInfo.activatorId = activatorId;
	
	trapInfo.flags |= TRAP_IS_ACTIVATED;
	trapInfo.flags |= TRAP_IS_TEMPLATE;
	trapInfo.flags |= TRAP_HAS_SPAWN_DATA_SET;
	trapInfo.flags |= TRAP_HAS_CONFIG_FLAGS_SET;
	
	if (!view_as<bool>(trapInfo.configFlags & TRAP_IGNORE_OUTPUTS))
	{
		trapInfo.flags |= TRAP_LISTEN_TO_OUTPUTS;
	}
	
	GetEntityTrapFlags(entity, trapInfo.configFlags);
	
	switch (classType)
	{
		case ClassType_LogicTimer, ClassType_TriggerMultiple, ClassType_TriggerOnce:
		{
			if (!IsEntityEnabled(entity, trapInfo.classType))
			{
				return;
			}
			
			trapInfo.configFlags |= TRAP_SPAWN_ENABLED;
		}
		
		case ClassType_TriggerHurt:
		{
			if (!IsEntityEnabled(entity, trapInfo.classType))
			{
				return;
			}
			
			trapInfo.configFlags |= TRAP_SPAWN_ENABLED;
			
			if (!view_as<bool>(trapInfo.configFlags & TRAP_IGNORE_PROXIMITY_FROM_TEMPLATE) 
				&& CanPlayersTouchEntity(entity, classType) 
				&& CanEntityDamageClients(entity, trapInfo.classType))
			{
				AddEntityInProximity(reference, trapInfo, TRAP_IN_PROXIMITY);
			}
		}
		
		case ClassType_TriggerPush:
		{
			if (!IsEntityEnabled(entity, trapInfo.classType))
			{
				return;
			}
			
			trapInfo.configFlags |= TRAP_SPAWN_ENABLED;
			
			if (!view_as<bool>(trapInfo.configFlags & TRAP_IGNORE_PROXIMITY_FROM_TEMPLATE) 
				&& CanPlayersTouchEntity(entity, classType))
			{
				AddEntityInProximity(reference, trapInfo, TRAP_IN_PROXIMITY);
			}
		}
		
		case ClassType_TriggerTeleport:
		{
			if (!IsEntityEnabled(entity, trapInfo.classType))
			{
				return;
			}
			
			trapInfo.configFlags |= TRAP_SPAWN_ENABLED;
			
			if (!view_as<bool>(trapInfo.configFlags & TRAP_IGNORE_PROXIMITY_FROM_TEMPLATE) 
				&& CanPlayersTouchEntity(entity, classType) 
				&& HasEntityValidDestination(entity))
			{
				AddEntityInProximity(reference, trapInfo, TRAP_IN_PROXIMITY);
			}
		}
				
		case ClassType_EnvBeam, 
			ClassType_EnvFire, 
			ClassType_EnvGunFire, 
			ClassType_EnvLaser, 
			ClassType_EnvSmokeStack:
		{
			if (!IsEntityEnabled(entity, trapInfo.classType))
			{
				return;
			}
			
			trapInfo.configFlags |= TRAP_SPAWN_ENABLED;
			
			if (!view_as<bool>(trapInfo.configFlags & TRAP_IGNORE_PROXIMITY_FROM_TEMPLATE))
			{
				AddEntityInProximity(reference, trapInfo, TRAP_IN_PROXIMITY);
			}
		}
		
		case ClassType_FuncBrush, ClassType_FuncWallToggle:
		{
			if (!IsEntitySolid(entity) || !CanPlayersTouchEntity(entity, classType))
			{
				return;
			}
			
			trapInfo.configFlags |= TRAP_SPAWN_ENABLED;
			
			if (!view_as<bool>(trapInfo.configFlags & TRAP_IGNORE_PROXIMITY_FROM_TEMPLATE))
			{
				AddEntityInProximity(reference, trapInfo, TRAP_IN_PROXIMITY);
			}
		}
		
		case ClassType_FuncBreakable, 
			ClassType_FuncDoor, 
			ClassType_FuncDoorRotating, 
			ClassType_FuncMoveLinear, 
			ClassType_FuncPhysBox, 
			ClassType_FuncRotating, 
			ClassType_FuncTrain, 
			ClassType_FuncTankTrain, 
			ClassType_FuncTrackTrain, 
			ClassType_FuncWall, 
			ClassType_FuncWaterAnalog, 
			ClassType_PropDynamic, 
			ClassType_PropPhysics:
		{
			if (!view_as<bool>(trapInfo.configFlags & TRAP_IGNORE_PROXIMITY_FROM_TEMPLATE) 
				&& IsEntitySolid(entity) 
				&& CanPlayersTouchEntity(entity, classType))
			{
				AddEntityInProximity(reference, trapInfo, TRAP_IN_PROXIMITY);
			}
		}
		
		default:
		{
			return;
		}
	}
	
	g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
}

void OnMapFinishedByAllCTs(int numFinishers)
{
	int currentTerrorist = GetTerrorist();
	if (currentTerrorist && IsPlayerAlive(currentTerrorist))
	{
		if (numFinishers > 1 || g_Cvar_RoundTimeLastFinished.IntValue < 1)
		{
			if (g_Cvar_RoundTimeAllFinished.IntValue > 0 && ChangeRoundTimeLeft(g_Cvar_RoundTimeAllFinished.IntValue))
			{
				CPrintToChatAll("\x04[Deathrun]\x01 This round will end in\x07 %02d:%02d.", g_Cvar_RoundTimeAllFinished.IntValue / 60, g_Cvar_RoundTimeAllFinished.IntValue % 60);
			}
		}
		else
		{
			if (g_Cvar_RoundTimeLastFinished.IntValue > 0 && ChangeRoundTimeLeft(g_Cvar_RoundTimeLastFinished.IntValue))
			{
				CPrintToChatAll("\x04[Deathrun]\x01 This round will end in\x07 %02d:%02d.", g_Cvar_RoundTimeLastFinished.IntValue / 60, g_Cvar_RoundTimeLastFinished.IntValue % 60);
			}
		}
	}
	else
	{
		if (g_Cvar_DebugModeEnable.BoolValue)
		{
			PrintToChatAll("All players finished, end round.");
		}
		else
		{
			IncreaseTeamScore(CS_TEAM_CT);
			CS_TerminateRound(g_Cvar_RoundRestartDelay ? g_Cvar_RoundRestartDelay.FloatValue : 3.0, CSRoundEnd_CTWin, true);
		}
	}
}

void FindNextTerroristKiller()
{
	int terroristKiller = GetNextTerroristKiller();
	if (terroristKiller)
	{
		g_TerroristKillerId = GetClientUserId(terroristKiller);
		
		char terroristKillerName[MAX_NAME_LENGTH];
		GetClientName_Ex(terroristKiller, terroristKillerName, sizeof(terroristKillerName));

		CPrintToChatAll_Ex(terroristKiller, false, "\x04[Deathrun]\x03 %s\x04 [#%d]\x01 is now the\x0B Terrorist Killer.", terroristKillerName, g_FinishInfo[terroristKiller].finishPos);

		FadeScreen(terroristKiller, 0.5, 0.0, 114, 155, 221, 160);
		PlaySoundToClient(terroristKiller, "ui/armsrace_become_leader_team.wav");

		if (!g_RemoveProtectionTime[terroristKiller])
		{
			SetEntityGlow(terroristKiller, 114, 155, 221, 255);
			SetEntityRenderColor(terroristKiller, 114, 155, 221, 255);
		}

		if (view_as<bool>(g_RoundFlags & ROUND_END_CHOSEN) 
			&& view_as<bool>(g_CurrentEndInfo.flags & END_TERRORIST_KILLER_SPEED))
		{
			g_SpeedInfo[terroristKiller].speedType = SpeedType_Normal;
			g_SpeedInfo[terroristKiller].maxSpeedType = SpeedType_x3;
			
			CPrintToChatAll_Ex(terroristKiller, false, "\x04[Deathrun]\x03 %s\x01 can use\x04 [x%d]\x01 speed.", terroristKillerName, view_as<int>(g_SpeedInfo[terroristKiller].maxSpeedType));
		}
		
		int currentTerrorist = GetTerrorist();					
		if (currentTerrorist && IsPlayerAlive(currentTerrorist))
		{
			DisplayDuelHudToAll(currentTerrorist, terroristKiller);
		}
		else
		{
			HideDuelHudFromAll();
		}
	}
	else
	{
		g_TerroristKillerId = 0;
		HideDuelHudFromAll();
	}
}

void FindEnvFiresourceTargets(int entity, InputType inputType, int activatorId)
{
	float origin[3];
	float radius = GetEntPropFloat(entity, Prop_Data, "m_radius");
	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", origin);
	
	int ent = -1;
	while ((ent = FindEntityByClassname(ent, "env_fire")) != -1)
	{
		float fireOrigin[3];
		GetEntPropVector(ent, Prop_Data, "m_vecAbsOrigin", fireOrigin);
		
		if (GetVectorDistance(origin, fireOrigin) > radius)
		{
			continue;
		}
		
		TrapInfo trapInfo;
		int reference = EntIndexToEntRef_Ex(ent);
		
		if (g_Map_Traps.GetArray(reference, trapInfo, sizeof(TrapInfo)) 
			&& view_as<bool>(trapInfo.flags & TRAP_IS_ACTIVATED))
		{
			continue;
		}
		
		trapInfo.activatorId = activatorId;
		
		if (!view_as<bool>(trapInfo.flags & TRAP_HAS_SPAWN_DATA_SET))
		{
			trapInfo.classType = ClassType_EnvFire;
			GetEntityTrapFlags(ent, trapInfo.configFlags);
			trapInfo.flags |= TRAP_HAS_SPAWN_DATA_SET;
		}
		
		if (inputType == InputType_Enable)
		{
			if (IsEntityEnabled(ent, trapInfo.classType) 
				|| !view_as<bool>(GetEntProp(ent, Prop_Data, "m_bEnabled")))
			{
				continue;
			}
			
			if (!view_as<bool>(trapInfo.flags & TRAP_HAS_SPAWN_DATA_SET))
			{
				trapInfo.flags |= TRAP_HAS_SPAWN_DATA_SET;
			}
		}
		else
		{
			if (!IsEntityEnabled(ent, trapInfo.classType))
			{
				continue;
			}
			
			if (!view_as<bool>(trapInfo.flags & TRAP_HAS_SPAWN_DATA_SET))
			{
				trapInfo.configFlags |= TRAP_SPAWN_ENABLED;
				trapInfo.flags |= TRAP_HAS_SPAWN_DATA_SET;
			}
		}
		
		if (!view_as<bool>(trapInfo.configFlags & TRAP_IGNORE_OUTPUTS))
		{
			trapInfo.flags |= TRAP_LISTEN_TO_OUTPUTS;
		}
		
		g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
	}
}

void FindEnvShakeTargets(int entity, int activatorId)
{
	float vecOrigin[3];			
	float gameTime = GetGameTime();
	float duration = GetEntPropFloat(entity, Prop_Data, "m_Duration");
	float radius = GetEntPropFloat(entity, Prop_Data, "m_Radius");
	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vecOrigin);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
		{
			continue;
		}
		
		float clientOrigin[3];
		GetEntPropVector(i, Prop_Data, "m_vecAbsOrigin", clientOrigin);
		
		if (radius && GetVectorDistance(vecOrigin, clientOrigin) > radius)
		{
			continue;
		}
		
		g_ShakeInfo[i].activatorId = activatorId;
		g_ShakeInfo[i].shakeTime = gameTime + duration;
	}
}

void GetMiddleOfAxis(float& vecMins, float& vecMaxs, float& vecOrigin)
{
	float middle = (vecMaxs - vecMins) / 2.0;
	vecOrigin = vecMins + middle;
	
	vecMins = middle;
	if (vecMins > 0.0)
	{
		vecMins *= -1.0;
	}
	
	vecMaxs = middle;
	if (vecMaxs < 0.0)
	{
		vecMaxs *= -1.0;
	}
}

void GetMiddleOfBox(float vecMins[3], float vecMaxs[3], float vecOrigin[3])
{
	GetMiddleOfAxis(vecMins[0], vecMaxs[0], vecOrigin[0]);
	GetMiddleOfAxis(vecMins[1], vecMaxs[1], vecOrigin[1]);
	GetMiddleOfAxis(vecMins[2], vecMaxs[2], vecOrigin[2]);
}

void SetConVar(const char[] cvarName, const char[] value)
{
	ConVar cvar = FindConVar(cvarName);
	if (cvar)
	{
		cvar.SetString(value);
	}
}

void StringToLower(char[] buffer)
{
	for (int i = 0; buffer[i]; i++)
	{
		buffer[i] = CharToLower(buffer[i]);
	}
}

void SetUpperBound(any& value, any limit)
{
	if (value > limit)
	{
		value = limit;
	}
}

void SetLowerBound(any& value, any limit)
{
	if (value < limit)
	{
		value = limit;
	}
}

void AddEntityInRemoveList(RemoveEntityInfo removeEntity)
{
	if (!g_List_RemoveEntities.Length)
	{
		g_List_RemoveEntities.PushArray(removeEntity);
		return;
	}
	
	RemoveEntityInfo removeEntityInfo;
	for (int j = g_List_RemoveEntities.Length - 1; j >= 0; j--)
	{
		g_List_RemoveEntities.GetArray(j, removeEntityInfo);
		if (removeEntity.removeTime > removeEntityInfo.removeTime)
		{
			continue;
		}
		
		if (j != g_List_RemoveEntities.Length - 1)
		{
			g_List_RemoveEntities.ShiftUp(j + 1);
			g_List_RemoveEntities.SetArray(j + 1, removeEntity);
		}
		else
		{
			g_List_RemoveEntities.PushArray(removeEntity);
		}
		
		return;
	}
	
	g_List_RemoveEntities.ShiftUp(0);
	g_List_RemoveEntities.SetArray(0, removeEntity);
}

void TransferClientLife(int client, int target)
{
	float vecOrigin[3];
	float vecAngles[3];
	
	GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", vecOrigin);
	GetClientEyeAngles(client, vecAngles);
	
	CS_RespawnPlayer(target);
	g_PlayerFlags[target] |= PLAYER_HAS_RECEIVED_LIFE;
	
	if (g_Cvar_LifeTransferDelay.FloatValue > 0.0)
	{
		g_LifeTransferDelay[target] = GetGameTime() + g_Cvar_LifeTransferDelay.FloatValue;
	}
	
	RemoveClientProtection(target);
	SetEntityHealth(target, GetClientHealth(client));
	
	TeleportEntity(target, vecOrigin, vecAngles, view_as<float>({0.0, 0.0, 0.0}));
	PlayAmbientSound("player/pl_respawn.wav", vecOrigin);
	
	g_KillFeedType[client] = KillFeedType_LifeTransfer;
	ForcePlayerSuicide(client);
	
	char clientName[MAX_NAME_LENGTH];
	char targetName[MAX_NAME_LENGTH];
	
	GetClientName_Ex(client, clientName, sizeof(clientName));
	GetClientName_Ex(target, targetName, sizeof(targetName));
	
	CPrintToChatAll_Ex(client, false, "\x04[Deathrun]\x03 %s\x01 transfered his life to\x04 %s.", clientName, targetName);
}

void SetEntityGlow(int entity, int r, int g, int b, int a, int style = GLOW_STYLE_OUTLINE, float distance = 10000.0)
{
	int glow = CreateEntityByName("prop_dynamic");
	if (glow == -1)
	{
		return;
	}
	
	char modelName[PLATFORM_MAX_PATH];
	GetEntPropString(entity, Prop_Data, "m_ModelName", modelName, sizeof(modelName));
	DispatchKeyValue(glow, "model", modelName);
	
	float vecOrigin[3];
	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vecOrigin);
	DispatchKeyValueVector(glow, "origin", vecOrigin);
	
	DispatchKeyValue(glow, "solid", "0");
	DispatchKeyValue(glow, "glowenabled", "1");
	DispatchKeyValue(glow, "spawnflags", "256");
	DispatchKeyValue(glow, "disableshadows", "1");
	DispatchKeyValue(glow, "disablereceiveshadows", "1");
	
	DispatchSpawn(glow);
	ActivateEntity(glow);
	
	SetEntProp(glow, Prop_Data, "m_nGlowStyle", style);
	SetEntPropFloat(glow, Prop_Data, "m_flGlowMaxDist", distance);
	
	int effects = GetEntProp(glow, Prop_Send, "m_fEffects");
	SetEntProp(glow, Prop_Send, "m_fEffects", effects | 641);
	
	int color[4];
	color[0] = r;
	color[1] = g;
	color[2] = b;
	color[3] = a;
	
	SetVariantColor(color);
	AcceptEntityInput(glow, "SetGlowColor");
	
	SetVariantString("!activator");
	AcceptEntityInput(glow, "SetParent", entity);
	
	SetVariantString("primary");
	AcceptEntityInput(glow, "SetParentAttachment");
	
	SetEntPropEnt(glow, Prop_Data, "m_hOwnerEntity", entity);
	g_PlayerGlow[entity] = EntIndexToEntRef(glow);
	
	if (entity > 0 && entity <= MaxClients)
	{
		SDKHook(glow, SDKHook_SetTransmit, SDK_OnGlowTransmit);
	}
}

void RemoveEntityGlow(int entity)
{
	if (g_PlayerGlow[entity] != INVALID_ENT_REFERENCE)
	{
		int glow = EntRefToEntIndex(g_PlayerGlow[entity]);
		if (IsValidEntity(glow))
		{
			RemoveEntity(glow);
		}
	}
	
	g_PlayerGlow[entity] = INVALID_ENT_REFERENCE;
}

void AddEntityInThinkTraps(int reference, TrapInfo trapInfo)
{
	if (view_as<bool>(trapInfo.flags & TRAP_IN_THINK_FUNCTION))
	{
		return;
	}
	
	trapInfo.flags |= TRAP_IN_THINK_FUNCTION;
	trapInfo.flags &= ~TRAP_HAS_MOVED_SINCE_SPAWN;
	
	g_List_ThinkTraps.Push(reference);
}

void RemoveEntityFromThinkTraps(int reference, TrapInfo trapInfo)
{
	if (!view_as<bool>(trapInfo.flags & TRAP_IN_THINK_FUNCTION))
	{
		return;
	}
	
	trapInfo.flags &= ~TRAP_IN_THINK_FUNCTION;
	RemoveCellFromArrayList(reference, g_List_ThinkTraps);
}

void CheckTrapStatus(int entity, int reference, TrapInfo trapInfo)
{
	switch (trapInfo.classType)
	{
		case ClassType_FuncRotating:
		{
			if (IsEntityMoving(entity, trapInfo.classType))
			{
				return;
			}
			
			if (view_as<bool>(trapInfo.configFlags & TRAP_IS_REPLACING_OTHER_TRAPS) 
				|| view_as<bool>(trapInfo.configFlags & TRAP_DISABLE_ON_STOP)
				|| !view_as<bool>(trapInfo.configFlags & TRAP_SPAWN_ENABLED) 
					&& !view_as<bool>(trapInfo.flags & TRAP_IS_TEMPLATE) 
					&& HasEntitySpawnAngles(entity, trapInfo.classType))
			{
				trapInfo.flags &= ~TRAP_IS_ACTIVATED;
				trapInfo.flags &= ~TRAP_LISTEN_TO_OUTPUTS;
				
				RemoveEntityFromProximity(entity, trapInfo, TRAP_IN_PROXIMITY);
				RemoveEntityFromBreakables(entity, trapInfo, TRAP_IN_BREAKABLES_ON_MOVE | TRAP_IN_BREAKABLES_ON_FIRST_MOVE);
				
				DeactivateTrapChildren(entity, TRAP_CHILD_IN_PROXIMITY | TRAP_CHILD_IN_BREAKABLES_ON_MOVE | TRAP_CHILD_IN_BREAKABLES_ON_FIRST_MOVE);
				
				if (view_as<bool>(trapInfo.configFlags & TRAP_IS_REPLACING_OTHER_TRAPS))
				{
					RemoveReplacedEntitiesFromBreakables(entity);
				}
				
				RemoveEntityFromThinkTraps(reference, trapInfo);
				g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
			}
			else if (view_as<bool>(trapInfo.configFlags & TRAP_REMOVE_FROM_PROXIMITY_ON_STOP))
			{
				RemoveEntityFromProximity(entity, trapInfo, TRAP_IN_PROXIMITY);
				DeactivateTrapChildren(entity, TRAP_CHILD_IN_PROXIMITY);
				
				RemoveEntityFromThinkTraps(reference, trapInfo);
				g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
			}
		}
		
		case ClassType_FuncMoveLinear, ClassType_FuncTankTrain, ClassType_FuncTrackTrain, ClassType_FuncTrain, ClassType_FuncWaterAnalog:
		{
			if (view_as<bool>(trapInfo.flags & TRAP_HAS_MOVED_SINCE_SPAWN))
			{
				if (IsEntityMoving(entity, trapInfo.classType))
				{
					return;
				}
				
				if (view_as<bool>(trapInfo.configFlags & TRAP_DISABLE_ON_STOP) 
					|| view_as<bool>(trapInfo.configFlags & TRAP_IS_REPLACING_OTHER_TRAPS)
					|| !view_as<bool>(trapInfo.flags & TRAP_IS_TEMPLATE) 
						&& IsEntityInSpawnPosition(entity, trapInfo.spawnOrigin))
				{
					trapInfo.flags &= ~TRAP_IS_ACTIVATED;
					trapInfo.flags &= ~TRAP_LISTEN_TO_OUTPUTS;
					
					RemoveEntityFromProximity(entity, trapInfo, TRAP_IN_PROXIMITY);
					RemoveEntityFromBreakables(entity, trapInfo, TRAP_IN_BREAKABLES_ON_MOVE | TRAP_IN_BREAKABLES_ON_FIRST_MOVE);
					
					DeactivateTrapChildren(entity, TRAP_CHILD_IN_PROXIMITY | TRAP_CHILD_IN_BREAKABLES_ON_MOVE | TRAP_CHILD_IN_BREAKABLES_ON_FIRST_MOVE);
					
					if (view_as<bool>(trapInfo.configFlags & TRAP_IS_REPLACING_OTHER_TRAPS))
					{
						RemoveReplacedEntitiesFromBreakables(entity);
					}
					
					RemoveEntityFromThinkTraps(reference, trapInfo);
					g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
				}
				else if (view_as<bool>(trapInfo.configFlags & TRAP_REMOVE_FROM_PROXIMITY_ON_STOP))
				{
					RemoveEntityFromProximity(entity, trapInfo, TRAP_IN_PROXIMITY);
					DeactivateTrapChildren(entity, TRAP_CHILD_IN_PROXIMITY);
					
					RemoveEntityFromThinkTraps(reference, trapInfo);
					g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
				}
			}
			else if (IsEntityMoving(entity, trapInfo.classType))
			{
				trapInfo.flags |= TRAP_HAS_MOVED_SINCE_SPAWN;
				g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
			}
		}
	}
}

void ActivateTrapChildren(int entity, int activatorId, int flags)
{
	int child = entity;	
	while ((child = GetEntPropEnt(child, Prop_Data, "m_hMoveChild")) != -1)
	{
		ActivateChild(child, entity, activatorId, flags);
		ActivateTrapChildren(child, activatorId, flags);
		
		int peer = child;
		while ((peer = GetEntPropEnt(peer, Prop_Data, "m_hMovePeer")) != -1)
		{
			ActivateChild(peer, entity, activatorId, flags);
			ActivateTrapChildren(peer, activatorId, flags);
		}
	}
}

void DeactivateTrapChildren(int entity, int flags)
{
	int child = entity;	
	while ((child = GetEntPropEnt(child, Prop_Data, "m_hMoveChild")) != -1)
	{
		DeactivateChild(child, flags);
		DeactivateTrapChildren(child, flags);
		
		int peer = child;
		while ((peer = GetEntPropEnt(peer, Prop_Data, "m_hMovePeer")) != -1)
		{
			DeactivateChild(peer, flags);
			DeactivateTrapChildren(peer, flags);
		}
	}
}

void ActivateChild(int entity, int parent, int activatorId, int flags)
{
	char className[256];
	GetEntityClassname(entity, className, sizeof(className));
	
	ClassType classType;
	if (!g_Map_ClassNames.GetValue(className, classType))
	{
		return;
	}
	
	TrapInfo trapInfo;
	int reference = EntIndexToEntRef_Ex(entity);
	
	g_Map_Traps.GetArray(reference, trapInfo, sizeof(TrapInfo));
	
	trapInfo.classType = classType;
	trapInfo.activatorId = activatorId;
	
	if (!view_as<bool>(trapInfo.flags & TRAP_HAS_CONFIG_FLAGS_SET))
	{
		trapInfo.flags |= TRAP_HAS_CONFIG_FLAGS_SET;
		GetEntityTrapFlags(entity, trapInfo.configFlags);
	}
	
	switch (classType)
	{
		case ClassType_EnvBeam, ClassType_EnvLaser:
		{
			if (!IsEntityEnabled(entity, trapInfo.classType) 
				|| !CanEntityDamageClients(entity, trapInfo.classType))
			{
				return;
			}
			
			flags &= ~TRAP_CHILD_IN_BREAKABLES_ON_KILL;
			flags &= ~TRAP_CHILD_IN_BREAKABLES_ON_MOVE;
			flags &= ~TRAP_CHILD_IN_BREAKABLES_ON_FIRST_MOVE;
			flags &= ~TRAP_CHILD_IN_BREAKABLES_ON_SPEED;
			flags &= ~TRAP_CHILD_IN_BREAKABLES_ON_REVERSE;
		}
		
		case ClassType_EnvFire:
		{
			if (!IsEntityEnabled(entity, trapInfo.classType))
			{
				return;
			}
			
			flags &= ~TRAP_CHILD_IN_BREAKABLES_ON_KILL;
			flags &= ~TRAP_CHILD_IN_BREAKABLES_ON_MOVE;
			flags &= ~TRAP_CHILD_IN_BREAKABLES_ON_FIRST_MOVE;
			flags &= ~TRAP_CHILD_IN_BREAKABLES_ON_SPEED;
			flags &= ~TRAP_CHILD_IN_BREAKABLES_ON_REVERSE;
		}
		
		case ClassType_TriggerHurt:
		{
			if (!IsEntityEnabled(entity, trapInfo.classType) 
				|| !CanPlayersTouchEntity(entity, trapInfo.classType) 
				|| !CanEntityDamageClients(entity, trapInfo.classType))
			{
				return;
			}
			
			flags &= ~TRAP_CHILD_IN_BREAKABLES_ON_KILL;
			flags &= ~TRAP_CHILD_IN_BREAKABLES_ON_MOVE;
			flags &= ~TRAP_CHILD_IN_BREAKABLES_ON_FIRST_MOVE;
			flags &= ~TRAP_CHILD_IN_BREAKABLES_ON_SPEED;
			flags &= ~TRAP_CHILD_IN_BREAKABLES_ON_REVERSE;
		}
		
		case ClassType_TriggerPush:
		{
			if (!IsEntityEnabled(entity, trapInfo.classType) 
				|| !CanPlayersTouchEntity(entity, trapInfo.classType))
			{
				return;
			}
			
			flags &= ~TRAP_CHILD_IN_BREAKABLES_ON_KILL;
			flags &= ~TRAP_CHILD_IN_BREAKABLES_ON_MOVE;
			flags &= ~TRAP_CHILD_IN_BREAKABLES_ON_FIRST_MOVE;
			flags &= ~TRAP_CHILD_IN_BREAKABLES_ON_SPEED;
			flags &= ~TRAP_CHILD_IN_BREAKABLES_ON_REVERSE;
		}
		
		case ClassType_TriggerTeleport:
		{
			if (!IsEntityEnabled(entity, trapInfo.classType) 
				|| !CanPlayersTouchEntity(entity, trapInfo.classType)
				|| !HasEntityValidDestination(entity))
			{
				return;
			}
			
			flags &= ~TRAP_CHILD_IN_BREAKABLES_ON_KILL;
			flags &= ~TRAP_CHILD_IN_BREAKABLES_ON_MOVE;
			flags &= ~TRAP_CHILD_IN_BREAKABLES_ON_FIRST_MOVE;
			flags &= ~TRAP_CHILD_IN_BREAKABLES_ON_SPEED;
			flags &= ~TRAP_CHILD_IN_BREAKABLES_ON_REVERSE;
		}
		
		case ClassType_FuncBreakable,
			ClassType_FuncBrush,
			ClassType_FuncDoor,
			ClassType_FuncDoorRotating,
			ClassType_FuncMoveLinear,
			ClassType_FuncPhysBox,
			ClassType_FuncRotating,
			ClassType_FuncTankTrain,
			ClassType_FuncTrackTrain,
			ClassType_FuncTrain,
			ClassType_FuncWall,
			ClassType_FuncWallToggle,
			ClassType_FuncWaterAnalog,
			ClassType_PropDynamic,
			ClassType_PropPhysics:
		{
			if (!IsEntitySolid(entity) || !CanPlayersTouchEntity(entity, trapInfo.classType))
			{
				return;
			}
		}
		
		case ClassType_EnvEntityMaker,
			ClassType_EnvExplosion,
			ClassType_EnvFireSource,
			ClassType_EnvGunFire,
			ClassType_EnvShake,
			ClassType_EnvSmokeStack,
			ClassType_FuncButton,
			ClassType_GameUI,
			ClassType_LogicBranch,
			ClassType_LogicCase,
			ClassType_LogicCompare,
			ClassType_LogicRelay,
			ClassType_LogicTimer,
			ClassType_MathCounter,
			ClassType_PointTemplate,
			ClassType_TriggerMultiple,
			ClassType_TriggerOnce:
		{
			flags &= ~TRAP_CHILD_IN_PROXIMITY;
			flags &= ~TRAP_CHILD_IN_BREAKABLES_ON_KILL;
			flags &= ~TRAP_CHILD_IN_BREAKABLES_ON_MOVE;
			flags &= ~TRAP_CHILD_IN_BREAKABLES_ON_FIRST_MOVE;
			flags &= ~TRAP_CHILD_IN_BREAKABLES_ON_SPEED;
			flags &= ~TRAP_CHILD_IN_BREAKABLES_ON_REVERSE;
		}
		
		default:
		{
			return;
		}
	}
	
	if (view_as<bool>(flags & TRAP_CHILD_IN_PROXIMITY))
	{
		AddChildInProximity(entity, trapInfo);
	}
	
	if (view_as<bool>(flags & TRAP_CHILD_IN_BREAKABLES_ON_KILL) 
		|| view_as<bool>(flags & TRAP_CHILD_IN_BREAKABLES_ON_MOVE) 
		|| view_as<bool>(flags & TRAP_CHILD_IN_BREAKABLES_ON_FIRST_MOVE) 
		|| view_as<bool>(flags & TRAP_CHILD_IN_BREAKABLES_ON_SPEED) 
		|| view_as<bool>(flags & TRAP_CHILD_IN_BREAKABLES_ON_REVERSE))
	{
		AddChildInBreakables(entity, parent, trapInfo, flags);
	}
	
	trapInfo.flags |= TRAP_IS_CHILD;
	g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
}

void DeactivateChild(int entity, int flags)
{
	TrapInfo trapInfo;
	int reference = EntIndexToEntRef_Ex(entity);
	int hammerId = GetEntProp(entity, Prop_Data, "m_iHammerID");
	
	if (!g_Map_Traps.GetArray(reference, trapInfo, sizeof(TrapInfo)))
	{
		return;
	}
		
	if (view_as<bool>(flags & TRAP_CHILD_IN_PROXIMITY))
	{
		RemoveChildFromProximity(reference, trapInfo);
	}
	
	if (view_as<bool>(flags & TRAP_CHILD_IN_BREAKABLES_ON_KILL) 
		|| view_as<bool>(flags & TRAP_CHILD_IN_BREAKABLES_ON_MOVE) 
		|| view_as<bool>(flags & TRAP_CHILD_IN_BREAKABLES_ON_FIRST_MOVE) 
		|| view_as<bool>(flags & TRAP_CHILD_IN_BREAKABLES_ON_SPEED) 
		|| view_as<bool>(flags & TRAP_CHILD_IN_BREAKABLES_ON_REVERSE))
	{
		RemoveChildFromBreakables(hammerId, trapInfo, flags);
	}
	
	trapInfo.flags &= ~TRAP_IS_CHILD;
	g_Map_Traps.SetArray(reference, trapInfo, sizeof(TrapInfo));
}

void AddChildInProximity(int entity, TrapInfo trapInfo)
{
	if (view_as<bool>(trapInfo.configFlags & TRAP_IGNORE_PROXIMITY))
	{
		return;
	}
	
	if (g_Cvar_DebugModeEnable.BoolValue)
	{
		int hammerId = GetEntProp(entity, Prop_Data, "m_iHammerID");
		
		char entityName[256];
		GetEntPropString(entity, Prop_Data, "m_iName", entityName, sizeof(entityName));
		StringToLower(entityName);
		
		char className[256];
		GetEntityClassname(entity, className, sizeof(className));
		
		PrintToChatAll("Add %s : %d : %s in proximity (child)", entityName, hammerId, className);
	}
	
	if (!view_as<bool>(trapInfo.flags & TRAP_CHILD_IN_PROXIMITY) 
		&& !view_as<bool>(trapInfo.flags & TRAP_IN_PROXIMITY))
	{
		int reference = EntIndexToEntRef_Ex(entity);
		g_List_ProximityTraps.Push(reference);
	}
	
	trapInfo.flags |= TRAP_CHILD_IN_PROXIMITY;
}

void RemoveChildFromProximity(int reference, TrapInfo trapInfo)
{
	if (!view_as<bool>(trapInfo.flags & TRAP_CHILD_IN_PROXIMITY))
	{
		return;
	}
	
	if (g_Cvar_DebugModeEnable.BoolValue)
	{
		if (g_List_ProximityTraps.FindValue(reference) != -1)
		{
			int entity = EntRefToEntIndex(reference);
			if (IsValidEntity(entity))
			{
				int hammerId = GetEntProp(entity, Prop_Data, "m_iHammerID");
				
				char entityName[256];
				GetEntPropString(entity, Prop_Data, "m_iName", entityName, sizeof(entityName));
				StringToLower(entityName);
				
				char className[256];
				GetEntityClassname(entity, className, sizeof(className));
				
				PrintToChatAll("Remove %s : %d : %s from proximity (child)", entityName, hammerId, className);
			}
			else
			{
				PrintToChatAll("Remove [%d] from proximity (child)", reference);
			}
		}
	}
	
	trapInfo.flags &= ~TRAP_CHILD_IN_PROXIMITY;
	if (!view_as<bool>(trapInfo.flags & TRAP_IN_PROXIMITY))
	{
		RemoveCellFromArrayList(reference, g_List_ProximityTraps);
	}
}

void AddChildInBreakables(int entity, int parent, TrapInfo trapInfo, int flags)
{
	int reference = EntIndexToEntRef_Ex(entity);
	int hammerId = GetEntProp(entity, Prop_Data, "m_iHammerID");
	int parentHammerId = GetEntProp(parent, Prop_Data, "m_iHammerID");
	float gameTime = GetGameTime();
	
	char entityName[256];
	GetEntPropString(entity, Prop_Data, "m_iName", entityName, sizeof(entityName));
	StringToLower(entityName);
	
	BreakableInfo breakableInfo;
	breakableInfo.hammerId = hammerId;
	breakableInfo.entityRef = reference;
	breakableInfo.activatorId = trapInfo.activatorId;
	breakableInfo.parentHammer = parentHammerId;
	
	strcopy(breakableInfo.entityName, sizeof(BreakableInfo::entityName), entityName);
	GetEntityBounds(entity, breakableInfo.pointMin, breakableInfo.pointMax);
	
	if (view_as<bool>(flags & TRAP_CHILD_IN_BREAKABLES_ON_KILL))
	{
		if (g_Cvar_DebugModeEnable.BoolValue)
		{
			char className[256];
			GetEntityClassname(entity, className, sizeof(className));
			PrintToChatAll("Add child %s : %d : %s in breakables (on kill)", entityName, hammerId, className);
		}
		
		breakableInfo.removeTime = 0.0;
		g_Map_BreakablesOnKill.SetArray(hammerId, breakableInfo, sizeof(BreakableInfo));
		
		if (!view_as<bool>(trapInfo.flags & TRAP_CHILD_IN_BREAKABLES_ON_KILL) 
			&& !view_as<bool>(trapInfo.flags & TRAP_IN_BREAKABLES_ON_KILL) 
			&& !view_as<bool>(trapInfo.configFlags & TRAP_IGNORE_BREAKABLES_ON_KILL))
		{
			g_List_BreakablesOnKill.Push(hammerId);
		}
		
		trapInfo.flags |= TRAP_CHILD_IN_BREAKABLES_ON_KILL;
	}
	
	if (view_as<bool>(flags & TRAP_CHILD_IN_BREAKABLES_ON_MOVE))
	{
		if (g_Cvar_DebugModeEnable.BoolValue)
		{
			char className[256];
			GetEntityClassname(entity, className, sizeof(className));
			PrintToChatAll("Add child %s : %d : %s in breakables (on move)", entityName, hammerId, className);
		}
				
		breakableInfo.removeTime = view_as<bool>(flags & TRAP_SPAWN_ENABLED) ? gameTime + 1.0 : 0.0;
		g_Map_BreakablesOnMove.SetArray(hammerId, breakableInfo, sizeof(BreakableInfo));
		
		if (!view_as<bool>(trapInfo.flags & TRAP_CHILD_IN_BREAKABLES_ON_MOVE) 
			&& !view_as<bool>(trapInfo.flags & TRAP_IN_BREAKABLES_ON_MOVE) 
			&& !view_as<bool>(trapInfo.configFlags & TRAP_IGNORE_BREAKABLES_ON_MOVE))
		{
			g_List_BreakablesOnMove.Push(hammerId);
		}
		
		trapInfo.flags |= TRAP_CHILD_IN_BREAKABLES_ON_MOVE;
	}
	
	if (view_as<bool>(flags & TRAP_CHILD_IN_BREAKABLES_ON_FIRST_MOVE))
	{
		if (g_Cvar_DebugModeEnable.BoolValue)
		{
			char className[256];
			GetEntityClassname(entity, className, sizeof(className));
			PrintToChatAll("Add child %s : %d : %s in breakables (on first move)", entityName, hammerId, className);
		}
		
		breakableInfo.removeTime = 0.0;
		g_Map_BreakablesOnFirstMove.SetArray(hammerId, breakableInfo, sizeof(BreakableInfo));
		
		if (!view_as<bool>(trapInfo.flags & TRAP_CHILD_IN_BREAKABLES_ON_FIRST_MOVE) 
			&& !view_as<bool>(trapInfo.flags & TRAP_IN_BREAKABLES_ON_FIRST_MOVE) 
			&& !view_as<bool>(trapInfo.configFlags & TRAP_IGNORE_BREAKABLES_ON_FIRST_MOVE))
		{
			g_List_BreakablesOnFirstMove.Push(hammerId);
		}
		
		trapInfo.flags |= TRAP_CHILD_IN_BREAKABLES_ON_FIRST_MOVE;
	}
	
	if (view_as<bool>(flags & TRAP_CHILD_IN_BREAKABLES_ON_SPEED))
	{
		if (g_Cvar_DebugModeEnable.BoolValue)
		{
			char className[256];
			GetEntityClassname(entity, className, sizeof(className));
			PrintToChatAll("Add child %s : %d : %s in breakables (on speed)", entityName, hammerId, className);
		}
				
		breakableInfo.removeTime = gameTime + 1.0;
		g_Map_BreakablesOnSpeed.SetArray(hammerId, breakableInfo, sizeof(BreakableInfo));
		
		if (!view_as<bool>(trapInfo.flags & TRAP_CHILD_IN_BREAKABLES_ON_SPEED) 
			&& !view_as<bool>(trapInfo.flags & TRAP_IN_BREAKABLES_ON_SPEED) 
			&& !view_as<bool>(trapInfo.configFlags & TRAP_IGNORE_BREAKABLES_ON_SPEED))
		{
			g_List_BreakablesOnSpeed.Push(hammerId);
		}
		
		trapInfo.flags |= TRAP_CHILD_IN_BREAKABLES_ON_SPEED;
	}
	
	if (view_as<bool>(flags & TRAP_CHILD_IN_BREAKABLES_ON_REVERSE))
	{
		if (g_Cvar_DebugModeEnable.BoolValue)
		{
			char className[256];
			GetEntityClassname(entity, className, sizeof(className));
			PrintToChatAll("Add child %s : %d : %s in breakables (on reverse)", entityName, hammerId, className);
		}
				
		breakableInfo.removeTime = gameTime + 1.0;
		g_Map_BreakablesOnReverse.SetArray(hammerId, breakableInfo, sizeof(BreakableInfo));
		
		if (!view_as<bool>(trapInfo.flags & TRAP_CHILD_IN_BREAKABLES_ON_REVERSE) 
			&& !view_as<bool>(trapInfo.flags & TRAP_IN_BREAKABLES_ON_REVERSE) 
			&& !view_as<bool>(trapInfo.configFlags & TRAP_IGNORE_BREAKABLES_ON_REVERSE))
		{
			g_List_BreakablesOnReverse.Push(hammerId);
		}
		
		trapInfo.flags |= TRAP_CHILD_IN_BREAKABLES_ON_REVERSE;
	}
}

void RemoveChildFromBreakables(int hammerId, TrapInfo trapInfo, int flags)
{
	if (view_as<bool>(flags & TRAP_CHILD_IN_BREAKABLES_ON_KILL) 
		&& view_as<bool>(trapInfo.flags & TRAP_CHILD_IN_BREAKABLES_ON_KILL))
	{
		if (g_Cvar_DebugModeEnable.BoolValue)
		{
			BreakableInfo breakableInfo;
			if (g_Map_BreakablesOnFirstMove.GetArray(hammerId, breakableInfo, sizeof(BreakableInfo)))
			{
				PrintToChatAll("Remove child %s : %d from breakables (on kill)", breakableInfo.entityName, hammerId);
			}
		}
		
		trapInfo.flags &= ~TRAP_CHILD_IN_BREAKABLES_ON_KILL;
		if (!view_as<bool>(trapInfo.flags & TRAP_IN_BREAKABLES_ON_KILL))
		{
			g_Map_BreakablesOnKill.Remove(hammerId);
			RemoveCellFromArrayList(hammerId, g_List_BreakablesOnKill);
		}
	}
	
	if (view_as<bool>(flags & TRAP_CHILD_IN_BREAKABLES_ON_MOVE) 
		&& view_as<bool>(trapInfo.flags & TRAP_CHILD_IN_BREAKABLES_ON_MOVE))
	{
		if (g_Cvar_DebugModeEnable.BoolValue)
		{
			BreakableInfo breakableInfo;
			if (g_Map_BreakablesOnFirstMove.GetArray(hammerId, breakableInfo, sizeof(BreakableInfo)))
			{
				PrintToChatAll("Remove child %s : %d from breakables (on move)", breakableInfo.entityName, hammerId);
			}
		}
		
		trapInfo.flags &= ~TRAP_CHILD_IN_BREAKABLES_ON_MOVE;
		if (!view_as<bool>(trapInfo.flags & TRAP_IN_BREAKABLES_ON_MOVE))
		{
			g_Map_BreakablesOnMove.Remove(hammerId);
			RemoveCellFromArrayList(hammerId, g_List_BreakablesOnMove);
		}
	}
	
	if (view_as<bool>(flags & TRAP_CHILD_IN_BREAKABLES_ON_FIRST_MOVE) 
		&& view_as<bool>(trapInfo.flags & TRAP_CHILD_IN_BREAKABLES_ON_FIRST_MOVE))
	{
		if (g_Cvar_DebugModeEnable.BoolValue)
		{
			BreakableInfo breakableInfo;
			if (g_Map_BreakablesOnFirstMove.GetArray(hammerId, breakableInfo, sizeof(BreakableInfo)))
			{
				PrintToChatAll("Remove child %s : %d from breakables (on first move)", breakableInfo.entityName, hammerId);
			}
		}
		
		trapInfo.flags &= ~TRAP_CHILD_IN_BREAKABLES_ON_FIRST_MOVE;
		if (!view_as<bool>(trapInfo.flags & TRAP_IN_BREAKABLES_ON_FIRST_MOVE))
		{
			g_Map_BreakablesOnFirstMove.Remove(hammerId);
			RemoveCellFromArrayList(hammerId, g_List_BreakablesOnFirstMove);
		}
	}
	
	if (view_as<bool>(flags & TRAP_CHILD_IN_BREAKABLES_ON_SPEED) 
		&& view_as<bool>(trapInfo.flags & TRAP_CHILD_IN_BREAKABLES_ON_SPEED))
	{
		if (g_Cvar_DebugModeEnable.BoolValue)
		{
			BreakableInfo breakableInfo;
			if (g_Map_BreakablesOnFirstMove.GetArray(hammerId, breakableInfo, sizeof(BreakableInfo)))
			{
				PrintToChatAll("Remove child %s : %d from breakables (on speed)", breakableInfo.entityName, hammerId);
			}
		}
		
		trapInfo.flags &= ~TRAP_CHILD_IN_BREAKABLES_ON_SPEED;
		if (!view_as<bool>(trapInfo.flags & TRAP_IN_BREAKABLES_ON_SPEED))
		{
			g_Map_BreakablesOnSpeed.Remove(hammerId);
			RemoveCellFromArrayList(hammerId, g_List_BreakablesOnSpeed);
		}
	}
	
	if (view_as<bool>(flags & TRAP_CHILD_IN_BREAKABLES_ON_REVERSE) 
		&& view_as<bool>(trapInfo.flags & TRAP_CHILD_IN_BREAKABLES_ON_REVERSE))
	{
		if (g_Cvar_DebugModeEnable.BoolValue)
		{
			BreakableInfo breakableInfo;
			if (g_Map_BreakablesOnFirstMove.GetArray(hammerId, breakableInfo, sizeof(BreakableInfo)))
			{
				PrintToChatAll("Remove child %s : %d from breakables (on reverse)", breakableInfo.entityName, hammerId);
			}
		}
		
		trapInfo.flags &= ~TRAP_CHILD_IN_BREAKABLES_ON_REVERSE;
		if (!view_as<bool>(trapInfo.flags & TRAP_IN_BREAKABLES_ON_REVERSE))
		{
			g_Map_BreakablesOnReverse.Remove(hammerId);
			RemoveCellFromArrayList(hammerId, g_List_BreakablesOnReverse);
		}
	}
}

void AddEntityInProximity(int reference, TrapInfo trapInfo, int flags)
{
	if (view_as<bool>(trapInfo.configFlags & TRAP_IGNORE_PROXIMITY))
	{
		return;
	}
	
	if (g_Cvar_DebugModeEnable.BoolValue)
	{
		int entity = EntRefToEntIndex(reference);
		if (IsValidEntity(entity))
		{
			int hammerId = GetEntProp(entity, Prop_Data, "m_iHammerID");
			
			char entityName[256];
			GetEntPropString(entity, Prop_Data, "m_iName", entityName, sizeof(entityName));
			StringToLower(entityName);
			
			char className[256];
			GetEntityClassname(entity, className, sizeof(className));
			
			PrintToChatAll("Add %s : %d : %s in proximity", entityName, hammerId, className);
		}
		else
		{
			PrintToChatAll("Add [%d] in proximity", reference);
		}
	}
	
	if (view_as<bool>(flags & TRAP_IN_PROXIMITY))
	{
		if (!view_as<bool>(trapInfo.flags & TRAP_IN_PROXIMITY) 
			&& !view_as<bool>(trapInfo.flags & TRAP_CHILD_IN_PROXIMITY))
		{
			g_List_ProximityTraps.Push(reference);
		}
		
		trapInfo.flags |= TRAP_IN_PROXIMITY;
	}
	
	if (view_as<bool>(flags & TRAP_CHILD_IN_PROXIMITY))
	{
		if (!view_as<bool>(trapInfo.flags & TRAP_CHILD_IN_PROXIMITY) 
			&& !view_as<bool>(trapInfo.flags & TRAP_IN_PROXIMITY))
		{
			g_List_ProximityTraps.Push(reference);
		}
		
		trapInfo.flags |= TRAP_CHILD_IN_PROXIMITY;
	}
}

void RemoveEntityFromProximity(int entity, TrapInfo trapInfo, int flags)
{
	int reference = EntIndexToEntRef_Ex(entity);
	if (view_as<bool>(flags & TRAP_IN_PROXIMITY) && view_as<bool>(trapInfo.flags & TRAP_IN_PROXIMITY))
	{
		if (g_Cvar_DebugModeEnable.BoolValue)
		{
			if (g_List_ProximityTraps.FindValue(reference) != -1)
			{
				int hammerId = GetEntProp(entity, Prop_Data, "m_iHammerID");
				
				char entityName[256];
				GetEntPropString(entity, Prop_Data, "m_iName", entityName, sizeof(entityName));
				StringToLower(entityName);
				
				char className[256];
				GetEntityClassname(entity, className, sizeof(className));
				
				PrintToChatAll("Remove %s : %d : %s from proximity", entityName, hammerId, className);
			}
		}
		
		trapInfo.flags &= ~TRAP_IN_PROXIMITY;
		if (!view_as<bool>(trapInfo.flags & TRAP_CHILD_IN_PROXIMITY))
		{
			RemoveCellFromArrayList(reference, g_List_ProximityTraps);
		}
	}
	
	if (view_as<bool>(flags & TRAP_CHILD_IN_PROXIMITY) && view_as<bool>(trapInfo.flags & TRAP_CHILD_IN_PROXIMITY))
	{
		if (g_Cvar_DebugModeEnable.BoolValue)
		{
			if (g_List_ProximityTraps.FindValue(reference) != -1)
			{
				int hammerId = GetEntProp(entity, Prop_Data, "m_iHammerID");
				
				char entityName[256];
				GetEntPropString(entity, Prop_Data, "m_iName", entityName, sizeof(entityName));
				StringToLower(entityName);
				
				char className[256];
				GetEntityClassname(entity, className, sizeof(className));
				
				PrintToChatAll("Remove %s : %d : %s from proximity", entityName, hammerId, className);
			}
		}
		
		trapInfo.flags &= ~TRAP_CHILD_IN_PROXIMITY;
		if (!view_as<bool>(trapInfo.flags & TRAP_IN_PROXIMITY))
		{
			RemoveCellFromArrayList(reference, g_List_ProximityTraps);
		}
	}
}

void AddEntityInBreakables(int entity, TrapInfo trapInfo, int flags)
{
	int reference = EntIndexToEntRef_Ex(entity);
	int hammerId = GetEntProp(entity, Prop_Data, "m_iHammerID");
	float gameTime = GetGameTime();
	
	char entityName[256];
	GetEntPropString(entity, Prop_Data, "m_iName", entityName, sizeof(entityName));
	StringToLower(entityName);
	
	BreakableInfo breakableInfo;
	breakableInfo.hammerId = hammerId;
	breakableInfo.entityRef = reference;
	breakableInfo.activatorId = trapInfo.activatorId;
	breakableInfo.parentHammer = -1;
	
	strcopy(breakableInfo.entityName, sizeof(BreakableInfo::entityName), entityName);
	GetEntityBounds(entity, breakableInfo.pointMin, breakableInfo.pointMax);
	
	if (view_as<bool>(flags & TRAP_IN_BREAKABLES_ON_KILL))
	{
		if (g_Cvar_DebugModeEnable.BoolValue)
		{
			char className[256];
			GetEntityClassname(entity, className, sizeof(className));
			PrintToChatAll("Add %s : %d : %s in breakables (on kill)", entityName, hammerId, className);
		}
		
		breakableInfo.removeTime = 0.0;
		g_Map_BreakablesOnKill.SetArray(hammerId, breakableInfo, sizeof(BreakableInfo));
		
		if (!view_as<bool>(trapInfo.flags & TRAP_IN_BREAKABLES_ON_KILL) 
			&& !view_as<bool>(trapInfo.flags & TRAP_CHILD_IN_BREAKABLES_ON_KILL) 
			&& !view_as<bool>(trapInfo.configFlags & TRAP_IGNORE_BREAKABLES_ON_KILL))
		{
			g_List_BreakablesOnKill.Push(hammerId);
		}
		
		trapInfo.flags |= TRAP_IN_BREAKABLES_ON_KILL;
	}
	
	if (view_as<bool>(flags & TRAP_IN_BREAKABLES_ON_MOVE))
	{
		if (g_Cvar_DebugModeEnable.BoolValue)
		{
			char className[256];
			GetEntityClassname(entity, className, sizeof(className));
			PrintToChatAll("Add %s : %d : %s in breakables (on move)", entityName, hammerId, className);
		}
				
		breakableInfo.removeTime = view_as<bool>(flags & TRAP_SPAWN_ENABLED) ? gameTime + 1.0 : 0.0;
		g_Map_BreakablesOnMove.SetArray(hammerId, breakableInfo, sizeof(BreakableInfo));
		
		if (!view_as<bool>(trapInfo.flags & TRAP_IN_BREAKABLES_ON_MOVE) 
			&& !view_as<bool>(trapInfo.flags & TRAP_CHILD_IN_BREAKABLES_ON_MOVE) 
			&& !view_as<bool>(trapInfo.configFlags & TRAP_IGNORE_BREAKABLES_ON_MOVE))
		{
			g_List_BreakablesOnMove.Push(hammerId);
		}
		
		trapInfo.flags |= TRAP_IN_BREAKABLES_ON_MOVE;
	}
	
	if (view_as<bool>(flags & TRAP_IN_BREAKABLES_ON_FIRST_MOVE))
	{
		if (g_Cvar_DebugModeEnable.BoolValue)
		{
			char className[256];
			GetEntityClassname(entity, className, sizeof(className));
			PrintToChatAll("Add %s : %d : %s in breakables (on first move)", entityName, hammerId, className);
		}
				
		breakableInfo.removeTime = 0.0;
		g_Map_BreakablesOnFirstMove.SetArray(hammerId, breakableInfo, sizeof(BreakableInfo));
		
		if (!view_as<bool>(trapInfo.flags & TRAP_IN_BREAKABLES_ON_FIRST_MOVE) 
			&& !view_as<bool>(trapInfo.flags & TRAP_CHILD_IN_BREAKABLES_ON_FIRST_MOVE) 
			&& !view_as<bool>(trapInfo.configFlags & TRAP_IGNORE_BREAKABLES_ON_FIRST_MOVE))
		{
			g_List_BreakablesOnFirstMove.Push(hammerId);
		}
		
		trapInfo.flags |= TRAP_IN_BREAKABLES_ON_FIRST_MOVE;
	}
	
	if (view_as<bool>(flags & TRAP_IN_BREAKABLES_ON_SPEED))
	{
		if (g_Cvar_DebugModeEnable.BoolValue)
		{
			char className[256];
			GetEntityClassname(entity, className, sizeof(className));
			PrintToChatAll("Add %s : %d : %s in breakables (on speed)", entityName, hammerId, className);
		}
				
		breakableInfo.removeTime = gameTime + 2.0;
		g_Map_BreakablesOnSpeed.SetArray(hammerId, breakableInfo, sizeof(BreakableInfo));
		
		if (!view_as<bool>(trapInfo.flags & TRAP_IN_BREAKABLES_ON_SPEED) 
			&& !view_as<bool>(trapInfo.flags & TRAP_CHILD_IN_BREAKABLES_ON_SPEED) 
			&& !view_as<bool>(trapInfo.configFlags & TRAP_IGNORE_BREAKABLES_ON_SPEED))
		{
			g_List_BreakablesOnSpeed.Push(hammerId);
		}
		
		trapInfo.flags |= TRAP_IN_BREAKABLES_ON_SPEED;
	}
	
	if (view_as<bool>(flags & TRAP_IN_BREAKABLES_ON_REVERSE))
	{
		if (g_Cvar_DebugModeEnable.BoolValue)
		{
			char className[256];
			GetEntityClassname(entity, className, sizeof(className));
			
			PrintToChatAll("Add %s : %d : %s in breakables (on reverse)", entityName, hammerId, className);
		}
				
		breakableInfo.removeTime = gameTime + 2.0;
		g_Map_BreakablesOnReverse.SetArray(hammerId, breakableInfo, sizeof(BreakableInfo));
		
		if (!view_as<bool>(trapInfo.flags & TRAP_IN_BREAKABLES_ON_REVERSE) 
			&& !view_as<bool>(trapInfo.flags & TRAP_CHILD_IN_BREAKABLES_ON_REVERSE) 
			&& !view_as<bool>(trapInfo.configFlags & TRAP_IGNORE_BREAKABLES_ON_REVERSE))
		{
			g_List_BreakablesOnReverse.Push(hammerId);
		}
		
		trapInfo.flags |= TRAP_IN_BREAKABLES_ON_REVERSE;
	}
}

void RemoveEntityFromBreakables(int entity, TrapInfo trapInfo, int flags)
{
	int hammerId = GetEntProp(entity, Prop_Data, "m_iHammerID");
	if (view_as<bool>(flags & TRAP_IN_BREAKABLES_ON_KILL) 
		&& view_as<bool>(trapInfo.flags & TRAP_IN_BREAKABLES_ON_KILL))
	{
		if (g_Cvar_DebugModeEnable.BoolValue)
		{
			BreakableInfo breakableInfo;
			if (g_Map_BreakablesOnFirstMove.GetArray(hammerId, breakableInfo, sizeof(BreakableInfo)))
			{
				PrintToChatAll("Remove %s : %d from breakables (on kill)", breakableInfo.entityName, hammerId);
			}
		}
		
		trapInfo.flags &= ~TRAP_IN_BREAKABLES_ON_KILL;
		if (!view_as<bool>(trapInfo.flags & TRAP_CHILD_IN_BREAKABLES_ON_KILL))
		{
			g_Map_BreakablesOnKill.Remove(hammerId);
			RemoveCellFromArrayList(hammerId, g_List_BreakablesOnKill);
		}
	}
	
	if (view_as<bool>(flags & TRAP_CHILD_IN_BREAKABLES_ON_KILL) 
		&& view_as<bool>(trapInfo.flags & TRAP_CHILD_IN_BREAKABLES_ON_KILL))
	{
		if (g_Cvar_DebugModeEnable.BoolValue)
		{
			BreakableInfo breakableInfo;
			if (g_Map_BreakablesOnFirstMove.GetArray(hammerId, breakableInfo, sizeof(BreakableInfo)))
			{
				PrintToChatAll("Remove child %s : %d from breakables (on kill)", breakableInfo.entityName, hammerId);
			}
		}
		
		trapInfo.flags &= ~TRAP_CHILD_IN_BREAKABLES_ON_KILL;
		if (!view_as<bool>(trapInfo.flags & TRAP_IN_BREAKABLES_ON_KILL))
		{
			g_Map_BreakablesOnKill.Remove(hammerId);
			RemoveCellFromArrayList(hammerId, g_List_BreakablesOnKill);
		}
	}
	
	if (view_as<bool>(flags & TRAP_IN_BREAKABLES_ON_MOVE) 
		&& view_as<bool>(trapInfo.flags & TRAP_IN_BREAKABLES_ON_MOVE))
	{
		if (g_Cvar_DebugModeEnable.BoolValue)
		{
			BreakableInfo breakableInfo;
			if (g_Map_BreakablesOnFirstMove.GetArray(hammerId, breakableInfo, sizeof(BreakableInfo)))
			{
				PrintToChatAll("Remove %s : %d from breakables (on move)", breakableInfo.entityName, hammerId);
			}
		}
		
		trapInfo.flags &= ~TRAP_IN_BREAKABLES_ON_MOVE;
		if (!view_as<bool>(trapInfo.flags & TRAP_CHILD_IN_BREAKABLES_ON_MOVE))
		{
			g_Map_BreakablesOnMove.Remove(hammerId);
			RemoveCellFromArrayList(hammerId, g_List_BreakablesOnMove);
		}
	}
	
	if (view_as<bool>(flags & TRAP_CHILD_IN_BREAKABLES_ON_MOVE) 
		&& view_as<bool>(trapInfo.flags & TRAP_CHILD_IN_BREAKABLES_ON_MOVE))
	{
		if (g_Cvar_DebugModeEnable.BoolValue)
		{
			BreakableInfo breakableInfo;
			if (g_Map_BreakablesOnFirstMove.GetArray(hammerId, breakableInfo, sizeof(BreakableInfo)))
			{
				PrintToChatAll("Remove child %s : %d from breakables (on move)", breakableInfo.entityName, hammerId);
			}
		}
		
		trapInfo.flags &= ~TRAP_CHILD_IN_BREAKABLES_ON_MOVE;
		if (!view_as<bool>(trapInfo.flags & TRAP_IN_BREAKABLES_ON_MOVE))
		{
			g_Map_BreakablesOnMove.Remove(hammerId);
			RemoveCellFromArrayList(hammerId, g_List_BreakablesOnMove);
		}
	}
	
	if (view_as<bool>(flags & TRAP_IN_BREAKABLES_ON_FIRST_MOVE) 
		&& view_as<bool>(trapInfo.flags & TRAP_IN_BREAKABLES_ON_FIRST_MOVE))
	{
		if (g_Cvar_DebugModeEnable.BoolValue)
		{
			BreakableInfo breakableInfo;
			if (g_Map_BreakablesOnFirstMove.GetArray(hammerId, breakableInfo, sizeof(BreakableInfo)))
			{
				PrintToChatAll("Remove %s : %d from breakables (on first move)", breakableInfo.entityName, hammerId);
			}
		}
		
		trapInfo.flags &= ~TRAP_IN_BREAKABLES_ON_FIRST_MOVE;
		if (!view_as<bool>(trapInfo.flags & TRAP_CHILD_IN_BREAKABLES_ON_FIRST_MOVE))
		{
			g_Map_BreakablesOnFirstMove.Remove(hammerId);
			RemoveCellFromArrayList(hammerId, g_List_BreakablesOnFirstMove);
		}
	}
	
	if (view_as<bool>(flags & TRAP_CHILD_IN_BREAKABLES_ON_FIRST_MOVE) 
		&& view_as<bool>(trapInfo.flags & TRAP_CHILD_IN_BREAKABLES_ON_FIRST_MOVE))
	{
		if (g_Cvar_DebugModeEnable.BoolValue)
		{
			BreakableInfo breakableInfo;
			if (g_Map_BreakablesOnFirstMove.GetArray(hammerId, breakableInfo, sizeof(BreakableInfo)))
			{
				PrintToChatAll("Remove child %s : %d from breakables (on first move)", breakableInfo.entityName, hammerId);
			}
		}
		
		trapInfo.flags &= ~TRAP_CHILD_IN_BREAKABLES_ON_FIRST_MOVE;
		if (!view_as<bool>(trapInfo.flags & TRAP_IN_BREAKABLES_ON_FIRST_MOVE))
		{
			g_Map_BreakablesOnFirstMove.Remove(hammerId);
			RemoveCellFromArrayList(hammerId, g_List_BreakablesOnFirstMove);
		}
	}
	
	if (view_as<bool>(flags & TRAP_IN_BREAKABLES_ON_SPEED) 
		&& view_as<bool>(trapInfo.flags & TRAP_IN_BREAKABLES_ON_SPEED))
	{
		if (g_Cvar_DebugModeEnable.BoolValue)
		{
			BreakableInfo breakableInfo;
			if (g_Map_BreakablesOnFirstMove.GetArray(hammerId, breakableInfo, sizeof(BreakableInfo)))
			{
				PrintToChatAll("Remove %s : %d from breakables (on speed)", breakableInfo.entityName, hammerId);
			}
		}
		
		trapInfo.flags &= ~TRAP_IN_BREAKABLES_ON_SPEED;
		if (!view_as<bool>(trapInfo.flags & TRAP_CHILD_IN_BREAKABLES_ON_SPEED))
		{
			g_Map_BreakablesOnSpeed.Remove(hammerId);
			RemoveCellFromArrayList(hammerId, g_List_BreakablesOnSpeed);
		}
	}
	
	if (view_as<bool>(flags & TRAP_CHILD_IN_BREAKABLES_ON_SPEED) 
		&& view_as<bool>(trapInfo.flags & TRAP_CHILD_IN_BREAKABLES_ON_SPEED))
	{
		if (g_Cvar_DebugModeEnable.BoolValue)
		{
			BreakableInfo breakableInfo;
			if (g_Map_BreakablesOnFirstMove.GetArray(hammerId, breakableInfo, sizeof(BreakableInfo)))
			{
				PrintToChatAll("Remove child %s : %d from breakables (on speed)", breakableInfo.entityName, hammerId);
			}
		}
		
		trapInfo.flags &= ~TRAP_CHILD_IN_BREAKABLES_ON_SPEED;
		if (!view_as<bool>(trapInfo.flags & TRAP_IN_BREAKABLES_ON_SPEED))
		{
			g_Map_BreakablesOnSpeed.Remove(hammerId);
			RemoveCellFromArrayList(hammerId, g_List_BreakablesOnSpeed);
		}
	}
	
	if (view_as<bool>(flags & TRAP_IN_BREAKABLES_ON_REVERSE) 
		&& view_as<bool>(trapInfo.flags & TRAP_IN_BREAKABLES_ON_REVERSE))
	{
		if (g_Cvar_DebugModeEnable.BoolValue)
		{
			BreakableInfo breakableInfo;
			if (g_Map_BreakablesOnFirstMove.GetArray(hammerId, breakableInfo, sizeof(BreakableInfo)))
			{
				PrintToChatAll("Remove %s : %d from breakables (on reverse)", breakableInfo.entityName, hammerId);
			}
		}
		
		trapInfo.flags &= ~TRAP_IN_BREAKABLES_ON_REVERSE;
		if (!view_as<bool>(trapInfo.flags & TRAP_CHILD_IN_BREAKABLES_ON_REVERSE))
		{
			g_Map_BreakablesOnReverse.Remove(hammerId);
			RemoveCellFromArrayList(hammerId, g_List_BreakablesOnReverse);
		}
	}
	
	if (view_as<bool>(flags & TRAP_CHILD_IN_BREAKABLES_ON_REVERSE) 
		&& view_as<bool>(trapInfo.flags & TRAP_CHILD_IN_BREAKABLES_ON_REVERSE))
	{
		if (g_Cvar_DebugModeEnable.BoolValue)
		{
			BreakableInfo breakableInfo;
			if (g_Map_BreakablesOnFirstMove.GetArray(hammerId, breakableInfo, sizeof(BreakableInfo)))
			{
				PrintToChatAll("Remove child %s : %d from breakables (on reverse)", breakableInfo.entityName, hammerId);
			}
		}
		
		trapInfo.flags &= ~TRAP_CHILD_IN_BREAKABLES_ON_REVERSE;
		if (!view_as<bool>(trapInfo.flags & TRAP_IN_BREAKABLES_ON_REVERSE))
		{
			g_Map_BreakablesOnReverse.Remove(hammerId);
			RemoveCellFromArrayList(hammerId, g_List_BreakablesOnReverse);
		}
	}
}

void GetEntityTrapFlags(int entity, int& flags)
{
	char buffer[256];
	Format(buffer, sizeof(buffer), "h:%d", GetEntProp(entity, Prop_Data, "m_iHammerID"));
	
	int addFlags;
	if (!g_Map_TrapFlags.GetValue(buffer, addFlags))
	{
		char entityName[256];
		GetEntPropString(entity, Prop_Data, "m_iName", entityName, sizeof(entityName));
		StringToLower(entityName);
		
		if (!entityName[0])
		{
			return;
		}
		
		Format(buffer, sizeof(buffer), "n:%s", entityName);
		if (!g_Map_TrapFlags.GetValue(buffer, addFlags))
		{
			return;
		}
	}
	
	flags |= addFlags;
}

void DisplayDuelHud(int client, int currentTerrorist, int terroristKiller)
{
	Event newEvent = CreateEvent("cs_win_panel_round");
	if (newEvent)
	{
		char message[512];
		FormatDuelHud(message, sizeof(message), currentTerrorist, terroristKiller);
		
		newEvent.SetString("funfact_token", message);
		newEvent.FireToClient(client);
		newEvent.Cancel();
	}
}

void DisplayDuelHudToAll(int currentTerrorist, int terroristKiller)
{
	Event newEvent = CreateEvent("cs_win_panel_round");
	if (newEvent)
	{
		char message[512];
		FormatDuelHud(message, sizeof(message), currentTerrorist, terroristKiller);
		
		newEvent.SetString("funfact_token", message);
		newEvent.Fire();
	}
}

void HideDuelHudFromAll()
{
	Event newEvent = CreateEvent("cs_win_panel_round");
	if (newEvent)
	{
		newEvent.SetString("funfact_token", "");
		newEvent.Fire();
	}
}

void FormatDuelHud(char[] buffer, int maxlen, int currentTerrorist, int terroristKiller)
{
	char terroristName[256];
	char terroristKillerName[256];
	
	GetClientName_Ex(currentTerrorist, terroristName, sizeof(terroristName));
	GetClientName_Ex(terroristKiller, terroristKillerName, sizeof(terroristKillerName));
	
	if (terroristName[16])
	{
		strcopy(terroristName[16], sizeof(terroristName) - 16, "...");
	}
	
	if (terroristKillerName[16])
	{
		strcopy(terroristKillerName[16], sizeof(terroristKillerName) - 16, "...");
	}
	
	strcopy(buffer, maxlen, "<br /><b class='fontSize-l' color='#FFFFFF'>");
	
	if (view_as<bool>(g_RoundFlags & ROUND_END_CHOSEN) && g_CurrentEndInfo.endName[0])
	{
		Format(buffer, maxlen, "%s%s<br />", buffer, g_CurrentEndInfo.endName);
	}
	
	Format(buffer, maxlen, "%s<span color='#F4D58F'>%s</span>", buffer, terroristName);
	Format(buffer, maxlen, "%s&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;-&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;", buffer);
	Format(buffer, maxlen, "%s<span color='#99CCFF'>%s</span> [#%d]", buffer, terroristKillerName, g_FinishInfo[terroristKiller].finishPos);
	Format(buffer, maxlen, "%s</b><br />", buffer);
}

void SetClientProtection(int client)
{
	SetEntityRenderMode(client, RENDER_TRANSALPHA);
	SetEntityRenderColor(client, 255, 255, 255, 128);
	SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
}

void RemoveClientProtection(int client)
{
	SetEntityRenderMode(client, RENDER_NORMAL);
	SetEntityRenderColor(client, 255, 255, 255, 255);
	SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
}

void RenderZoneToAll(float pointMin[3], const float pointMax[3], int model, float time, float width, const int color[4], int flags = ZONE_RENDER_ALL)
{
	float pos1[3];
	pos1 = pointMax;
	pos1[0] = pointMin[0];
	
	float pos2[3];
	pos2 = pointMax;
	pos2[1] = pointMin[1];
	
	float pos3[3];
	pos3 = pointMax;
	pos3[2] = pointMin[2];
	
	float pos4[3];
	pos4 = pointMin;
	pos4[0] = pointMax[0];
	
	float pos5[3];
	pos5 = pointMin;
	pos5[1] = pointMax[1];
	
	float pos6[3];
	pos6 = pointMin;
	pos6[2] = pointMax[2];
	
	if (view_as<bool>(flags & ZONE_RENDER_ALL) 
		|| view_as<bool>(flags & ZONE_RENDER_TOP) 
		|| view_as<bool>(flags & ZONE_RENDER_BACK))
	{
		TE_SetupBeamPoints(pointMax, pos1, model, model, 0, 0, time, width, width, 1, 0.0, color, 0);
		TE_SendToAll();
	}
	
	if (view_as<bool>(flags & ZONE_RENDER_ALL) 
		|| view_as<bool>(flags & ZONE_RENDER_TOP) 
		|| view_as<bool>(flags & ZONE_RENDER_RIGHT))
	{
		TE_SetupBeamPoints(pointMax, pos2, model, model, 0, 0, time, width, width, 1, 0.0, color, 0);
		TE_SendToAll();
	}
	
	if (view_as<bool>(flags & ZONE_RENDER_ALL) 
		|| view_as<bool>(flags & ZONE_RENDER_BACK) 
		|| view_as<bool>(flags & ZONE_RENDER_RIGHT))
	{
		TE_SetupBeamPoints(pointMax, pos3, model, model, 0, 0, time, width, width, 1, 0.0, color, 0);
		TE_SendToAll();
	}
	
	if (view_as<bool>(flags & ZONE_RENDER_ALL) 
		|| view_as<bool>(flags & ZONE_RENDER_TOP) 
		|| view_as<bool>(flags & ZONE_RENDER_LEFT))
	{
		TE_SetupBeamPoints(pos6, pos1, model, model, 0, 0, time, width, width, 1, 0.0, color, 0);
		TE_SendToAll();
	}
	
	if (view_as<bool>(flags & ZONE_RENDER_ALL) 
		|| view_as<bool>(flags & ZONE_RENDER_TOP) 
		|| view_as<bool>(flags & ZONE_RENDER_FRONT))
	{
		TE_SetupBeamPoints(pos6, pos2, model, model, 0, 0, time, width, width, 1, 0.0, color, 0);
		TE_SendToAll();
	}
	
	if (view_as<bool>(flags & ZONE_RENDER_ALL) 
		|| view_as<bool>(flags & ZONE_RENDER_FRONT) 
		|| view_as<bool>(flags & ZONE_RENDER_LEFT))
	{
		TE_SetupBeamPoints(pos6, pointMin, model, model, 0, 0, time, width, width, 1, 0.0, color, 0);
		TE_SendToAll();
	}
	
	if (view_as<bool>(flags & ZONE_RENDER_ALL) 
		|| view_as<bool>(flags & ZONE_RENDER_BOTTOM) 
		|| view_as<bool>(flags & ZONE_RENDER_FRONT))
	{
		TE_SetupBeamPoints(pos4, pointMin, model, model, 0, 0, time, width, width, 1, 0.0, color, 0);
		TE_SendToAll();
	}
	
	if (view_as<bool>(flags & ZONE_RENDER_ALL) 
		|| view_as<bool>(flags & ZONE_RENDER_BOTTOM) 
		|| view_as<bool>(flags & ZONE_RENDER_LEFT))
	{
		TE_SetupBeamPoints(pos5, pointMin, model, model, 0, 0, time, width, width, 1, 0.0, color, 0);
		TE_SendToAll();
	}
	
	if (view_as<bool>(flags & ZONE_RENDER_ALL) 
		|| view_as<bool>(flags & ZONE_RENDER_BACK) 
		|| view_as<bool>(flags & ZONE_RENDER_LEFT))
	{
		TE_SetupBeamPoints(pos5, pos1, model, model, 0, 0, time, width, width, 1, 0.0, color, 0);
		TE_SendToAll();
	}
	
	if (view_as<bool>(flags & ZONE_RENDER_ALL) 
		|| view_as<bool>(flags & ZONE_RENDER_BOTTOM) 
		|| view_as<bool>(flags & ZONE_RENDER_BACK))
	{
		TE_SetupBeamPoints(pos5, pos3, model, model, 0, 0, time, width, width, 1, 0.0, color, 0);
		TE_SendToAll();
	}
	
	if (view_as<bool>(flags & ZONE_RENDER_ALL) 
		|| view_as<bool>(flags & ZONE_RENDER_BOTTOM) 
		|| view_as<bool>(flags & ZONE_RENDER_RIGHT))
	{
		TE_SetupBeamPoints(pos4, pos3, model, model, 0, 0, time, width, width, 1, 0.0, color, 0);
		TE_SendToAll();
	}
	
	if (view_as<bool>(flags & ZONE_RENDER_ALL) 
		|| view_as<bool>(flags & ZONE_RENDER_FRONT) 
		|| view_as<bool>(flags & ZONE_RENDER_RIGHT))
	{
		TE_SetupBeamPoints(pos4, pos2, model, model, 0, 0, time, width, width, 1, 0.0, color, 0);
		TE_SendToAll();
	}
}

void SetRoundTime(int time)
{
	GameRules_SetProp("m_iRoundTime", time);
}

void RemoveClientWeapons(int client)
{   
	int entity = CreateStripEntity();
	if (entity != -1)
	{
		AcceptEntityInput(entity, "Use", client);
		RemoveEntity(entity);
	}
}

void RefillClientAmmo(int client)
{
	int entity = CreateAmmoEntity();
	if (entity != -1)
	{
		AcceptEntityInput(entity, "GiveAmmo", client);
		RemoveEntity(entity);
	}
}

void GetEntityBounds(int entity, float vecMins[3], float vecMaxs[3])
{
	float vecOrigin[3];
	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vecOrigin);
	GetEntPropVector(entity, Prop_Data, "m_vecMins", vecMins);
	GetEntPropVector(entity, Prop_Data, "m_vecMaxs", vecMaxs);
	
	AddVectors(vecMins, view_as<float>({1.0, 1.0, 1.0}), vecMins);
	SubtractVectors(vecMaxs, view_as<float>({1.0, 1.0, 1.0}), vecMaxs);
	
	float vecPoints[8][3];
	vecPoints[0][0] = vecMins[0];
	vecPoints[0][1] = vecMins[1];
	vecPoints[0][2] = vecMins[2];

	vecPoints[1][0] = vecMins[0];
	vecPoints[1][1] = vecMaxs[1];
	vecPoints[1][2] = vecMins[2];
	
	vecPoints[2][0] = vecMaxs[0];
	vecPoints[2][1] = vecMaxs[1];
	vecPoints[2][2] = vecMins[2];
	
	vecPoints[3][0] = vecMaxs[0];
	vecPoints[3][1] = vecMins[1];
	vecPoints[3][2] = vecMins[2];
	
	vecPoints[4][0] = vecMins[0];
	vecPoints[4][1] = vecMins[1];
	vecPoints[4][2] = vecMaxs[2];
	
	vecPoints[5][0] = vecMins[0];
	vecPoints[5][1] = vecMaxs[1];
	vecPoints[5][2] = vecMaxs[2];
	
	vecPoints[6][0] = vecMaxs[0];
	vecPoints[6][1] = vecMaxs[1];
	vecPoints[6][2] = vecMaxs[2];
	
	vecPoints[7][0] = vecMaxs[0];
	vecPoints[7][1] = vecMins[1];
	vecPoints[7][2] = vecMaxs[2];
	
	float coordinateFrame[3][3];
	coordinateFrame[0][0] = GetEntPropFloat(entity, Prop_Data, "m_rgflCoordinateFrame", 0);
	coordinateFrame[0][1] = GetEntPropFloat(entity, Prop_Data, "m_rgflCoordinateFrame", 1);
	coordinateFrame[0][2] = GetEntPropFloat(entity, Prop_Data, "m_rgflCoordinateFrame", 2);
	coordinateFrame[1][0] = GetEntPropFloat(entity, Prop_Data, "m_rgflCoordinateFrame", 4);
	coordinateFrame[1][1] = GetEntPropFloat(entity, Prop_Data, "m_rgflCoordinateFrame", 5);
	coordinateFrame[1][2] = GetEntPropFloat(entity, Prop_Data, "m_rgflCoordinateFrame", 6);
	coordinateFrame[2][0] = GetEntPropFloat(entity, Prop_Data, "m_rgflCoordinateFrame", 8);
	coordinateFrame[2][1] = GetEntPropFloat(entity, Prop_Data, "m_rgflCoordinateFrame", 9);
	coordinateFrame[2][2] = GetEntPropFloat(entity, Prop_Data, "m_rgflCoordinateFrame", 10);
	
	float buffer[3];
	for (int i = 0; i < 8; i++)
	{
		buffer = vecPoints[i];
		for (int j = 0; j < 3; j++)
		{
			vecPoints[i][j] = GetVectorDotProduct(buffer, coordinateFrame[j]);
		}
	}
	
	vecMins = vecPoints[0];
	vecMaxs = vecPoints[0];

	for (int i = 1; i < 8; i++)
	{
		for (int j = 0; j < 3; j++)
		{
			if (vecPoints[i][j] < vecMins[j])
			{
				vecMins[j] = vecPoints[i][j];
			}
			
			if (vecPoints[i][j] > vecMaxs[j])
			{
				vecMaxs[j] = vecPoints[i][j];
			}
		}
	}
	
	for (int j = 0; j < 3; j++)
	{
		vecMins[j] += vecOrigin[j];
		vecMaxs[j] += vecOrigin[j];
	}
}

void RemoveClientWeaponByName(int client, const char[] name)
{
	for (int i = 0; i < GetEntPropArraySize(client, Prop_Send, "m_hMyWeapons"); i++) 
	{
		int weapon = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", i); 
		if (weapon == -1)
        {
			continue;
		}
		
		char weaponName[256];
		GetEntPropString(weapon, Prop_Data, "m_iszName", weaponName, sizeof(weaponName));
		
		if (!StrEqual(weaponName, name, true))
		{
			continue;
		}
		
		CS_DropWeapon(client, weapon, false);
		RemoveEntity(weapon);
	}
}

void DisplayLifeTransferMenu(int client)
{
	char userId[64];
	char name[MAX_NAME_LENGTH];
	char display[MAX_NAME_LENGTH + 64];	
	
	Menu menu = new Menu(Menu_LifeTransfer);
	menu.SetTitle("Transfer Life");
	menu.AddItem("#refresh", "Refresh");
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) 
			|| IsFakeClient(i) 
			|| IsPlayerAlive(i) 
			|| GetClientTeam(i) != CS_TEAM_CT 
			|| g_RespawnInfo[i].respawnTime 
			|| g_TerroristInfo[i].lastRound && g_TerroristInfo[i].lastRound == g_TotalRoundsPlayed)
		{
			continue;
		}
		
		Format(userId, sizeof(userId), "%d", GetClientUserId(i));
		GetClientName(i, name, sizeof(name));
		
		Format(display, sizeof(display), "%s (%s)", name, userId);
		menu.AddItem(userId, display);
	}
	
	for (int i = menu.ItemCount; i < 3; i++)
	{
		menu.AddItem("", "", ITEMDRAW_SPACER);
	}
	
	menu.Display(client, MENU_TIME_FOREVER);
}

void DisplayHudPreferencesMenu(int client)
{
	Menu menu = new Menu(Menu_HudPreferences);
	menu.SetTitle("HUD Preferences");
	
	if (view_as<bool>(g_HudInfo[client].displayFlags & HUD_DISPLAY_BUTTONS))
	{
		menu.AddItem("#buttons", "Buttons [On]");
	}
	else
	{
		menu.AddItem("#buttons", "Buttons [Off]");
	}
	
	if (view_as<bool>(g_HudInfo[client].displayFlags & HUD_DISPLAY_SPEC_BUTTONS))
	{
		menu.AddItem("#spectator_buttons", "(Spectator) Buttons [On]");
	}
	else
	{
		menu.AddItem("#spectator_buttons", "(Spectator) Buttons [Off]");
	}
	
	if (view_as<bool>(g_HudInfo[client].displayFlags & HUD_DISPLAY_SPECTATORS))
	{
		menu.AddItem("#spectators", "Spectators [On]");
	}
	else
	{
		menu.AddItem("#spectators", "Spectators [Off]");
	}
	
	if (g_HudInfo[client].displayFlags != HUD_DISPLAY_DEFAULT)
	{
		menu.AddItem("#reset_all", "Reset All");
	}
	else
	{
		menu.AddItem("#reset_all", "Reset All", ITEMDRAW_DISABLED);
	}
	
	for (int i = menu.ItemCount; i < 3; i++)
	{
		menu.AddItem("", "", ITEMDRAW_SPACER);
	}
	
	menu.Display(client, MENU_TIME_FOREVER);
}

void VectorToNearest(float vec[3])
{
	for (int i = 0; i < 3; i++)
	{
		vec[i] = float(RoundToNearest(vec[i]));
	}
}

void FadeScreen(int client, float time, float hold, int r, int g, int b, int a)
{
	Handle userMsg = StartMessageOne("Fade", client, USERMSG_RELIABLE | USERMSG_BLOCKHOOKS);
	if (userMsg)
	{
		int color[4];
		color[0] = r;
		color[1] = g;
		color[2] = b;
		color[3] = a;
		
		PbSetInt(userMsg, "duration", RoundToZero(time * 1000));
		PbSetInt(userMsg, "hold_time", RoundToZero(hold * 1000));
		PbSetInt(userMsg, "flags", FADE_IN | FADE_STAYOUT | FADE_PURGE);
		PbSetColor(userMsg, "clr", color);
		EndMessage();
	}
}

void RemoveCellFromArrayList(any value, ArrayList& list)
{
	int pos = list.FindValue(value);
	if (pos != -1)
	{
		list.Erase(pos);
	}
}

void TeleportClientToFinish(int client)
{
	float vecOrigin[3];
	float clientMins[3];
	float clientMaxs[3];
	
	vecOrigin = g_EndZoneOrigin;
	GetEntPropVector(client, Prop_Data, "m_vecMins", clientMins);
	GetEntPropVector(client, Prop_Data, "m_vecMaxs", clientMaxs);
	
	float middle = (clientMaxs[2] - clientMins[2]) / 2.0;
	if (clientMaxs[2] > clientMins[2])
	{
		vecOrigin[2] -= middle;
	}
	else
	{
		vecOrigin[2] += middle;
	}
	
	TeleportEntity(client, vecOrigin, NULL_VECTOR, view_as<float>({0.0, 0.0, 0.0}));
}

void IncreaseTeamScore(int team)
{
	int score = CS_GetTeamScore(team) + 1;
	CS_SetTeamScore(team, score);
	SetTeamScore(team, score);
}

void DecreaseTeamScore(int team)
{
	int score = CS_GetTeamScore(team) - 1;
	CS_SetTeamScore(team, score);
	SetTeamScore(team, score);
}

void SaveClientCookies(int client)
{
	if (g_Cookie_HudDisplay)
	{
		if (g_HudInfo[client].inCookies || g_HudInfo[client].displayFlags != HUD_DISPLAY_DEFAULT)
		{
			char buffer[256];
			IntToString(g_HudInfo[client].displayFlags, buffer, sizeof(buffer));
			g_Cookie_HudDisplay.Set(client, buffer);
		}
	}
}

void PlayAmbientSound(const char[] path, float vecOrigin[3], float volume = SNDVOL_NORMAL)
{
	EmitAmbientSound(path, vecOrigin, SOUND_FROM_WORLD, SNDLEVEL_NORMAL, SND_CHANGEVOL, volume);
}

void PlaySoundToClient(int client, const char[] path, float volume = SNDVOL_NORMAL)
{
	EmitSoundToClient(client, path, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NONE, SND_CHANGEVOL, volume);
}

void PlaySoundToAll(const char[] path, float volume = SNDVOL_NORMAL)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i))
		{
			continue;
		}
		
		PlaySoundToClient(i, path, volume);
	}
}

void GetClientName_Ex(int client, char[] clientName, int maxlen)
{
	GetClientName(client, clientName, maxlen);
	if (IsFakeClient(client))
	{
		Format(clientName, maxlen, "BOT %s", clientName);
	}
}

void ListenToTrapOutputs(int entity, const char[] output, int activatorId)
{
	if (!g_IsEntityIOLibraryLoaded)
	{
		return;
	}
	
	int offset = EntityIO_FindEntityOutputOffset(entity, output);
	if (offset == -1)
	{
		return;
	}
	
	int reference = EntIndexToEntRef_Ex(entity);
	float gameTime = GetGameTime();
	Handle actionIter = EntityIO_FindEntityFirstOutputAction(entity, offset);
	
	if (actionIter)
	{
		do
		{
			OutputActionInfo outputActionInfo;
			float actionDelay = EntityIO_GetEntityOutputActionDelay(actionIter);
			
			outputActionInfo.actionId = --g_OutputActionId;
			outputActionInfo.numTargets = 0;
			outputActionInfo.activatorId = activatorId;
			outputActionInfo.callerReference = reference;
			outputActionInfo.fireTime = gameTime + actionDelay;
			EntityIO_GetEntityOutputActionTarget(actionIter, outputActionInfo.target, sizeof(OutputActionInfo::target));
			
			EntityIO_SetEntityOutputActionID(actionIter, outputActionInfo.actionId);
			g_Map_OutputActions.SetArray(outputActionInfo.actionId, outputActionInfo, sizeof(OutputActionInfo));
			
		} while (EntityIO_FindEntityNextOutputAction(actionIter));
	}
	
	delete actionIter;
}

void RenderTrapsToAll()
{
	float gameTime = GetGameTime();
	if (g_List_BreakablesOnKill.Length)
	{
		BreakableInfo breakableInfo;
		for (int i = g_List_BreakablesOnKill.Length - 1; i >= 0; i--)
		{
			int hammerId = g_List_BreakablesOnKill.Get(i);
			if (!g_Map_BreakablesOnKill.GetArray(hammerId, breakableInfo, sizeof(BreakableInfo)))
			{
				g_List_BreakablesOnKill.Erase(i);
				continue;
			}
			
			if (breakableInfo.removeTime && gameTime > breakableInfo.removeTime)
			{
				TrapInfo trapInfo;
				if (g_Map_Traps.GetArray(breakableInfo.entityRef, trapInfo, sizeof(TrapInfo)))
				{
					trapInfo.flags &= ~TRAP_IN_BREAKABLES_ON_KILL;
					trapInfo.flags &= ~TRAP_CHILD_IN_BREAKABLES_ON_KILL;
					g_Map_Traps.SetArray(breakableInfo.entityRef, trapInfo, sizeof(TrapInfo));
				}
				
				g_List_BreakablesOnKill.Erase(i);
				continue;
			}
			
			RenderZoneToAll(breakableInfo.pointMin, breakableInfo.pointMax, g_BeamModel, TIMER_THINK_INTERVAL + 0.1, 3.0, view_as<int>({255, 0, 0, 255}));
		}
	}
	
	if (g_List_BreakablesOnMove.Length)
	{
		BreakableInfo breakableInfo;
		for (int i = g_List_BreakablesOnMove.Length - 1; i >= 0; i--)
		{
			int hammerId = g_List_BreakablesOnMove.Get(i);
			if (!g_Map_BreakablesOnMove.GetArray(hammerId, breakableInfo, sizeof(BreakableInfo)))
			{
				g_List_BreakablesOnMove.Erase(i);
				continue;
			}
			
			if (breakableInfo.removeTime && gameTime > breakableInfo.removeTime)
			{
				TrapInfo trapInfo;
				if (g_Map_Traps.GetArray(breakableInfo.entityRef, trapInfo, sizeof(TrapInfo)))
				{
					trapInfo.flags &= ~TRAP_IN_BREAKABLES_ON_MOVE;
					trapInfo.flags &= ~TRAP_CHILD_IN_BREAKABLES_ON_MOVE;
					g_Map_Traps.SetArray(breakableInfo.entityRef, trapInfo, sizeof(TrapInfo));
				}
				
				g_List_BreakablesOnMove.Erase(i);
				continue;
			}
			
			RenderZoneToAll(breakableInfo.pointMin, breakableInfo.pointMax, g_BeamModel, TIMER_THINK_INTERVAL + 0.1, 3.0, view_as<int>({255, 0, 0, 255}));
		}
	}
	
	if (g_List_BreakablesOnFirstMove.Length)
	{
		BreakableInfo breakableInfo;
		for (int i = g_List_BreakablesOnFirstMove.Length - 1; i >= 0; i--)
		{
			int hammerId = g_List_BreakablesOnFirstMove.Get(i);
			if (!g_Map_BreakablesOnFirstMove.GetArray(hammerId, breakableInfo, sizeof(BreakableInfo)))
			{
				g_List_BreakablesOnFirstMove.Erase(i);
				continue;
			}
			
			if (breakableInfo.removeTime && gameTime > breakableInfo.removeTime)
			{
				TrapInfo trapInfo;
				if (g_Map_Traps.GetArray(breakableInfo.entityRef, trapInfo, sizeof(TrapInfo)))
				{
					trapInfo.flags &= ~TRAP_IN_BREAKABLES_ON_FIRST_MOVE;
					trapInfo.flags &= ~TRAP_CHILD_IN_BREAKABLES_ON_FIRST_MOVE;
					g_Map_Traps.SetArray(breakableInfo.entityRef, trapInfo, sizeof(TrapInfo));
				}
				
				g_List_BreakablesOnFirstMove.Erase(i);
				continue;
			}
			
			RenderZoneToAll(breakableInfo.pointMin, breakableInfo.pointMax, g_BeamModel, TIMER_THINK_INTERVAL + 0.1, 3.0, view_as<int>({255, 0, 0, 255}));
		}
	}
	
	if (g_List_BreakablesOnSpeed.Length)
	{
		BreakableInfo breakableInfo;
		for (int i = g_List_BreakablesOnSpeed.Length - 1; i >= 0; i--)
		{
			int hammerId = g_List_BreakablesOnSpeed.Get(i);
			if (!g_Map_BreakablesOnSpeed.GetArray(hammerId, breakableInfo, sizeof(BreakableInfo)))
			{
				g_List_BreakablesOnSpeed.Erase(i);
				continue;
			}
			
			if (breakableInfo.removeTime && gameTime > breakableInfo.removeTime)
			{
				TrapInfo trapInfo;
				if (g_Map_Traps.GetArray(breakableInfo.entityRef, trapInfo, sizeof(TrapInfo)))
				{
					trapInfo.flags &= ~TRAP_IN_BREAKABLES_ON_SPEED;
					trapInfo.flags &= ~TRAP_CHILD_IN_BREAKABLES_ON_SPEED;
					g_Map_Traps.SetArray(breakableInfo.entityRef, trapInfo, sizeof(TrapInfo));
				}
				
				g_List_BreakablesOnSpeed.Erase(i);
				continue;
			}
			
			RenderZoneToAll(breakableInfo.pointMin, breakableInfo.pointMax, g_BeamModel, TIMER_THINK_INTERVAL + 0.1, 3.0, view_as<int>({255, 0, 0, 255}));
		}
	}
	
	if (g_List_BreakablesOnReverse.Length)
	{
		BreakableInfo breakableInfo;
		for (int i = g_List_BreakablesOnReverse.Length - 1; i >= 0; i--)
		{
			int hammerId = g_List_BreakablesOnReverse.Get(i);
			if (!g_Map_BreakablesOnReverse.GetArray(hammerId, breakableInfo, sizeof(BreakableInfo)))
			{
				g_List_BreakablesOnReverse.Erase(i);
				continue;
			}
			
			if (breakableInfo.removeTime && gameTime > breakableInfo.removeTime)
			{
				TrapInfo trapInfo;
				if (g_Map_Traps.GetArray(breakableInfo.entityRef, trapInfo, sizeof(TrapInfo)))
				{
					trapInfo.flags &= ~TRAP_IN_BREAKABLES_ON_REVERSE;
					trapInfo.flags &= ~TRAP_CHILD_IN_BREAKABLES_ON_REVERSE;
					g_Map_Traps.SetArray(breakableInfo.entityRef, trapInfo, sizeof(TrapInfo));
				}
				
				g_List_BreakablesOnReverse.Erase(i);
				continue;
			}
			
			RenderZoneToAll(breakableInfo.pointMin, breakableInfo.pointMax, g_BeamModel, TIMER_THINK_INTERVAL + 0.1, 3.0, view_as<int>({255, 0, 0, 255}));
		}
	}
	
	if (g_List_ProximityTraps.Length)
	{
		float pointMin[3];
		float pointMax[3];
		float vecMins[3];
		float vecMaxs[3];
		float vecOrigin[3];
		TrapInfo trapInfo;
		
		for (int i = g_List_ProximityTraps.Length - 1; i >= 0; i--)
		{
			int reference = g_List_ProximityTraps.Get(i);
			if (!g_Map_Traps.GetArray(reference, trapInfo, sizeof(TrapInfo)))
			{
				g_List_ProximityTraps.Erase(i);
				continue;
			}
			
			int entity = EntRefToEntIndex(reference);
			if (!IsValidEntity(entity))
			{
				g_List_ProximityTraps.Erase(i);
				continue;
			}
			
			GetEntityBounds(entity, pointMin, pointMax);
			
			vecMins = pointMin;
			vecMaxs = pointMax;
			GetMiddleOfBox(vecMins, vecMaxs, vecOrigin);
			
			if (trapInfo.flags & TRAP_IS_ACTIVATED)
			{
				RenderZoneToAll(pointMin, pointMax, g_BeamModel, TIMER_THINK_INTERVAL + 0.1, 3.0, view_as<int>({0, 255, 0, 255}));
			}
			else
			{
				RenderZoneToAll(pointMin, pointMax, g_BeamModel, TIMER_THINK_INTERVAL + 0.1, 3.0, view_as<int>({0, 0, 255, 255}));
			}
		}
	}
}

bool OnClientActivateEnd(int client, int entity, int endId)
{
	if (!view_as<bool>(g_PlayerFlags[client] & PLAYER_HAS_FINISHED_MAP) 
		&& IsClientInGame(client) 
		&& GetClientTeam(client) == CS_TEAM_CT)
	{
		CPrintToChat(client, "\x04[Deathrun]\x01 You must finish the map before going to an end.");
		return false;
	}
	
	EndInfo endInfo;
	if (endId)
	{
		g_Map_Endings.GetArray(endId, endInfo, sizeof(EndInfo));
	}
	
	bool isChosen;
	int userId = GetClientUserId(client);
	int reference = EntIndexToEntRef_Ex(entity);
	
	if (!g_Map_CurrentEndActivators.GetValue(reference, isChosen))
	{
		if (view_as<bool>(g_RoundFlags & ROUND_END_CHOSEN))
		{
			if (endId != g_CurrentEndInfo.endId)
			{
				CPrintToChat(client, "\x04[Deathrun]\x01 You cannot go to another end other than\x04 %s.", g_CurrentEndInfo.endName);
				return false;
			}
		}
		else if (userId != g_TerroristKillerId)
		{
			CPrintToChat(client, "\x04[Deathrun]\x01 You must be the\x0B Terrorist Killer\x01 to choose an end.");
			return false;
		}
	}
	
	if (view_as<bool>(g_RoundFlags & ROUND_IS_FREERUN) 
		&& view_as<bool>(endInfo.flags & END_RESTRICTED_ON_FREERUN))
	{
		CPrintToChat(client, "\x04[Deathrun]\x01 You cannot choose\x04 %s\x01 in\x04 Freerun Mode.", endInfo.endName);
		return false;
	}
	
	if (!view_as<bool>(g_RoundFlags & ROUND_END_CHOSEN) && endId)
	{
		g_RoundFlags |= ROUND_END_CHOSEN;
		g_CurrentEndInfo = endInfo;
		
		char clientName[MAX_NAME_LENGTH];
		GetClientName_Ex(client, clientName, sizeof(clientName));
		
		if (view_as<bool>(endInfo.flags & END_KILL_TERRORIST))
		{
			CPrintToChatAll_Ex(client, false, "\x04[Deathrun]\x03 %s\x01 choosed to kill the\x10 Terrorist.", clientName);
		}
		else
		{
			CPrintToChatAll_Ex(client, false, "\x04[Deathrun]\x03 %s\x01 choosed\x04 %s\x01 as the end.", clientName, endInfo.endName);
		}
		
		int currentTerrorist = GetTerrorist();
		if (currentTerrorist && IsPlayerAlive(currentTerrorist))
		{
			char terroristName[MAX_NAME_LENGTH];
			GetClientName_Ex(currentTerrorist, terroristName, sizeof(terroristName));
			
			if (g_SpeedInfo[currentTerrorist].maxSpeedType != SpeedType_Normal)
			{
				CPrintToChatAll_Ex(currentTerrorist, false, "\x04[Deathrun]\x03 %s\x01 can no longer use\x07 [x%d]\x01 speed.", terroristName, view_as<int>(g_SpeedInfo[currentTerrorist].maxSpeedType));
				
				g_SpeedInfo[currentTerrorist].speedType = SpeedType_Normal;
				g_SpeedInfo[currentTerrorist].maxSpeedType = SpeedType_Normal;
				
				SetEntPropFloat(currentTerrorist, Prop_Data, "m_flLaggedMovementValue", 1.0);
			}
			
			if (view_as<bool>(endInfo.flags & END_TERRORIST_SPEED))
			{
				g_SpeedInfo[currentTerrorist].speedType = SpeedType_Normal;
				g_SpeedInfo[currentTerrorist].maxSpeedType = SpeedType_x3;
				
				CPrintToChatAll_Ex(currentTerrorist, false, "\x04[Deathrun]\x03 %s\x01 can use\x04 [x%d]\x01 speed.", terroristName, view_as<int>(g_SpeedInfo[currentTerrorist].maxSpeedType));
			}
			
			DisplayDuelHudToAll(currentTerrorist, client);
		}
		
		if (view_as<bool>(endInfo.flags & END_TERRORIST_KILLER_SPEED))
		{
			g_SpeedInfo[client].speedType = SpeedType_Normal;
			g_SpeedInfo[client].maxSpeedType = SpeedType_x3;
			CPrintToChatAll_Ex(client, false, "\x04[Deathrun]\x03 %s\x01 can use\x04 [x%d]\x01 speed.", clientName, view_as<int>(g_SpeedInfo[client].maxSpeedType));
		}
	}
	
	g_Map_CurrentEndActivators.SetValue(reference, true);
	return true;
}

bool IsValveWarmupPeriod()
{
	return view_as<bool>(GameRules_GetProp("m_bWarmupPeriod"));
}

bool RemoveReplacedEntitiesFromBreakables(int entity)
{
	char buffer[256];
	Format(buffer, sizeof(buffer), "h:%d", GetEntProp(entity, Prop_Data, "m_iHammerID"));
	
	RangeInfo rangeInfo;
	if (!g_Map_ReplacedTraps.GetArray(buffer, rangeInfo, sizeof(RangeInfo)))
	{
		char entityName[256];
		GetEntPropString(entity, Prop_Data, "m_iName", entityName, sizeof(entityName));
		StringToLower(entityName);
		
		if (!entityName[0])
		{
			return false;
		}
		
		Format(buffer, sizeof(buffer), "n:%s", entityName);
		if (!g_Map_ReplacedTraps.GetArray(buffer, rangeInfo, sizeof(RangeInfo)))
		{
			return false;
		}
	}
	
	for (int i = rangeInfo.rangeStart; i < rangeInfo.rangeEnd; i++)
	{
		g_List_ReplacedTraps.GetString(i, buffer, sizeof(buffer));		
		if (buffer[0] == 'h')
		{
			RemoveEntityHammerIDFromBreakables(StringToInt(buffer[2]), g_Map_BreakablesOnKill, g_List_BreakablesOnKill);
			RemoveEntityHammerIDFromBreakables(StringToInt(buffer[2]), g_Map_BreakablesOnMove, g_List_BreakablesOnMove);
			RemoveEntityHammerIDFromBreakables(StringToInt(buffer[2]), g_Map_BreakablesOnFirstMove, g_List_BreakablesOnFirstMove);
		}
		else
		{
			RemoveEntityNameFromBreakables(buffer[2], g_Map_BreakablesOnKill, g_List_BreakablesOnKill);
			RemoveEntityNameFromBreakables(buffer[2], g_Map_BreakablesOnMove, g_List_BreakablesOnMove);
			RemoveEntityNameFromBreakables(buffer[2], g_Map_BreakablesOnFirstMove, g_List_BreakablesOnFirstMove);
		}
	}
	
	return rangeInfo.rangeStart != rangeInfo.rangeEnd;
}

bool IsEntitySolid(int entity)
{
	if (GetEntProp(entity, Prop_Data, "m_nSolidType") == SOLID_NONE 
		|| view_as<bool>(GetEntProp(entity, Prop_Data, "m_usSolidFlags") & FSOLID_NOT_SOLID))
	{
		return false;
	}
	
	return true;
}

bool CanPlayerRespawnInWarmup(int client)
{
	if (g_TerroristInfo[client].lastRound && g_TerroristInfo[client].lastRound == g_TotalRoundsPlayed)
	{
		return false;
	}
	
	if (g_Cvar_WarmupMaxRespawns.BoolValue && g_NumWarmups[client] >= g_Cvar_WarmupMaxRespawns.IntValue)
	{
		return false;
	}
	
	return true;
}

bool CanPlayersTouchEntity(int entity, ClassType classType)
{
	switch (classType)
	{
		case ClassType_FuncDoor, 
			ClassType_FuncDoorRotating:
		{
			int collisionGroup = GetEntProp(entity, Prop_Data, "m_CollisionGroup");
			if (collisionGroup == COLLISION_GROUP_INTERACTIVE 
				|| collisionGroup == COLLISION_GROUP_PASSABLE_DOOR)
			{
				return false;
			}
		}
		
		case ClassType_FuncPhysBox:
		{
			int collisionGroup = GetEntProp(entity, Prop_Data, "m_CollisionGroup");
			if (collisionGroup == COLLISION_GROUP_DEBRIS)
			{
				return false;
			}
		}
		
		case ClassType_PropPhysics:
		{
			int collisionGroup = GetEntProp(entity, Prop_Data, "m_CollisionGroup");
			if (collisionGroup == COLLISION_GROUP_DEBRIS 
				|| collisionGroup == COLLISION_GROUP_DEBRIS_TRIGGER)
			{
				return false;
			}
		}
		
		case ClassType_TriggerHurt, 
			ClassType_TriggerMultiple, 
			ClassType_TriggerOnce, 
			ClassType_TriggerPush, 
			ClassType_TriggerTeleport:
		{
			int spawnFlags = GetEntProp(entity, Prop_Data, "m_spawnflags");
			if (!view_as<bool>(spawnFlags & SF_TRIGGER_ALLOW_ALL) 
				&& !view_as<bool>(spawnFlags & SF_TRIGGER_ALLOW_CLIENTS))
			{
				return false;
			}
		}
	}
	
	return true;
}

bool CanClientPassTriggerFilter(int entity, int client)
{
	return SDKCall(g_SDKCall_PassesTriggerFilters, entity, client);
}

bool IsEntityEnabled(int entity, ClassType classType)
{
	switch (classType)
	{
		case ClassType_EnvBeam:
		{
			return view_as<bool>(GetEntProp(entity, Prop_Data, "m_active"));
		}
		
		case ClassType_EnvFire:
		{
			return GetEntPropEnt(entity, Prop_Data, "m_hEffect") != -1;
		}
		
		case ClassType_EnvFireSource:
		{
			return view_as<bool>(GetEntProp(entity, Prop_Data, "m_bEnabled"));
		}
		
		case ClassType_EnvGunFire, 
			ClassType_LogicRelay, 
			ClassType_MathCounter:
		{
			return !view_as<bool>(GetEntProp(entity, Prop_Data, "m_bDisabled"));
		}
		
		case ClassType_EnvLaser, ClassType_FuncBrush:
		{
			return !view_as<bool>(GetEntProp(entity, Prop_Data, "m_fEffects") & EF_NODRAW);
		}
		
		case ClassType_EnvSmokeStack:
		{
			return view_as<bool>(GetEntProp(entity, Prop_Data, "m_bEmit"));
		}
		
		case ClassType_FuncPhysBox:
		{
			int flags = GetEntProp(entity, Prop_Data, "m_spawnflags");
			return !view_as<bool>(flags & SF_PHYSBOX_START_ASLEEP) 
				&& !view_as<bool>(flags & SF_PHYSBOX_MOTION_DISABLED);
		}
		
		case ClassType_FuncWallToggle:
		{
			return IsEntitySolid(entity);
		}
		
		case ClassType_GameUI:
		{
			return IsEntityClient(GetEntPropEnt(entity, Prop_Data, "m_player"));
		}
		
		case ClassType_LogicTimer:
		{
			return !view_as<bool>(GetEntProp(entity, Prop_Data, "m_iDisabled"));
		}
		
		case ClassType_PropPhysics:
		{
			int flags = GetEntProp(entity, Prop_Data, "m_spawnflags");
			return !view_as<bool>(flags & SF_PROP_PHYSICS_START_ASLEEP) 
				&& !view_as<bool>(flags & SF_PROP_PHYSICS_MOTION_DISABLED);
		}
		
		case ClassType_TriggerHurt, 
			ClassType_TriggerMultiple, 
			ClassType_TriggerOnce, 
			ClassType_TriggerPush, 
			ClassType_TriggerTeleport:
		{
			return view_as<bool>(GetEntProp(entity, Prop_Data, "m_usSolidFlags") & FSOLID_TRIGGER);
		}
	}
	
	return true;
}

bool IsEntityMoving(int entity, ClassType classType)
{
	switch (classType)
	{
		case ClassType_FuncDoor, ClassType_FuncDoorRotating:
		{
			int toggleState = GetEntProp(entity, Prop_Data, "m_toggle_state");
			return (toggleState == TS_GOING_UP || toggleState == TS_GOING_DOWN);
		}
		
		case ClassType_FuncRotating, ClassType_FuncTankTrain, ClassType_FuncTrackTrain:
		{
			return view_as<bool>(FloatAbs(GetEntitySpeed(entity)) != 0.0);
		}
		
		case ClassType_FuncTrain:
		{
			return !view_as<bool>(GetEntProp(entity, Prop_Data, "m_spawnflags") & SF_TRAIN_WAIT_RETRIGGER);
		}
	}
	
	return false;
}

bool IsDirForward(int entity, ClassType classType)
{
	switch (classType)
	{
		case ClassType_FuncRotating:
		{
			return !view_as<bool>(GetEntProp(entity, Prop_Data, "m_bReversed"));
		}
		
		case ClassType_FuncTankTrain, ClassType_FuncTrackTrain:
		{
			return GetEntPropFloat(entity, Prop_Data, "m_dir") == 1.0;
		}
	}
	
	return true;
}

bool CanEntityDamageClients(int entity, ClassType classType)
{
	switch (classType)
	{
		case ClassType_EnvBeam, ClassType_EnvLaser, ClassType_TriggerHurt:
		{
			return view_as<bool>(GetEntPropFloat(entity, Prop_Data, "m_flDamage") > 0.0);
		}
	}
	
	return false;
}

bool CanEntityHealClients(int entity, ClassType classType)
{
	switch (classType)
	{
		case ClassType_TriggerHurt:
		{
			return view_as<bool>(GetEntPropFloat(entity, Prop_Data, "m_flDamage") < 0.0);
		}
	}
	
	return false;
}

bool HasEntityValidDestination(int entity)
{
	char target[256];
	GetEntPropString(entity, Prop_Data, "m_target", target, sizeof(target));
	
	return (target[0] && FindEntityByName(-1, target) != -1);
}

bool IsEntityClient(int client)
{
	return (client > 0 && client <= MaxClients);
}

bool IsClientOnLadder(int client)
{
	return view_as<bool>(GetEntityMoveType(client) & MOVETYPE_LADDER);
}

bool IsClientSurfing(int client)
{
	float vecOrigin[3];
	float vecMins[3];
	float vecMaxs[3];
	
	GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", vecOrigin);
	GetEntPropVector(client, Prop_Data, "m_vecMins", vecMins);
	GetEntPropVector(client, Prop_Data, "m_vecMaxs", vecMaxs);
	
	float vecTarget[3];
	vecTarget = vecOrigin;
	vecTarget[2] -= 0.1;
	
	TR_TraceHullFilter(vecOrigin, vecTarget, vecMins, vecMaxs, MASK_PLAYERSOLID_BRUSHONLY, TR_FilterPlayers);
	if (TR_DidHit())
	{
		float vecPlane[3];
		TR_GetPlaneNormal(INVALID_HANDLE, vecPlane);
		return (vecPlane[2] > 0.0 && vecPlane[2] < 0.7);
	}
	
	return false;
}

bool IsClientOnGround(int client)
{
	return (view_as<bool>(GetEntityFlags(client) & FL_ONGROUND) || IsClientOnLadder(client) || IsClientSurfing(client));
}

bool IsClientInBoxArea(float clientOrigin[3], float clientMins[3], float clientMaxs[3], float pointMin[3], float pointMax[3])
{
	for (int i = 0; i < 3; i++)
	{
		if (clientOrigin[i] <= pointMin[i] + clientMins[i] || clientOrigin[i] >= pointMax[i] + clientMaxs[i])
		{
			return false;
		}
	}
	
	return true;
}

bool RemoveEntityHammerIDFromBreakables(int hammerId, IntMap& map, ArrayList& list)
{
	BreakableInfo breakableInfo;
	if (!map.GetArray(hammerId, breakableInfo, sizeof(BreakableInfo)))
	{
		return false;
	}
	
	map.Remove(hammerId);
	RemoveCellFromArrayList(hammerId, list);
	
	TrapInfo trapInfo;
	if (g_Map_Traps.GetArray(breakableInfo.entityRef, trapInfo, sizeof(TrapInfo)))
	{
		trapInfo.flags &= ~TRAP_IN_BREAKABLES_ON_KILL;
		trapInfo.flags &= ~TRAP_IN_BREAKABLES_ON_MOVE;
		trapInfo.flags &= ~TRAP_IN_BREAKABLES_ON_FIRST_MOVE;
		trapInfo.flags &= ~TRAP_IN_BREAKABLES_ON_SPEED;
		trapInfo.flags &= ~TRAP_IN_BREAKABLES_ON_REVERSE;
		
		trapInfo.flags &= ~TRAP_CHILD_IN_BREAKABLES_ON_KILL;
		trapInfo.flags &= ~TRAP_CHILD_IN_BREAKABLES_ON_MOVE;
		trapInfo.flags &= ~TRAP_CHILD_IN_BREAKABLES_ON_FIRST_MOVE;
		trapInfo.flags &= ~TRAP_CHILD_IN_BREAKABLES_ON_SPEED;
		trapInfo.flags &= ~TRAP_CHILD_IN_BREAKABLES_ON_REVERSE;
		
		g_Map_Traps.SetArray(breakableInfo.entityRef, trapInfo, sizeof(TrapInfo));
	}
	
	RemoveHammerIDChildrenFromBreakables(hammerId, map, list);	
	return true;
}

bool RemoveEntityNameFromBreakables(const char[] entityName, IntMap& map, ArrayList& list)
{
	if (!entityName[0])
	{
		return false;
	}
	
	bool removeFromBreakables;
	BreakableInfo breakableInfo;
	
	for (int i = list.Length - 1; i >= 0; i--)
	{
		int hammerId = list.Get(i);
		if (!map.GetArray(hammerId, breakableInfo, sizeof(BreakableInfo)))
		{
			list.Erase(i);
			continue;
		}
		
		if (!StrEqual(entityName, breakableInfo.entityName, false))
		{
			continue;
		}
		
		map.Remove(hammerId);
		list.Erase(i);
		
		TrapInfo trapInfo;
		if (g_Map_Traps.GetArray(breakableInfo.entityRef, trapInfo, sizeof(TrapInfo)))
		{
			trapInfo.flags &= ~TRAP_IN_BREAKABLES_ON_KILL;
			trapInfo.flags &= ~TRAP_IN_BREAKABLES_ON_MOVE;
			trapInfo.flags &= ~TRAP_IN_BREAKABLES_ON_FIRST_MOVE;
			trapInfo.flags &= ~TRAP_IN_BREAKABLES_ON_SPEED;
			trapInfo.flags &= ~TRAP_IN_BREAKABLES_ON_REVERSE;
			
			trapInfo.flags &= ~TRAP_CHILD_IN_BREAKABLES_ON_KILL;
			trapInfo.flags &= ~TRAP_CHILD_IN_BREAKABLES_ON_MOVE;
			trapInfo.flags &= ~TRAP_CHILD_IN_BREAKABLES_ON_FIRST_MOVE;
			trapInfo.flags &= ~TRAP_CHILD_IN_BREAKABLES_ON_SPEED;
			trapInfo.flags &= ~TRAP_CHILD_IN_BREAKABLES_ON_REVERSE;
			
			g_Map_Traps.SetArray(breakableInfo.entityRef, trapInfo, sizeof(TrapInfo));
		}
		
		removeFromBreakables = true;		
		if (RemoveHammerIDChildrenFromBreakables(hammerId, map, list))
		{
			i = list.Length - 1;
		}
	}
	
	return removeFromBreakables;
}

bool RemoveHammerIDChildrenFromBreakables(int parentHammer, IntMap& map, ArrayList& list)
{
	bool removeFromBreakables;
	BreakableInfo breakableInfo;
	
	for (int i = list.Length - 1; i >= 0; i--)
	{
		int hammerId = list.Get(i);
		if (!map.GetArray(hammerId, breakableInfo, sizeof(BreakableInfo)) 
			|| breakableInfo.parentHammer != parentHammer)
		{
			continue;
		}
		
		list.Erase(i);
		map.Remove(breakableInfo.hammerId);
		
		TrapInfo trapInfo;
		if (g_Map_Traps.GetArray(breakableInfo.entityRef, trapInfo, sizeof(TrapInfo)))
		{
			trapInfo.flags &= ~TRAP_IN_BREAKABLES_ON_KILL;
			trapInfo.flags &= ~TRAP_IN_BREAKABLES_ON_MOVE;
			trapInfo.flags &= ~TRAP_IN_BREAKABLES_ON_FIRST_MOVE;
			trapInfo.flags &= ~TRAP_IN_BREAKABLES_ON_SPEED;
			trapInfo.flags &= ~TRAP_IN_BREAKABLES_ON_REVERSE;
			
			trapInfo.flags &= ~TRAP_CHILD_IN_BREAKABLES_ON_KILL;
			trapInfo.flags &= ~TRAP_CHILD_IN_BREAKABLES_ON_MOVE;
			trapInfo.flags &= ~TRAP_CHILD_IN_BREAKABLES_ON_FIRST_MOVE;
			trapInfo.flags &= ~TRAP_CHILD_IN_BREAKABLES_ON_SPEED;
			trapInfo.flags &= ~TRAP_CHILD_IN_BREAKABLES_ON_REVERSE;
			
			g_Map_Traps.SetArray(breakableInfo.entityRef, trapInfo, sizeof(TrapInfo));
		}
		
		removeFromBreakables = true;
		if (RemoveHammerIDChildrenFromBreakables(hammerId, map, list))
		{
			i = list.Length - 1;
		}
	}
	
	return removeFromBreakables;
}

bool IsEntityActivatingEnd(int entity, int& endId = 0)
{
	char key[256];	
	FormatEx(key, sizeof(key), "h:%d", GetEntProp(entity, Prop_Data, "m_iHammerID"));
	
	if (g_Map_EndActivators.GetValue(key, endId))
	{
		return true;
	}
	
	GetEntPropString(entity, Prop_Data, "m_iName", key, sizeof(key));
	if (key[0])
	{
		StringToLower(key);
		Format(key, sizeof(key), "n:%s", key);
		return g_Map_EndActivators.GetValue(key, endId);
	}
	
	return false;
}

bool IsEntityActivatingTrap(int entity, TrapActivatorInfo trapActivatorInfo)
{
	char key[256];	
	FormatEx(key, sizeof(key), "h:%d", GetEntProp(entity, Prop_Data, "m_iHammerID"));
	
	if (g_Map_TrapActivators.GetArray(key, trapActivatorInfo, sizeof(TrapActivatorInfo)))
	{
		return true;
	}
	
	GetEntPropString(entity, Prop_Data, "m_iName", key, sizeof(key));
	if (key[0])
	{
		StringToLower(key);
		Format(key, sizeof(key), "n:%s", key);
		return g_Map_TrapActivators.GetArray(key, trapActivatorInfo, sizeof(TrapActivatorInfo));
	}
	
	return false;
}

bool SetClientMaxVelocity(int client, float maxSpeed)
{
	float velocity[3];	
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);
	
	float velocity2 = velocity[2];
	velocity[2] = 0.0;
	
	float currentSpeed = GetVectorLength(velocity);
	if (currentSpeed > maxSpeed)
	{
		float factor = currentSpeed / maxSpeed;
		if (factor)
		{
			velocity[0] /= factor;
			velocity[1] /= factor;
			velocity[2] = velocity2;
			
			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
			return true;
		}
	}
	
	return false;
}

bool ChangeRoundTimeLeft(int newTime)
{
	int timeLeft = RoundToZero(GetRoundTimeleft());
	if (timeLeft > newTime)
	{
		SetRoundTime(newTime + GetRoundTime() - timeLeft);
		return true;
	}
	
	return false;
}

bool IsEntityInSpawnPosition(int entity, float spawnOrigin[3])
{
	float vecOrigin[3];
	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vecOrigin);
	return (!RoundToZero(GetVectorDistance(vecOrigin, spawnOrigin)));
}

bool HasEntitySpawnAngles(int entity, ClassType classType)
{
	switch (classType)
	{
		case ClassType_FuncDoorRotating:
		{
			int distance = RoundToZero(GetEntPropFloat(entity, Prop_Data, "m_flMoveDistance"));
			return (!view_as<bool>(distance % 360));
		}
		
		case ClassType_FuncRotating:
		{
			float vecRotation[3];
			int spawnFlags = GetEntProp(entity, Prop_Data, "m_spawnflags");
			GetEntPropVector(entity, Prop_Data, "m_angAbsRotation", vecRotation);
			
			if (view_as<bool>(spawnFlags & SF_BRUSH_ROTATE_X_AXIS))
			{
				return (!view_as<bool>(RoundToZero(vecRotation[2]) % 360));
			}
			else if (view_as<bool>(spawnFlags & SF_BRUSH_ROTATE_Y_AXIS))
			{
				return (!view_as<bool>(RoundToZero(vecRotation[0]) % 360));
			}
			else
			{
				return (!view_as<bool>(RoundToZero(vecRotation[1]) % 360));
			}
		}
	}
	
	return false;
}

bool IsMapFinishedByAllCTs(int& numFinishers = 0, int ignoreClient = 0)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (i == ignoreClient || !IsClientInGame(i) || !IsPlayerAlive(i) && !g_RespawnInfo[i].respawnTime || GetClientTeam(i) != CS_TEAM_CT)
		{
			continue;
		}
		
		if (!view_as<bool>(g_PlayerFlags[i] & PLAYER_HAS_FINISHED_MAP))
		{
			return false;
		}
		
		numFinishers++;
	}
	
	return view_as<bool>(numFinishers);
}

bool IsWeaponKnife(int weapon)
{
	char netClass[256];
	GetEntityNetClass(weapon, netClass, sizeof(netClass));
	return !strncmp(netClass, "CKnife", 6, true);
}

bool IsClientInTrapProximity(int client, int &activatorId)
{
	float gameTime = GetGameTime();
	float clientOrigin[3];
	float clientMins[3];
	float clientMaxs[3];
	
	GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", clientOrigin);
	GetEntPropVector(client, Prop_Data, "m_vecMins", clientMins);
	GetEntPropVector(client, Prop_Data, "m_vecMaxs", clientMaxs);
	
	VectorToNearest(clientOrigin);
	AddVectors(clientMins, clientOrigin, clientMins);
	AddVectors(clientMaxs, clientOrigin, clientMaxs);
	
	GetMiddleOfBox(clientMins, clientMaxs, clientOrigin);
	
	if (g_List_BreakablesOnKill.Length)
	{
		BreakableInfo breakableInfo;
		for (int i = g_List_BreakablesOnKill.Length - 1; i >= 0; i--)
		{
			int hammerId = g_List_BreakablesOnKill.Get(i);
			if (!g_Map_BreakablesOnKill.GetArray(hammerId, breakableInfo, sizeof(BreakableInfo)))
			{
				g_List_BreakablesOnKill.Erase(i);
				continue;
			}
			
			if (breakableInfo.removeTime && gameTime > breakableInfo.removeTime)
			{
				TrapInfo trapInfo;
				if (g_Map_Traps.GetArray(breakableInfo.entityRef, trapInfo, sizeof(TrapInfo)))
				{
					trapInfo.flags &= ~TRAP_IN_BREAKABLES_ON_KILL;
					trapInfo.flags &= ~TRAP_CHILD_IN_BREAKABLES_ON_KILL;
					g_Map_Traps.SetArray(breakableInfo.entityRef, trapInfo, sizeof(TrapInfo));
				}
				
				g_List_BreakablesOnKill.Erase(i);
				continue;
			}
			
			if (!IsClientInBoxArea(clientOrigin, clientMins, clientMaxs, breakableInfo.pointMin, breakableInfo.pointMax))
			{
				continue;
			}
			
			activatorId = breakableInfo.activatorId;
			return true;
		}
	}
	
	if (g_List_BreakablesOnMove.Length)
	{
		BreakableInfo breakableInfo;
		for (int i = g_List_BreakablesOnMove.Length - 1; i >= 0; i--)
		{
			int hammerId = g_List_BreakablesOnMove.Get(i);
			if (!g_Map_BreakablesOnMove.GetArray(hammerId, breakableInfo, sizeof(BreakableInfo)))
			{
				g_List_BreakablesOnMove.Erase(i);
				continue;
			}
			
			if (breakableInfo.removeTime && gameTime > breakableInfo.removeTime)
			{
				TrapInfo trapInfo;
				if (g_Map_Traps.GetArray(breakableInfo.entityRef, trapInfo, sizeof(TrapInfo)))
				{
					trapInfo.flags &= ~TRAP_IN_BREAKABLES_ON_MOVE;
					trapInfo.flags &= ~TRAP_CHILD_IN_BREAKABLES_ON_MOVE;
					g_Map_Traps.SetArray(breakableInfo.entityRef, trapInfo, sizeof(TrapInfo));
				}
				
				g_List_BreakablesOnMove.Erase(i);
				continue;
			}
			
			if (!IsClientInBoxArea(clientOrigin, clientMins, clientMaxs, breakableInfo.pointMin, breakableInfo.pointMax))
			{
				continue;
			}
			
			activatorId = breakableInfo.activatorId;
			return true;
		}
	}
	
	if (g_List_BreakablesOnFirstMove.Length)
	{
		BreakableInfo breakableInfo;
		for (int i = g_List_BreakablesOnFirstMove.Length - 1; i >= 0; i--)
		{
			int hammerId = g_List_BreakablesOnFirstMove.Get(i);
			if (!g_Map_BreakablesOnFirstMove.GetArray(hammerId, breakableInfo, sizeof(BreakableInfo)))
			{
				g_List_BreakablesOnFirstMove.Erase(i);
				continue;
			}
			
			if (breakableInfo.removeTime && gameTime > breakableInfo.removeTime)
			{
				TrapInfo trapInfo;
				if (g_Map_Traps.GetArray(breakableInfo.entityRef, trapInfo, sizeof(TrapInfo)))
				{
					trapInfo.flags &= ~TRAP_IN_BREAKABLES_ON_FIRST_MOVE;
					trapInfo.flags &= ~TRAP_CHILD_IN_BREAKABLES_ON_FIRST_MOVE;
					g_Map_Traps.SetArray(breakableInfo.entityRef, trapInfo, sizeof(TrapInfo));
				}
				
				g_List_BreakablesOnFirstMove.Erase(i);
				continue;
			}
			
			if (!IsClientInBoxArea(clientOrigin, clientMins, clientMaxs, breakableInfo.pointMin, breakableInfo.pointMax))
			{
				continue;
			}
			
			activatorId = breakableInfo.activatorId;
			return true;
		}
	}
	
	if (g_List_BreakablesOnSpeed.Length)
	{
		BreakableInfo breakableInfo;
		for (int i = g_List_BreakablesOnSpeed.Length - 1; i >= 0; i--)
		{
			int hammerId = g_List_BreakablesOnSpeed.Get(i);
			if (!g_Map_BreakablesOnSpeed.GetArray(hammerId, breakableInfo, sizeof(BreakableInfo)))
			{
				g_List_BreakablesOnSpeed.Erase(i);
				continue;
			}
			
			if (breakableInfo.removeTime && gameTime > breakableInfo.removeTime)
			{
				TrapInfo trapInfo;
				if (g_Map_Traps.GetArray(breakableInfo.entityRef, trapInfo, sizeof(TrapInfo)))
				{
					trapInfo.flags &= ~TRAP_IN_BREAKABLES_ON_SPEED;
					trapInfo.flags &= ~TRAP_CHILD_IN_BREAKABLES_ON_SPEED;
					g_Map_Traps.SetArray(breakableInfo.entityRef, trapInfo, sizeof(TrapInfo));
				}
				
				g_List_BreakablesOnSpeed.Erase(i);
				continue;
			}
			
			if (!IsClientInBoxArea(clientOrigin, clientMins, clientMaxs, breakableInfo.pointMin, breakableInfo.pointMax))
			{
				continue;
			}
			
			activatorId = breakableInfo.activatorId;
			return true;
		}
	}
	
	if (g_List_BreakablesOnReverse.Length)
	{
		BreakableInfo breakableInfo;
		for (int i = g_List_BreakablesOnReverse.Length - 1; i >= 0; i--)
		{
			int hammerId = g_List_BreakablesOnReverse.Get(i);
			if (!g_Map_BreakablesOnReverse.GetArray(hammerId, breakableInfo, sizeof(BreakableInfo)))
			{
				g_List_BreakablesOnReverse.Erase(i);
				continue;
			}
			
			if (breakableInfo.removeTime && gameTime > breakableInfo.removeTime)
			{
				TrapInfo trapInfo;
				if (g_Map_Traps.GetArray(breakableInfo.entityRef, trapInfo, sizeof(TrapInfo)))
				{
					trapInfo.flags &= ~TRAP_IN_BREAKABLES_ON_REVERSE;
					trapInfo.flags &= ~TRAP_CHILD_IN_BREAKABLES_ON_REVERSE;
					g_Map_Traps.SetArray(breakableInfo.entityRef, trapInfo, sizeof(TrapInfo));
				}
				
				g_List_BreakablesOnReverse.Erase(i);
				continue;
			}
			
			if (!IsClientInBoxArea(clientOrigin, clientMins, clientMaxs, breakableInfo.pointMin, breakableInfo.pointMax))
			{
				continue;
			}
			
			activatorId = breakableInfo.activatorId;
			return true;
		}
	}
	
	clientMins[0] -= 16.0;
	clientMins[1] -= 16.0;
	clientMins[2] -= 8.0;
	
	clientMaxs[0] += 16.0;
	clientMaxs[1] += 16.0;
	clientMaxs[2] += 8.0;
	
	if (g_List_ProximityTraps.Length)
	{
		float pointMin[3];
		float pointMax[3];
		float vecMins[3];
		float vecMaxs[3];
		float vecOrigin[3];
		TrapInfo trapInfo;
		
		for (int i = g_List_ProximityTraps.Length - 1; i >= 0; i--)
		{
			int reference = g_List_ProximityTraps.Get(i);
			if (!g_Map_Traps.GetArray(reference, trapInfo, sizeof(TrapInfo)))
			{
				g_List_ProximityTraps.Erase(i);
				continue;
			}
			
			int entity = EntRefToEntIndex(reference);
			if (!IsValidEntity(entity))
			{
				g_List_ProximityTraps.Erase(i);
				continue;
			}
			
			GetEntityBounds(entity, pointMin, pointMax);
			
			vecMins = pointMin;
			vecMaxs = pointMax;
			GetMiddleOfBox(vecMins, vecMaxs, vecOrigin);
			
			if (!IsClientInBoxArea(clientOrigin, clientMins, clientMaxs, pointMin, pointMax))
			{
				continue;
			}
			
			if ((trapInfo.classType == ClassType_TriggerHurt 
					|| trapInfo.classType == ClassType_TriggerPush 
					|| trapInfo.classType == ClassType_TriggerTeleport) 
				&& !CanClientPassTriggerFilter(entity, client))
			{
				continue;
			}
			
			TR_TraceRayFilter(clientOrigin, vecOrigin, MASK_PLAYERSOLID, RayType_EndPoint, TR_FilterPlayers);
			if (TR_DidHit() && TR_GetEntityIndex() != entity)
			{
				continue;
			}
			
			activatorId = trapInfo.activatorId;
			return true;
		}
	}
	
	return false;
}

int GetTerrorist()
{
	if (g_TerroristId)
	{
		int currentTerrorist = GetClientOfUserId(g_TerroristId);
		if (currentTerrorist && IsClientInGame(currentTerrorist))
		{
			return currentTerrorist;
		}
	}
	
	return 0;
}

int GetFakeTerrorist()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsFakeClient(i))
		{
			continue;
		}
		
		return i;
	}
	
	return 0;
}

int GetTerroristKiller()
{
	if (g_TerroristKillerId)
	{
		int terroristKiller = GetClientOfUserId(g_TerroristKillerId);
		if (terroristKiller && IsClientInGame(terroristKiller))
		{
			return terroristKiller;
		}
	}
	
	return 0;
}

int FindTarget_Ex(int client, const char[] target, int flags = 0)
{
	char target_name[MAX_TARGET_LENGTH];
	int target_list[1], target_count;
	bool tn_is_ml;
	
	if ((target_count = ProcessTargetString(target, client, target_list, sizeof(target_list), COMMAND_FILTER_NO_MULTI | flags, target_name, sizeof(target_name), tn_is_ml)) > 0)
	{
		return target_list[0];
	}
	
	ReplyToTargetError(client, target_count);
	return -1;
}

int EntIndexToEntRef_Ex(int entity)
{
	if (entity == -1)
	{
		return INVALID_ENT_REFERENCE;
	}
	
	if (entity < 0 || entity > 4096)
	{
		return entity;
	}
	
	return EntIndexToEntRef(entity);
}

int FindEntityByName(int entity, const char[] targetName)
{
	if (!targetName[0])
	{
		return -1;
	}
	
	char buffer[256];
	int length = strlen(targetName);
	
	while ((entity = FindEntityByClassname(entity, "*")) != -1)
	{
		GetEntPropString(entity, Prop_Data, "m_iName", buffer, sizeof(buffer));
		if (!buffer[0])
		{
			continue;
		}
		
		if (targetName[length - 1] != '*')
		{
			if (StrEqual(buffer, targetName, false))
			{
				return entity;
			}
		}
		else
		{
			if (!strncmp(buffer, targetName, length - 1, false))
			{
				return entity;
			}
		}
	}
	
	return -1;
}

int GetRoundTime()
{
	return GameRules_GetProp("m_iRoundTime");
}

int GetTerroristFromQueue()
{
	if (g_List_TerroristQueue.Length)
	{
		for (int i = 0; i < g_List_TerroristQueue.Length; i++)
		{
			int client = GetClientOfUserId(g_List_TerroristQueue.Get(i));
			if (!client)
			{
				g_List_TerroristQueue.Erase(i--);
				continue;
			}
			
			if (GetClientTerroristDelay(client))
			{
				break;
			}
			
			g_List_TerroristQueue.Erase(i);
			return client;
		}
	}
	
	return 0;
}

int GetRandomTerrorist()
{
	if (!g_Cvar_RandomTerroristEnable.BoolValue)
	{
		return 0;
	}
	
	int client = 0;
	int numClients = 0;
	float lastTime = GetGameTime();
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i) || GetClientTeam(i) < CS_TEAM_T)
		{
			continue;
		}
		
		numClients++;
		if (GetClientTerroristDelay(i) || g_TerroristInfo[i].lastTime >= lastTime)
		{
			continue;
		}
		
		client = i;
		lastTime = g_TerroristInfo[i].lastTime;
	}
	
	if (g_Cvar_RandomTerroristMinPlayers.BoolValue 
		&& numClients < g_Cvar_RandomTerroristMinPlayers.IntValue)
	{
		return 0;
	}
	
	return client;
}

int GetClientPositionInQueue(int client)
{
	int delay = GetClientTerroristDelay(client);
	for (int i = g_List_TerroristQueue.Length - 1; i >= 0; i--)
	{
		int player = GetClientOfUserId(g_List_TerroristQueue.Get(i));
		if (!player)
		{
			g_List_TerroristQueue.Erase(i);
			continue;
		}
		
		if (delay > GetClientTerroristDelay(player) 
			|| g_TerroristInfo[client].lastTime > g_TerroristInfo[player].lastTime)
		{
			return i;
		}
	}
	
	return 0;
}

int GetClientTerroristDelay(int client)
{
	if (!g_Cvar_TerroristRoundsDelay.BoolValue || !g_TerroristInfo[client].lastRound)
	{
		return 0;
	}
	
	int delay = g_TerroristInfo[client].lastRound + g_Cvar_TerroristRoundsDelay.IntValue - g_TotalRoundsPlayed + 1;
	SetLowerBound(delay, 0);
	
	return delay;
}

int GetNextTerroristKiller()
{
	int terroristKiller = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i) || GetClientTeam(i) != CS_TEAM_CT || !g_FinishInfo[i].finishPos)
		{
			continue;
		}
		
		if (terroristKiller)
		{
			if (g_FinishInfo[i].finishPos < g_FinishInfo[terroristKiller].finishPos)
			{
				terroristKiller = i;
			}
		}
		else
		{
			terroristKiller = i;
		}
	}
	
	return terroristKiller;
}

int GetClientObserverMode(int client)
{
	return GetEntProp(client, Prop_Send, "m_iObserverMode");
}

int GetClientObserverTarget(int client)
{
	int observerTarget = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
	if (observerTarget != -1 && observerTarget != client && IsClientInGame(observerTarget))
	{
		return observerTarget;
	}
	
	return 0;
}

int CreateStripEntity()
{
	int entity = CreateEntityByName("game_player_equip");
	if (entity != -1)
	{
		DispatchKeyValue(entity, "spawnflags", "3");
		
		DispatchSpawn(entity);
		ActivateEntity(entity);
	}
	
	return entity;
}

int CreateAmmoEntity()
{
	int entity = CreateEntityByName("point_give_ammo");
	if (entity != -1)
	{		
		DispatchSpawn(entity);
		ActivateEntity(entity);
	}
	
	return entity;
}

int CreateTriggerEntity(float pointMin[3], float pointMax[3])
{
	int entity = CreateEntityByName("trigger_multiple");
	if (entity != -1)
	{
		float vecMins[3];
		float vecMaxs[3];
		float vecOrigin[3];
		
		vecMins = pointMin;
		vecMaxs = pointMax;
		
		GetMiddleOfBox(vecMins, vecMaxs, vecOrigin);
		DispatchKeyValueVector(entity, "origin", vecOrigin);
		
		DispatchKeyValue(entity, "wait", "0.1");
		DispatchKeyValue(entity, "spawnflags", "4097");
		
		DispatchSpawn(entity);
		ActivateEntity(entity);
		
		SetEntityModel(entity, "models/error.mdl");
		SetEntProp(entity, Prop_Send, "m_nSolidType", SOLID_BBOX);
		SetEntProp(entity, Prop_Send, "m_fEffects", EF_NODRAW);
		
		SetEntPropVector(entity, Prop_Data, "m_vecMins", vecMins);
		SetEntPropVector(entity, Prop_Data, "m_vecMaxs", vecMaxs);
	}
	
	return entity;
}

int CreateHurtEntity(float pointMin[3], float pointMax[3])
{
	int entity = CreateEntityByName("trigger_hurt");
	if (entity != -1)
	{
		float vecMins[3];
		float vecMaxs[3];
		float vecOrigin[3];
		
		vecMins = pointMin;
		vecMaxs = pointMax;
		
		GetMiddleOfBox(vecMins, vecMaxs, vecOrigin);
		DispatchKeyValueVector(entity, "origin", vecOrigin);
		
		DispatchKeyValue(entity, "damage", "1000");
		DispatchKeyValue(entity, "damagecap", "1000");
		DispatchKeyValue(entity, "spawnflags", "4097");
		
		DispatchSpawn(entity);
		ActivateEntity(entity);
		
		SetEntityModel(entity, "models/error.mdl");
		SetEntProp(entity, Prop_Send, "m_nSolidType", SOLID_BBOX);
		SetEntProp(entity, Prop_Send, "m_fEffects", EF_NODRAW);
		
		SetEntPropVector(entity, Prop_Data, "m_vecMins", vecMins);
		SetEntPropVector(entity, Prop_Data, "m_vecMaxs", vecMaxs);
	}
	
	return entity;
}

int CreateSolidEntity(float pointMin[3], float pointMax[3])
{
	int entity = CreateEntityByName("func_wall_toggle");
	if (entity != -1)
	{
		float vecMins[3];
		float vecMaxs[3];
		float vecOrigin[3];
		
		vecMins = pointMin;
		vecMaxs = pointMax;
		
		GetMiddleOfBox(vecMins, vecMaxs, vecOrigin);
		DispatchKeyValueVector(entity, "origin", vecOrigin);
		
		DispatchSpawn(entity);
		ActivateEntity(entity);
		
		SetEntityModel(entity, "models/error.mdl");
		SetEntProp(entity, Prop_Send, "m_nSolidType", SOLID_BBOX);
		SetEntProp(entity, Prop_Send, "m_fEffects", EF_NODRAW);
		
		SetEntPropVector(entity, Prop_Data, "m_vecMins", vecMins);
		SetEntPropVector(entity, Prop_Data, "m_vecMaxs", vecMaxs);
	}
	
	return entity;
}

int FormatTimeDuration(char[] buffer, int maxlen, float time)
{
	int days = RoundToZero(time) / 86400;
	if (days)
	{
		return FormatEx(buffer, maxlen, "%dd", days);
	}
	
	int length = 0;
	int hours = (RoundToZero(time) / 3600) % 24;
	int minutes = (RoundToZero(time) / 60) % 60;
	
	if (hours)
	{
		if (length)
		{
			length = Format(buffer, maxlen, "%s %dh", buffer, hours);
		}
		else
		{
			length = FormatEx(buffer, maxlen, "%dh", hours);
		}
	}
	
	if (minutes)
	{
		if (length)
		{
			length = Format(buffer, maxlen, "%s %dm", buffer, minutes);
		}
		else
		{
			length = FormatEx(buffer, maxlen, "%dm", minutes);
		}
	}
	
	if (length)
	{
		return length;
	}
	
	int seconds = RoundToZero(time) % 60;
	if (seconds)
	{
		return FormatEx(buffer, maxlen, "%ds", seconds);
	}
	
	return FormatEx(buffer, maxlen, "%dms", RoundToZero(time * 1000));
}

float GetRoundStartTime()
{
	return GameRules_GetPropFloat("m_fRoundStartTime");
}

float GetRoundTimeleft()
{
	return float(GetRoundTime()) - (GetGameTime() - GetRoundStartTime());
}

float GetClientVelocity(int client)
{
	float velocity[3];
	velocity[0] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[0]");
	velocity[1] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[1]");
	return GetVectorLength(velocity);
}

float GetClientVelocityFactor(int client)
{
	return GetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue");
}

float GetEntitySpeed(int entity)
{
	return GetEntPropFloat(entity, Prop_Data, "m_flSpeed");
}

public int Native_GetTerrorist(Handle hPlugin, int numParams)
{
	return GetTerrorist();
}

public int Native_GetTerroristKiller(Handle hPlugin, int numParams)
{
	return GetTerroristKiller();
}

public int Native_HasClientReceivedLife(Handle hPlugin, int numParams)
{
	int client = GetNativeCell(1);
	if (client < 1 || client > MaxClients)
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index %d", client);
	}
	
	if (!IsClientConnected(client))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not connected", client);
	}
	
	return view_as<bool>(g_PlayerFlags[client] & PLAYER_HAS_RECEIVED_LIFE);
}