saef_antistasi_squad_default_frequency
====================

This addon changes the inventory mass of the existing Arma 3 Titan_AA magazine to 200.

Source:
@TitanAA_Heavy/
  addons/
    TitanAA_Heavy/
      config.cpp

Build:
1. Install Arma 3 Tools from Steam.
2. Open Addon Builder.
3. Select the folder:
   @TitanAA_Heavy/addons/TitanAA_Heavy
4. Set the destination to:
   @TitanAA_Heavy/addons
5. Pack the addon. This creates TitanAA_Heavy.pbo.
6. The final mod should contain:
   @TitanAA_Heavy/
     addons/
       TitanAA_Heavy.pbo
7. Launch Arma 3 with @TitanAA_Heavy enabled.

NOTE:
The config uses the inherited class override form. If your Arma build reports a duplicate/redefinition error, use a patch class instead:

class CfgPatches
{
    class TitanAA_Heavy
    {
        requiredVersion = 1.60;
        requiredAddons[] = {"A3_Weapons_F"};
        units[] = {};
        weapons[] = {};
    };
};

class CfgMagazines
{
    class Titan_AA
    {
        mass = 200;
    };
};

The supplied config is intended as the starting point.
