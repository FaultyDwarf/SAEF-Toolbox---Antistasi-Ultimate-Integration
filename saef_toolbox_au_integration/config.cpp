class CfgPatches {
    class saef_toolbox_au_integration {
        name = "SAEF Toolbox / Antistasi Ultimate Integration (server-side)";
        author = "SAEF";
        version = "1.0.0";
        versionStr = "1.0.0";
        versionAr[] = {1,0,0};
        requiredVersion = 2.20;
        // cba_xeh only. XEH_postInit.sqf waits on the toolbox functions it needs and
        // logs if they never appear, so no toolbox dependency is declared here.
        requiredAddons[] = {"cba_xeh"};
        units[] = {};
        weapons[] = {};
        magazines[] = {};
        ammo[] = {};
    };
};

class CfgFunctions {
    class SAEF_TBAU {
        class Logging {
            file = "saef_toolbox_au_integration\Functions";
            class log {};   // -> SAEF_TBAU_fnc_log, called directly as
                             // [_level, _message, _file] call SAEF_TBAU_fnc_log;
                             // matches Antistasi's own A3A_fnc_log: 1=Error, 2=Info,
                             // 3=Debug, 4=Verbose, gated on the same LogLevel variable.
        };
    };
};

class Extended_PostInit_EventHandlers {
    class saef_toolbox_au_integration {
        init = "call compile preprocessFileLineNumbers '\saef_toolbox_au_integration\XEH_postInit.sqf'";
    };
};
