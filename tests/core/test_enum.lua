local rtti = require( 'core.rtti' )
local meta = require( 'core.meta' )
local enum = require( 'core.enum' )
local M = {}

local function test_basic()
  --- @enum Color
  local Color = meta.class( enum.Enum )
  Color.RED = 1
  Color.GREEN = 2
  --- @diagnostic disable
  assert( rtti.typeof( Color.RED ) == Color )
  assert( rtti.typeof( Color, Color.GREEN ) == Color )
  assert( Color.RED.name == 'RED' )
  assert( Color.GREEN.name == 'GREEN' )
  assert( Color.RED.value == 1 )
  assert( Color.GREEN.value == 2 )
end

local function test_auto()
  --- @enum Test
  local Test = meta.class( enum.Enum )
  Test.A = 10
  Test.B = 3
  Test.C = enum.auto
  Test.D = enum.auto
  Test.E = 1
  Test.F = 'x'
  local ok, err = pcall( function()
    Test.G = enum.auto
  end )
  --- @diagnostic disable
  assert( Test.A.value == 10 )
  assert( Test.B.value == 3 )
  assert( Test.C.value == 11 )
  assert( Test.D.value == 12 )
  assert( Test.E.value == 1 )
  assert( Test.F.value == 'x' )
  assert( ok == false and err ~= nil and err:match( 'non%-numeric values' ) )
end

function M.run()
  test_basic()
  test_auto()
  print( 'enum tests all passed.' )
end

local filename = (arg or { ... })[0]
if filename and filename:match( 'test_enum.lua$' ) then
  M.run()
end

return M
