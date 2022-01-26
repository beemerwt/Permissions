-- Copyright (c) 2018, Souche Inc.
-- lua-pretty-json https://github.com/xiedacon/lua-pretty-json

local Constant = {
  ESC_MAP = {
      ["\\"] = [[\]],
      ["\""] = [[\"]],
      ["/"] = [[\/]],
      ["\b"] = [[\b]],
      ["\f"] = [[\f]],
      ["\n"] = [[\n]],
      ["\r"] = [[\r]],
      ["\t"] = [[\t]],
      ["\a"] = [[\u0007]],
      ["\v"] = [[\u000b]]
  },

  UN_ESC_MAP = {
      b = "\b",
      f = "\f",
      n = "\n",
      r = "\r",
      t = "\t",
      u0007 = "\a",
      u000b = "\v"
  },

  NULL = setmetatable({}, {
      __tostring = function() return "null" end
  })
}

local NULL = Constant.NULL
local UN_ESC_MAP = Constant.UN_ESC_MAP
local ESC_MAP = Constant.ESC_MAP

function next_char(str, pos)
    pos = pos + #str:match("^%s*", pos)
    return str:sub(pos, pos), pos
end

local function syntax_error(str, pos)
    return error("Invalid json syntax starting at position " .. pos .. ": " .. str:sub(pos, pos + 10))
end

local Parser = {}

setmetatable(Parser, {
    __call = function(self, opts)
        local parser = {
            without_null = opts.without_null
        }

        setmetatable(parser, { __index = Parser })

        return parser
    end
})

function Parser:number(str, pos)
    local num = str:match("^-?%d+%.?%d*[eE]?[+-]?%d*", pos)
    local val = tonumber(num)

    if not val then
        syntax_error(str, pos)
    else
        return val, pos + #num
    end
end

function Parser:string(str, pos)
    pos = pos + 1
    
    local i = 1
    local chars = {} --table.new(#str - pos - 1, 0)
    while(pos <= #str) do
        local c = str:sub(pos, pos)

        if c == "\"" then
            return table.concat(chars, ""), pos + 1
        elseif c == "\\" then
            local j = pos + 1

            local next_c = str:sub(j, j)
            for k, v in pairs(UN_ESC_MAP) do
                if str:sub(j, j + #k - 1) == k then
                    next_c = v
                    j = j + #k - 1
                end
            end

            c = next_c
            pos = j
        end

        chars[i] = c
        i = i + 1
        pos = pos + 1
    end

    syntax_error(str, pos)
end

function Parser:array(str, pos)
    local arr = {} -- table.new(10, 0)
    local val
    local i = 1
    local c
    
    pos = pos + 1
    while true do
        val, pos = self:json(str, pos)
        arr[i] = val
        i = i + 1

        c, pos = next_char(str, pos)
        if (c == ",") then
            pos = pos + 1
        elseif (c == "]") then
            return arr, pos + 1
        else
            syntax_error(str, pos)
        end
    end

    return arr
end

function Parser:table(str, pos)
    local obj = {};
    local key
    local val
    local c

    pos = pos + 1
    while true do
        c, pos = next_char(str, pos)

        if c == "}" then return obj, pos + 1
        elseif c == "\"" then key, pos = self:string(str, pos)
        else syntax_error(str, pos) end

        c, pos = next_char(str, pos)
        if c ~= ":" then syntax_error(str, pos) end

        val, pos = self:json(str, pos + 1)
        obj[key] = val

        c, pos = next_char(str, pos)
        if c == "}" then
            return obj, pos + 1
        elseif c == "," then
            pos = pos + 1
        else
            syntax_error(str, pos)
        end
    end
end

function Parser:json(str, pos)
    local first = false
    local val
    local c

    if not pos or pos == 1 then first = true end
    pos = pos or 1

    if type(str) ~= "string" then error("str should be a string")
    elseif pos > #str then error("Reached unexpected end of input") end

    c, pos = next_char(str, pos)
    if c == "{" then
        val, pos =  self:table(str, pos)
    elseif c == "[" then
        val, pos = self:array(str, pos)
    elseif c == "\"" then
        val, pos = self:string(str, pos)
    elseif c == "-" or c:match("%d") then
        val, pos = self:number(str, pos)
    else
        for k, v in pairs({ ["true"] = true, ["false"] = false, ["null"] = NULL }) do
            if (str:sub(pos, pos + #k - 1) == k) then 
                val, pos = v, pos + #k
                break
            end
        end

        if val == nil then syntax_error(str, pos) end
    end

    if first and pos <= #str then syntax_error(str, pos) end
    if self.without_null and val == NULL then val = nil end

    return val, pos
end

local function kind_of(obj)
    if type(obj) ~= "table" then return type(obj) end
    if obj == NULL then return "nil" end

    local i = 1
    for _ in pairs(obj) do
        if obj[i] ~= nil then i = i + 1 else return "table" end
    end

    if i == 1 then
        return "table"
    else
        return "array"
    end
end

local function escape_str(s)
    for k, v in pairs(ESC_MAP) do
        s = s:gsub(k, v)
    end

    return s
end

local Serializer = {
    print_address = false,
    max_depth = 100
}

setmetatable(Serializer, {
    __call = function(self, opts)
        local serializer = {
            depth = 0,
            max_depth = opts.max_depth,
            print_address = opts.print_address,
            stream = opts.stream
        }

        setmetatable(serializer, { __index = Serializer })

        return serializer
    end
})

function Serializer:space(n)
    local stream = self.stream
    for i = 1, n or 0 do
        stream:write(" ")
    end

    return self
end

function Serializer:key(key)
    local stream = self.stream
    local kind = kind_of(key)

    if kind == "array" then
        error("Can't encode array as key.")
    elseif kind == "table" then
        error("Can't encode table as key.")
    elseif kind == "string" then
        stream:write("\"", escape_str(key), "\"")
    elseif kind == "number" then
        stream:write("\"", tostring(key), "\"")
    elseif self.print_address then
        stream:write(tostring(key))
    else
        error("Unjsonifiable type: " .. kind .. ".")
    end

    return self
end

function Serializer:array(arr, replacer, indent, space)
    local stream = self.stream

    stream:write("[")
    for i, v in ipairs(arr) do
        if replacer then v = replacer(k, v) end

        stream:write(i == 1 and "" or ",")
        stream:write(space > 0 and "\n" or "")
        self:space(indent)
        self:json(v, replacer, indent + space, space)
    end
    if #arr > 0 then
        stream:write(space > 0 and "\n" or "")
        self:space(indent - space)
    end
    stream:write("]")

    return self
end

function Serializer:table(obj, replacer, indent, space)
    local stream = self.stream

    stream:write("{")
    local len = 0
    for k, v in pairs(obj) do
        if replacer then v = replacer(k, v) end

        if v ~= nil then
            stream:write(len == 0 and "" or ",")
            stream:write(space > 0 and "\n" or "")
            self:space(indent)
            self:key(k)
            stream:write(space > 0 and ": " or ":")
            self:json(v, replacer, indent + space, space)
            len = len + 1
        end
    end
    if len > 0 then
        stream:write(space > 0 and "\n" or "")
        self:space(indent - space)
    end
    stream:write("}")

    return self
end

function Serializer:json(obj, replacer, indent, space)
    local stream = self.stream
    local kind = kind_of(obj)

    self.depth = self.depth + 1
    if self.depth > self.max_depth then error("Reach max depth: " .. tostring(self.max_depth)) end

    if kind == "array" then
        self:array(obj, replacer, indent, space)
    elseif kind == "table" then
        self:table(obj, replacer, indent, space)
    elseif kind == "string" then
        stream:write("\"", escape_str(obj), "\"")
    elseif kind == "number" then
        stream:write(tostring(obj))
    elseif kind == "boolean" then
        stream:write(tostring(obj))
    elseif kind == "nil" then
        stream:write("null")
    elseif self.print_address then
        stream:write(tostring(obj))
    else
        error("Unjsonifiable type: " .. kind)
    end

    return self
end

function Serializer:toString()
    return self.stream:toString()
end

local json = {
    _VERSION = "0.1",
    null = Constant.NULL
}

function json.stringify(obj, replacer, space, print_address)
    if type(space) ~= "number" then space = 0 end

    return Serializer({
        print_address = print_address,
        stream = {
            fragments = {},
            write = function(self, ...)
                for i = 1, #{...} do
                    self.fragments[#self.fragments + 1] = ({...})[i]
                end
            end,
            toString = function(self)
                return table.concat(self.fragments)
            end
        }
    }):json(obj, replacer, space, space):toString()
end

function json.parse(str, without_null)
    return Parser({ without_null = without_null }):json(str, 1)
end

return json
