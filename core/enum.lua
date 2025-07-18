local meta = require( 'core.meta' )
local panic = require( 'core.panic' )
local enum = {}

enum.auto = {}

--- @class EnumMeta : Type
enum.EnumMeta = meta.metaclass()

--- @generic T, U
--- @param metatype string
--- @param namespace U
--- @param requirement T[] | nil
--- @return U
function enum.EnumMeta:_new_( metatype, namespace, requirement )
  meta.superof( self, enum.EnumMeta )._new_( self, metatype, namespace, requirement )
  local mt = getmetatable( namespace )
  rawset( mt, '__newindex',
          function( cls, key, val )
            local values = rawget( cls, '__value__' )
            if values == nil then
              values = { ['seq'] = {}, ['map'] = {} }
              rawset( cls, '__value__', values )
            end
            local valseq, val2item = values.seq, values.map

            local valtype = type( val )
            if valtype == 'function' then
              if val2item[val] == nil then
                rawset( cls, key, val )
              end
              return
            elseif type( key ) ~= 'string' then
              panic.raise( panic.KIND.TYPE_ERROR, 'attempt to define a non-enum type member' )
            end

            local item = cls()
            rawset( item, 'name', key )
            if val2item[val] == nil then
              if val == enum.auto then
                val = cls._auto_value_( key, 1, #valseq, valseq )
              end
              rawset( item, 'value', val )
              val2item[val] = item
              valseq[#valseq+1] = val
            else
              rawset( item, 'value', val2item[val].value )
            end
            rawset( cls, key, item )
          end )
  rawset( mt, '__pairs',
          function( cls )
            return function( tbl, name )
              local item
              repeat
                name, item = next( tbl, name )
              until name == nil or (type( item ) ~= 'function' and name:sub( 1, 2 ) ~= '__')
              return name, item
            end, cls, nil
          end )
  return namespace
end

--- @generic T, E
--- @param cls T
--- @param definition string[] | table<string, any> | any
--- @return T | E
function enum.EnumMeta:_construct_( cls, definition )
  if definition == nil then
    return meta.superof( self, enum.EnumMeta ):_construct_( cls )
  end
  local values = rawget( cls, '__value__' )
  if values.map[definition] ~= nil then
    return values.map[definition]
  elseif type( definition ) ~= 'table' then
    panic.raise( panic.KIND.TYPE_ERROR, 'members must be a table or an existing value' )
  end

  local is_array = false
  if #definition > 0 then
    local cursor = 1 -- members is an array
    --- @cast definition string[]
    for i, v in ipairs( definition ) do
      if cursor ~= i then
        panic.raise( panic.KIND.TYPE_ERROR, 'the members indices are not consecutive ' )
      elseif type( v ) ~= 'string' then
        panic.raise( panic.KIND.TYPE_ERROR, 'enum member must be a string' )
      end
      cursor = cursor + 1
    end
    is_array = true
  else
    --- @cast definition table<string, any>
    for k, v in pairs( definition ) do -- members is a dict
      if type( k ) ~= 'string' then
        panic.raise( panic.KIND.TYPE_ERROR, 'enum member must be a string' )
      elseif v == enum.auto then
        panic.raise( panic.KIND.FATAL_ERROR, 'the dictionary in lua does not guarantee the insertion order' )
      end
    end
  end

  local enum_cls = meta.class( cls )
  if is_array then
    for i = 1, #definition do
      enum_cls[definition[i]] = enum.auto
    end
  else
    --- @cast definition table<string, any>
    for k, v in pairs( definition ) do
      enum_cls[k] = v
    end
  end
  return enum_cls
end

meta.classmethod( enum.EnumMeta, { '_new_', '_construct_' } )

--- @class Enum : Object
enum.Enum = meta.class( nil, enum.EnumMeta )

--- @generic T
--- @param name string
--- @param start integer
--- @param count integer
--- @param last_values T[]
--- @return any
function enum.Enum._auto_value_( name, start, count, last_values )
  -- Implement the same as "Enum._generate_next_value_" in Python 3.13.
  if #last_values == 0 then return start end
  --- @type integer
  local maxval = last_values[1] --- @as integer
  local mtype = type( maxval )
  for i = 2, #last_values do
    if type( last_values[i] ) ~= mtype or mtype ~= 'number' then
      panic.raise( panic.KIND.TYPE_ERROR, 'unable to sort non-numeric values' )
    end
    if last_values[i] > maxval then
      maxval = last_values[i]
    end
  end
  return maxval + 1
end

return enum
