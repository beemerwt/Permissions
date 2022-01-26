
if isClient() then return end

local debug = true;

local function log(...)
  local tArgs = { ... }
  local logStr = "Permissions: "
  for k, v in pairs(tArgs) do
    logStr = logStr .. tostring(v)
  end

  DebugLog.log(logStr)
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

Permissions = {
  Groups = {},
  Users = {},
};

local permissionsFile = "permissions.json";

local function createDefaultPermissionsFile()
  log("Creating default permissions file");

  local Groups = {};
  Groups['admin'] = PermissionGroup("*");
  Groups['moderator'] = PermissionGroup({ "test" });
  Groups['default'] = PermissionGroup();

  local Users = {};
  Users['admin'] = PermissionUser("admin", "test");

  Permissions.Groups = Groups;
  Permissions.Users = Users;

  Permissions.Save();
end

function Permissions.GroupHasPermission(groupName, perm)
  if not Permissions.Groups[groupName] then return false end
  for _,p in ipairs(Permissions.Groups[groupName].permissions) do
    if p == perm or p == "*" then
      return true;
    end
  end

  return false;
end

function Permissions.UserHasPermission(userName, perm)
  if not Permissions.Users[userName] then return false end
  
  for _,p in ipairs(Permissions.Users[userName].permissions) do
    if p == perm or p == "*" then
      return true
    end
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
    log("Failed to save Permissions");
  else
    file:write(jsonStr)
    file:close()
  end
end

function Permissions.Reload()
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

  log("Assigning Permissions");
  Permissions.Groups = permissions.groups;
  Permissions.Users = permissions.users;
end

Permissions.Reload()

-- Run Tests
if debug then
  log("Running Permissions Tests");
  
  local testGroupPermission = Permissions.GroupHasPermission("admin", "test");
  log("AssertTrue: " .. tostring(testGroupPermission));

  local testUserPermission = Permissions.UserHasPermission("admin", "test");
  log("AssertTrue: " .. tostring(testUserPermission));

  local testGroupNotPermission = Permissions.GroupHasPermission("default", "test");
  log("AssertFalse: " .. tostring(testGroupNotPermission));

  local testCreateUser = Permissions.CreateUser("default")
  log("AssertTrue: " .. tostring(testCreateUser));

  local testUserNotPermission = Permissions.UserHasPermission("default", "test");
  log("AssertFalse: " .. tostring(testUserNotPermission));

  local testSave = Permissions.Save();
end