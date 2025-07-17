local rtti = require( 'core.rtti' )
local panic = require( 'core.panic' )
--- Python meta class type system for Lua.
---
--- Expected layout:
---
---   Class definition:
--- ```lua
---     {
---       __index: a self-reference, or a function,
---       __metatable = {
---         _rtti = {
---           -- RTTI fields...
---
---           metaclass: table,
---           base: table[],
---           mro: [index, order array],
---         },
---         __index: a function,
---       }
---     }
--- ```
local meta = {}

--- Return the metaclass of the identifier.
--- @generic T, U
--- @param identifier T
--- @return U
function meta.metaclassof( identifier )
  -- assert( rtti.has_rtti( identifier ) )
  local typeinfo = rtti.typeid( identifier )
  --- @cast typeinfo TypeInfo
  return typeinfo.metaclass
end

--- Calculate or return the MRO table of the class.
--- @generic T, U
--- @param cls T
--- @return table<string, table<U, integer> | U[]>
function meta.mroof( cls )
  -- assert( rtti.is_type( cls ) )
  local typeinfo = rtti.typeid( cls )
  --- @cast typeinfo TypeInfo
  if typeinfo.mro ~= nil then return typeinfo.mro end

  --- @type table[][]
  local reslv_paths = {}
  -- The position when taking the candidate.
  --- @type integer[]
  local paths_pos = {}
  for i, base in ipairs( typeinfo.base or {} ) do
    reslv_paths[i] = meta.mroof( base ).order --- @as table[]
    --[[
    lua does not have forward declarations,
    so it is unlikely that a circular dependency will be formed here.
    ]]
    paths_pos[i] = 1
  end
  if typeinfo.base ~= nil then
    assert( #typeinfo.base > 0,
            'If the base class does not exist, the value of "base" should be nil rather than an empty array.' )
    reslv_paths[#reslv_paths+1] = typeinfo.base
    paths_pos[#paths_pos+1] = 1
  end

  --- @type table[]
  local linearized = { cls }
  --- @type table<U, integer>
  local linearized_index = { [cls] = 1 }
  -- True if there are still unresolved paths.
  local pending_merge = #reslv_paths > 0
  -- If the size of reslv_path is 0, the MRO only contains cls itself.
  while pending_merge do
    local next_candidate = nil

    for i, reslv_path in ipairs( reslv_paths ) do
      local beginning = paths_pos[i]
      --- @cast beginning integer
      if beginning <= #reslv_path then
        local candidate = reslv_path[beginning]
        local is_unanimous = true

        for ii, other_reslv_path in ipairs( reslv_paths ) do
          -- Check if the candidate is globally prioritized.
          if ii ~= i then
            -- disable nullable value detection
            --- @diagnostic disable-next-line
            for iii = paths_pos[ii] + 1, #other_reslv_path do
              if other_reslv_path[iii] == candidate then
                is_unanimous = false
                break
              end
            end
          end
        end

        if is_unanimous then
          next_candidate = candidate
          break
        end
      end
    end

    if next_candidate == nil then
      panic.raise( panic.KIND.TYPE_ERROR, 'inconsistent hierarchy in ', tostring( cls ) )
    end
    --- @cast next_candidate U
    linearized[#linearized+1] = next_candidate
    linearized_index[next_candidate] = #linearized

    local num_empty_path = 0
    for pos, path in ipairs( reslv_paths ) do
      local beginning = paths_pos[pos]
      --- @cast beginning integer
      if path[beginning] == next_candidate then
        paths_pos[pos] = beginning + 1
      end
      if paths_pos[pos] > #path then
        num_empty_path = num_empty_path + 1
      end
    end
    pending_merge = num_empty_path < #reslv_paths
  end

  typeinfo.mro = { index = linearized_index, order = linearized }
  return typeinfo.mro
end

--- @generic Derived
--- @generic Base
--- @param base Base
--- @param derived Derived
--- @return boolean
function meta.is_base_of( base, derived )
  -- assert( rtti.is_type( base ) and rtti.is_type( derived ) )
  if base == derived then return true end
  local mro_table = meta.mroof( derived )
  return mro_table.index[base] ~= nil
end

--- Return the direct superclass of the given identifier or the next class in MRO after `cls`.
--- @generic T, U, V
--- @param identifier T
--- @param cls? V
--- @return U | nil
function meta.super( identifier, cls )
  -- assert( rtti.has_rtti( identifier ) )
  local mro_table = meta.mroof( rtti.typeof( identifier ) )
  if cls ~= nil then
    local index = mro_table.index[cls]
    if index == nil then return nil end
    return mro_table.order[index + 1]
  end
  return mro_table.order[2] -- For Object it's nil.
end

--- Search for the key in the inheritance chain using MRO.
--- @generic T
--- @param identifier T
--- @param key any
--- @return any
function meta.c3( identifier, key )
  local mro_table = meta.mroof( rtti.typeof( identifier ) )
  if mro_table == nil then return nil end
  local mro_chain = mro_table.order
  for i = 1, #mro_chain do
    local val = rawget( mro_chain[i], key )
    if val ~= nil then return val end
  end
  return nil
end

--- Create a new class.
--- The argument `requirement` and `metaclass` should not be nil simultaneously
--- @generic T, U
--- @param metatype string
--- @param requirement? T[]
--- @param metaclass? U
--- @return table
function meta.newtype( metatype, requirement, metaclass )
  if requirement ~= nil and #requirement == 0 then requirement = nil end
  if requirement == nil and metaclass == nil then
    panic.raise( panic.KIND.TYPE_ERROR,
                 'the argument "requirement" and "metaclass" should not be nil simultaneously' )
  end

  --- @type table<T, boolean>
  local seen = {}
  local metaclasses = { metaclass }
  for _, base in ipairs( requirement or {} ) do
    if seen[base] then
      panic.raise( panic.KIND.TYPE_ERROR, 'duplicate base class' )
    end
    seen[base] = true
    metaclasses[#metaclasses+1] = meta.metaclassof( base )
  end
  -- Automatic derivation of metaclasses.
  metaclass = metaclasses[1]
  --- @cast metaclass U
  for i = 2, #metaclasses do
    if meta.is_base_of( metaclass, metaclasses[i] ) then
      metaclass = metaclasses[i]
    elseif not meta.is_base_of( metaclasses[i], metaclass ) then
      panic.raise( panic.KIND.TYPE_ERROR,
                   'conflicting metaclasses in base classes' )
    end
  end

  return metaclass:_init_( metaclass:_new_( metatype,
                                            metaclass:_prepare_( requirement ),
                                            requirement ),
                           requirement )
end

--- Mark functions as class methods on a class,
--- raising an error if passed functions do not exist in class.
--- @generic T
--- @param cls T
--- @param method table<string, fun(...)>
--- @return T
function meta.classmethod( cls, method )
  local classmethods = rawget( cls, '__classmethod__' )
  if classmethods == nil then
    classmethods = {}
    rawset( cls, '__classmethod__', classmethods )

    local indexer = rawget( cls, '__index' )
    if indexer == nil then
      rawset( cls, '__index',
              function( self, key )
                local classinfo = rtti.typeof( self )
                local mthd = rawget( classinfo, '__classmethod__' )
                if mthd ~= nil and mthd[key] ~= nil then
                  return function( _, ... ) return mthd[key]( classinfo, ... ) end
                end
                return nil
              end )
    elseif type( indexer ) == 'function' then
      rawset( cls, '__index',
              function( self, key )
                local classinfo = rtti.typeof( self )
                local mthd = rawget( classinfo, '__classmethod__' )
                if mthd ~= nil and mthd[key] ~= nil then
                  return function( _, ... ) return mthd[key]( classinfo, ... ) end
                end
                return indexer( self, key )
              end )
    else
      rawset( cls, '__index',
              function( self, key )
                local classinfo = rtti.typeof( self )
                local mthd = rawget( classinfo, '__classmethod__' )
                if mthd ~= nil and mthd[key] ~= nil then
                  return function( _, ... ) return mthd[key]( classinfo, ... ) end
                end
                return indexer[key]
              end )
    end
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

--- @class Type : Object
--- @field private inheritable_metamethods string[]
meta.Type = {}

meta.Type.inheritable_metamethods = {
  -- Lua 5.1
  '__newindex', '__add', '__sub', '__mul', '__div',
  '__mod', '__pow', '__unm', '__concat',
  '__eq', '__lt', '__le', '__tostring',

  -- Lua 5.2+
  '__len', '__pairs', '__ipairs',

  -- Lua 5.3
  '__band', '__bor', '__bxor', '__bnot',
  '__shl', '__shr', '__idiv',
}

--- @generic T
--- @param requirement T[] | nil
function meta.Type:_prepare_( requirement )
  return {}
end

--- Create a class.
--- @generic T, U
--- @param metatype string
--- @param namespace U
--- @param requirement T[] | nil
--- @return U
function meta.Type:_new_( metatype, namespace, requirement )
  namespace.__index = namespace
  local mt = {
    _rtti = {
      metatype = metatype,
      metaclass = self,
      base = requirement,
    },
    __call = function( cls, ... )
      return self:_construct_( cls, ... )
    end,
  }
  setmetatable( namespace, mt )
  local mro_chain = meta.mroof( namespace ).order
  for i = #mro_chain, 2, -1 do
    for _, metamethod in ipairs( meta.Type.inheritable_metamethods ) do
      local impl = rawget( mro_chain[i], metamethod )
      if impl ~= nil then rawset( namespace, metamethod, impl ) end
    end
  end
  -- The performance of table queries is far superior to that of function calls.
  -- Therefore, we directly point the __index in the metatable of the type
  -- to the direct base class recursively according to MRO.
  mt.__index = mro_chain[2]
  return namespace
end

--- Initialize a instance of the class.
--- @generic T, U
--- @param namespace U
--- @param requirement T[] | nil
--- @return U
function meta.Type:_init_( namespace, requirement )
  return namespace
end

--- Construct an empty instance of the class, this is a classmethod.
--- It's equivalent to `__call__` of metaclass in Python.
--- @generic T
--- @param cls T
--- @return T
function meta.Type:_construct_( cls, ... )
  -- assert( rtti.is_type( cls ) )
  local obj = setmetatable( {}, cls )
  return obj
end

--- Create a metaclass.
--- @generic T
--- @param base_meta? T | T[] @ Metaclasses
--- @return T
function meta.metaclass( base_meta )
  if base_meta == nil then
    base_meta = { meta.Type }
  elseif base_meta[1] == nil then
    base_meta = { base_meta }
  end
  return meta.newtype( 'metaclass', base_meta )
end

--- @generic T
--- @class Object
meta.Object = meta.newtype( 'class', nil, meta.Type )

function meta.Object.foo()
  return 'From Object'
end

--- Object method, initialize a existed Object.
--- @return self
function meta.Object:init()
  -- assert( rtti.is_object( self ) )
  return self
end

--- Class method, create and initialize a new Object.
--- @return self
function meta.Object:new( ... )
  return self():init( ... )
end

-- cycle reference, as same as Python
do
  local requirement = { meta.Object }
  meta.Type:_init_( meta.Type:_new_( 'metaclass',
                                     meta.Type, requirement ),
                    requirement )
end

--- @generic T, U
--- @param base? T | T[]
--- @param metaclass? Type
--- @return U
function meta.class( base, metaclass )
  if base == nil then
    base = { meta.Object }
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
function meta.init_super( cls, obj, ... )
  -- assert( mro_table.index[cls] ~= nil )
  return meta.super( obj, cls ).init( obj, ... )
end

return meta
