"""Execute real profile/combat modules with service adapters; no Studio or world writes."""
from pathlib import Path
import subprocess
import tempfile
import os

ROOT = Path(__file__).resolve().parents[2]
CLI = Path(os.environ.get('LUAU_CLI', str(Path.home() / 'Desktop/climb&collect/tools/.luau/luau.exe')))

def module(path, bindings=''):
    return '(function()\n' + bindings + '\n' + (ROOT / path).read_text(encoding='utf-8') + '\nend)()'

preamble = r'''
local checks=0
local function check(v,message) assert(v,message);checks+=1 end
local function copy(value,seen)
 if type(value)=='number' then assert(value==value and math.abs(value)<math.huge,'nonfinite');return value end
 if type(value)~='table' then assert(type(value)~='function','unsupported');return value end
 seen=seen or {};assert(not seen[value],'cycle');seen[value]=true
 local result={};for k,v in pairs(value) do result[k]=copy(v,seen) end;seen[value]=nil;return result
end
local guid=0
local Http={JSONEncode=function(_,value) return copy(value) end,JSONDecode=function(_,value) return copy(value) end,GenerateGUID=function() guid+=1;return 'fixture'..guid end}
local Run={IsStudio=function() return true end}
local task={wait=function() end,defer=function(fn,...) fn(...) end,spawn=function(fn,...) fn(...) end}
local game={JobId='fixture',GetService=function(_,name) return if name=='HttpService' then Http elseif name=='RunService' then Run else error('Unsupported service: '..name) end}
local require=function(value) return value end
'''
body = preamble
body += '\nlocal Catalog=' + module('mountain/shared/Catalog.luau')
body += '\nlocal TycoonConfig=' + module('mountain/shared/TycoonConfig.luau')
body += '\nlocal Tycoon=' + module('mountain/shared/Tycoon.luau', 'local script={Parent={Catalog=Catalog,TycoonConfig=TycoonConfig}}')
body += '\nlocal RunRules=' + module('mountain/shared/RunRules.luau', 'local script={Parent={Catalog=Catalog}}')
body += '\nlocal RaidConfig=' + module('mountain/shared/RaidConfig.luau')
body += '\nlocal GuardianRules=' + module('mountain/shared/GuardianRules.luau', 'local script={Parent={RaidConfig=RaidConfig}}')
body += '\nlocal Rules=' + module('mountain/shared/Rules.luau', 'local script={Parent={Catalog=Catalog,Tycoon=Tycoon,RunRules=RunRules}}')
body += '\nlocal Protocol=' + module('mountain/shared/UIProtocol.luau')
body += '\nlocal BatRules=' + module('mountain/shared/BatRules.luau', 'local script={Parent={Catalog=Catalog}}')
body += '\nlocal ExplorerRules=' + module('mountain/shared/ExplorerRules.luau', 'local script={Parent={Catalog=Catalog}}')
body += '\nlocal EggOdds=' + module('mountain/shared/EggOdds.luau', 'local script={Parent={Catalog=Catalog}}')
body += '\nlocal ShopRules=' + module('mountain/shared/ShopRules.luau', 'local script={Parent={EggOdds=EggOdds}}')
body += '\ngame.ReplicatedStorage={MountainShared={Catalog=Catalog,Rules=Rules,UIProtocol=Protocol,BatRules=BatRules,RaidConfig=RaidConfig,GuardianRules=GuardianRules,ExplorerRules=ExplorerRules,EggOdds=EggOdds,ShopRules=ShopRules}}'
body += '\nlocal Store=' + module('mountain/server/Store.luau')
body += '\nlocal Profiles=' + module('mountain/server/Profiles.luau', 'local script={Parent={Store=Store}}')
body += '\nlocal UIRequests=' + module('mountain/server/UIRequests.luau', 'local script=true')
body += '\ngame.ServerStorage={MountainWorld={Art={}}}'
body += '\nlocal Combat=' + module('mountain/server/Combat.luau')
