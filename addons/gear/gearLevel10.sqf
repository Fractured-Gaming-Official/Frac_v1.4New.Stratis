/*//*//*//*//*//*//*//*//*//*//*//*//*//*//*//*//*//*//*//*//*//*//*///*//*//*/

//	@file Version: 2.0
//	@file Name gearLevel10.sqf
//	@file Author: [FRAC] Mokey
//	@file Created: 4/21/2018 09:48

/*//*//*//*//*//*//*//*//*//*//*//*//*//*//*//*//*//*//*//*//*//*//*//

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as published
by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

/*//*//*//*//*//*//*//*//*//*//*//*//*//*//*//*//*//*//*//*//*//*//*/

private ["_player"];

_player = _this;

_player setVariable ["gmoney",1000];

{_player removeWeapon _x} forEach weapons _player;
{_player removeMagazine _x} forEach magazines _player;
removeVest _player;
removeBackpack _player;
removeGoggles _player;
removeHeadgear _player;
_player addBackpack "B_Carryall_oli";
_player addVest "V_PlateCarrierGL_rgr";
_player linkItem "NVGoggles";
_player linkItem "ItemGPS";
_player addWeapon "Binocular";
_player addMagazines ["HandGrenade", 4];
_player addItem "FirstAidKit";
_player addGoggles "G_Sport_Red";
_player addHeadgear "H_HelmetB_light";
_player addMagazines ["11Rnd_45ACP_Mag", 2];
_player addWeapon "hgun_Pistol_heavy_01_F";
_player addhandGunItem "optic_MRD";
_player addhandGunItem "muzzle_snds_acp";
_player addMagazines ["20Rnd_762x51_Mag", 5];
_player addWeapon "srifle_DMR_06_camo_F";
_player addPrimaryWeaponItem "optic_Hamr";
_player addPrimaryWeaponItem "muzzle_snds_B";
_player addMagazines ["RPG32_F", 1];
_player addWeapon "launch_RPG32_F";
_player selectWeapon "srifle_DMR_06_camo_F";

switch (true) do
	{
		case (["_medic_", typeOf _player] call fn_findString != -1):
		{
			_player addItem "MediKit";
			_player removeItem "";
		};
		case (["_engineer_", typeOf _player] call fn_findString != -1):
		{
			_player addItem "ToolKit";
			_Player addItem "MineDetector";
			_player removeItem "";
		};
		case (["_sniper_", typeOf _player] call fn_findString != -1):
		{
			_player addWeapon "Rangefinder";
			_player removeItem "";
		};
			case (["_diver_", typeOf _player] call fn_findString != -1):
		{
			_player addVest "V_RebreatherIA";
			_player addGoggles "G_Diving";
			_player removeItem "";

		};
	};
