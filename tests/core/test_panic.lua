local panic = require( 'core.panic' )
local M = {}

local function test_known_kind()
  local ok = pcall( function()
    panic.raise( panic.KIND.TYPE_ERROR, 'something' )
  end )
  assert( not ok,
          '"raise" raises on known kind.' )
end

local function test_unknown_kind()
  local ok = pcall( function()
    panic.raise( 'UNKNOWN_KIND', 'something' )
  end )
  assert( not ok,
          '"raise" raises on unknown kind.' )
end

local function test_no_extra()
  local ok = pcall( function()
    panic.raise( panic.KIND.FIELD_CONFLICT )
  end )
  assert( not ok,
          '"raise" raises without extra info.' )
end

function M.run()
  test_known_kind()
  test_unknown_kind()
  test_no_extra()
  print( 'panic tests all passed.' )
end

local filename = (arg or { ... })[0]
if filename and filename:match( 'test_panic.lua$' ) then
  M.run()
end

return M
