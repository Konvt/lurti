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
  meta.super( self, enum.EnumMeta )._new_( self, metatype, namespace, requirement )
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
  return namespace
end

--- @generic T
--- @param cls T
--- @return T
function enum.EnumMeta:_instantiate_( cls, ... )
  -- TODO: Color = Enum('Color', [('RED', 1), ('GREEN', 2), ('BLUE', 3)])
  return meta.super( self, enum.EnumMeta ):_instantiate_( cls, ... )
end

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
