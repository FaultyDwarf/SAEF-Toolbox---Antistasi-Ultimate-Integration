class Templates
{
	class Aegis_Base;

	/*
		Name and preview icon shown for this template on the faction-select
		screen, which reads them straight off the config class.

		This is not what skins the in-game flagpole - that comes from the
		template's own script, overridden in fn_SAEF_flagOverride.sqf.
	*/
	class Aegis_FIA : Aegis_Base
	{
		name = "SAEF";
		flagTexture = "saef_tbau_saef_rebels\Pictures\Markers\SAEF_flag_1024x512.paa";
	};
};
