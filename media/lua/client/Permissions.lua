
if isServer() then return end

local function getArgFunc(numArgs)
  if numArgs == 0 then return function(old, args) old() end end
  if numArgs == 1 then return function(old, args) old(args[1]) end end
  if numArgs == 2 then return function(old, args) old(args[1], args[2]) end end
  if numArgs == 3 then return function(old, args) old(args[1], args[2], args[3]) end end
  if numArgs == 4 then return function(old, args) old(args[1], args[2], args[3], args[4]) end end
  if numArgs == 5 then return function(old, args) old(args[1], args[2], args[3], args[4], args[5]) end end
  if numArgs == 6 then return function(old, args) old(args[1], args[2], args[3], args[4], args[5], args[6]) end end
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

PermissiveAction(ISWorldObjectContextMenu, "onTeleport", 0);
PermissiveAction(ISWorldObjectContextMenu, "addToolTip", 0);

PermissiveAction(ISWorldObjectContextMenu, "checkWeapon", 1);
PermissiveAction(ISWorldObjectContextMenu, "canStoreWater", 1);
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
PermissiveAction(ISWorldObjectContextMenu, "grabItemTime", 2);
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
PermissiveAction(ISWorldObjectContextMenu, "canCleanBlood", 2);
PermissiveAction(ISWorldObjectContextMenu, "doCleanBlood", 2);
PermissiveAction(ISWorldObjectContextMenu, "doRemoveGrass", 2);
PermissiveAction(ISWorldObjectContextMenu, "onFishing", 2);
PermissiveAction(ISWorldObjectContextMenu, "onFishingNet", 2);
PermissiveAction(ISWorldObjectContextMenu, "getFishingLure", 2);
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
PermissiveAction(ISWorldObjectContextMenu, "getZone", 3);
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

-- TODO: doRClick handle from server
--  Instead of blocking "doRClick" altogether, we should get a permissions object
--  which allows us to see each permission of the action, so we can block out individual non-permissive actions
PermissiveAction(ISObjectClickHandler, "doClick", 3)
PermissiveAction(ISObjectClickHandler, "doDoubleClick", 3)
PermissiveAction(ISObjectClickHandler, "doClickCurtain", 3)
PermissiveAction(ISObjectClickHandler, "doClickDoor", 3)
PermissiveAction(ISObjectClickHandler, "doClickLightSwitch", 3)
PermissiveAction(ISObjectClickHandler, "doClickThumpable", 3)
PermissiveAction(ISObjectClickHandler, "doClickWindow", 3)
PermissiveAction(ISObjectClickHandler, "doClickSpecificObject", 3)

-- Events.OnServerCommand.Add(ISObjectClickHandler.OnServerCommand);
-- We are no longer handling client command because it calls itself
--  and we have verified that OnClientCommand CANNOT be called from the server

