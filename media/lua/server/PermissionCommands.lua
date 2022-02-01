
Permissions = _G['Permissions'] or {};

if isClient() then return end

local function AddUserPermission(sender, args)
  if not Permissions.UserHasPermission(sender, "adduserpermission") then
    return "You do not have permission to adduserpermission";
  end

  if args.length < 2 then
    return "Usage: adduserpermission \"user\" \"permission\""
  end

  local username = args[1];
  local permission = args[2];

  local success = Permissions.AddPermissionToUser(username, permission);
  if not success then
    return "User " .. username .. " does not exist.";
  else
    return "Added permission \"" .. permission .. "\" to " .. username;
  end
end

local function AddGroupPermission(sender, args)
  if not Permissions.UserHasPermission(sender, "addgrouppermission") then
    return "You do not have permission to addgrouppermission";
  end

  if args.length < 2 then
    return "Usage: addgrouppermission \"group\" \"permission\""
  end

  local group = args[1];
  local permission = args[2];

  local success = Permissions.AddPermissionToGroup(group, permission);
  if not success then
    return "Group " .. groupName .. " does not exist.";
  else
    return "Added " .. permission .. " to group " .. groupName;
  end
end

function Permissions.RegisterCommands()
  Commands.Add("adduserpermission", AddUserPermission);
  Commands.Add("addgrouppermission", AddGroupPermission);
end

