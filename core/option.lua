local panic = require( 'core.panic' )
local meta = require( 'core.meta' )
--- Rust Option for Lua.
local option = {}

--- @class Option<T> : Object
--- @field private _is_some boolean
--- @field private _val T
option.Option = meta.class()

--- Initialize a Option instance with status and value.
--- @generic T
--- @param is_some boolean
--- @param value? T
--- @return self
function option.Option:init( is_some, value )
  meta.init_super( option.Option, self )
  self._is_some = is_some
  self._val = value
  return self
end

--- Create a new Option object from given class and value.
--- @generic C, T
--- @param cls C
--- @param is_some boolean
--- @param value? T
--- @return C
function option.Option.new( cls, is_some, value )
  return cls():init( is_some, value )
end

--- Create a Option with value.
--- @generic T
--- @param value T
--- @return Option<T>
function option.Some( value )
  return option.Option:new( true, value )
end

--- Create a null Option meta.
--- @generic T
--- @return Option<T>
function option.None()
  return option.Option:new( false )
end

--- @return boolean
function option.Option:is_some()
  return self._is_some
end

--- @return boolean
function option.Option:is_none()
  return not self._is_some
end

--- @generic T
--- @param fn fun( x: T ): boolean
--- @return boolean
function option.Option:is_some_and( fn )
  return self._is_some and fn( self._val )
end

--- @generic T
--- @param fn fun( x: T ): boolean
--- @return boolean
function option.Option:is_none_or( fn )
  return not self._is_some or fn( fn )
end

--- @generic T
--- @return T
function option.Option:unwrap()
  if not self._is_some then
    panic.raise( panic.KIND.TYPE_ERROR, 'cannot unwrap an None value' )
  end
  return self._val
end

--- @generic T
--- @param default T
--- @return T
function option.Option:unwrap_or( default )
  if self._is_some then return self._val end
  return default
end

--- @generic T
--- @param default fun(): T
--- @return T
function option.Option:unwrap_or_else( default )
  if self._is_some then return self._val end
  return default()
end

--- @generic T, U
--- @param fn fun( x: T ): U
--- @return Option<U>
function option.Option:map( fn )
  if self._is_some then return option.Some( fn( self._val ) ) end
  return option.None()
end

--- @generic T, U
--- @param default U
--- @param fn fun( x: T ): U
--- @return U
function option.Option:map_or( default, fn )
  if self._is_some then return fn( self._val ) end
  return default
end

--- @generic T, U
--- @param default fun(): T
--- @param fn fun( x: T ): U
--- @return U
function option.Option:map_or_else( default, fn )
  if self._is_some then return fn( self._val ) end
  return fn( default() )
end

--- @generic T, U
--- @param other Option<U>
--- @return Option<[T, U]>
function option.Option:zip( other )
  if self._is_some and other._is_some then
    return option.Some( { self._val, other._val } )
  end
  return option.None()
end

--- @generic T, U
--- @param fn fun( x: T ): Option<U>
--- @return Option<U>
function option.Option:and_then( fn )
  if self._is_some then return fn( self._val ) end
  return option.None()
end

--- @generic T, U
--- @param fn fun(): Option<U>
--- @return Option<U>
function option.Option:or_else( fn )
  if not self._is_some then return fn() end
  return self
end

--- @generic U
--- @param opt Option<U>
--- @return Option<U>
function option.Option:and_( opt )
  if self._is_some and opt._is_some then return opt end
  return option.None()
end

--- @generic U
--- @param opt Option<U>
--- @return Option<U>
function option.Option:or_( opt )
  if self._is_some then
    return self
  elseif opt._is_some then
    return opt
  end
  return option.None()
end

--- @generic U
--- @param opt Option<U>
--- @return Option<U>
function option.Option:xor_( opt )
  if self._is_some == opt._is_some then return option.None() end
  if self._is_some then return self end
  return opt
end

--- @generic T
--- @param value T
--- @return T
function option.Option:insert( value )
  self._val = value
  self._is_some = true
  return value
end

--- @generic T
--- @param value T
--- @return T
function option.Option:get_or_insert( value )
  if not self._is_some then
    self._val = value
    self._is_some = true
  end
  return self._val
end

--- @generic T
--- @param fn fun(): T
--- @return T
function option.Option:get_or_insert_with( fn )
  if not self._is_some then
    self._val = fn()
    self._is_some = true
  end
  return self._val
end

--- @generic T
--- @return Option<T>
function option.Option:take()
  if self._is_some then
    local value = self._val
    self._val = nil
    self._is_some = false
    return option.Some( value )
  end
  return option.None()
end

--- @generic T
--- @param predicate fun( x: T ): boolean
--- @return Option<T>
function option.Option:take_if( predicate )
  if self._is_some and predicate( self._val ) then
    local value = self._val
    self._val = nil
    self._is_some = false
    return option.Some( value )
  end
  return option.None()
end

--- @generic T
--- @param value T
--- @return Option<T>
function option.Option:replace( value )
  if self._is_some then
    local old = self._val
    self._val = value
    return option.Some( old )
  end
  self._val = value
  self._is_some = true
  return option.None()
end

--- @generic T, E
--- @param err E
--- @return Result<T, E>
function option.Option:ok_or( err )
  local result = require( 'core.result' )
  if self._is_some then return result.Ok( self._val ) end
  return result.Err( err )
end

--- @generic T, E
--- @param fn fun(): E
--- @return Result<T, E>
function option.Option:ok_or_else( fn )
  local result = require( 'core.result' )
  if self._is_some then return result.Ok( self._val ) end
  return result.Err( fn() )
end

return option
