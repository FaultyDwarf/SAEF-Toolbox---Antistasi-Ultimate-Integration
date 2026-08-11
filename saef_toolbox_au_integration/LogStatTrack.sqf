/*
	LogStatTrack.sqf

	Writes the current StatTrack summary to server.rpt and hints it back to the caller.

	Runs on the server: the Log StatTrack admin action remoteExecs
	[[], "\saef_toolbox_au_integration\LogStatTrack.sqf"] to execVM on machine 2.
*/

[] call RS_ST_fnc_LogInfo;
