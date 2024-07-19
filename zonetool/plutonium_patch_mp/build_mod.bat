@echo off

setlocal

set codPath="D:\Program Files\Steam\steamapps\common\Call of Duty Modern Warfare 3"
set editedPatch=%codPath%"\zone\english\plutonium_patch_mp.ff"
set plutoPath=%localappdata%"\Plutonium\storage\iw5\mods\survival"

cd %codPath%

"zonetool.exe" -buildzone plutonium_patch_mp

move %editedPatch% %plutoPath%

endlocal