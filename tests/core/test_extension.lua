local extension = require( 'core.extension' )
local M = {}

-- A RTTI layout type and instance.
--- @class Duck
local Duck = {}
Duck.__index = Duck
setmetatable( Duck, {
  _rtti = {
    metatype = 'class',
  },
} )
local donald = setmetatable( {}, Duck )

local function test_add_new_method()
  extension.mixin( Duck, {
    quack = function() return 'quack' end,
  } )
  assert( donald.quack() == 'quack',
          'Duck can quack' )
end

local function test_add_multiple_methods()
  extension.mixin( Duck, {
    walk = function() return 'walk' end,
    swim = function() return 'swim' end,
  } )
  assert( donald.walk() == 'walk',
          'Duck can walk' )
  assert( donald.swim() == 'swim',
          'Duck can swim' )
end

local function test_class_field_priority()
  Duck.fly = function() return 'native' end
  extension.mixin( Duck, {
    fly = function() return 'extension' end,
  } )
  assert( donald.fly() == 'native',
          'Duck keeps native fly' )
  Duck.fly = nil
end

local function test_instance_field_priority()
  Duck.run = function() return 'instance' end
  extension.mixin( Duck, {
    run = function() return 'extension' end,
  } )
  --- @diagnostic disable-next-line
  assert( donald.run() == 'instance',
          'donald keeps instance run' )
  Duck.run = nil
end

local function test_conflict_raises()
  local ok, err = pcall( function()
    extension.mixin( Duck, {
      quack = function() return 'another' end,
    } )
  end )
  assert( not ok and tostring( err ):match( 'class already contains' ),
          'Duck raises conflict on quack' )
end

local function test_object_extension_interaction()
  local meta = require( 'core.meta' )
  local Bird = meta.class()
  local sparrow = Bird()

  extension.mixin( Bird, {
    sing = function() return 'tweet' end,
  } )
  assert( sparrow:sing() == 'tweet',
          'Bird can sing' )

  sparrow.fly = function() return 'instance' end
  extension.mixin( Bird, {
    fly = function() return 'extension' end,
  } )
  --- @diagnostic disable-next-line
  assert( sparrow:fly() == 'instance',
          'sparrow keeps instance fly' )

  -- 3. 字段冲突检测
  local ok, err = pcall( function()
    extension.mixin( Bird, {
      sing = function() return 'another' end,
    } )
  end )
  assert( not ok and tostring( err ):match( 'class already contains' ),
          'Bird raises conflict on sing' )
end

function M.run()
  test_add_new_method()
  test_add_multiple_methods()
  test_class_field_priority()
  test_instance_field_priority()
  test_conflict_raises()
  test_object_extension_interaction()
  print( 'extension tests all passed.' )
end

local filename = (arg or { ... })[0]
if filename and filename:match( 'test_extension.lua$' ) then
  M.run()
end

return M
