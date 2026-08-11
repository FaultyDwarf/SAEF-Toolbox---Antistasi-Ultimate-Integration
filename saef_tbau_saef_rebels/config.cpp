/*
	saef_tbau_saef_rebels

	Puts the SAEF logo on the Aegis rebel template (Aegis_FIA), in the three
	places Antistasi draws it from:

		faction-select preview   config merge, Templates\Templates.hpp
		in-game flagpole         function override,
		                         Templates\functions\fn_compatibilityLoadFaction.sqf
		strategic map marker     CfgMarkers class, CfgMarkers.hpp

	Everything else about the faction is left as Antistasi defines it.

	Client-side, unlike the other PBOs in this mod: the textures and the
	CfgMarkers class are resolved by whichever machine renders them, so this has
	to be in the player preset.

	All texture and script paths below are resolved against $PBOPREFIX$ at load
	time. A wrong prefix shows up as a missing flag or a CfgMarkers lookup
	failure in game, not as a build error.
*/

class CfgPatches
{
	class SAEF_AntistasiBridge
	{
		name = "SAEF Antistasi Bridge";
		units[] = {};
		weapons[] = {};
		requiredVersion = 0.1;
		requiredAddons[] = {"A3A_core"};
		author = "SAEF";
		version = 1;
	};
};

class A3A
{
	#include "Templates\Templates.hpp"
};

class CfgFunctions
{
	class A3A
	{
		class FunctionsTemplates
		{
			class compatibilityLoadFaction
			{
				file = "saef_tbau_saef_rebels\Templates\functions\fn_compatibilityLoadFaction.sqf";
			};
		};
	};
};

#include "CfgMarkers.hpp"