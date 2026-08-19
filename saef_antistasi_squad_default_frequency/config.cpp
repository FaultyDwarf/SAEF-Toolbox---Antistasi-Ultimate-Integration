class CfgPatches {
    class AU_SquadRadio {
        units[] = {};
        weapons[] = {};
        requiredVersion = 1.0;
        requiredAddons[] = {"A3A_core","task_force_radio"}; // AU + TFAR
        author = "AU_SquadRadio (external)";
    };
};

class CfgFunctions {
    class AU_SquadRadio {
        class Core {
            file = "\saef_antistasi_squad_default_frequency\functions";
            class setSquadFrequency {};      // server-side setter
            class applyFrequencyToPlayer {}; // client-side applicator
        };
    };
};