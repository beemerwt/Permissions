-- Don't know when this applies
--  basically some server scripts call "noise" when an event is triggered
--  presumably this is to log while inside another thread
--  but if it doesn't apply, then we just use print
local log = noise or print
local debug = true;
Permissions = {};

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

function Permissions.OnServerCommand(module, perm, args)
  if module ~= "permission" then return end

  -- resume all coroutines with the given args
  local remove = {}
  for i=1,#coroutines do
    -- check for dead coroutines, append to "remove" list
    if coroutine.status(coroutines[i]) == "dead" then
      table.insert(remove, i);
    else
      coroutine.resume(coroutines[i], args);
    end
  end

  -- remove all dead coroutines
  for i=1,#remove do
    table.remove(coroutines, remove[i]);
  end
end

if isClient() then
  Events.OnServerCommand.Add(Permissions.OnServerCommand);
  return;
end

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

  -- sends "permission" response specifically to "player"
  args.permission = perm;
  args.granted = Permissions.UserHasPermission(player, perm);

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

Permissions.Load();

Events.OnResetLua.Add(Permissions.OnResetLua);
Events.OnConnected.Add(Permissions.OnConnected);
Events.OnServerStarted.Add(Permissions.OnServerStarted);
Events.OnClientCommand.Add(Permissions.OnClientCommand);
Events.OnServerStartSaving.Add(Permissions.OnServerStartSaving);