local utility = require( 'core.utility' )
local M = {}

local function test_shallowcopy_table()
  local inner = { x = 1 }
  local t = { a = inner }
  local copy = utility.shallowcopy( t )
  assert( copy.a == inner,
          'shallowcopy copies reference' )
  assert( copy ~= t,
          'shallowcopy creates new table' )
end

local function test_shallowcopy_non_table()
  local n = 42
  local copy = utility.shallowcopy( n )
  assert( copy == 42,
          'shallowcopy keeps non-table value' )
end

local function test_deepcopy_simple()
  local t = { a = { b = 2 } }
  local copy = utility.deepcopy( t )
  --- @diagnostic disable-next-line
  assert( copy.a.b == 2,
          'deepcopy keeps nested value' )
  --- @diagnostic disable-next-line
  assert( copy.a ~= t.a,
          'deepcopy creates nested table' )
end

local function test_deepcopy_cycle()
  local t = {}
  t.self = t
  local copy = utility.deepcopy( t )
  assert( copy ~= t,
          'deepcopy creates new table' )
  assert( copy.self == copy,
          'deepcopy keeps cycle' )
end

function M.run()
  test_shallowcopy_table()
  test_shallowcopy_non_table()
  test_deepcopy_simple()
  test_deepcopy_cycle()
  print( 'utility tests all passed.' )
end

local filename = (arg or { ... })[0]
if filename and filename:match( 'test_utility.lua$' ) then
  M.run()
end

return M
