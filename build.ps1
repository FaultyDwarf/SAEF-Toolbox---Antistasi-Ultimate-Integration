# Builds mods\@SAEF_Toolbox_AU_Integration from the source folders beside this script.
#
# Three PBOs in the one mod folder:
#
#   saef_toolbox_au_integration  admin actions
#   saef_tbau_waverespawn        wave respawn and its setup-screen parameters
#   saef_tbau_saef_rebels        SAEF flag and map marker over the Aegis_FIA template
#
# FileBank rather than AddonBuilder: nothing here needs binarising, and FileBank leaves
# the files readable inside the PBO so a deployed copy can be checked by eye. It also
# packs the folder wholesale, so the .paa textures and the .hpp files pulled in by
# #include come along without an include list.
#
# mod.cpp and README.md are copied alongside the addons folder so the staged mod
# folder is a complete, self-describing copy of what goes onto the live server.

$ErrorActionPreference = "Stop"

$FileBank = "D:\SteamLibrary\steamapps\common\Arma 3 Tools\FileBank\FileBank.exe"
$Prefixes = @("saef_toolbox_au_integration", "saef_tbau_waverespawn", "saef_tbau_saef_rebels", "saef_antistasi_squad_default_frequency")
$ModDir   = "D:\ArmA3\A3Files\mods\@SAEF_Toolbox_AU_Integration"
$OutDir   = Join-Path $ModDir "addons"

if (-not (Test-Path $FileBank)) { throw "FileBank not found at $FileBank" }
if (-not (Test-Path $OutDir))   { New-Item -ItemType Directory -Path $OutDir -Force | Out-Null }

$built = @()
foreach ($Prefix in $Prefixes)
{
    $Src = Join-Path $PSScriptRoot $Prefix
    if (-not (Test-Path $Src)) { throw "Source folder not found at $Src" }

    Write-Host "Packing $Src -> $OutDir"
    & $FileBank -property prefix=$Prefix -dst $OutDir $Src
    if ($LASTEXITCODE -ne 0) { throw "FileBank failed for $Prefix with exit code $LASTEXITCODE" }

    $pbo = Join-Path $OutDir "$Prefix.pbo"
    if (-not (Test-Path $pbo)) { throw "Expected $pbo was not produced" }
    $built += $pbo
}

foreach ($file in @("mod.cpp", "README.md"))
{
    $source = Join-Path $PSScriptRoot $file
    if (Test-Path $source) { Copy-Item -Path $source -Destination $ModDir -Force }
}

foreach ($pbo in $built) { "OK: {0} ({1:N0} bytes)" -f $pbo, (Get-Item $pbo).Length }
"Staged mod folder: {0}" -f $ModDir
