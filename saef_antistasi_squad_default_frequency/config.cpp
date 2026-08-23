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

class RscText; // Reference the base class
class SquadFreqLabel : RscText {
    style = 1;                               // 1 = ST_RIGHT (Right align)
    text = "Freq.:";                        // Default text
    colorText[] = {0, 0, 0, 1};             // Black text color [R, G, B, A]
    tooltip = "Squad radio frequency (20-9999 MHz)"; // Built-in tooltip
    font = "RobotoCondensed";
    shadow = 0;
    sizeEx = "( ( ( ((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 0.8 )"; // Native Arma GUI Grid scale
};