local panic = require( 'core.panic' )
--- C# extension method mechanics for Lua.
---
--- Expected layout:
---
---   Class definition:
--- ```lua
---     {
---       __index: type table,
---       -- Other type system fields...
---       __extension__: a dictionary,
---
---       __metatable = {
---         _rtti = {
---           -- RTTI fields...
---           -- Meta fields...
---         },
---         __index: a function overrided the original indexer,
---       }
---     }
--- ```
local extension = {}

--- Mixes extension methods into a class type.
--- It will modify the class __index to prioritize class fields before extensions.
--- @generic T
--- @param cls T
--- @param fields table<any, any> @ Extension methods to add to the class.
--- @return T
function extension.mixin( cls, fields )
  -- assert( rtti.is_type( cls ) )
  local extensions = rawget( cls, '__extension__' )
  if extensions == nil then
    extensions = {}
    rawset( cls, '__extension__', extensions )

    local indexer = rawget( cls, '__index' )
    -- Just like in C#, the fields of the class itself take priority.
    if indexer == nil then
      rawset( cls, '__index',
              function( _, key )
                local val = cls[key]
                if val ~= nil then return val end
                return rawget( cls, '__extension__' )[key]
              end )
    elseif type( indexer ) == 'function' then
      rawset( cls, '__index',
              function( self, key )
                local val = indexer( self, key )
                if val ~= nil then return val end
                return rawget( cls, '__extension__' )[key]
              end )
    else
      rawset( cls, '__index',
              function( _, key )
                local val = indexer[key]
                if val ~= nil then return val end
                return rawget( cls, '__extension__' )[key]
              end )
    end
  end
  for name, fn in pairs( fields ) do
    if extensions[name] ~= nil then
      panic.raise( panic.KIND.FIELD_CONFLICT,
                   'class already contains a extension field called "' .. name .. '"' )
    end
    extensions[name] = fn
  end
  return cls
end

return extension
