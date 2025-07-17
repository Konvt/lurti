local panic = require( 'core.panic' )
local meta = require( 'core.meta' )
--- Python Abstract Base Class for Lua.
---
--- Expected layout:
---
---   Class definition:
--- ```lua
---     {
---       __abstract__: table<string, Class>
---
---       __index: type table,
---       __metatable = {
---         _rtti = {
---           -- RTTI fields...
---           -- Meta fields...
---         },
---         __index: a function,
---       }
---     }
--- ```
local abc = {}

--- Mark methods as abstract in the class.
--- @generic T
--- @param cls T
--- @param method string | string[]
--- @return T
function abc.abstract( cls, method )
  local abstract = rawget( cls, '__abstract__' )
  if abstract == nil then
    panic.raise( panic.KIND.TYPE_ERROR,
                 'attempt to declare the methods of non-abstract base classes as abstractions' )
  end
  --- @cast abstract table<string, T>
  local methods = type( method ) == 'string' and { method } or method
  for i = 1, #methods do
    abstract[methods[i]] = cls
  end
  return cls
end

--- Check if the class is abstract and cannot be instantiated.
--- @generic T
--- @param cls T
--- @return boolean
function abc.is_abstract( cls )
  local abstract = rawget( cls, '__abstract__' )
  if abstract == nil then return false end
  for method_name, source_cls in pairs( abstract ) do
    if source_cls == cls or type( rawget( cls, method_name ) ) ~= 'function' then
      return true
    end
  end
  return false
end

--- @class ABCMeta : Type
abc.ABCMeta = meta.metaclass()

--- Create a new namespace with abstract tracking.
--- @generic T, U
--- @param metatype string
--- @param requirement T[]
--- @param namespace U
--- @return U
function abc.ABCMeta:_new_( metatype, requirement, namespace )
  namespace = meta.super( self, abc.ABCMeta )._new_( self, metatype, requirement, namespace )
  --- @type table<string, Object>
  local abstract = {}
  return rawset( namespace, '__abstract__', abstract )
end

--- Initialize namespace and gather abstract methods from bases.
--- @generic T, U
--- @param requirement T[]
--- @param namespace U
--- @return U
function abc.ABCMeta:_init_( requirement, namespace )
  -- assert( type( rawget( namespace, '__abstract__' ) ) == 'table' )
  namespace = meta.super( self, abc.ABCMeta )._init_( self, requirement, namespace )
  --- @type table<string, Object>
  local abstract = {}
  local mro_chain = meta.mroof( namespace ).order
  for i = #mro_chain, 2, -1 do
    local base = mro_chain[i]
    --- @cast base table<any, any>
    for method_name, _ in pairs( abstract ) do
      -- Assuming no cyclic inheritance,
      -- `abstract` will not contain methods originating from this `base` here.
      if type( rawget( base, method_name ) ) == 'function' then
        abstract[method_name] = nil
      end
    end
    local base_ab = rawget( base, '__abstract__' )
    if base_ab ~= nil then
      for method_name, source_cls in pairs( base_ab ) do
        if source_cls == base or rawget( base, method_name ) == nil then
          abstract[method_name] = source_cls
        end
      end
    end
  end
  namespace.__abstract__ = abstract
  return namespace
end

--- Instantiate a class if it is not abstract.
--- @generic T
--- @param cls T
--- @return T
function abc.ABCMeta:_construct_( cls, ... )
  if abc.is_abstract( cls ) then
    panic.raise( panic.KIND.TYPE_ERROR, 'attempt to instantiate an abstract class' )
  end
  return meta.super( self, abc.ABCMeta ):_construct_( cls, ... )
end

--- @class ICopyable : Object
abc.ICopyable = meta.class( nil, abc.ABCMeta )

--- Return a deep copy of the meta.
function abc.ICopyable:clone()
  --- @generic T
  --- @param orig T
  --- @param cache? table
  --- @return T
  local function deepcopy( orig, cache )
    if type( orig ) ~= 'table' then return orig end
    cache = cache or {}
    if cache[orig] then
      return cache[orig]
    end

    local copy = {}
    cache[orig] = copy
    for k, v in pairs( orig ) do
      copy[deepcopy( k, cache )] = deepcopy( v, cache )
    end
    -- metatable is used as type info and it is unique.
    setmetatable( copy, getmetatable( orig ) )
    return copy
  end
  return deepcopy( self )
end

--- Return a shallow copy of the meta.
function abc.ICopyable:copy()
  --- @param orig any
  --- @return any
  local function shallowcopy( orig )
    if type( orig ) ~= 'table' then return orig end
    local copy = {}
    for k, v in pairs( orig ) do
      copy[k] = v
    end
    return copy
  end
  return shallowcopy( self )
end

return abc
