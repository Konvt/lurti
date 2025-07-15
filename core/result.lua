local panic = require( 'core.panic' )
local meta = require( 'core.meta' )
--- Rust Result for Lua.
local result = {}

--- @class Result<T, E> : Object
--- @field private _is_ok boolean
--- @field private _val T | E
result.Result = meta.class()

--- Initialize a Result instance with status and value.
--- @generic T, E
--- @param ok boolean
--- @param value T | E
--- @return self
function result.Result:init( ok, value )
  meta.init_super( result.Result, self )
  self._is_ok = ok
  self._val = value
  return self
end

--- Create a new Result object from given class and value.
--- @generic C, T, E
--- @param is_ok boolean
--- @param value T | E
--- @return self
function result.Result:new( is_ok, value )
  -- assert( rtti.is_type( self ) )
  return self():init( is_ok, value )
end

--- Create a successful Result containing the given value.
--- @generic T, E
--- @param value T
--- @return Result<T | E>
function result.Ok( value )
  return result.Result:new( true, value )
end

--- Create an error Result containing the given error.
--- @generic T, E
--- @param value E
--- @return Result<T | E>
function result.Err( value )
  return result.Result:new( false, value )
end

--- Return true if the Result is Ok.
--- @return boolean
function result.Result:is_ok()
  return self._is_ok
end

--- Return true if the Result is Err.
--- @return boolean
function result.Result:is_err()
  return not self._is_ok
end

--- Return the contained Ok value or raise if Err.
--- @generic T
--- @return T
function result.Result:unwrap()
  if not self._is_ok then
    panic.raise( panic.KIND.TYPE_ERROR, 'cannot unwrap an Err value' )
  end
  return self._val
end

--- Return the contained Err value or raise if Ok.
--- @generic E
--- @return E
function result.Result:unwrap_err()
  if self._is_ok then
    panic.raise( panic.KIND.TYPE_ERROR, 'cannot unwrap_err an Ok value' )
  end
  return self._val
end

--- Return the contained Ok value or a default.
--- @generic T
--- @param default T
--- @return T
function result.Result:unwrap_or( default )
  if self._is_ok then return self._val end
  return default
end

--- Return Ok value or compute default with function.
--- @generic T
--- @param default fun(): T
--- @return T
function result.Result:unwrap_or_else( default )
  if self._is_ok then return self._val end
  return default()
end

--- Map the Ok value using function if Ok.
--- @generic U, T, E
--- @param fn fun( ok: T ): U
--- @return Result<U, E>
function result.Result:map( fn )
  if self._is_ok then return result.Ok( fn( self._val ) ) end
  return result.Err( self._val )
end

--- Map the Err value using function if Err.
--- @generic T, E, F
--- @param fn fun( err: E ): F
--- @return Result<T, F>
function result.Result:map_err( fn )
  if not self._is_ok then return result.Err( fn( self._val ) ) end
  return result.Ok( self._val )
end

--- Chain another Result-producing function if Ok.
--- @generic T, U, E
--- @param fn fun( ok: T ): Result<U, E>
--- @return Result<U, E>
function result.Result:and_then( fn )
  if self._is_ok then return fn( self._val ) end
  return result.Err( self._val )
end

--- Chain another Result-producing function if Err.
--- @generic T, F
--- @param fn fun( err: F ): Result<T, F>
--- @return Result<T, F>
function result.Result:or_else( fn )
  if not self._is_ok then return fn( self._val ) end
  return result.Ok( self._val )
end

--- Return res if Ok, else keep Err.
--- @generic T, U, E
--- @param res Result<U, E>
--- @return Result<U, E>
function result.Result:and_( res )
  if self._is_ok then return res end
  return result.Err( self._val )
end

--- Return res if Err, else keep Ok.
--- @generic T, F
--- @param res Result<T, F>
--- @return Result<T, F>
function result.Result:or_( res )
  if not self._is_ok then return res end
  return result.Ok( self._val )
end

--- Return Ok value or raise with message.
--- @generic T
--- @param msg string
--- @return T
function result.Result:expect( msg )
  if not self._is_ok then
    panic.raise( panic.KIND.TYPE_ERROR, msg )
  end
  return self._val
end

--- Return Err value or raise with message.
--- @generic E
--- @param msg string
--- @return E
function result.Result:expect_err( msg )
  if self._is_ok then
    panic.raise( panic.KIND.TYPE_ERROR, msg )
  end
  return self._val
end

--- Call function with Ok value for inspection.
--- @generic T
--- @param fn fun( ok: T ): nil
--- @return self
function result.Result:inspect( fn )
  if self._is_ok then fn( self._val ) end
  return self
end

--- Call function with Err value for inspection.
--- @generic E
--- @param fn fun( err: E ): nil
--- @return self
function result.Result:inspect_err( fn )
  if not self._is_ok then fn( self._val ) end
  return self
end

return result
