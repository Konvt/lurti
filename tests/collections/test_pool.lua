local pool = require( 'collections.pool' )
local object = require( 'core.object' )
local abc = require( 'core.abc' )
local M = {}

--- @class Dummy
local Dummy = object.class( abc.ICopyable )

function Dummy:init( val )
  self.val = val
end

function Dummy:clone()
  return Dummy( self.val )
end

function Dummy:__eq( other )
  return other and self.val == other.val
end

local function test_new()
  local p = pool.ObjectPool:new( Dummy( 1 ) )
  assert( p:size() == 0,
          'ObjectPool init keeps buffer empty' )
end

local function test_new_with()
  local p = pool.ObjectPool:new_with( Dummy( 2 ), 3 )
  assert( p:size() == 3,
          'ObjectPool init_with produces objects' )
end

local function test_produce()
  local p = pool.ObjectPool:new( Dummy( 1 ) ):produce( 5 )
  assert( p:size() == 5,
          'ObjectPool produce increases buffer' )
end

local function test_load()
  local p = pool.ObjectPool:new( Dummy( 1 ) ):produce( 4 )
  local list = p:load( 3 )
  assert( #list == 3,
          'ObjectPool load returns requested number' )
  assert(
    p:size() == 1,
    'ObjectPool load removes from buffer'
  )
end

local function test_pop()
  local p = pool.ObjectPool:new( Dummy( 1 ) ):produce( 2 )
  local obj = p:pop()
  assert( obj ~= nil,
          'ObjectPool pop returns object' )
  assert( p:size() == 1,
          'ObjectPool pop removes one from buffer' )
end

local function test_store()
  local p = pool.ObjectPool:new( Dummy( 1 ) )
  local list = { Dummy( 5 ), Dummy( 6 ) }
  p:store( list )
  assert( p:size() == 2,
          'ObjectPool store adds objects to buffer' )
  assert( list[1] == nil and list[2] == nil,
          'ObjectPool store clears input list' )
end

local function test_push()
  local p = pool.ObjectPool:new( Dummy( 1 ) )
  p:push( Dummy( 7 ) )
  assert( p:size() == 1,
          'ObjectPool push adds single object' )
end

local function test_remove()
  local p = pool.ObjectPool:new( Dummy( 1 ) )
  local obj = Dummy( 9 )
  p:push( obj )
  local removed = p:remove( obj )
  assert( removed == obj,
          'ObjectPool remove returns removed object' )
  assert( p:size() == 0,
          'ObjectPool remove reduces buffer' )
end

local function test_clear()
  local p = pool.ObjectPool:new( Dummy( 1 ) ):produce( 3 )
  p:clear()
  assert( p:size() == 0,
          'ObjectPool clear empties buffer' )
end

function M.run()
  test_new()
  test_new_with()
  test_produce()
  test_load()
  test_pop()
  test_store()
  test_push()
  test_remove()
  test_clear()
  print( 'pool tests all passed.' )
end

local filename = (arg or { ... })[0]
if filename and filename:match( 'test_pool.lua$' ) then
  M.run()
end

return M
