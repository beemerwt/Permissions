-- Don't know when this applies
--  basically some server scripts call "noise" when an event is triggered
--  presumably this is to log while inside another thread
--  but if it doesn't apply, then we just use print
local log = noise or print
local debug = true;
Permissions = _G['Permissions'] or {};

if isClient() then return end

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

Permissions.Groups = {}
Permissions.Users = {}

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

function Permissions.AddPermissionToUser(user, permission)
  if type(user) ~= "string" then
    user = user:getUsername()
  end

  if not Permissions.Users[user] then return false end
  table.insert(Permissions.Users[user].permissions, permission);
  return true;
end

function Permissions.AddPermissionToGroup(groupName, permission)
  if not Permissions.Groups[groupName] then return false end
  table.insert(Permissions.Groups[groupName].permissions, permission);
  return true;
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
  Permissions.RegisterCommands();
end

-- Gets a list of permissions from the group and individual player permissions
function Permissions.GetPlayer(playerObj)
  local username = playerObj:getUsername();
  if not Permissions.Users[username] then return nil end

  local user = Permissions.Users[username];
  local group = Permissions.Groups[user.group];

  local permissions = {};

  for _, perm in ipairs(user.permissions) do
    table.insert(permissions, perm);
  end

  for _, perm in ipairs(group.permissions) do
    table.insert(permissions, perm)
  end

  return permissions;
end

-- module and perm are always strings
-- player is always IsoPlayer
-- args will always be present, but could be empty
function Permissions.OnClientCommand(module, command, player, args)
  if module ~= "permission" then return end
  if args == nil then args = {} end

  local argStr = '';
  for k,v in pairs(args) do argStr = argStr .. k .. "=" .. v .. "," end

  log("Permissions received ClientCommand " .. command .. ", " .. argStr)

  if command == "syncplayer" then
    local playerPermissions = Permissions.GetPlayer(player);
    if playerPermissions == nil then
      Permissions.CreateUser(player);
      playerPermissions = Permissions.GetPlayer(player);
    end
    sendServerCommand(player, "permission", command, playerPermissions)
  elseif perm == "addpermission" then
    log("Permissions Received Command to AddPermission.");
  else
    -- sends "permission" response specifically to "player"
    args.permission = command;
    args.granted = Permissions.UserHasPermission(player, command);
    sendServerCommand(player, "permission", command, args);
  end
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
  log("Handled Event: OnServerStartSaving");
  Permissions.Save();
end

-- I don't even know if this is actually working...
-- OnConnected seems not to work on either side.
function Permissions.OnConnected()
  log("Handled Event: OnConnected");
  -- List<IsoPlayer>
  local connected = getOnlinePlayers();
  
  for i=1,connected:size() do
    local player = connected:get(i-1);
    local username = player:getUsername();

    if not Permissions.PlayerExists(username) then
      log("Player " .. username .. " joined for the first time.")
      Permissions.CreateUser(username)
    end
  end
end

-- update all player permissions once a "day"
function Permissions.OnDayChange()
  local connected = getOnlinePlayers();
  for i=1,connected:size() do
    local player = connected:get(i-1);
    -- invoke as if player requested...
    Permissions.OnClientCommand("permission", "syncplayer", player)
  end
end

Permissions.Load();

Events.EveryDays.Add(Permissions.OnDayChange);
Events.OnResetLua.Add(Permissions.OnResetLua);
Events.OnConnected.Add(Permissions.OnConnected);
Events.OnServerStarted.Add(Permissions.OnServerStarted);
Events.OnClientCommand.Add(Permissions.OnClientCommand);
Events.OnServerStartSaving.Add(Permissions.OnServerStartSaving);