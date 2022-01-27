
if isClient() and not isCoopHost() then return end

-- Don't know when this applies
--  basically some server scripts call "noise" when an event is triggered
--  presumably this is to log while inside another thread
--  but if it doesn't apply, then we just use print
local log = noise or print

local debug = true;

-- LuaManager.java
--  Do not use "fileExists" or "serverFileExists"
--  getFileWriter(file, shouldCreate, shouldAppend) -- starts in ./Lua/
--  getFileReader(file, shouldCreate) -- starts in ./Lua/
local function doesFileExist(fileName)
  local fileReader = getFileReader(fileName, false);
  if fileReader then
    local line = fileReader:readLine();
    fileReader:close();
    return line ~= nil;
  end

  return false;
end

json = require "json"

Permissions = {
  Groups = {},
  Users = {},
};

local permissionsFile = "permissions.json";

local function createDefaultPermissionsFile()
  print("Creating default permissions file");

  local Groups = {};
  Groups['admin'] = PermissionGroup("*");
  Groups['default'] = PermissionGroup();

  local Users = {};
  Users['admin'] = PermissionUser("admin", "test");

  Permissions.Groups = Groups;
  Permissions.Users = Users;

  Permissions.Save();
end

function Permissions.GroupHasPermission(groupName, perm)
  if not Permissions.Groups[groupName] then
    log("Group " .. groupName .. " does not exist. This likely means a player has an incorrect group association.");
    return false
  end

  for _,p in ipairs(Permissions.Groups[groupName].permissions) do
    if p == perm or p == "*" then return true end
  end

  return false;
end

-- "user" can be IsoPlayer or String
function Permissions.UserHasPermission(user, perm)
  local username = "";

  if instanceof(user, "IsoPlayer") then
    username = user:getUsername();
  elseif type(user) == "string" then
    username = user;
  else
    return false;
  end

  if not Permissions.Users[username] then return false end
  
  local user = Permissions.Users[username];
  if Permissions.GroupHasPermission(user.group, perm) then return true end

  for _,p in ipairs(Permissions.Users[username].permissions) do
    if p == perm or p == "*" then return true end
  end

  return false
end

function Permissions.CreateUser(userName, group, permissions)
  if group == nil then group = "default" end
  if permissions == nil then permissions = {} end

  Permissions.Users[userName] = {
    group = group,
    permissions = permissions,
  };

  return true;
end

function Permissions.CreateGroup(groupName, permissions)
  if permissions == nil then permissions = {} end
  Permissions.Groups[groupName] = {
    permissions = permissions
  };

  return true;
end

function Permissions.Save()
  local saveObj = {
    groups = Permissions.Groups,
    users = Permissions.Users
  };
  local jsonStr = json.stringify(saveObj, nil, 4);

  local file = getFileWriter(permissionsFile, true, false);
  if file == nil then
    print("Failed to save Permissions");
  else
    file:write(jsonStr)
    file:close()
  end
end

function Permissions.Reload()
  Permissions.Save()
  Permissions.Load()
end

function Permissions.PlayerExists(username)
  return Permissions.Users[username] ~= nil;
end

function Permissions.Load()
  if not doesFileExist(permissionsFile) then
    createDefaultPermissionsFile()
  end

  local file = getFileReader(permissionsFile, false);

  local jsonStr = "";
  local line = file:readLine();

  while true do
    if line == nil then
      break;
    end

    jsonStr = jsonStr .. line;
    line = file:readLine();
  end

  file:close();
  local permissions = json.parse(jsonStr, false)

  for k,v in pairs(permissions.groups) do
    print(k, v)
  end

  for k,v in pairs(permissions.users) do
    print(k, v)
  end

  print("Assigning Permissions");
  Permissions.Groups = permissions.groups;
  Permissions.Users = permissions.users;  
end

-- module and perm are always strings
-- player is always IsoPlayer
-- args will always be present, but could be empty
function Permissions.OnClientCommand(module, perm, player, args)
  if module ~= "permission" then return end
  if args == nil then args = {} end

  local argStr = '';
  for k,v in pairs(args) do argStr = argStr .. k .. "=" .. v .. "," end

  log("Permissions received ClientCommand " .. perm .. ", " .. argStr)

  local playerNum = player:getPlayerNum();

  -- sends "permission" response specifically to "player"
  local hasPermission = Permissions.UserHasPermission(player, perm);
  args.permission = hasPermission;
  args.playerNum = playerNum;

  sendServerCommand(player, "permission", perm, args);
end

function Permissions.OnResetLua(reason)
  log("Handled Event: OnResetLua for reason: " .. reason)
  Permissions.Reload();
end

function Permissions.OnServerStarted()
  log("Handled Event: OnServerStarted");
  Permissions.Load();
end


function Permissions.OnServerStartSaving()
  noise("Handled Event: OnServerStartSaving");
  Permissions.Save();
end

function Permissions.OnConnected()
  -- List<IsoPlayer>
  local connected = getOnlinePlayers();
  
  for i=1,connected:size() do
    local player = connected:get(i-1);
    local username = player:getUsername();

    if not Permissions.PlayerExists(username) then
      Permissions.CreateUser(username)
    end
  end
end

-- Events.OnServerCommand.Add(Permissions.OnServerCommand); would serve itself, so no?

Permissions.Load();

Events.OnResetLua.Add(Permissions.OnResetLua);
Events.OnConnected.Add(Permissions.OnConnected);
Events.OnServerStarted.Add(Permissions.OnServerStarted);
Events.OnClientCommand.Add(Permissions.OnClientCommand);
Events.OnServerStartSaving.Add(Permissions.OnServerStartSaving);


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
AddEvent("OnprintinState");
AddEvent("OnprintinStateSuccess");
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
AddEvent("OnReceiveUserprint");
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