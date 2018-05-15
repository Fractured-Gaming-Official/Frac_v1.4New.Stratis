// ******************************************************************************************
// * This project is licensed under the GNU Affero GPL v3. Copyright © 2014 A3Wasteland.com *
// ******************************************************************************************
//	@file Name: mission_HostileHelicopter.sqf
//	@file Author: JoSchaap, AgentRev

if (!isServer) exitwith {};
#include "sideMissionDefines.sqf"

private ["_vehicleClass", "_vehicle", "_createVehicle", "_vehicles", "_leader", "_speedMode", "_waypoint", "_vehicleName", "_numWaypoints", "_box1", "_box2", "_smoke"];

_setupVars =
{
	_missionType = "Hostile Helicopter";
	_locationsArray = nil;
};

_setupObjects =
{
	_missionPos = markerPos (((call cityList) call BIS_fnc_selectRandom) select 0);

	_vehicleClass = if (missionDifficultyHard) then
	{
		selectRandom [["B_Heli_Light_01_dynamicLoadout_F", "pawneeMission"], ["I_Heli_light_03_dynamicLoadout_F", "HellMission"], ["B_Heli_Attack_01_dynamicLoadout_F", "BlackfootAG"], ["O_Heli_Attack_02_dynamicLoadout_F", "KajmanMissionAG"], ["O_Heli_Light_02_dynamicLoadout_F", "orcaMission"]] ;
	}
	else
	{
		selectRandom [["B_Heli_Light_01_dynamicLoadout_F", "pawneeMission"], ["I_Heli_light_03_dynamicLoadout_F", "HellMission"], ["B_Heli_Attack_01_dynamicLoadout_F", "BlackfootAG"], ["O_Heli_Attack_02_dynamicLoadout_F", "KajmanMissionAG"], ["O_Heli_Light_02_dynamicLoadout_F", "orcaMission"]];
	};

	_createVehicle =
	{
		private ["_type", "_position", "_direction", "_variant", "_vehicle", "_soldier"];

		_type = _this select 0;
		_position = _this select 1;
		_direction = _this select 2;
		_variant = _type param [1,"",[""]];

 		if (_type isEqualType []) then
 		{
 			_type = _type select 0;
 		};

		_vehicle = createVehicle [_type, _position, [], 0, "FLY"];
		_vehicle setVariable ["R3F_LOG_disabled", true, true];

		if (_variant != "") then
 		{
 			_vehicle setVariable ["A3W_vehicleVariant", _variant, true];
 		};

		[_vehicle] call vehicleSetup;
		_vehicle setDir _direction;
		_aiGroup addVehicle _vehicle;
		_soldier = [_aiGroup, _position] call createRandomSoldierC;
		_soldier moveInDriver _vehicle;

		switch (true) do
		{
			case (_type isKindOf "Heli_Transport_01_base_F"):
			{
				// these choppers have 2 turrets so we need 2 gunners
				_soldier = [_aiGroup, _position] call createRandomSoldierC;
				_soldier moveInTurret [_vehicle, [1]];

				_soldier = [_aiGroup, _position] call createRandomSoldierC;
				_soldier moveInTurret [_vehicle, [2]];
			};

			case (_type isKindOf "Heli_Attack_01_base_F" || _type isKindOf "Heli_Attack_02_base_F"):
			{
				// these choppers need 1 gunner
				_soldier = [_aiGroup, _position] call createRandomSoldierC;
				_soldier moveInGunner _vehicle;
			};
		};

		if (_type isKindOf "Air") then
		{
			{
				if (["CMFlare", _x] call fn_findString != -1) then
				{
					_vehicle removeMagazinesTurret [_x, [-1]];
				};
			} forEach getArray (configFile >> "CfgVehicles" >> _type >> "magazines");
		};

		[_vehicle, _aiGroup] spawn checkMissionVehicleLock;
		_vehicle
	};

	_aiGroup = createGroup CIVILIAN;
	_vehicle = [_vehicleClass, _missionPos, 0] call _createVehicle;
	_leader = effectiveCommander _vehicle;
	_aiGroup selectLeader _leader;
	_leader setRank "LIEUTENANT";
	_aiGroup setCombatMode "WHITE";
	_aiGroup setBehaviour "AWARE";
	_aiGroup setFormation "STAG COLUMN";
	_speedMode = if (missionDifficultyHard) then { "NORMAL" } else { "LIMITED" };
	_aiGroup setSpeedMode _speedMode;

	{
		_waypoint = _aiGroup addWaypoint [markerPos (_x select 0), 0];
		_waypoint setWaypointType "MOVE";
		_waypoint setWaypointCompletionRadius 50;
		_waypoint setWaypointCombatMode "WHITE";
		_waypoint setWaypointBehaviour "AWARE";
		_waypoint setWaypointFormation "STAG COLUMN";
		_waypoint setWaypointSpeed _speedMode;
	} forEach ((call cityList) call BIS_fnc_arrayShuffle);

	_missionPos = getPosATL leader _aiGroup;

	_missionPicture = getText (configFile >> "CfgVehicles" >> (_vehicleClass param [0,""]) >> "picture");
 	_vehicleName = getText (configFile >> "CfgVehicles" >> (_vehicleClass param [0,""]) >> "displayName");

	_missionHintText = format ["An Experimental <t color='%2'>%1</t> is patrolling the island. Intercept it and recover its cargo!", _vehicleName, sideMissionColor];

	_numWaypoints = count waypoints _aiGroup;
};

_waitUntilMarkerPos = {getPosATL _leader};
_waitUntilExec = nil;
_waitUntilCondition = {currentWaypoint _aiGroup >= _numWaypoints};
_failedExec = nil;

_successExec =
{
	/*/ --------------------------------------------------------------------------------------- /*/
    _numCratesToSpawn = 1; // edit this value to how many crates are to be spawned!
	/*/ --------------------------------------------------------------------------------------- /*/

	/*/ --------------------------------------------------------------------------------------- /*/
	_lastPos = _this;
    _i = 0;
    while {_i < _numCratesToSpawn} do
    {
        _lastPos spawn
        {
            _lastPos = _this;
            _crate = createVehicle ["Box_East_Wps_F", _lastPos, [], 5, "None"];
            _crate setDir random 360;
            _crate allowDamage false;
            waitUntil {!isNull _crate};
            _crateParachute = createVehicle ["O_Parachute_02_F", (getPosATL _crate), [], 0, "CAN_COLLIDE" ];
            _crateParachute allowDamage false;
            _crate attachTo [_crateParachute, [0,0,0]];
            _crate call randomCrateLoadOut;
            waitUntil {getPosATL _crate select 2 < 5};
            detach _crate;
            deleteVehicle _crateParachute;
            _smokeSignalTop = createVehicle  ["SmokeShellRed_infinite", getPosATL _crate, [], 0, "CAN_COLLIDE" ];
            _lightSignalTop = createVehicle  ["Chemlight_red", getPosATL _crate, [], 0, "CAN_COLLIDE" ];
            _smokeSignalTop attachTo [_crate, [0,0,0.5]];
            _lightSignalTop attachTo [_crate, [0,0,0.25]];
	    _timer = time + 240;
	    waitUntil {sleep 1; time > _timer};
            _crate allowDamage true;
	    deleteVehicle _smokeSignalTop;
	    deleteVehicle _lightSignalTop;
        };
        _i = _i + 1;
    };
	_successHintMessage = "The sky is clear again, the enemy patrol was taken out! Ammo crates have fallen out their chopper.";
};

_this call sideMissionProcessor;
