/*
	CfgMarkers.hpp

	Marker type used for the rebel flag markers on the strategic map, e.g. the HQ.
	flagMarkerType names this class rather than a texture path, and the icon and
	texture properties here are what actually get drawn.

	Inherits flag_FIA - Antistasi's default for this template - so anything else
	that class sets stays intact.
*/

class CfgMarkers
{
	class flag_FIA;

	class SAEF_flag_marker : flag_FIA
	{
		name = "SAEF";
		icon = "saef_tbau_saef_rebels\Pictures\Markers\SAEF_logo_patch.paa";
		texture = "saef_tbau_saef_rebels\Pictures\Markers\SAEF_logo_patch.paa";
	};
};
