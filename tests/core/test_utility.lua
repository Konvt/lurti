local option = require( 'core.option' )
local result = require( 'core.result' )
local _utility = require( 'core.utility' )
local M = {}

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
  test_ok_or_some()
  test_ok_or_none()
  test_ok_or_else_some()
  test_ok_or_else_none()
  test_result_ok()
  test_result_ok_err()
  test_result_err()
  test_result_err_ok()
  print( 'utility tests all passed.' )
end

local filename = (arg or { ... })[0]
if filename and filename:match( 'test_utility.lua$' ) then
  M.run()
end

return M
