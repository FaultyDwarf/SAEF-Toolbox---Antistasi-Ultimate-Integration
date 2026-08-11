/*
    SAEF wave respawn for Antistasi Ultimate.

    Adds six settings to the Antistasi setup screen under EXTENDER OPTIONS. Antistasi
    enumerates configFile >> A3A >> Params to build those rows and to publish each class
    as a global, so declaring them here is all that is needed - see XEH_postInit.sqf,
    which reads the globals and drives the toolbox wave handler from them.

    Kept in its own PBO because `class ExtenderParams;` is an external reference into
    A3A_core: this config cannot resolve without Antistasi loaded, while its sibling
    saef_toolbox_au_integration has no such dependency and must keep working alone.

    cba_xeh is required for the Extended_PostInit_EventHandlers block at the bottom.
*/

class CfgPatches
{
    class SAEF_TBAU_WAVERESPAWN
    {
        name = "SAEF - AU Wave Respawn";
        units[] = {};
        weapons[] = {};
        requiredVersion = 0.1;
        requiredAddons[] = {"cba_xeh", "A3A_core", "SAEF_TOOLBOX_RESPAWN"};
        author = "SAEF";
    };
};

class A3A
{
    class Params
    {
        class ExtenderParams;   // external ref into A3A_core, gives us type = "Extender"

        class SAEF_Wave_Enabled : ExtenderParams
        {
            title = "SAEF wave respawn";
            tooltip = "Hold dead players in spectator and release them in timed waves.";
            values[] = {0,1};
            texts[]  = {"Disabled","Enabled"};
            default  = 0;
        };
        class SAEF_Wave_MinTime : ExtenderParams
        {
            title = "Wave - minimum time";
            tooltip = "Baseline spectator time before a wave fires on its own.";
            values[] = {30,60,120,180,240};
            texts[]  = {"30 s","1 min","2 min","3 min","4 min"};
            default  = 120;
        };
        class SAEF_Wave_MaxTime : ExtenderParams
        {
            title = "Wave - maximum time";
            tooltip = "Ceiling once penalty time is stacked on. Must be >= minimum.";
            values[] = {240,300,360,480,600};
            texts[]  = {"4 min","5 min","6 min","8 min","10 min"};
            default  = 300;
        };
        class SAEF_Wave_HoldTime : ExtenderParams
        {
            title = "Wave - respawn window";
            tooltip = "How long respawn stays open once a wave fires.";
            values[] = {10,15,30,45,60};
            texts[]  = {"10 s","15 s","30 s","45 s","60 s"};
            default  = 30;
        };
        class SAEF_Wave_PlayerThreshold : ExtenderParams
        {
            title = "Wave - dead player threshold";
            tooltip = "Dead players needed to fire a wave early. Does not skip penalty time.";
            values[] = {2,3,4,5,6,8,10,999};
            texts[]  = {"2","3","4","5","6","8","10","Never (timer only)"};
            default  = 5;
        };
        class SAEF_Wave_PenaltyTime : ExtenderParams
        {
            title = "Wave - penalty per death";
            tooltip = "Seconds added to the whole squad's next wave for each death.";
            values[] = {0,15,30,45,60,90};
            texts[]  = {"None","15 s","30 s","45 s","60 s","90 s"};
            default  = 0;
        };
    };
};

class Extended_PostInit_EventHandlers {
    class SAEF_TBAU_WAVERESPAWN {
        init = "call compile preprocessFileLineNumbers '\saef_tbau_waverespawn\XEH_postInit.sqf'";
    };
};
