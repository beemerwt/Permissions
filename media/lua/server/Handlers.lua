
if isClient() then return end

local log = DebugLog.log;

local Handlers = {}

local function getArgString(...)
  local tArgs = { ... }
  local argStr = "{ "
  for k,v in pairs(tArgs) do
    argStr = argStr .. "[" .. tostring(k) .. "]=" .. tostring(v)
  end
  argStr = argStr .. " }"
  return argStr
end

function Handlers.OnClientCommand(module, command, player, args)
  if module ~= "permission" then return end
  if command == "openDoor" then
    args:setIsLocked(true);

    if Permissions.UserHasPermission(player.username, "openDoor") then
      log("User tried opening door: " .. tostring(args));
      --args:ToggleDoor(player);
    end
  end

end

function Handlers.OnServerCommand(...)
  log("Handled Event: OnServerCommand");
  local argStr = getArgString(...)
  log(argStr);
end

function Handlers.OnServerStarted(...)
  log("Handled Event: OnServerStarted");
  local argStr = getArgString(...)
  log(argStr);
end

function Handlers.OnServerWorkshopItems(...)
  log("Handled Event: OnServerWorkshopItems");
  local argStr = getArgString(...)
  log(argStr);
end

function Handlers.OnServerStartSaving(...)
  log("Handled Event: OnServerStartSaving");
  local argStr = getArgString(...)
  log(argStr);
  Permissions.Save();
end

function Handlers.OnServerFinishSaving(...)
  log("Handled Event: OnServerFinishSaving");
  local argStr = getArgString(...)
  log(argStr);
end
  
function Handlers.OnServerStatisticReceived(...)
  log("Handled Event: OnServerStatisticReceived");
  local argStr = getArgString(...)
  log(argStr);
end

function Handlers.OnResetLua(...)
  log("Handled Event: OnResetLua");
  local argStr = getArgString(...)
  log(argStr);
end

function Handlers.OnGameBoot(...)
  log("Handled Event: On Game Boot");
  local argStr = getArgString(...)
  log(argStr);
end

function Handlers.OnCreatePlayer(player, ...)
  log("Player Created: " .. tostring(player))
  local argStr = getArgString(...)
  log(argStr);
end

function Handlers.OnWorldMessage(...)
  log("Handled Event: On World Message");
  local argStr = getArgString(...)
  log(argStr);
end
  
function Handlers.OnAddMessage(...)
  log("Handled Event: On Add Message");
  local argStr = getArgString(...)
  log(argStr);
end

function Handlers.OnAdminMessage(...)
  log("Handled Event: On Admin Message");
  local argStr = getArgString(...)
  log(argStr);
end

function Handlers.OnCoopServerMessage(...)
  log("Handled Event: On Coop Server Message");
  local argStr = getArgString(...)
  log(argStr);
end

function Handlers.OnConnected(...)
  log("Handled Event: OnConnected");
  log("User Connected");
  local argStr = getArgString(...)
  log(argStr);
end

function Handlers.OnDisconnect(...)
  log("Handled Event: OnDisconnect");
  log("User Disconnected");
  local argStr = getArgString(...)
  log(argStr)
end

function Handlers.OnPlayerUpdate(...)
  log("Handled Event: OnPlayerUpdate");
  local argStr = getArgString(...)
  log(argStr);
end

-- Food | IsoDeadBody | IsoGridSquare | IsoWorldInventoryObject
function Handlers.OnContainerUpdate(container)

  -- if container is IsoGridSquare?
  if container.getDoor then
    local characters = container:getDeferedCharacters();
    local door = container:getDoor(true);
    if door == nil then door = container:getDoor(false) end
    if door == nil then return end

    if not door:isLocked() then
      door:setIsLocked(true)
    end

    print(tostring(characters))
    print(tostring(door))

  end
end



for eventName,fn in pairs(Handlers) do
  _G['Events'][eventName].Add(fn)
  log("Adding Handler: " .. eventName);
end

--[[ LuaEventManager.java
AddEvent("OnGameBoot");
AddEvent("OnPreGameStart");
AddEvent("OnTick");
AddEvent("OnTickEvenPaused");
AddEvent("OnRenderUpdate");
AddEvent("OnFETick");
AddEvent("OnGameStart");
AddEvent("OnPreUIDraw");
AddEvent("OnPostUIDraw");
AddEvent("OnCharacterCollide");
AddEvent("OnKeyStartPressed");
AddEvent("OnKeyPressed");
AddEvent("OnObjectCollide");
AddEvent("OnNPCSurvivorUpdate");
AddEvent("OnPlayerUpdate");
AddEvent("OnZombieUpdate");
AddEvent("OnTriggerNPCEvent");
AddEvent("OnMultiTriggerNPCEvent");
AddEvent("OnLoadMapZones");
AddEvent("OnAddBuilding");
AddEvent("OnCreateLivingCharacter");
AddEvent("OnChallengeQuery");
AddEvent("OnFillInventoryObjectContextMenu");
AddEvent("OnPreFillInventoryObjectContextMenu");
AddEvent("OnFillWorldObjectContextMenu");
AddEvent("OnPreFillWorldObjectContextMenu");
AddEvent("OnRefreshInventoryWindowContainers");
AddEvent("OnGamepadConnect");
AddEvent("OnGamepadDisconnect");
AddEvent("OnJoypadActivate");
AddEvent("OnJoypadActivateUI");
AddEvent("OnJoypadBeforeDeactivate");
AddEvent("OnJoypadDeactivate");
AddEvent("OnJoypadBeforeReactivate");
AddEvent("OnJoypadReactivate");
AddEvent("OnJoypadRenderUI");
AddEvent("OnMakeItem");
AddEvent("OnWeaponHitCharacter");
AddEvent("OnWeaponSwing");
AddEvent("OnWeaponHitTree");
AddEvent("OnWeaponHitXp");
AddEvent("OnWeaponSwingHitPoint");
AddEvent("OnPlayerAttackFinished");
AddEvent("OnLoginState");
AddEvent("OnLoginStateSuccess");
AddEvent("OnCharacterCreateStats");
AddEvent("OnLoadSoundBanks");
AddEvent("OnObjectLeftMouseButtonDown");
AddEvent("OnObjectLeftMouseButtonUp");
AddEvent("OnObjectRightMouseButtonDown");
AddEvent("OnObjectRightMouseButtonUp");
AddEvent("OnDoTileBuilding");
AddEvent("OnDoTileBuilding2");
AddEvent("OnDoTileBuilding3");
AddEvent("OnConnectFailed");
AddEvent("OnConnected");
AddEvent("OnDisconnect");
AddEvent("OnConnectionStateChanged");
AddEvent("OnScoreboardUpdate");
AddEvent("OnMouseMove");
AddEvent("OnMouseDown");
AddEvent("OnMouseUp");
AddEvent("OnRightMouseDown");
AddEvent("OnRightMouseUp");
AddEvent("OnNewSurvivorGroup");
AddEvent("OnPlayerSetSafehouse");
AddEvent("OnLoad");
AddEvent("AddXP");
AddEvent("LevelPerk");
AddEvent("OnSave");
AddEvent("OnMainMenuEnter");
AddEvent("OnPreMapLoad");
AddEvent("OnPostFloorSquareDraw");
AddEvent("OnPostFloorLayerDraw");
AddEvent("OnPostTilesSquareDraw");
AddEvent("OnPostTileDraw");
AddEvent("OnPostWallSquareDraw");
AddEvent("OnPostCharactersSquareDraw");
AddEvent("OnCreateUI");
AddEvent("OnMapLoadCreateIsoObject");
AddEvent("OnCreateSurvivor");
AddEvent("OnCreatePlayer");
AddEvent("OnPlayerDeath");
AddEvent("OnZombieDead");
AddEvent("OnCharacterDeath");
AddEvent("OnCharacterMeet");
AddEvent("OnSpawnRegionsLoaded");
AddEvent("OnPostMapLoad");
AddEvent("OnAIStateExecute");
AddEvent("OnAIStateEnter");
AddEvent("OnAIStateExit");
AddEvent("OnAIStateChange");
AddEvent("OnPlayerMove");
AddEvent("OnInitWorld");
AddEvent("OnNewGame");
AddEvent("OnIsoThumpableLoad");
AddEvent("OnIsoThumpableSave");
AddEvent("ReuseGridsquare");
AddEvent("LoadGridsquare");
AddEvent("EveryOneMinute");
AddEvent("EveryTenMinutes");
AddEvent("EveryDays");
AddEvent("EveryHours");
AddEvent("OnDusk");
AddEvent("OnDawn");
AddEvent("OnEquipPrimary");
AddEvent("OnEquipSecondary");
AddEvent("OnClothingUpdated");
AddEvent("OnWeatherPeriodStart");
AddEvent("OnWeatherPeriodStage");
AddEvent("OnWeatherPeriodComplete");
AddEvent("OnWeatherPeriodStop");
AddEvent("OnRainStart");
AddEvent("OnRainStop");
AddEvent("OnAmbientSound");
AddEvent("OnWorldSound");
AddEvent("OnResetLua");
AddEvent("OnModsModified");
AddEvent("OnSeeNewRoom");
AddEvent("OnNewFire");
AddEvent("OnFillContainer");
AddEvent("OnChangeWeather");
AddEvent("OnRenderTick");
AddEvent("OnDestroyIsoThumpable");
AddEvent("OnPostSave");
AddEvent("OnResolutionChange");
AddEvent("OnWaterAmountChange");
AddEvent("OnClientCommand");
AddEvent("OnServerCommand");
AddEvent("OnContainerUpdate");
AddEvent("OnObjectAdded");
AddEvent("OnObjectAboutToBeRemoved");
AddEvent("onLoadModDataFromServer");
AddEvent("OnGameTimeLoaded");
AddEvent("OnCGlobalObjectSystemInit");
AddEvent("OnSGlobalObjectSystemInit");
AddEvent("OnWorldMessage");
AddEvent("OnKeyKeepPressed");
AddEvent("SendCustomModData");
AddEvent("ServerPinged");
AddEvent("OnServerStarted");
AddEvent("OnLoadedTileDefinitions");
AddEvent("OnPostRender");
AddEvent("DoSpecialTooltip");
AddEvent("OnCoopJoinFailed");
AddEvent("OnServerWorkshopItems");
AddEvent("OnVehicleDamageTexture");
AddEvent("OnCustomUIKey");
AddEvent("OnCustomUIKeyPressed");
AddEvent("OnCustomUIKeyReleased");
AddEvent("OnDeviceText");
AddEvent("OnRadioInteraction");
AddEvent("OnLoadRadioScripts");
AddEvent("OnAcceptInvite");
AddEvent("OnCoopServerMessage");
AddEvent("OnReceiveUserlog");
AddEvent("OnAdminMessage");
AddEvent("OnGetDBSchema");
AddEvent("OnGetTableResult");
AddEvent("ReceiveFactionInvite");
AddEvent("AcceptedFactionInvite");
AddEvent("ReceiveSafehouseInvite");
AddEvent("AcceptedSafehouseInvite");
AddEvent("ViewTickets");
AddEvent("SyncFaction");
AddEvent("OnReceiveItemListNet");
AddEvent("OnMiniScoreboardUpdate");
AddEvent("OnSafehousesChanged");
AddEvent("RequestTrade");
AddEvent("AcceptedTrade");
AddEvent("TradingUIAddItem");
AddEvent("TradingUIRemoveItem");
AddEvent("TradingUIUpdateState");
AddEvent("OnGridBurnt");
AddEvent("OnPreDistributionMerge");
AddEvent("OnDistributionMerge");
AddEvent("OnPostDistributionMerge");
AddEvent("MngInvReceiveItems");
AddEvent("OnTileRemoved");
AddEvent("OnServerStartSaving"); 
AddEvent("OnServerFinishSaving");
AddEvent("OnMechanicActionDone");
AddEvent("OnClimateTick");
AddEvent("OnThunderEvent");
AddEvent("OnEnterVehicle");
AddEvent("OnSteamGameJoin");
AddEvent("OnTabAdded");
AddEvent("OnSetDefaultTab");
AddEvent("OnTabRemoved");
AddEvent("OnAddMessage");
AddEvent("SwitchChatStream");
AddEvent("OnChatWindowInit");
AddEvent("OnInitSeasons");
AddEvent("OnClimateTickDebug");
AddEvent("OnInitModdedWeatherStage");
AddEvent("OnUpdateModdedWeatherStage");
AddEvent("OnClimateManagerInit");
AddEvent("OnPressReloadButton");
AddEvent("OnPressRackButton");
AddEvent("OnHitZombie");
AddEvent("OnBeingHitByZombie");
AddEvent("OnServerStatisticReceived");
AddEvent("OnDynamicMovableRecipe");
AddEvent("OnInitGlobalModData");
AddEvent("OnReceiveGlobalModData");
AddEvent("OnInitRecordedMedia");
AddEvent("onUpdateIcon");
AddEvent("preAddForageDefs");
AddEvent("preAddZoneDefs");
AddEvent("preAddCatDefs");
AddEvent("preAddItemDefs");
AddEvent("onAddForageDefs");
AddEvent("onFillSearchIconContextMenu");
AddEvent("onItemFall");]]--