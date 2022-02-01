-- We are no longer handling client command because it calls itself
--  and we have verified that OnClientCommand CANNOT be called from the server

Permissions = _G['Permissions'] or {}

if isServer() then return end

local function getArgFunc(numArgs)
  if numArgs == 0 then return function(old, args) old() end end
  if numArgs == 1 then return function(old, args) old(args[1]) end end
  if numArgs == 2 then return function(old, args) old(args[1], args[2]) end end
  if numArgs == 3 then return function(old, args) old(args[1], args[2], args[3]) end end
  if numArgs == 4 then return function(old, args) old(args[1], args[2], args[3], args[4]) end end
  if numArgs == 5 then return function(old, args) old(args[1], args[2], args[3], args[4], args[5]) end end
  if numArgs == 6 then return function(old, args) old(args[1], args[2], args[3], args[4], args[5], args[6]) end end
  if numArgs == 7 then return function(old, args) old(args[1], args[2], args[3], args[4], args[5], args[6], args[7]) end end
  return nil;
end

local function PermissiveAction(origin, name, numArgs)
  local argFunc = getArgFunc(numArgs);
  
  local old = origin[name];
  origin[name] = function(...)
    local tArgs = { ... }
    Permissions.RequestPermission(getPlayer(), name, function()
      argFunc(old, tArgs)
    end)
  end
end

-- TODO: Add the same message like in RequestPermission for when it doesn't exist in playerPermissions
-- Uses the playerPermissions object to verify that we have permission to do the action
-- Less secure, but less load.
local function RequirePermission(permission, origin, numArgs)
  local argFunc = getArgFunc(numArgs);
  local old = origin[name];
  origin[name] = function(...)
    local tArgs = { ... }
    if Permissions.HasPermission(permission) then
      argFunc(old, tArgs);
    end
  end
end

-- Binds multiple functions to one permission
-- Params:
-- String permission  - The permission required to perform the actions
-- Table origin       - The original table containing the actions
-- ...                - The list of functions (bound using BindAction) that require "permission" to perform
local function PermissiveActions(permission, origin, ...)
  local boundActions = { ... }
  for i = 1,#boundActions do
    local bind = boundActions[i];
    local old = origin[bind.name]
    local argFunc = getArgFunc(bind.args);

    origin[funcName] = function(...)
      local tArgs = { ... }
      Permissions.RequestPermission(getPlayer(), permission, function()
        argFunc(old, tArgs)
      end)
    end
  end
end

local function BindAction(funcName, numArgs)
  return {
    args = numArgs,
    name = funcName
  };
end

local coroutines = {};

function Permissions.RequestPermission(player, permission, func)
  local co = coroutine.create(function()
    sendClientCommand(player, "permission", permission, {});

    retryCount = 0;
    local response = coroutine.yield();
    while retryCount < 3 do

      -- nullcheck, then check if the permission passed was relevant to this one
      if response.permission then
        if response.permission == permission then
          break
        end
      end

      -- otherwise, add to retry count and await again
      retryCount = retryCount + 1;
      response = coroutine.yield();
    end

    if retryCount < 3 then
      if response.granted then
        func();
      end
    end
  end);

  table.insert(coroutines, co);
  coroutine.resume(co); -- start by sending message and yielding response
end

function Permissions.HasPermission(permission)
  if not Permissions.playerPermissions then return end
  for _, perm in ipairs(Permissions.playerPermissions) do
    if perm == "*" or perm == permission then
      return true
    end
  end

  return false
end

function Permissions.OnServerCommand(module, perm, args)
  if module ~= "permission" then return end

  if perm == "syncplayer" then
    print("Player has synchronized with server.")
    Permissions.SyncPlayer(args);
  else
    -- resume all coroutines with the given args
    local remove = {}
    for i=1,#coroutines do
      -- check for dead coroutines, append to "remove" list
      local status = coroutine.status(coroutines[i]);
      if status == "dead" then
        table.insert(remove, i);
      elseif status == "suspended" then
        coroutine.resume(coroutines[i], args);
      end
    end

    -- remove all dead coroutines
    for i=1,#remove do
      table.remove(coroutines, remove[i]);
    end
  end
end

function Permissions.SyncPlayer(args)
  if type(args) ~= "table" then
    print("Synchronizing Player with Server Permissions");
    sendClientCommand(getPlayer(), "permission", "syncplayer", {})
  else
    print("Received Player Permissions from Server");
    Permissions.playerPermissions = args;
    Events.OnTick.Remove(Permissions.SyncPlayer);
  end
end

function Permissions.RegisterActions()
  ------------------------------------------------
  -- World (Right-Click) Permissions
  ------------------------------------------------

  PermissiveAction(ISWorldObjectContextMenu, "onTeleport", 0);

  PermissiveAction(ISWorldObjectContextMenu, "checkWeapon", 1);
  PermissiveAction(ISWorldObjectContextMenu, "haveWaterContainer", 1);
  PermissiveAction(ISWorldObjectContextMenu, "isThumpDoor", 1);
  PermissiveAction(ISWorldObjectContextMenu, "checkBlowTorchForBarricade", 1);
  PermissiveAction(ISWorldObjectContextMenu, "onSitOnGround", 1);

  PermissiveAction(ISWorldObjectContextMenu, "emptyRainCollector", 2);
  PermissiveAction(ISWorldObjectContextMenu, "onSleepModalClick", 2);
  PermissiveAction(ISWorldObjectContextMenu, "onToggleThumpableLight", 2);
  PermissiveAction(ISWorldObjectContextMenu, "onRemoveFuel", 2);
  PermissiveAction(ISWorldObjectContextMenu, "onRest", 2);
  PermissiveAction(ISWorldObjectContextMenu, "onSleep", 2);
  PermissiveAction(ISWorldObjectContextMenu, "onSleepWalkToComplete", 2);
  PermissiveAction(ISWorldObjectContextMenu, "onRemoveDigitalPadlockWalkToComplete", 2);
  PermissiveAction(ISWorldObjectContextMenu, "onChooseSafehouse", 2);

  -- All apply to the same permission "survivorControl"
  PermissiveActions("survivorControl",
    ISWorldObjectContextMenu,
    BindAction("onTalkTo", 2),
    BindAction("onStay", 2),
    BindAction("onGuard", 2),
    BindAction("onFollow", 2),
    BindAction("onTeamUp", 2)
  );

  PermissiveAction(ISWorldObjectContextMenu, "isTrappedAdjacentToWindow", 2);
  PermissiveAction(ISWorldObjectContextMenu, "doCleanBlood", 2);
  PermissiveAction(ISWorldObjectContextMenu, "doRemoveGrass", 2);
  PermissiveAction(ISWorldObjectContextMenu, "onFishing", 2);
  PermissiveAction(ISWorldObjectContextMenu, "onFishingNet", 2);
  PermissiveAction(ISWorldObjectContextMenu, "doChopTree", 2);

  PermissiveAction(ISWorldObjectContextMenu, "onGetCompost", 3);
  PermissiveAction(ISWorldObjectContextMenu, "onAddCompost", 3);
  PermissiveAction(ISWorldObjectContextMenu, "onAddPlayerToSafehouse", 3);
  PermissiveAction(ISWorldObjectContextMenu, "onReleaseSafeHouse", 3);
  PermissiveAction(ISWorldObjectContextMenu, "onTakeSafeHouse", 3);
  PermissiveAction(ISWorldObjectContextMenu, "onViewSafeHouse", 3);

  PermissiveActions("generatorControl",
    ISWorldObjectContextMenu,
    BindAction("onTakeFuel", 3),
    BindAction("onInfoGenerator", 3),
    BindAction("onFixGenerator", 3)
  );

  PermissiveAction(ISWorldObjectContextMenu, "onTakeGenerator", 3);
  PermissiveAction(ISWorldObjectContextMenu, "onRemoveFishingNet", 3);
  PermissiveAction(ISWorldObjectContextMenu, "onDestroy", 3);
  PermissiveAction(ISWorldObjectContextMenu, "onChopTree", 3);
  PermissiveAction(ISWorldObjectContextMenu, "onTrade", 3);
  PermissiveAction(ISWorldObjectContextMenu, "onCheckStats", 3);
  PermissiveAction(ISWorldObjectContextMenu, "onMedicalCheck", 3);
  PermissiveAction(ISWorldObjectContextMenu, "onWakeOther", 3);
  PermissiveAction(ISWorldObjectContextMenu, "onInsertFuel", 3);
  PermissiveAction(ISWorldObjectContextMenu, "onToggleClothingDryer", 3);
  PermissiveAction(ISWorldObjectContextMenu, "onToggleClothingWasher", 3);
  PermissiveAction(ISWorldObjectContextMenu, "onMicrowaveSetting", 3);
  PermissiveAction(ISWorldObjectContextMenu, "onStoveSetting", 3);
  PermissiveAction(ISWorldObjectContextMenu, "onToggleLight", 3);
  PermissiveAction(ISWorldObjectContextMenu, "onToggleStove", 3);
  PermissiveAction(ISWorldObjectContextMenu, "onWashYourself", 3);
  PermissiveAction(ISWorldObjectContextMenu, "doRecipeUsingWaterMenu", 3);
  PermissiveAction(ISWorldObjectContextMenu, "onDrink", 3);
  PermissiveAction(ISWorldObjectContextMenu, "onRemovePadlock", 3);
  PermissiveAction(ISWorldObjectContextMenu, "onClearAshes", 3);
  PermissiveAction(ISWorldObjectContextMenu, "onBurnCorpse", 3);
  PermissiveAction(ISWorldObjectContextMenu, "doFillWaterMenu", 3);
  PermissiveAction(ISWorldObjectContextMenu, "doDrinkWaterMenu", 3);
  PermissiveAction(ISWorldObjectContextMenu, "onGrabWItem", 3);
  PermissiveAction(ISWorldObjectContextMenu, "onGrabHalfWItems", 3);
  PermissiveAction(ISWorldObjectContextMenu, "onGrabAllWItems", 3);
  PermissiveAction(ISWorldObjectContextMenu, "onTakeTrap", 3);
  PermissiveAction(ISWorldObjectContextMenu, "onGrabCorpseItem", 3);
  PermissiveAction(ISWorldObjectContextMenu, "onPlumbItem", 3);
  PermissiveAction(ISWorldObjectContextMenu, "onRemoveDigitalPadlock", 3);
  PermissiveAction(ISWorldObjectContextMenu, "onPutDigitalPadlockWalkToComplete", 3);
  PermissiveAction(ISWorldObjectContextMenu, "onUnbarricade", 3);
  PermissiveAction(ISWorldObjectContextMenu, "onUnbarricadeMetal", 3);
  PermissiveAction(ISWorldObjectContextMenu, "onUnbarricadeMetalBar", 3);
  PermissiveAction(ISWorldObjectContextMenu, "onSit", 3);
  PermissiveAction(ISWorldObjectContextMenu, "onMetalBarBarricade", 3);
  PermissiveAction(ISWorldObjectContextMenu, "onMetalBarricade", 3);
  PermissiveAction(ISWorldObjectContextMenu, "onBarricade", 3);
  PermissiveAction(ISWorldObjectContextMenu, "onAddSheet", 3);
  PermissiveAction(ISWorldObjectContextMenu, "onRemoveCurtain", 3);
  PermissiveAction(ISWorldObjectContextMenu, "onOpenCloseCurtain", 3);
  PermissiveAction(ISWorldObjectContextMenu, "onOpenCloseWindow", 3);
  PermissiveAction(ISWorldObjectContextMenu, "onAddSheetRope", 3);
  PermissiveAction(ISWorldObjectContextMenu, "onRemoveSheetRope", 3);
  PermissiveAction(ISWorldObjectContextMenu, "onClimbOverFence", 3);
  PermissiveAction(ISWorldObjectContextMenu, "onClimbThroughWindow", 3);
  PermissiveAction(ISWorldObjectContextMenu, "onSmashWindow", 3);
  PermissiveAction(ISWorldObjectContextMenu, "onRemoveBrokenGlass", 3);
  PermissiveAction(ISWorldObjectContextMenu, "onPickupBrokenGlass", 3);
  PermissiveAction(ISWorldObjectContextMenu, "onOpenCloseDoor", 3);
  PermissiveAction(ISWorldObjectContextMenu, "onCleanBlood", 3);
  PermissiveAction(ISWorldObjectContextMenu, "doRemovePlant", 3);
  PermissiveAction(ISWorldObjectContextMenu, "onRemoveGrass", 3);
  PermissiveAction(ISWorldObjectContextMenu, "onRemoveWallVine", 3);
  PermissiveAction(ISWorldObjectContextMenu, "onWalkTo", 3);
  PermissiveAction(ISWorldObjectContextMenu, "onDigGraves", 3);
  PermissiveAction(ISWorldObjectContextMenu, "onBuryCorpse", 3);
  PermissiveAction(ISWorldObjectContextMenu, "onFillGrave", 3);

  PermissiveAction(ISWorldObjectContextMenu, "onRemoveFire", 4);
  PermissiveAction(ISWorldObjectContextMenu, "onRemovePlayerFromSafehouse", 4);
  PermissiveAction(ISWorldObjectContextMenu, "onPlugGenerator", 4);
  PermissiveAction(ISWorldObjectContextMenu, "onActivateGenerator", 4);
  PermissiveAction(ISWorldObjectContextMenu, "onAddFuel", 4);
  PermissiveAction(ISWorldObjectContextMenu, "onCheckFishingNet", 4);
  PermissiveAction(ISWorldObjectContextMenu, "onConfirmSleep", 4);
  PermissiveAction(ISWorldObjectContextMenu, "onScavenge", 4);
  PermissiveAction(ISWorldObjectContextMenu, "toggleClothingDryer", 4);
  PermissiveAction(ISWorldObjectContextMenu, "toggleClothingWasher", 4);
  PermissiveAction(ISWorldObjectContextMenu, "onLightModify", 4);

  PermissiveActions("doorControl",
    ISWorldObjectContextMenu,
    BindAction("onGetDoorKey", 4),
    BindAction("onUnLockDoor", 4),
    BindAction("onLockDoor", 3)
  );

  PermissiveAction(ISWorldObjectContextMenu, "onPutDigitalPadlock", 4);
  PermissiveAction(ISWorldObjectContextMenu, "onPutPadlock", 4);
  PermissiveAction(ISWorldObjectContextMenu, "onAddWaterFromItem", 4);
  PermissiveAction(ISWorldObjectContextMenu, "addRemoveCurtainOption", 4);
  PermissiveAction(ISWorldObjectContextMenu, "onClimbSheetRope", 4);
  PermissiveAction(ISWorldObjectContextMenu, "onRemovePlant", 4);
  PermissiveAction(ISWorldObjectContextMenu, "doSleepOption", 4);

  PermissiveAction(ISWorldObjectContextMenu, "handleCarBatteryCharger", 5);
  PermissiveAction(ISWorldObjectContextMenu, "onTakeWater", 5);
  PermissiveAction(ISWorldObjectContextMenu, "onLightBulb", 5);
  PermissiveAction(ISWorldObjectContextMenu, "onLightBattery", 5);

  PermissiveActions("equip",
    ISWorldObjectContextMenu,
    BindAction("equip", 5),
    BindAction("equip2", 4)
  );

  PermissiveAction(ISWorldObjectContextMenu, "onWashClothing", 6);

  ------------------------------------------------
  -- Vehicle Permissions
  ------------------------------------------------
  PermissiveAction(ISVehicleMenu, "OnFillWorldObjectContextMenu", 4);
  PermissiveAction(ISVehicleMenu, "showRadialMenu", 1);
  PermissiveAction(ISVehicleMenu, "showRadialMenuOutside", 1);
  PermissiveAction(ISVehicleMenu, "doTowingMenu", 3);
  PermissiveAction(ISVehicleMenu, "FillMenuOutsideVehicle", 4);
  PermissiveAction(ISVehicleMenu, "onRoadtrip", 1);

  PermissiveActions("debugVehicle",
    ISVehicleMenu,
    BindAction("onDebugAngles", 2),
    BindAction("onDebugColor", 2),
    BindAction("onDebugBlood", 2),
    BindAction("onDebugEditor", 2),
    BindAction("addSetScriptMenu", 3),
    BindAction("onDebugSetScript", 3)
  );

  PermissiveAction(ISVehicleMenu, "onMechanic", 2);
  PermissiveAction(ISVehicleMenu, "FillPartMenu", 4);
  PermissiveAction(ISVehicleMenu, "onSwitchSeat", 2);
  PermissiveAction(ISVehicleMenu, "onToggleHeadlights", 1);
  PermissiveAction(ISVehicleMenu, "onToggleTrunkLocked", 1);
  PermissiveAction(ISVehicleMenu, "onToggleHeater", 1);
  PermissiveAction(ISVehicleMenu, "onSignalDevice", 2);
  PermissiveAction(ISVehicleMenu, "onStartEngine", 1);
  PermissiveAction(ISVehicleMenu, "onHotwire", 1);
  PermissiveAction(ISVehicleMenu, "onShutOff", 1);
  PermissiveAction(ISVehicleMenu, "onInfo", 1);
  PermissiveAction(ISVehicleMenu, "onSleep", 1);
  PermissiveAction(ISVehicleMenu, "onOpenDoor", 1);
  PermissiveAction(ISVehicleMenu, "onCloseDoor", 1);
  PermissiveAction(ISVehicleMenu, "onLockDoor", 1);
  PermissiveAction(ISVehicleMenu, "onUnlockDoor", 1);
  PermissiveAction(ISVehicleMenu, "onWash", 1);
  PermissiveAction(ISVehicleMenu, "moveItemsOnSeat", 5);
  PermissiveAction(ISVehicleMenu, "tryMoveItemsFromSeat", 7);
  PermissiveAction(ISVehicleMenu, "moveItemsFromSeat", 5);
  PermissiveAction(ISVehicleMenu, "onEnter", 3);
  PermissiveAction(ISVehicleMenu, "processShiftEnter", 3);
  PermissiveAction(ISVehicleMenu, "processEnter", 3);
  PermissiveAction(ISVehicleMenu, "onEnterAux", 3);
  PermissiveAction(ISVehicleMenu, "onEnter2", 3);
  PermissiveAction(ISVehicleMenu, "processEnter2", 3);
  PermissiveAction(ISVehicleMenu, "onEnterAux2", 3);
  PermissiveAction(ISVehicleMenu, "onExit", 2);
  PermissiveAction(ISVehicleMenu, "onExitAux", 2);
  PermissiveAction(ISVehicleMenu, "onShowSeatUI", 2);
  PermissiveAction(ISVehicleMenu, "onWalkPath", 2);

  PermissiveActions("hornControl",
    ISVehicleMenu,
    BindAction("onHorn", 1),
    BindAction("onHornStart", 1),
    BindAction("onHornStop", 1)
  );

  PermissiveAction(ISVehicleMenu, "onLightbar", 1);

  PermissiveActions("trailerControl",
    ISVehicleMenu,
    BindAction("onAttachTrailer", 4),
    BindAction("onDetachTrailer", 3)
  );

  ------------------------------------------------
  -- Normal "Click" permissions
  ------------------------------------------------
  RequirePermission(ISObjectClickHandler, "doClick", 3)
  RequirePermission(ISObjectClickHandler, "doDoubleClick", 3)
  RequirePermission(ISObjectClickHandler, "doClickCurtain", 3)
  RequirePermission(ISObjectClickHandler, "doClickDoor", 3)
  RequirePermission(ISObjectClickHandler, "doClickLightSwitch", 3)
  RequirePermission(ISObjectClickHandler, "doClickThumpable", 3)
  RequirePermission(ISObjectClickHandler, "doClickWindow", 3)
  RequirePermission(ISObjectClickHandler, "doClickSpecificObject", 3)
end

Events.OnServerCommand.Add(Permissions.OnServerCommand);
Events.OnGameStart.Add(Permissions.RegisterActions);
Events.OnTick.Add(Permissions.SyncPlayer);