// ******************************************************************************************
// * This project is licensed under the GNU Affero GPL v3. Copyright © 2014 A3Wasteland.com *
// ******************************************************************************************
//@file Version: 1.1
//@file Name: init.sqf
//@file Author: [404] Deadbeat, [GoT] JoSchaap, AgentRev, [KoS] Bewilderbeest
//@file Created: 20/11/2012 05:19
//@file Description: The client init.

if (isDedicated) exitWith {};

if (!isServer) then
{
	waitUntil {!isNil "A3W_network_compileFuncs"};
};

waitUntil {!isNil "A3W_serverSetupComplete"};

[] execVM "client\functions\bannedNames.sqf";

showPlayerIcons = true;
mutexScriptInProgress = false;
respawnDialogActive = false;
groupManagmentActive = false;
pvar_PlayerTeamKiller = [];
doCancelAction = false;

//AJ Beacondetector
BeaconScanInProgress = false;

//Initialization Variables
playerCompiledScripts = false;
playerSetupComplete = false;

waitUntil {!isNull player && time > 0};

removeAllWeapons player;
player switchMove "";

// initialize actions and inventory
"client\actions" call mf_init;
"client\inventory" call mf_init;
"client\items" call mf_init;

//Call client compile list.
call compile preprocessFileLineNumbers "client\functions\clientCompile.sqf";

//Stop people being civ's.
if !(playerSide in [BLUFOR,OPFOR,INDEPENDENT]) exitWith
{
	endMission "LOSER";
};

//Setup player events.
if (!isNil "client_initEH") then { player removeEventHandler ["Respawn", client_initEH] };
player addEventHandler ["Respawn", { _this spawn onRespawn }];
player addEventHandler ["Killed", onKilled];

call compile preprocessFileLineNumbers "addons\far_revive\FAR_revive_init.sqf";

A3W_scriptThreads pushBack execVM "client\functions\evalManagedActions.sqf";

[player, objNull] remoteExec ["A3W_fnc_playerRespawnServer", 2];

//Player setup
player call playerSetupStart;

// Deal with money here
_baseMoney = ["A3W_startingMoney", 100] call getPublicVar;
//player setVariable ["cmoney", _baseMoney, true];
[player, _baseMoney, true] call A3W_fnc_setCMoney;

// Player saving - load data
if (["A3W_playerSaving"] call isConfigOn) then
{
	call compile preprocessFileLineNumbers "persistence\client\players\setupPlayerDB.sqf";
	call fn_requestPlayerData;

	waitUntil {!isNil "playerData_loaded"};

	A3W_scriptThreads pushBack ([] spawn
	{
		scriptName "savePlayerLoop";

		// Save player every 60s
		while {true} do
		{
			sleep 60;
			call fn_savePlayerData;
		};
	});
};

if (isNil "playerData_alive") then
{
	player call playerSetupGear;
};

player call playerSetupEnd;

diag_log format ["Player starting with $%1", (player getVariable ["cmoney", 0]) call fn_numToStr];

[] execVM "territory\client\hideDisabledTerritories.sqf";

// Territory system enabled?
if (count (["config_territory_markers", []] call getPublicVar) > 0) then
{
	A3W_fnc_territoryActivityHandler = "territory\client\territoryActivityHandler.sqf" call mf_compile;
	[] execVM "territory\client\setupCaptureTriggers.sqf";
};

//Setup player menu scroll action.
//[] execVM "client\clientEvents\onMouseWheel.sqf";

// Load custom keys from profile
call compile preprocessFileLineNumbers "client\clientEvents\customKeys.sqf";

//Setup Key Handler
waitUntil {!isNull findDisplay 46};
(findDisplay 46) displayAddEventHandler ["KeyDown", onKeyPress];
(findDisplay 46) displayAddEventHandler ["KeyUp", onKeyRelease];

_mouseButtonToKey = "params ['_disp','_btn']; ([_disp, _btn + 65536 + ([0,128] select (_btn isEqualTo 1))] + (_this select [4,999])) call "; // actionKeys mouse bitflag + RMB fix

(findDisplay 46) displayAddEventHandler ["MouseButtonDown", _mouseButtonToKey + "onKeyPress"];
(findDisplay 46) displayAddEventHandler ["MouseButtonUp", _mouseButtonToKey + "onKeyRelease"];

call compile preprocessFileLineNumbers "client\functions\setupClientPVars.sqf";

//client Executes
A3W_scriptThreads pushBack execVM "client\systems\hud\playerHud.sqf";
A3W_scriptThreads pushBack execVM "client\systems\killFeed\killFeed.sqf";

if (["A3W_survivalSystem"] call isConfigOn) then
{
	execVM "client\functions\initSurvival.sqf";
};

[] spawn
{
	[] execVM "client\functions\createGunStoreMarkers.sqf";

	if (["A3W_privateParking"] call isConfigOn) then
	{
		waitUntil {!isNil "parking_functions_defined"};
	};

	if (["A3W_privateStorage"] call isConfigOn) then
	{
		waitUntil {!isNil "storage_functions_defined"};
	};

	[] execVM "client\functions\createGeneralStoreMarkers.sqf";
	[] execVM "client\functions\createVehicleStoreMarkers.sqf";
	[] execVM "client\functions\createLegendMarkers.sqf";
};

A3W_clientSetupComplete = compileFinal "true";

[] spawn playerSpawn;

A3W_scriptThreads pushBack execVM "addons\fpsFix\vehicleManager.sqf";
A3W_scriptThreads pushBack execVM "addons\Lootspawner\LSclientScan.sqf";
[] execVM "addons\disableThermal\disablethermal.sqf";
[] execVM "client\functions\drawPlayerIcons.sqf";
[] execVM "addons\camera\functions.sqf";
[] execVM "addons\UAV_Control\functions.sqf";
[] execVM "addons\water_edge\functions.sqf";

if(hasInterface) then{[] execVM "addons\statusBar\statusBar.sqf"};

call compile preprocessFileLineNumbers "client\functions\generateAtmArray.sqf";
[] execVM "client\functions\drawPlayerMarkers.sqf";

inGameUISetEventHandler ["Action", "_this call A3W_fnc_inGameUIActionEvent"];

{ [_x] call fn_remotePlayerSetup } forEach allPlayers;

// update player's spawn beacon
{
	if (_x getVariable ["ownerUID",""] == getPlayerUID player) then
	{
		_x setVariable ["ownerName", name player, true];
		_x setVariable ["side", playerSide, true];
	};
} forEach pvar_spawn_beacons;

[] execVM "client\functions\globalChatMessages.sqf";

/*/ virtual arsenal --------------------------------------------------------------------------- /*/
[missionNamespace, "arsenalOpened", {
	9999 cutText ["", "BLACK IN", 0.01]; // remove the black screen
	player hideObject false; // unhide player for virtual arsenal viewing purposes (local only, not global).
    disableSerialization;
    _display = _this select 0;
    (_display displayCtrl 44150) ctrlRemoveAllEventHandlers "buttonclick";
    (_display displayCtrl 44150) ctrlEnable false; // remove random button action.
	_display displayAddEventHandler ["KeyDown", "if ((_this select 1) in [19,29]) then {true}"];
	['showMessage',[_display,'VA RESTRICTION: You are only allowed a maximum of 4 held magazines with 1 in gun. Rockets cannot exceed 1 per type in bag, however 1 AT will be in Launcher on spawn, extra equipment and magazines will be removed!']] call BIS_fnc_Arsenal;
}] call BIS_fnc_addScriptedEventHandler;

[missionNamespace, "arsenalClosed", {
	9999 cutText ["", "BLACK", 0.01]; // fade to black screen
	va_var_gearCheckInProgress = nil; // gearCheck.sqf has a waitUntil for VA level 15... and only exits once VA has CLOSED so the respawn screen doesn't show whilst in VA! damn bugs!
    [] call va_fnc_gearRestrict; // restrict the VA load out (mokey)
}] call BIS_fnc_addScriptedEventHandler;
/*/ ------------------------------------------------------------------------------------------- /*/
