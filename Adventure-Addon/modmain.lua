-- maxwell phonograph, mod by DoktorHolmes
-- maxwell light, mod by Leonardo Coxington
-- and my own work..


-- TODO:

-- wormholes noch versuchen rauszufinden

-- rausfinden wie man character mit in nächste welt nimmt (ohne neu aussuchen)

-- gucken ob es eine setskin funktion oderso gibt. iwie müssen doch modder skins spawnen können (für items von worldjump, aber auch für puppe on throne)
--> zumindest fuer player könnte das hier funzen (vom spieler die skins abfragen und dann der puppet geben): 
-- local skinner = player.components.skinner
        -- skinner:SetClothing(clothing_body)
        -- skinner:SetClothing(clothing_hand)
        -- skinner:SetClothing(clothing_legs)
        -- skinner:SetClothing(clothing_feet)
        -- skinner:SetSkinName(skin_base)
        -- skinner:SetSkinMode("normal_skin")

-- mit c_spawn("wortox") geht -> noichmal gucken wie genau die puppet gemacht wird..


-- TheWorld.components.adventurejump:DoJump()

-- .. nächste verision starting items nicht nil sondern leere liste setzen
-- maxw.components.maxwelltalker.speeches[speechName]==nil testen und dann wieder auf chapter Rede umstellen, falls ein anderer mod ne welt hinzugefügt hat
-- weiß garnicht ob maxwell dann access zu einer neuen Rede hätte, sicherlich nicht...
-- müsste man dann schauen, wie man das macht





print("HIER modmain adv")

PrefabFiles = { 
	"maxwellphonograph",
    "maxwelllight_p",
	"maxwelllight_flame",
    "maxwellthrone",	
    "paired_maxwelllight",
    "maxwell",
    "maxwellendgame",
    "maxwellhead",
    "maxwellhead_trigger",
    "maxwellintro",
    "maxwellkey",
    "maxwelllock",
    "diviningrodstart",
    "teleportato_checkmate",
    "teleportlocation",
    "puppet",
}
Assets = {
	Asset("ANIM", "anim/phonograph.zip"),
	Asset("SOUND", "sound/phonograph.fsb"),
	Asset("SOUNDPACKAGE", "sound/phonograph.fev"),
	Asset("ATLAS", "images/inventoryimages/Gramophone.xml"),
    Asset("IMAGE", "images/inventoryimages/Gramophone.tex"),
    ----------------------------------------------------
    Asset( "IMAGE", "images/map_icons/evilthrone.tex" ),
	Asset( "ATLAS", "images/map_icons/evilthrone.xml" ),
	Asset( "IMAGE", "images/map_icons/evillight.tex" ),
	Asset( "ATLAS", "images/map_icons/evillight.xml" ),
	----------------------------------------------------
	Asset( "IMAGE", "images/inventoryimages/evilthrone.tex" ),
	Asset( "ATLAS", "images/inventoryimages/evilthrone.xml" ),
	Asset( "IMAGE", "images/inventoryimages/evillight.tex" ),
	Asset( "ATLAS", "images/inventoryimages/evillight.xml" ),
    -------------------------------------------------------
    Asset("ANIM", "anim/maxwell_build.zip"),
    Asset("ANIM", "anim/max_fx.zip"),
    Asset("ANIM", "anim/maxwell_basic.zip"),
	Asset("ANIM", "anim/maxwell_adventure.zip"),
	-- Asset("SOUND", "sound/maxwell.fsb"),
    Asset("SCRIPT", "scripts/prefabs/player_common.lua"),
    Asset("ANIM", "anim/maxwell_endgame.zip"),
    Asset("ANIM", "anim/maxwell_floatinghead.zip"),
    Asset("ANIM", "anim/diviningrod_maxwell.zip"),
    Asset("ANIM", "anim/purple_gem.zip"),
    Asset("ANIM", "anim/player_throne.zip"),
}
RemapSoundEvent( "phonograph/play", "phonograph/sound/gramaphoneplay" )
RemapSoundEvent( "phonograph/end", "phonograph/sound/gramaphoneend" )

local TheNet = GLOBAL.TheNet
local SERVER_SIDE, DEDICATED_SIDE, CLIENT_SIDE, ONLY_CLIENT_SIDE
if TheNet:GetIsServer() then
	SERVER_SIDE = true
	if TheNet:IsDedicated() then
		DEDICATED_SIDE = true -- ==ONLY_SERVER_SIDE
	else
		CLIENT_SIDE = true
	end
elseif TheNet:GetIsClient() then
	SERVER_SIDE = false
	CLIENT_SIDE = true
	ONLY_CLIENT_SIDE = true
end

local _G = GLOBAL
if not _G.TUNING.TELEPORTATOMOD then
    _G.TUNING.TELEPORTATOMOD = {}
end


_G.TUNING.ADV_DIFFICULTY = GetModConfigData("difficulty") -- also used within chest scenarios
local adv_helpers = _G.require("adv_helpers") 
-- we can use _G.TUNING.TELEPORTATOMOD.LEVEL and _G.TUNING.TELEPORTATOMOD.CHAPTER as soon as the game started
-- _G.TUNING.TELEPORTATOMOD.LEVELINFOLOADED will be true after everythong was loaded.


-- AddPrefabPostInit("world",function(world) world:DoTaskInTime(1,function() world.components.adventurejump:DoJump() end) end) -- endless jump for testing

-- maxwell spawn for every single player only on their client side, so other players should not be able to see him
local function SpawnMaxwell(inst)
    print("SpawnMaxwell")
    if _G.TUNING.TELEPORTATOMOD.CHAPTER then
        inst:DoTaskInTime(4,function(inst) -- wait after the title screen is gone
            print("SpawnMaxwell1")
            local speechName = "SANDBOX_1"
            if _G.TUNING.TELEPORTATOMOD.CHAPTER>0 then
                speechName = "ADVENTURE_".._G.TUNING.TELEPORTATOMOD.CHAPTER -- strings matching the actual chapter
            end
            if _G.TUNING.ADV_DIFFICULTY==0 then -- DS. so no new dialog
                inst.dolevelspeech = false
            end
            -- inst.dolevelspeech = true -- test
            if inst.dolevelspeech then -- 66% chance, different for every single player
                speechName = "ADVENTURE_LEVEL"..tostring(_G.TUNING.TELEPORTATOMOD.LEVEL) -- alternative strings matching the chosen level
            end
            local maxw = _G.SpawnPrefab("maxwellintro")
            if maxw~=nil then
                if maxw.components.maxwelltalker.speeches[speechName]~=nil then
                    maxw:Hide() -- invisible
                    if _G.ThePlayer==inst or SERVER_SIDE then
                        if _G.ThePlayer==inst then
                            maxw:Show() -- make it visible only for the player who "called" him
                        end
                        maxw.components.maxwelltalker:SetSpeech(speechName)
                        maxw.components.maxwelltalker:Initialize(inst,CLIENT_SIDE)
                        maxw:StartThread(function() maxw.components.maxwelltalker:DoTalk(CLIENT_SIDE,inst.dolevelspeech) end)
                    end
                else
                    maxw:Remove()
                end
            end
        end)
    else
        print("Adventure: SpawnMaxwell CHAPTER is nil?!")
    end
end


-- some functions you can use which will be called within teleportato mod:
-- functionatplayerfirstspawn(player) -- will be executed for every players first spawn (during showing the title) and can eg. be used to spawn some starter items or lit some fires around him and so on. wait 4 seconds, to do something if you want the player to see it (eg player:DoTaskInTime(4,function))
-- functionpostloadworldONCE(world) -- will be executed at world start ONCE (only the first time directly after generating the world).  eg. you could add some stuff around startposition 
-- in addition you can addprefabpostinit into your modmain, but LEVEL and CHAPTER will need ~0.1 seconds to be set, so do DoTaskInTime within your Addprefabpostiint! (only continue after _G.TUNING.TELEPORTATOMOD.LEVELINFOLOADED was set to true by teleportato mod)

local functionatplayerfirstspawn = _G.TUNING.TELEPORTATOMOD.functionatplayerfirstspawn
local functionpostloadworldONCE = _G.TUNING.TELEPORTATOMOD.functionpostloadworldONCE
_G.TUNING.TELEPORTATOMOD.functionatplayerfirstspawn = function(player) -- called for server and client
    print("functionatplayerfirstspawn")
    if functionatplayerfirstspawn~=nil then -- call a previous funtion from another mod, if there is one
        functionatplayerfirstspawn(player)
    end
    player:DoTaskInTime(0,function() -- do the following after everything is finally done
        if SERVER_SIDE then
            player.dolevelspeech = _G.GetRandomItem({true,false,true}) -- higher chance for true
            player.mynetvardolevelspeech:set(player.dolevelspeech) -- random and server may get differnt result for this, so we have to send the server result to client
        end
        SpawnMaxwell(player)
        if SERVER_SIDE then 
            if _G.TheWorld:HasTag("forest") then
                
                if not GetModConfigData("repickcharacter") and _G.TUNING.TELEPORTATOMOD.CHAPTER~=nil and _G.TUNING.TELEPORTATOMOD.CHAPTER<=1 and player.starting_inventory_orig~=nil then -- give the starting items only in those 2 chapters
                    player.starting_inventory = player.starting_inventory_orig
                    if player.starting_inventory ~= nil and #player.starting_inventory > 0 and player.components.inventory ~= nil then -- code taken from NewSpawn within player_common.lua
                        player.components.inventory.ignoresound = true
                        if player.components.inventory:GetNumSlots() > 0 then
                            for i, v in ipairs(player.starting_inventory) do
                                player.components.inventory:GiveItem(_G.SpawnPrefab(v))
                            end
                        else
                            local items = {}
                            for i, v in ipairs(player.starting_inventory) do
                                local item = _G.SpawnPrefab(v)
                                if item.components.equippable ~= nil then
                                    player.components.inventory:Equip(item)
                                    table.insert(items, item)
                                else
                                    item:Remove()
                                end
                            end
                            for i, v in ipairs(items) do
                                if v.components.inventoryitem == nil or not v.components.inventoryitem:IsHeld() then
                                    v:Remove()
                                end
                            end
                        end
                        player.components.inventory.ignoresound = false
                    end
                end
                
                print("functionatplayerfirstspawn, level:"..tostring(_G.TUNING.TELEPORTATOMOD.LEVEL).." chapter:"..tostring(_G.TUNING.TELEPORTATOMOD.CHAPTER))
                if _G.TUNING.ADV_DIFFICULTY~=0 and _G.TUNING.ADV_DIFFICULTY~=3 then -- spawn some helpful stuff for starting players, at least on easy and default difficutly
                    adv_helpers.FuelNearFires(player) -- always fuel nerby fires to help new starting players a bit
                    if _G.TUNING.TELEPORTATOMOD.WORLDS[_G.TUNING.TELEPORTATOMOD.LEVEL].name=="Maxwells Door" and GetModConfigData("sandboxpreconfigured") then
                        local chest = adv_helpers.SpawnPrefabAtLandPlotNearInst("backpack",player,15,0,15,1,3,3)
                        adv_helpers.AddScenario(chest,"chest_random_good")
                        adv_helpers.SpawnPrefabAtLandPlotNearInst("cutgrass",player,15,0,15,6/_G.TUNING.ADV_DIFFICULTY,3,3)
                        adv_helpers.SpawnPrefabAtLandPlotNearInst("twigs",player,15,0,15,4/_G.TUNING.ADV_DIFFICULTY,3,3)
                        adv_helpers.SpawnPrefabAtLandPlotNearInst("flint",player,15,0,15,8/_G.TUNING.ADV_DIFFICULTY,3,3)
                        adv_helpers.SpawnPrefabAtLandPlotNearInst("flint",player,80,0,80,8/_G.TUNING.ADV_DIFFICULTY,20,20)           
                    elseif _G.TUNING.TELEPORTATOMOD.WORLDS[_G.TUNING.TELEPORTATOMOD.LEVEL].name=="A Cold Reception" then
                        adv_helpers.SpawnPrefabAtLandPlotNearInst("axe",player,15,0,15,2/_G.TUNING.ADV_DIFFICULTY,3,3)
                        adv_helpers.SpawnPrefabAtLandPlotNearInst("grass_umbrella",player,15,0,15,1,3,3)
                        adv_helpers.SpawnPrefabAtLandPlotNearInst("cutgrass",player,15,0,15,6/_G.TUNING.ADV_DIFFICULTY,3,3)
                        adv_helpers.SpawnPrefabAtLandPlotNearInst("twigs",player,15,0,15,4/_G.TUNING.ADV_DIFFICULTY,3,3)
                        adv_helpers.SpawnPrefabAtLandPlotNearInst("flint",player,15,0,15,8/_G.TUNING.ADV_DIFFICULTY,3,3)
                    elseif _G.TUNING.TELEPORTATOMOD.WORLDS[_G.TUNING.TELEPORTATOMOD.LEVEL].name=="King of Winter" then
                        adv_helpers.SpawnPrefabAtLandPlotNearInst("cutgrass",player,15,0,15,6/_G.TUNING.ADV_DIFFICULTY,3,3)
                        adv_helpers.SpawnPrefabAtLandPlotNearInst("twigs",player,15,0,15,4/_G.TUNING.ADV_DIFFICULTY,3,3)
                        adv_helpers.SpawnPrefabAtLandPlotNearInst("flint",player,15,0,15,6/_G.TUNING.ADV_DIFFICULTY,3,3)
                        adv_helpers.SpawnPrefabAtLandPlotNearInst("log",player,15,0,15,8/_G.TUNING.ADV_DIFFICULTY,3,3)
                        adv_helpers.SpawnPrefabAtLandPlotNearInst("axe",player,15,0,15,2/_G.TUNING.ADV_DIFFICULTY,3,3)
                        adv_helpers.SpawnPrefabAtLandPlotNearInst("skeleton",player,15,0,15,1,3,3)
                        local blueprint = adv_helpers.SpawnPrefabAtLandPlotNearInst("earmuffshat_blueprint",player,15,0,15,1,3,3)
                        adv_helpers.MakeFireProof(blueprint,20)
                        local chest = adv_helpers.SpawnPrefabAtLandPlotNearInst("backpack",player,15,0,15,1,3,3)
                        adv_helpers.AddScenario(chest,"packloot_winter_start_medium")
                        adv_helpers.MakeFireProof(chest,20)
                    elseif _G.TUNING.TELEPORTATOMOD.WORLDS[_G.TUNING.TELEPORTATOMOD.LEVEL].name=="The Game is Afoot" then
                        adv_helpers.SpawnPrefabAtLandPlotNearInst("cutgrass",player,15,0,15,6/_G.TUNING.ADV_DIFFICULTY,3,3)
                        adv_helpers.SpawnPrefabAtLandPlotNearInst("twigs",player,15,0,15,4/_G.TUNING.ADV_DIFFICULTY,3,3)
                        adv_helpers.SpawnPrefabAtLandPlotNearInst("flint",player,15,0,15,4/_G.TUNING.ADV_DIFFICULTY,3,3)
                        adv_helpers.SpawnPrefabAtLandPlotNearInst("grass_umbrella",player,15,0,15,1,3,3)
                        local chest = adv_helpers.SpawnPrefabAtLandPlotNearInst("backpack",player,15,0,15,1,3,3)
                        adv_helpers.AddScenario(chest,"chest_presummer")
                    elseif _G.TUNING.TELEPORTATOMOD.WORLDS[_G.TUNING.TELEPORTATOMOD.LEVEL].name=="Archipelago" then
                        adv_helpers.SpawnPrefabAtLandPlotNearInst("axe",player,15,0,15,2/_G.TUNING.ADV_DIFFICULTY,3,3)
                        adv_helpers.SpawnPrefabAtLandPlotNearInst("cutgrass",player,15,0,15,6/_G.TUNING.ADV_DIFFICULTY,3,3)
                        adv_helpers.SpawnPrefabAtLandPlotNearInst("twigs",player,15,0,15,4/_G.TUNING.ADV_DIFFICULTY,3,3)
                        adv_helpers.SpawnPrefabAtLandPlotNearInst("flint",player,15,0,15,4/_G.TUNING.ADV_DIFFICULTY,3,3)
                    elseif _G.TUNING.TELEPORTATOMOD.WORLDS[_G.TUNING.TELEPORTATOMOD.LEVEL].name=="Two Worlds" then
                        adv_helpers.SpawnPrefabAtLandPlotNearInst("cutgrass",player,15,0,15,20/_G.TUNING.ADV_DIFFICULTY,3,3)
                        adv_helpers.SpawnPrefabAtLandPlotNearInst("twigs",player,15,0,15,14/_G.TUNING.ADV_DIFFICULTY,3,3)
                        adv_helpers.SpawnPrefabAtLandPlotNearInst("flint",player,15,0,15,4/_G.TUNING.ADV_DIFFICULTY,3,3)
                        adv_helpers.SpawnPrefabAtLandPlotNearInst("nitre",player,15,0,15,6/_G.TUNING.ADV_DIFFICULTY,3,3)
                        adv_helpers.SpawnPrefabAtLandPlotNearInst("grass_umbrella",player,15,0,15,1,3,3)
                    elseif _G.TUNING.TELEPORTATOMOD.WORLDS[_G.TUNING.TELEPORTATOMOD.LEVEL].name=="Darkness" then
                        local chest = adv_helpers.SpawnPrefabAtLandPlotNearInst("backpack",player,15,0,15,1,3,3)
                        adv_helpers.AddScenario(chest,"packloot_nightmare")
                        adv_helpers.MakeFireProof(chest,20)
                        adv_helpers.SpawnPrefabAtLandPlotNearInst("cutgrass",player,15,0,15,20/_G.TUNING.ADV_DIFFICULTY,3,3)
                        adv_helpers.SpawnPrefabAtLandPlotNearInst("twigs",player,15,0,15,14/_G.TUNING.ADV_DIFFICULTY,3,3)
                        adv_helpers.SpawnPrefabAtLandPlotNearInst("flint",player,15,0,15,4/_G.TUNING.ADV_DIFFICULTY,3,3)
                        adv_helpers.SpawnPrefabAtLandPlotNearInst("grass_umbrella",player,15,0,15,1,3,3)
                        adv_helpers.SpawnPrefabAtLandPlotNearInst("torch",player,15,0,15,4/_G.TUNING.ADV_DIFFICULTY,3,3)
                        adv_helpers.SpawnPrefabAtLandPlotNearInst("skeleton",player,15,0,15,1,3,3)
                        adv_helpers.SpawnPrefabAtLandPlotNearInst("nitre",player,15,0,15,6/_G.TUNING.ADV_DIFFICULTY,3,3)
                    end
                end
            end
        end
    end)
end


_G.TUNING.TELEPORTATOMOD.functionpostloadworldONCE = function(world) -- only called for server and after everything is loaded
    if functionpostloadworldONCE~=nil then -- call a previous funtion from another mod, if there is one
        functionpostloadworldONCE(world)
    end
    world:DoTaskInTime(0,function() -- do the following after everything is finally done
        if SERVER_SIDE then -- only called for server anyway
            if world:HasTag("forest") then
                print("functionpostloadworldONCE, level:"..tostring(_G.TUNING.TELEPORTATOMOD.LEVEL).." chapter:"..tostring(_G.TUNING.TELEPORTATOMOD.CHAPTER))
                if _G.TUNING.ADV_DIFFICULTY~=0 and _G.TUNING.ADV_DIFFICULTY~=3 then -- spawn some helpful stuff
                    if _G.TUNING.TELEPORTATOMOD.CHAPTER~=6 then -- everytime except in the last chosen world
                        local x,y,z = world.components.playerspawner.GetAnySpawnPoint() -- we only have one starting position
                        local spawnpointpos = _G.Vector3(x ,y ,z )
                        local fire = adv_helpers.SpawnPrefabAtLandPlotNearInst("firepit",spawnpointpos,7,0,7,1,3,3)
                        if _G.TUNING.TELEPORTATOMOD.WORLDS[_G.TUNING.TELEPORTATOMOD.LEVEL].name=="Maxwells Door" and GetModConfigData("sandboxpreconfigured") then -- in lvl 1 add a pond to get some food
                            adv_helpers.SpawnPrefabAtLandPlotNearInst("pond",spawnpointpos,30,0,30,1,15,15)
                            adv_helpers.SpawnPrefabAtLandPlotNearInst("rock_ice",spawnpointpos,50,0,50,4/_G.TUNING.ADV_DIFFICULTY,20,20)
                            adv_helpers.SpawnPrefabAtLandPlotNearInst("rabbithole",spawnpointpos,50,0,50,10/_G.TUNING.ADV_DIFFICULTY,20,20)
                            adv_helpers.SpawnPrefabAtLandPlotNearInst("evergreen",spawnpointpos,100,0,100,30/_G.TUNING.ADV_DIFFICULTY,10,10)
                            adv_helpers.SpawnPrefabAtLandPlotNearInst("sapling",spawnpointpos,100,0,100,80/_G.TUNING.ADV_DIFFICULTY,10,10)
                            adv_helpers.SpawnPrefabAtLandPlotNearInst("grassgekko",spawnpointpos,100,0,100,40/_G.TUNING.ADV_DIFFICULTY,5,5)
                            adv_helpers.SpawnPrefabAtLandPlotNearInst("grass",spawnpointpos,100,0,100,80/_G.TUNING.ADV_DIFFICULTY,5,5)
                            adv_helpers.SpawnPrefabAtLandPlotNearInst("carrot_planted",spawnpointpos,100,0,100,20/_G.TUNING.ADV_DIFFICULTY,10,10)
                            adv_helpers.SpawnPrefabAtLandPlotNearInst("berrybush",spawnpointpos,100,0,100,20/_G.TUNING.ADV_DIFFICULTY,15,15)
                            adv_helpers.SpawnPrefabAtLandPlotNearInst("berrybush_juicy",spawnpointpos,100,0,100,20/_G.TUNING.ADV_DIFFICULTY,15,15)
                            adv_helpers.SpawnPrefabAtLandPlotNearInst("flower",spawnpointpos,20,0,20,10/_G.TUNING.ADV_DIFFICULTY,5,5)
                            adv_helpers.SpawnPrefabAtLandPlotNearInst("rock1",spawnpointpos,150,0,150,20/_G.TUNING.ADV_DIFFICULTY,15,15) -- some stone boulder, since its only swamp map
                            adv_helpers.SpawnPrefabAtLandPlotNearInst("rock2",spawnpointpos,150,0,150,12/_G.TUNING.ADV_DIFFICULTY,15,15) -- gold boulder
                        elseif _G.TUNING.TELEPORTATOMOD.WORLDS[_G.TUNING.TELEPORTATOMOD.LEVEL].name=="Two Worlds" then -- in twoworlds some saplings would be good
                            adv_helpers.SpawnPrefabAtLandPlotNearInst("sapling",spawnpointpos,20,0,40/_G.TUNING.ADV_DIFFICULTY,5,5,5)
                            adv_helpers.SpawnPrefabAtLandPlotNearInst("ice",spawnpointpos,15,0,15,30/_G.TUNING.ADV_DIFFICULTY,3,3) -- some ice for flingo
                            adv_helpers.SpawnPrefabAtLandPlotNearInst("knight",spawnpointpos,50,0,50,2/_G.TUNING.ADV_DIFFICULTY,30,30) -- knight for gears
                        elseif _G.TUNING.TELEPORTATOMOD.WORLDS[_G.TUNING.TELEPORTATOMOD.LEVEL].name=="Darkness" then
                            adv_helpers.SpawnPrefabAtLandPlotNearInst("ice",spawnpointpos,15,0,15,36/_G.TUNING.ADV_DIFFICULTY,3,3) -- some ice for flingo
                            adv_helpers.SpawnPrefabAtLandPlotNearInst("knight",spawnpointpos,50,0,50,2/_G.TUNING.ADV_DIFFICULTY,30,30) -- knight for gears
                        elseif _G.TUNING.TELEPORTATOMOD.WORLDS[_G.TUNING.TELEPORTATOMOD.LEVEL].name=="Archipelago" then
                            adv_helpers.SpawnPrefabAtLandPlotNearInst("rock1",spawnpointpos,150,0,150,20/_G.TUNING.ADV_DIFFICULTY,15,15) -- some stone boulder
                            adv_helpers.SpawnPrefabAtLandPlotNearInst("rock2",spawnpointpos,150,0,150,12/_G.TUNING.ADV_DIFFICULTY,15,15) -- gold boulder
                        end
                    end
                elseif _G.TUNING.ADV_DIFFICULTY~=3 then
                    if _G.TUNING.TELEPORTATOMOD.WORLDS[_G.TUNING.TELEPORTATOMOD.LEVEL].name=="Archipelago" then
                        adv_helpers.SpawnPrefabAtLandPlotNearInst("rock1",spawnpointpos,150,0,150,5,15,15) -- some stone boulder
                        adv_helpers.SpawnPrefabAtLandPlotNearInst("rock2",spawnpointpos,150,0,150,5,15,15) -- gold boulder
                    end
                end
            end
        end
    end)
end

local shadow_pieces = {"shadow_bishop","shadow_knight","shadow_rook"}
for _,piece in ipairs(shadow_pieces) do
    AddPrefabPostInit(piece,function(inst)
        if not _G.TheNet:GetIsServer() then 
            return
        end
        inst:DoTaskInTime(2,function()
            if _G.TUNING.TELEPORTATOMOD.WORLDS[_G.TUNING.TELEPORTATOMOD.LEVEL].name=="MaxwellHome" and inst~=nil and inst:IsValid() then
                inst.OnEntitySleep = nil -- no despawn for them
                inst:OnEntityWake()
            end
        end)
    end)
end

local function MCutsceneClient(player)
    local val = player.mynetvarMCutscene:value() -- is set from host within maxwelllock to also start the cutscene for clients
    if val==true and player==_G.ThePlayer then
        local throne = _G.TheSim:FindFirstEntityWithTag("maxwellthrone") -- on client this has only short range, but still better than nothing..
        -- throne = nil -- test the worst case
        if throne~=nil then -- if nil there still will be the server code, although it might look a bit odd
            throne.startthread(throne,nil,CLIENT_SIDE)
        end
    end
end

AddPlayerPostInit(function(player)
    player.mynetvardolevelspeech = _G.net_bool(player.GUID, "dolevelspeechNetStuff", "DirtyEventdolevelspeech") -- true or false
    player.mynetvardolevelspeech:set(true) -- set a default value
    player.dolevelspeech = true
    player.mynetvarMCutscene = _G.net_bool(player.GUID, "MCutsceneNetStuff", "DirtyEventMCutscene")
    player.mynetvarMCutscene:set(false) -- set a default value
    player.dolevelspeech = true
    if CLIENT_SIDE then
        player:ListenForEvent("DirtyEventdolevelspeech", function(player) print("set dolevelspeech for client to "..tostring(player.mynetvardolevelspeech:value()));player.dolevelspeech = player.mynetvardolevelspeech:value() end) -- also set up for client
        player:ListenForEvent("DirtyEventMCutscene", MCutsceneClient)
    end
    player:DoTaskInTime(1, function(player)
        if _G.TUNING.TELEPORTATOMOD.LEVEL~=nil then
            if _G.TUNING.TELEPORTATOMOD.WORLDS[_G.TUNING.TELEPORTATOMOD.LEVEL].name=="MaxwellHome" then -- has to be done everytime
                GLOBAL.TheCamera:SetHeadingTarget(225) -- rotate the camera for every player making south at the top (world was rotated for whatever reason)
            end
        end
    end)
    if not GetModConfigData("repickcharacter") then
        player.starting_inventory_orig = player.starting_inventory -- save it and give it within functionatplayerfirstspawn if the chapter is 0 or 1
        player.starting_inventory = nil -- dont give starting items generally
    end
end)

modes = {"survival","wilderness","endless"} -- overwriting every gamemode to the same, so regardless wich mode you choose, it is always the following
for i,mode in ipairs(modes) do
    _G.GAME_MODES[mode].spawn_mode = "fixed"
    _G.GAME_MODES[mode].ghost_sanity_drain = true
    _G.GAME_MODES[mode].ghost_enabled = true
    _G.GAME_MODES[mode].reset_time = { time = 120, loadingtime = 180 }
    _G.GAME_MODES[mode].portal_rez = true
    _G.GAME_MODES[mode].invalid_recipes = {} -- "lifeinjector", "resurrectionstatue", "reviver"
    _G.GAME_MODES[mode].resource_renewal = true
end




-- local function GetRoom(entity) -- written by ptr, thanks.
    -- local closestdist = math.huge
    -- local closestid = nil
    -- x,_,y=entity.Transform:GetWorldPosition()
    -- for i,v in pairs(_G.TheWorld.topology.nodes) do
        -- if #v.neighbours > 0 then
            -- local dx = math.floor((math.abs(v.x - x)+2)/4)
            -- local dy = math.floor((math.abs(v.y - y)+2)/4)
            -- local distsq = dx*dx + dy*dy
            -- if distsq < closestdist then
                -- closestdist = distsq
                -- closestid = i
            -- end
        -- end
    -- end
    -- return _G.TheWorld.topology.ids[closestid]
-- end

