local rtti = require( 'core.rtti' )
local meta = require( 'core.meta' )
local object = {}

--- @generic T
--- @class Object
object.Object = meta.newtype( 'class', nil, meta.Type )

--- Object method, initialize a existed Object.
--- @return self
function object.Object:init()
  -- assert( rtti.is_object( self ) )
  return self
end

--- Class method, create and initialize a new Object.
--- @return self
function object.Object:new( ... )
  return self():init( ... )
end

-- cycle reference, as same as Python
rtti.typeid( meta.Type ).base = { object.Object }

--- @generic T, U
--- @param base? T | T[]
--- @param metaclass? Type
--- @return U
function object.class( base, metaclass )
  if base == nil then
    base = { object.Object }
  elseif base[1] == nil then
    base = { base }
  end
  return meta.newtype( 'class', base, metaclass )
end

--- Call the next superclass init method in the MRO chain.
--- @generic T, U
--- @param cls T @ caller class type
--- @param obj U @ instance being initialized
--- @param ... any @ arguments passed to superclass init
--- @return U
function object.init_super( cls, obj, ... )
  -- assert( mro_table.index[cls] ~= nil )
  return meta.super( obj, cls ).init( obj, ... )
end

return object
