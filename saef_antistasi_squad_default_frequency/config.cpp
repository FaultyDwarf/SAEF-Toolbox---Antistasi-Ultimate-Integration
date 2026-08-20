class CfgPatches {
    class saef_antistasi_squad_default_frequency {
        units[] = {};
        weapons[] = {};
        requiredVersion = 1.0;
        requiredAddons[] = {
            "A3_UI_F",
            "A3A_Core",
            "tfar_core",
            "tfar_handhelds"
        };
        author = "FaultyDwarf";
    };
};

class CfgFunctions {
    class AU_SquadRadio {
        class Core {
            file = "\saef_antistasi_squad_default_frequency\functions";
            class setSquadFrequency {};
            class applyFrequencyToPlayer {};
            class dynamicGroupUpdate {};
            class radioAutoProgrammer {};
        };
    };
};

class Extended_PostInit_EventHandlers {
    class saef_antistasi_squad_default_frequency {
        clientInit = "if (hasInterface) then { execVM '\saef_antistasi_squad_default_frequency\initPlayerLocal.sqf'; };";
    };
};