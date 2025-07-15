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
  assert( rtti.typeof( Color.RED ) == Color,
          'Color.RED type' )
  assert( rtti.typeof( Color, Color.GREEN ) == Color,
          'Color.GREEN type' )
  assert( Color.RED.name == 'RED',
          'Color.RED name' )
  assert( Color.GREEN.name == 'GREEN',
          'Color.GREEN name' )
  assert( Color.RED.value == 1,
          'Color.RED value' )
  assert( Color.GREEN.value == 2,
          'Color.GREEN value' )
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
  assert( Test.A.value == 10,
          'Test.A value' )
  assert( Test.B.value == 3,
          'Test.B value' )
  assert( Test.C.value == 11,
          'Test.C value' )
  assert( Test.D.value == 12,
          'Test.D value' )
  assert( Test.E.value == 1,
          'Test.E value' )
  assert( Test.F.value ==
          'x', 'Test.F value' )
  assert( ok == false,
          'Test.G auto fail' )
  assert( err ~= nil and err:match( 'non%-numeric values' ),
          'Test.G error msg' )
end

local function test_instantiate_array()
  local E = enum.Enum( { 'X', 'Y', 'Z' } )
  assert( E.X ~= nil,
          'instantiate array member X exists' )
  assert( E.Y ~= nil,
          'instantiate array member Y exists' )
  assert( E.Z ~= nil,
          'instantiate array member Z exists' )
  assert( E.X.value == 1,
          'instantiate array member X value' )
  assert( E.Y.value == 2,
          'instantiate array member Y value' )
  assert( E.Z.value == 3,
          'instantiate array member Z value' )
end

local function test_instantiate_map()
  local E = enum.Enum( { A = 5, B = 10, C = 20 } )
  assert( E.A.value == 5,
          'instantiate map member A value' )
  assert( E.B.value == 10,
          'instantiate map member B value' )
  assert( E.C.value == 20,
          'instantiate map member C auto value' )
end

local function test_non_string_key_error()
  local status, err = pcall( function()
    local T = meta.class( enum.Enum )
    T[123] = 1
  end )
  assert( status == false,
          'non-string key error triggered' )
  assert( err ~= nil and err:match( 'non%-enum type member' ),
          'non-string key error msg' )
end

local function test_value_function()
  local T = meta.class( enum.Enum )
  local f = function() return 42 end
  T.fn = f
  assert( T.fn == f, 'function value preserved' )
end

local function test_iter_pairs()
  --- @enum Direction
  local Direction = meta.class( enum.Enum )
  Direction.NORTH = 1
  Direction.EAST = 2
  Direction.SOUTH = 3
  Direction.WEST = 4

  local keys = {}
  for k, v in pairs( Direction ) do
    keys[#keys+1] = k
    assert( type( k ) == 'string', 'Direction pair key type' )
  end

  local expected = { NORTH = true, EAST = true, SOUTH = true, WEST = true }
  local count = 0
  for _, k in ipairs( keys ) do
    expected[k] = nil
    count = count + 1
  end

  assert( count == 4, 'Not all enum members were iterated' )
  for k in pairs( expected ) do
    error( 'Missing enum member in iteration: ' .. k )
  end
end

local function test_instantiate_existing_value()
  --- @enum Sample
  local Sample = meta.class( enum.Enum )
  Sample.ONE = 1
  Sample.TWO = 2
  local inst = Sample( 1 )
  assert( inst == Sample.ONE,
          'instantiate returns existing value' )
end

local function test_error_on_non_table_members()
  local status, err = pcall( function()
    local E = enum.Enum( 123 )
  end )
  assert( status == false,
          'instantiate non-table members error' )
end

local function test_error_on_non_string_in_array()
  local status, err = pcall( function()
    local E = enum.Enum( { 'A', 123 } )
  end )
  assert( status == false,
          'instantiate non-string in array error' )
end

local function test_error_on_non_string_key_in_map()
  local status, err = pcall( function()
    local E = enum.Enum( { [123] = 1 } )
  end )
  assert( status == false,
          'instantiate non-string key in map error' )
end

local function test_error_on_auto_in_map()
  local status, err = pcall( function()
    local E = enum.Enum( { A = enum.auto, B = 1 } )
  end )
  assert( status == false,
          'instantiate auto value in map error' )
end

local function test_duplicate_value_shares_item()
  local D = meta.class( enum.Enum )
  D.A = 1
  D.B = 1
  assert( D.A.value == 1,
          'duplicate value A value' )
  assert( D.B.value == 1,
          'duplicate value B value' )
  assert( D.A.value == D.B.value,
          'duplicate values equal' )
end

function M.run()
  test_basic()
  test_auto()
  test_instantiate_array()
  test_instantiate_map()
  test_non_string_key_error()
  test_value_function()
  test_iter_pairs()
  test_instantiate_existing_value()
  test_error_on_non_table_members()
  test_error_on_non_string_in_array()
  test_error_on_non_string_key_in_map()
  test_error_on_auto_in_map()
  test_duplicate_value_shares_item()
  print( 'enum tests all passed.' )
end

local filename = (arg or { ... })[0]
if filename and filename:match( 'test_enum.lua$' ) then
  M.run()
end

return M
