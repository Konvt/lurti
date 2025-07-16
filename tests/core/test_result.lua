local result = require( 'core.result' )
local M = {}

local function test_ok_is_ok()
  local ok = result.Ok( 42 )
  assert( ok:is_ok() == true,
          'Ok should be ok' )
end

local function test_err_is_err()
  local err = result.Err( 'error' )
  assert( err:is_err() == true,
          'Err should be err' )
end

local function test_unwrap_ok()
  local ok = result.Ok( 'value' )
  assert( ok:unwrap() == 'value',
          'Ok should unwrap to value' )
end

local function test_unwrap_err_panic()
  local err = result.Err( 'fail' )
  local ok, msg = pcall( function() err:unwrap() end )
  assert( ok == false,
          'unwrap on Err should panic' )
end

local function test_unwrap_err()
  local err = result.Err( 'fail' )
  assert( err:unwrap_err() == 'fail',
          'Err should unwrap_err to value' )
end

local function test_unwrap_or_ok()
  local ok = result.Ok( 7 )
  --- @diagnostic disable-next-line
  assert( ok:unwrap_or( 99 ) == 7,
          'Ok should unwrap_or to self value' )
end

local function test_unwrap_or_err()
  local err = result.Err( 'bad' )
  --- @diagnostic disable-next-line
  assert( err:unwrap_or( 88 ) == 88,
          'Err should unwrap_or to default' )
end

local function test_unwrap_or_else_ok()
  local ok = result.Ok( 3 )
  --- @diagnostic disable-next-line
  assert( ok:unwrap_or_else( function() return 9 end ) == 3,
          'Ok should unwrap_or_else to self value' )
end

local function test_unwrap_or_else_err()
  local err = result.Err( 'fail' )
  --- @diagnostic disable-next-line
  assert( err:unwrap_or_else( function() return 5 end ) == 5,
          'Err should unwrap_or_else to fallback' )
end

local function test_map_ok()
  local ok = result.Ok( 2 )
  local mapped = ok:map( function( v ) return v * 10 end )
  assert( mapped:unwrap() == 20,
          'Ok should map value' )
end

local function test_map_err()
  local err = result.Err( 'bad' )
  local mapped = err:map( function( v ) return v * 10 end )
  assert( mapped:is_err() == true,
          'Err should stay err on map' )
end

local function test_map_err_on_err()
  local err = result.Err( 'bad' )
  local mapped = err:map_err( function( e ) return e .. '_mapped' end )
  assert( mapped:unwrap_err() == 'bad_mapped',
          'Err should map_err value' )
end

local function test_map_err_on_ok()
  local ok = result.Ok( 5 )
  local mapped = ok:map_err( function( e ) return e .. '_mapped' end )
  assert( mapped:unwrap() == 5,
          'Ok should stay ok on map_err' )
end

local function test_and_then_ok()
  local ok = result.Ok( 2 )
  local res = ok:and_then( function( v ) return result.Ok( v + 3 ) end )
  assert( res:unwrap() == 5,
          'Ok should and_then to new Ok' )
end

local function test_and_then_err()
  local err = result.Err( 'fail' )
  local res = err:and_then( function( v ) return result.Ok( v + 3 ) end )
  assert( res:is_err() == true,
          'Err should stay err on and_then' )
end

local function test_or_else_err()
  local err = result.Err( 'fail' )
  local res = err:or_else( function( e ) return result.Ok( e .. '_recovered' ) end )
  assert( res:unwrap() == 'fail_recovered',
          'Err should or_else to new Ok' )
end

local function test_or_else_ok()
  local ok = result.Ok( 1 )
  local res = ok:or_else( function( e ) return result.Ok( 99 ) end )
  assert( res:unwrap() == 1,
          'Ok should stay ok on or_else' )
end

local function test_and_ok()
  local ok1 = result.Ok( 'a' )
  local ok2 = result.Ok( 'b' )
  local res = ok1:and_( ok2 )
  assert( res:unwrap() == 'b',
          'Ok should and_ to next Ok' )
end

local function test_and_err()
  local err = result.Err( 'fail' )
  local ok = result.Ok( 'b' )
  local res = err:and_( ok )
  assert( res:is_err() == true,
          'Err should stay err on and_' )
end

local function test_or_err()
  local err1 = result.Err( 'fail1' )
  local err2 = result.Err( 'fail2' )
  local res = err1:or_( err2 )
  assert( res:unwrap_err() == 'fail2',
          'Err should or_ to next Err' )
end

local function test_or_ok()
  local ok = result.Ok( 'good' )
  local err = result.Err( 'fail' )
  local res = ok:or_( err )
  assert( res:unwrap() == 'good',
          'Ok should stay ok on or_' )
end

local function test_expect_ok()
  local ok = result.Ok( 'yes' )
  assert( ok:expect( 'should not fail' ) == 'yes',
          'Ok should expect to value' )
end

local function test_expect_err_panic()
  local err = result.Err( 'fail' )
  local ok, msg = pcall( function() err:expect( 'should panic' ) end )
  assert( ok == false and msg ~= nil and msg:match( 'should panic' ),
          'Err should panic on expect' )
end

local function test_inspect_ok()
  local value
  local ok = result.Ok( 'hi' )
  ok:inspect( function( v ) value = v end )
  assert( value == 'hi',
          'Ok should call inspect' )
end

local function test_inspect_err()
  local called = false
  local err = result.Err( 'bad' )
  err:inspect( function() called = true end )
  assert( called == false,
          'Err should not call inspect' )
end

local function test_inspect_err_called()
  local value
  local err = result.Err( 'bad' )
  err:inspect_err( function( v ) value = v end )
  assert( value == 'bad',
          'Err should call inspect_err' )
end

local function test_inspect_err_not_called()
  local called = false
  local ok = result.Ok( 'hi' )
  ok:inspect_err( function() called = true end )
  assert( called == false,
          'Ok should not call inspect_err' )
end

local function test_result_ok()
  local o = result.Ok( 42 ):ok()
  assert( o:is_some() == true,
          'ok returns Some when Ok' )
end

local function test_result_ok_err()
  local o = result.Err( 'error' ):ok()
  assert( o:is_none() == true,
          'ok returns None when Err' )
end

local function test_result_err()
  local o = result.Err( 'error' ):err()
  assert( o:is_some() == true,
          'err returns Some when Err' )
end

local function test_result_err_ok()
  local o = result.Ok( 42 ):err()
  assert( o:is_none() == true,
          'err returns None when Ok' )
end

function M.run()
  test_ok_is_ok()
  test_err_is_err()
  test_unwrap_ok()
  test_unwrap_err_panic()
  test_unwrap_err()
  test_unwrap_or_ok()
  test_unwrap_or_err()
  test_unwrap_or_else_ok()
  test_unwrap_or_else_err()
  test_map_ok()
  test_map_err()
  test_map_err_on_err()
  test_map_err_on_ok()
  test_and_then_ok()
  test_and_then_err()
  test_or_else_err()
  test_or_else_ok()
  test_and_ok()
  test_and_err()
  test_or_err()
  test_or_ok()
  test_expect_ok()
  test_expect_err_panic()
  test_inspect_ok()
  test_inspect_err()
  test_inspect_err_called()
  test_inspect_err_not_called()
  test_result_ok()
  test_result_ok_err()
  test_result_err()
  test_result_err_ok()
  print( 'result tests all passed.' )
end

local filename = (arg or { ... })[0]
if filename and filename:match( 'test_result.lua$' ) then
  M.run()
end

return M
