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
    if mro_table.index[cls] == nil then return nil end
    return mro_table.order[mro_table.index[cls] + 1]
  end
  return mro_table.order[2] -- For Object it's nil.
end

--- Search for the key in the inheritance chain using MRO.
--- @generic T
--- @param self T
--- @param key any
--- @return any
function meta.c3( self, key )
  local mro_chain = meta.mroof( rtti.typeof( self ) ).order
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
function meta.class( metatype, requirement, metaclass )
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

  return metaclass:_init( metaclass:_new( metatype,
                                          metaclass:_prepare( requirement ),
                                          requirement ),
                          requirement )
end

--- @class Type
meta.Type = {}
meta.Type.__index = meta.Type

--- @generic T
--- @param requirement T[] | nil
function meta.Type:_prepare( requirement )
  return {}
end

--- Create a class.
--- @generic T, U
--- @param metatype string
--- @param namespace U
--- @param requirement T[] | nil
--- @return U
function meta.Type:_new( metatype, namespace, requirement )
  namespace.__index = namespace
  setmetatable(
    namespace,
    {
      _rtti = {
        metatype = metatype,
        metaclass = self,
        base = requirement,
      },
      __index = meta.c3,
      __call = self._instantiate,
    } )
  meta.mroof( namespace )
  return namespace
end

--- Initialize a instance of the class.
--- @generic T, U
--- @param namespace U
--- @param requirement T[] | nil
--- @return U
function meta.Type:_init( namespace, requirement )
  return namespace
end

--- Create a instance of the class.
--- It's equivalent to `__call__` of metaclass in Python.
--- @generic T
--- @param cls T
--- @return T
function meta.Type._instantiate( cls, ... )
  -- assert( rtti.is_type( cls ) )
  local obj = setmetatable( {}, cls )
  return obj
end

setmetatable( meta.Type, {
  _rtti = {
    metatype = 'metaclass',
    metaclass = meta.Type,
    mro = { index = { [meta.Type] = 1 }, order = { meta.Type } },
  },
  __index = meta.c3,
  -- `meta.Type` need wait for the function `_instantiate` to be completed.
  __call = meta.Type._instantiate,
} )

--- Create a metaclass.
--- @generic T
--- @param base_meta? T | T[] @ Metaclasses
--- @return T
function meta.extend( base_meta )
  if base_meta == nil then
    base_meta = { meta.Type }
  elseif base_meta[1] == nil then
    base_meta = { base_meta }
  end
  return meta.class( 'metaclass', base_meta )
end

return meta
