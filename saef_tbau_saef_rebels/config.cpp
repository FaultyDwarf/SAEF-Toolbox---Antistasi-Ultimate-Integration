/*
	saef_tbau_saef_rebels

	Ships modified copies of Antistasi's own Aegis faction template scripts - the same
	pattern used by community "extender" mods for Antistasi Ultimate (see
	github.com/Westalgie/A3UExtender): Templates\Templates.hpp points each affected
	template's basepath/file at our copy under Templates\Templates\, so Antistasi's own,
	unmodified core keeps loading templates exactly as it always does - it just loads ours
	instead of the original for these specific templates.

		Aegis_FIA (Rebels)        SAEF name/flag/map-marker branding
		Aegis_AAF (Occupants)     air fleet re-pricing, Titan-to-NLAW swap
		Aegis_NATO_Arid (Invaders) air fleet re-pricing, roster swaps, Titan-to-NLAW swap

	Altis-only scope: Aegis_NATO_Temperate and Aegis_NATO_Tropical are not touched and
	keep loading Aegis's own, unmodified originals.

	Everything else about each faction (equipment, vehicles, loadouts not listed above) is
	left exactly as that copy's own upstream original defines it - see each .sqf's own
	header comment for precisely what was changed.

	Antistasi's own reads basepath/file straight off the template's config class, so
	pointing those at our folder is the entire override - no CfgFunctions override, no
	copy of compatibilityLoadFaction.

	Client-side, unlike the other PBOs in this mod: the templates' textures and the
	CfgMarkers class are resolved by whichever machine renders them, so this has to be in
	the player preset.

	All texture and script paths below are resolved against $PBOPREFIX$ at load time. A
	wrong prefix shows up as a missing flag, a CfgMarkers lookup failure, or a faction
	loading with Aegis's unmodified defaults in game - not as a build error.
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

#include "CfgMarkers.hpp"
