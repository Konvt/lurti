local panic = require( 'core.panic' )
local rtti = require( 'core.rtti' )
local meta = require( 'core.meta' )
local object = {}

--- Mark functions as class methods on a class,
--- raising an error if passed functions do not exist in class.
--- @generic T
--- @param cls T
--- @param method table<string, fun(...)>
--- @return T
function object.classmethod( cls, method )
  local classmethods = rawget( cls, '__classmethod__' )
  if classmethods == nil then
    classmethods = {}
    rawset( cls, '__classmethod__', classmethods )

    local indexer = rawget( cls, '__index' )
    rawset( cls, '__index',
            function( self, key )
              local classinfo = rtti.typeof( self )
              local mthd = rawget( classinfo, '__classmethod__' )
              if mthd ~= nil and mthd[key] ~= nil then
                return function( _, ... ) return mthd[key]( classinfo, ... ) end
              end
              return type( indexer ) == 'function' and indexer( self, key ) or indexer[key]
            end )
  end
  for name, fn in pairs( method ) do
    if rawget( cls, name ) ~= fn then
      panic.raise( panic.KIND.FIELD_CONFLICT,
                   'method "' .. name .. '" must exist in class and match the passed function' )
    end
    classmethods[name] = fn
  end
  return cls
end

--[[
  In dynamic languages like Lua (including Python):
  1. Types are objects, so types themselves can be dynamically extended;
  2. Unlike compiled languages such as C++, they do not support more aggressive optimizations (including unvirtualization);
  3. Because the type semantic expression of the framework cannot be applied to JIT optimization;
  4. This leads to the coupling of the subtype system and the metaclass mechanism (specifically, checking whether a type is final when constructing a type);

  Therefore, similar to Python, lurti does not provide a final marker for types;
  According to "convention over configuration" philosophy, users should use type annotations or documentation comments to solve this problem themselves.
]]

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
  -- assert( rtti.is_type( self ) )
  return self():init( ... )
end

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
