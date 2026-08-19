class CfgPatches
{
    class SAEF_ANTISTASI_ITEMS
    {
        name = "SAEF Antistasi Items";
        author = "SAEF";
        requiredVersion = 2.00;

        // A3_Weapons_F owns CA_LauncherMagazine and Titan_AA; ace_missileguidance owns
        // ace_missile_manpad_stinger_man. Both are required so the explicit parent
        // restatements below resolve correctly instead of failing to find their base class.
        requiredAddons[] =
        {
            "A3_Weapons_F",
            "ace_missileguidance"
        };
        units[] = {};
        weapons[] = {};
    };
};

// Each class below restates its real parent explicitly rather than using a bare edit
// ("class Titan_AA { ... };"), because a bare edit here silently drops the class's
// inheritance link, which loses every property (count, reloadAction, modelSpecial,
// nameSound, Library, libTextDesc, ...) that Titan_AA and its descendants would otherwise
// inherit from CA_LauncherMagazine/CA_Magazine/Default. Restating the parent keeps the
// inheritance chain intact while still applying our mass override.
class CfgMagazines
{
    class CA_LauncherMagazine;

    class Titan_AA : CA_LauncherMagazine
    {
        mass = 200;
    };

    class Titan_AT : Titan_AA
    {
        mass = 200;
    };

    class Titan_AP : Titan_AA
    {
        mass = 200;
    };

    class ace_missile_manpad_stinger_man : Titan_AA
    {
        mass = 200;
    };
};
