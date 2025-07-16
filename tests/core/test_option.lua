local option = require( 'core.option' )
local M = {}

local function test_is_some()
  local opt = option.Some( 42 )
  assert( opt:is_some() == true,
          'is_some should be true' )
  assert( opt:is_none() == false,
          'is_none should be false' )
end

local function test_none()
  local opt = option.None()
  assert( opt:is_some() == false,
          'is_some should be false' )
  assert( opt:is_none() == true,
          'is_none should be true' )
end

local function test_unwrap()
  local opt = option.Some( 'hello' )
  assert( opt:unwrap() == 'hello',
          'unwrap should get value' )
end

local function test_unwrap_or()
  local opt1 = option.Some( 'x' )
  local opt2 = option.None()
  --- @diagnostic disable-next-line
  assert( opt1:unwrap_or( 'y' ) == 'x',
          'unwrap_or should keep value' )
  --- @diagnostic disable-next-line
  assert( opt2:unwrap_or( 'y' ) == 'y',
          'unwrap_or should fallback' )
end

local function test_unwrap_or_else()
  local opt1 = option.Some( 'a' )
  local opt2 = option.None()
  --- @diagnostic disable-next-line
  assert( opt1:unwrap_or_else( function() return 'b' end ) == 'a',
          'unwrap_or_else should keep value' )
  --- @diagnostic disable-next-line
  assert( opt2:unwrap_or_else( function() return 'b' end ) == 'b',
          'unwrap_or_else should fallback' )
end

local function test_map()
  local opt1 = option.Some( 3 )
  local opt2 = option.None()
  local r1 = opt1:map( function( x ) return x * 2 end )
  local r2 = opt2:map( function( x ) return x * 2 end )
  assert( r1:is_some() == true,
          'map should produce Some' )
  assert( r1:unwrap() == 6,
          'map should map value' )
  assert( r2:is_none() == true,
          'map on None should stay None' )
end

local function test_map_or()
  local opt1 = option.Some( 5 )
  local opt2 = option.None()
  local r1 = opt1:map_or( 0, function( x ) return x * 2 end )
  local r2 = opt2:map_or( 0, function( x ) return x * 2 end )
  --- @diagnostic disable-next-line
  assert( r1 == 10,
          'map_or should map value' )
  --- @diagnostic disable-next-line
  assert( r2 == 0,
          'map_or on None should use default' )
end

local function test_map_or_else()
  local opt1 = option.Some( 7 )
  local opt2 = option.None()
  local r1 = opt1:map_or_else( function() return 1 end, function( x ) return x + 1 end )
  local r2 = opt2:map_or_else( function() return 1 end, function( x ) return x + 1 end )
  assert( r1 == 8,
          'map_or_else should map value' )
  assert( r2 == 2,
          'map_or_else on None should use default' )
end

local function test_is_some_and()
  local opt1 = option.Some( 4 )
  local opt2 = option.None()
  assert( opt1:is_some_and( function( x ) return x > 2 end ) == true,
          'is_some_and should check value' )
  assert( opt2:is_some_and( function( x ) return x > 2 end ) == false,
          'is_some_and on None should be false' )
end

local function test_is_none_or()
  local opt1 = option.Some( 4 )
  local opt2 = option.None()
  assert( opt1:is_none_or( function() return true end ) == true,
          'is_none_or on Some should check value' )
  assert( opt2:is_none_or( function() return false end ) == true,
          'is_none_or on None should be true' )
end

local function test_zip()
  local a = option.Some( 1 )
  local b = option.Some( 2 )
  local c = option.None()
  local r1 = a:zip( b )
  local r2 = a:zip( c )
  assert( r1:is_some() == true,
          'zip should produce Some' )
  assert( #r1:unwrap() == 2,
          'zip should pair values' )
  assert( r2:is_none() == true,
          'zip with None should be None' )
end

local function test_and_then()
  local opt = option.Some( 5 )
  local r1 = opt:and_then( function( x ) return option.Some( x * 10 ) end )
  assert( r1:is_some() == true,
          'and_then should produce Some' )
  assert( r1:unwrap() == 50,
          'and_then should map correctly' )
end

local function test_or_else()
  local opt1 = option.None()
  local opt2 = option.Some( 7 )
  local r = opt1:or_else( function() return opt2 end )
  assert( r:is_some() == true,
          'or_else should fallback to other' )
  assert( r:unwrap() == 7,
          'or_else should get fallback value' )
end

local function test_and_()
  local opt1 = option.Some( 1 )
  local opt2 = option.Some( 2 )
  local opt3 = option.None()
  local r1 = opt1:and_( opt2 )
  local r2 = opt1:and_( opt3 )
  assert( r1:is_some() == true,
          'and_ with two Some should be Some' )
  assert( r2:is_none() == true,
          'and_ with None should be None' )
end

local function test_or_()
  local opt1 = option.Some( 1 )
  local opt2 = option.Some( 2 )
  local opt3 = option.None()
  local r1 = opt3:or_( opt2 )
  local r2 = opt1:or_( opt3 )
  assert( r1:is_some() == true,
          'or_ should fallback to other' )
  assert( r2:is_some() == true,
          'or_ should keep self if Some' )
end

local function test_xor_()
  local opt1 = option.Some( 1 )
  local opt2 = option.None()
  local opt3 = option.Some( 2 )
  local r1 = opt1:xor_( opt2 )
  local r2 = opt1:xor_( opt3 )
  assert( r1:is_some() == true,
          'xor_ with different should be Some' )
  assert( r2:is_none() == true,
          'xor_ with same should be None' )
end

local function test_insert()
  local opt = option.None()
  local v = opt:insert( 9 )
  assert( opt:is_some() == true,
          'insert should set value' )
  --- @diagnostic disable-next-line
  assert( v == 9,
          'insert should return value' )
end

local function test_get_or_insert()
  local opt = option.None()
  local v = opt:get_or_insert( 5 )
  assert( opt:is_some() == true,
          'get_or_insert should set value' )
  --- @diagnostic disable-next-line
  assert( v == 5,
          'get_or_insert should return value' )
end

local function test_get_or_insert_with()
  local opt = option.None()
  local v = opt:get_or_insert_with( function() return 8 end )
  assert( opt:is_some() == true,
          'get_or_insert_with should set value' )
  --- @diagnostic disable-next-line
  assert( v == 8,
          'get_or_insert_with should return value' )
end

local function test_take()
  local opt = option.Some( 11 )
  local taken = opt:take()
  assert( taken:is_some() == true,
          'take should return Some' )
  assert( opt:is_none() == true,
          'take should empty option' )
end

local function test_take_if()
  local opt1 = option.Some( 4 )
  local opt2 = option.Some( 1 )
  local taken1 = opt1:take_if( function( x ) return x > 2 end )
  local taken2 = opt2:take_if( function( x ) return x > 2 end )
  assert( taken1:is_some() == true,
          'take_if should return Some if predicate true' )
  assert( taken2:is_none() == true,
          'take_if should return None if predicate false' )
end

local function test_replace()
  local opt = option.Some( 2 )
  local old = opt:replace( 3 )
  assert( old:is_some() == true,
          'replace should return old Some' )
  assert( opt:unwrap() == 3,
          'replace should set new value' )
end

local function test_ok_or_some()
  local v = option.Some( 42 ):ok_or( 'error' )
  assert( v:is_ok() == true,
          'ok_or returns Ok when Some' )
end

local function test_ok_or_none()
  local v = option.None():ok_or( 'error' )
  assert( v:is_err() == true,
          'ok_or returns Err when None' )
end

local function test_ok_or_else_some()
  local v = option.Some( 42 ):ok_or_else( function() return 'lazy error' end )
  assert( v:is_ok() == true,
          'ok_or_else returns Ok when Some' )
end

local function test_ok_or_else_none()
  local v = option.None():ok_or_else( function() return 'lazy error' end )
  assert( v:is_err() == true,
          'ok_or_else returns Err when None' )
end

function M.run()
  test_is_some()
  test_none()
  test_unwrap()
  test_unwrap_or()
  test_unwrap_or_else()
  test_map()
  test_map_or()
  test_map_or_else()
  test_is_some_and()
  test_is_none_or()
  test_zip()
  test_and_then()
  test_or_else()
  test_and_()
  test_or_()
  test_xor_()
  test_insert()
  test_get_or_insert()
  test_get_or_insert_with()
  test_take()
  test_take_if()
  test_replace()
  test_ok_or_some()
  test_ok_or_none()
  test_ok_or_else_some()
  test_ok_or_else_none()
  print( 'option tests all passed.' )
end

local filename = (arg or { ... })[0]
if filename and filename:match( 'test_option.lua$' ) then
  M.run()
end

return M
