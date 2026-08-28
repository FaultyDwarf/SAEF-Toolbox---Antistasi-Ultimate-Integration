saef_antistasi_squad_default_frequency
======================================

This addon integrates a custom squad frequency selection control directly into 
the Dynamic Groups menu (Display 60490) for Antistasi. It automatically 
programs Task Force Arrowhead Radio (TFAR) shortwave radios for squad members 
and configures Command Net (50 MHz) on Channel 2 for Squad Leaders.

Mod Directory Structure:
@saef_antistasi_squad_default_frequency/
  addons/
    saef_antistasi_squad_default_frequency/
      config.cpp
      initPlayerLocal.sqf
      functions/
        fn_applyFrequencyToPlayer.sqf
        fn_dynamicGroupUpdate.sqf
        fn_radioAutoProgrammer.sqf
        fn_setSquadFrequency.sqf

Dependencies:
- Arma 3 (v1.80+)
- CBA_A3
- Antistasi (A3A_Core)
- Task Force Arrowhead Radio (TFAR Beta / 1.0+)

Build Instructions:
1. Install Arma 3 Tools via Steam.
2. Open Addon Builder.
3. Set Source Directory to:
   ...\@saef_antistasi_squad_default_frequency\addons\saef_antistasi_squad_default_frequency
4. Set Destination Directory to:
   ...\@saef_antistasi_squad_default_frequency\addons
5. In Options, set Binarize to "Binarize All Files" (or leave unbinarized for raw SQF).
6. Click "Pack". Addon Builder will generate saef_antistasi_squad_default_frequency.pbo.

Final Output Structure:
@saef_antistasi_squad_default_frequency/
  addons/
    saef_antistasi_squad_default_frequency.pbo

How It Works:
- Dynamic Groups UI: When pressing the Dynamic Groups key (default U), a frequency input field is injected.
- Squad Leader Control: Only the Squad Leader can edit the squad's frequency.
- Radio Auto-Programmer: Automatically reprograms TFAR radios upon picking up radios from Arsenals/corpses, respawning, or squad transfers without continuous polling loops.