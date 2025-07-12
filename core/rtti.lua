--- Runtime Type Information (RTTI) for Lua.
---
--- This module provides functions to retrieve type metadata at runtime, inspired by C++ RTTI.
--- It supports distinguishing between types and type instances through metatable inspection.
---
--- Expected layout:
---
---   Type definition:
--- ```lua
---     {
---       __index: a self-reference, or a function,
---       __metatable = {
---         _rtti = {
---           metatype: string,
---           -- other metadata fields
---         },
---       }
---     }
--- ```
---
---   Type instance:
--- ```lua
---     {
---       -- fields ...
---       __metatable: type table,
---     }
--- ```
local rtti = {}

--- @alias TypeInfo table<string, any>

--- Check if the given identifier follows the RTTI type/object layout.
--- @generic T
--- @param identifier T
--- @return boolean
function rtti.has_rtti( identifier )
  local mt1 = getmetatable( identifier )
  if mt1 == nil then return false end
  local typeinfo = rawget( mt1, '_rtti' )
  if typeinfo ~= nil then
    if rawget( identifier, '__index' ) == nil then
      return false
    elseif type( typeinfo.metatype ) == 'string' then
      return true
    end
  end

  local mt2 = getmetatable( mt1 )
  if mt2 == nil then return false end
  typeinfo = rawget( mt2, '_rtti' )
  return typeinfo ~= nil and rawget( mt1, '__index' ) ~= nil
    and type( typeinfo.metatype ) == 'string'
end

--[[
--- The following code repetition in this module is intentional to avoid function call overhead
--- and preserve performance in low-level RTTI checks.
]]

--- Return the type of the given identifier.
--- @generic T, U
--- @param identifier T Type or type instance.
--- @return U | nil
function rtti.typeof( identifier )
  local classmeta = getmetatable( identifier )
  -- check if it's a class
  if classmeta ~= nil and rawget( classmeta, '_rtti' ) ~= nil then return identifier end
  local classinfo = classmeta
  classmeta = getmetatable( classinfo )
  -- check if it's an object
  if classmeta ~= nil and rawget( classmeta, '_rtti' ) ~= nil then return classinfo end
  return nil -- not a RTTI type
end

--- Return the type metatable associated with the given identifier.
--- @generic T, U
--- @param identifier T Type or type instance.
--- @return U | nil
function rtti.metaof( identifier )
  local classmeta = getmetatable( identifier )
  -- check if it's a class
  if classmeta ~= nil and rawget( classmeta, '_rtti' ) ~= nil then return classmeta end
  classmeta = getmetatable( classmeta )
  -- check if it's an object
  if classmeta ~= nil and rawget( classmeta, '_rtti' ) ~= nil then return classmeta end
  return nil -- not a RTTI type
end

--- Return the RTTI table of the identifier.
--- @generic T
--- @param identifier T Type or type instance.
--- @return TypeInfo | nil
function rtti.typeid( identifier )
  local classmeta = getmetatable( identifier )
  if classmeta == nil then return nil end -- not a RTTI type

  -- check if it's a class
  local typeinfo = rawget( classmeta, '_rtti' )
  if typeinfo ~= nil then return typeinfo end
  -- check if it's an object
  classmeta = getmetatable( classmeta )
  if classmeta == nil then return nil end -- not a RTTI type
  return rawget( classmeta, '_rtti' )
end

--- Return the meta-type name of the identifier.
--- @generic T
--- @param identifier T Type or type instance.
--- @return string
function rtti.metaname( identifier )
  local classmeta = getmetatable( identifier )
  if classmeta == nil then return '' end -- not a RTTI type

  -- check if it's a class
  local typeinfo = rawget( classmeta, '_rtti' )
  if typeinfo ~= nil then return typeinfo.metatype end
  -- check if it's an object
  classmeta = getmetatable( classmeta )
  if classmeta == nil then return '' end -- not a RTTI type
  typeinfo = rawget( classmeta, '_rtti' )
  if typeinfo == nil then return '' end
  return typeinfo.metatype == nil and '' or typeinfo.metatype
end

--- If identifier is an RTTI type, return true.
--- @generic T
--- @param identifier T
--- @return boolean
function rtti.is_type( identifier )
  if rawget( identifier, '__index' ) == nil then return false end
  local classinfo = getmetatable( identifier )
  if classinfo == nil then return false end
  local typeinfo = rawget( classinfo, '_rtti' )
  return typeinfo ~= nil and type( typeinfo.metatype ) == 'string'
end

--- If identifier is an object, return true.
--- @generic T
--- @param identifier T
--- @return boolean
function rtti.is_object( identifier )
  local classinfo = getmetatable( identifier )
  if classinfo == nil or rawget( classinfo, '__index' ) == nil then return false end
  local classmeta = getmetatable( classinfo )
  if classmeta == nil then return false end
  local typeinfo = rawget( classmeta, '_rtti' )
  return typeinfo ~= nil and type( typeinfo.metatype ) == 'string'
end

return rtti
