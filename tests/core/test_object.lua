local rtti = require( 'core.rtti' )
local meta = require( 'core.meta' )
local object = require( 'core.object' )
local M = {}

local function test_object_new()
  local cls = object.class()
  local inst = cls:new()
  assert( rtti.is_object( inst ) == true,
          'Object is instance' )
end

local function test_classmethod_basic()
  local cls = object.class()
  function cls:foo() return 'foo' end

  object.classmethod( cls, { foo = cls.foo } )
  local inst = cls:new()
  assert( inst:foo() == 'foo',
          'Object foo returns foo' )
end

local function test_classmethod_conflict()
  local cls = object.class()
  function cls:bar() return 'bar' end

  local ok, err = pcall( function()
    object.classmethod( cls, { bar = function() end } )
  end )
  assert( ok == false,
          'Classmethod conflict triggers panic' )
end

local function test_init_super()
  local Base = object.class()
  function Base:init()
    self.base_inited = true
    return self
  end

  local Derived = object.class( Base )
  function Derived:init()
    object.init_super( Derived, self )
    self.derived_inited = true
    return self
  end

  local inst = Derived:new()
  assert( inst.base_inited == true,
          'Super init sets base_inited' )
  assert( inst.derived_inited == true,
          'Init sets derived_inited' )
end

local function test_class_with_metaclass()
  local metaclass = meta.Type
  local cls = object.class( nil, metaclass )
  local inst = cls:new()
  assert( rtti.is_object( inst ) == true,
          'Object with metaclass is object' )
end

local function test_object_init()
  local cls = object.class()
  local inst = cls:new()
  local ret = inst:init()
  assert( ret == inst,
          'Init returns self' )
end

function M.run()
  test_object_new()
  test_classmethod_basic()
  test_classmethod_conflict()
  test_init_super()
  test_class_with_metaclass()
  test_object_init()
  print( 'object tests all passed.' )
end

local filename = (arg or { ... })[0]
if filename and filename:match( 'test_object.lua$' ) then
  M.run()
end

return M
