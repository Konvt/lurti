local result = require( 'core.result' )
local option = require( 'core.option' )
local utility = {}

--- @generic T, E
--- @param err E
--- @return Result<T, E>
function option.Option:ok_or( err )
  if self._is_some then return result.Ok( self._val ) end
  return result.Err( err )
end

--- @generic T, E
--- @param fn fun(): E
--- @return Result<T, E>
function option.Option:ok_or_else( fn )
  if self._is_some then return result.Ok( self._val ) end
  return result.Err( fn() )
end

--- @generic T
--- @return Option<T>
function result.Result:ok()
  if self._is_ok then return option.Some( self._val ) end
  return option.None()
end

--- @generic T
--- @return Option<T>
function result.Result:err()
  if not self._is_ok then return option.Some( self._val ) end
  return option.None()
end

return utility
