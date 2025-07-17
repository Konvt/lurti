local rtti = require( 'core.rtti' )
local meta = require( 'core.meta' )
local M = {}

local function test_metaclassof()
  local cls = meta.newtype( 'TestClass', {}, meta.Type )
  local mc = meta.metaclassof( cls )
  assert( mc == meta.Type,
          'metaclassof returns meta.Type' )
end

local function test_mroof()
  local A = meta.newtype( 'A', {}, meta.Type )
  local B = meta.newtype( 'B', { A }, meta.Type )
  local C = meta.newtype( 'C', { A }, meta.Type )
  local D = meta.newtype( 'D', { B, C }, meta.Type )

  local mroD = meta.mroof( D )
  assert( mroD.order[1] == D and mroD.index[D] == 1,
          'mroof head is D' )
  assert( mroD.order[2] == B and mroD.index[B] == 2,
          'mroof second is B' )
  assert( mroD.order[3] == C and mroD.index[C] == 3,
          'mroof third is C' )
  assert( mroD.order[4] == A and mroD.index[A] == 4,
          'mroof last is A' )
end

local function test_is_base_of()
  local A = meta.newtype( 'A', {}, meta.Type )
  local B = meta.newtype( 'B', { A }, meta.Type )
  local C = meta.newtype( 'C', {}, meta.Type )

  assert( meta.is_base_of( A, B ) == true,
          'is_base_of true for base' )
  assert( meta.is_base_of( B, A ) == false,
          'is_base_of false for derived' )
  assert( meta.is_base_of( A, A ) == true,
          'is_base_of true for same' )
  assert( meta.is_base_of( A, C ) == false,
          'is_base_of false unrelated' )
end

local function test_super()
  local A = meta.newtype( 'A', {}, meta.Type )
  local B = meta.newtype( 'B', { A }, meta.Type )
  local b_inst = B()
  local s = meta.super( b_inst )
  assert( s == A,
          'super returns base class' )
end

local function test_c3()
  local A = meta.newtype( 'A', {}, meta.Type )
  A.foo = 'foo'
  local B = meta.newtype( 'B', { A }, meta.Type )
  B.bar = 'bar'
  local b = B()

  assert( meta.c3( b, 'foo' ) == 'foo',
          'c3 finds base key' )
  assert( meta.c3( b, 'bar' ) == 'bar',
          'c3 finds derived key' )
  assert( meta.c3( b, 'baz' ) == nil,
          'c3 returns nil for missing key' )
end

local function test_class_conflict()
  local M1 = meta.metaclass()
  function M1:_init_( ns, req )
    ns.conflict = 'm1'
    return ns
  end

  local M2 = meta.metaclass()
  function M2:_init_( ns, req )
    ns.conflict = 'm2'
    return ns
  end

  local C1 = meta.newtype( 'C1', {}, M1 )
  local C2 = meta.newtype( 'C2', {}, M2 )

  local ok, err = pcall( function()
    meta.newtype( 'Conflict', { C1, C2 } )
  end )
  assert( not ok and err ~= nil and err:match( 'conflicting metaclasses' ),
          'class detects conflicting metaclasses' )
end

local function test_type_layer()
  assert( meta.is_base_of( meta.Object, meta.Type ) )
end

local function test_object_new()
  local cls = meta.class()
  local inst = cls:new()
  assert( rtti.is_object( inst ) == true,
          'Object is instance' )
end

local function test_init_super()
  local Base = meta.class()
  function Base:init()
    self.base_inited = true
    return self
  end

  local Derived = meta.class( Base )
  function Derived:init()
    meta.init_super( Derived, self )
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
  local cls = meta.class( nil, metaclass )
  local inst = cls:new()
  assert( rtti.is_object( inst ) == true,
          'Object with metaclass is meta' )
end

local function test_object_init()
  local cls = meta.class()
  local inst = cls:new()
  local ret = inst:init()
  assert( ret == inst,
          'Init returns self' )
end

local function test_classmethod_basic()
  local cls = meta.class()
  function cls.foo( self ) return self end

  meta.classmethod( cls, 'foo' )
  local obj = cls:new()
  local ret = obj:foo()
  assert( ret == cls,
          'foo should return class itself after classmethod' )
end

local function test_classmethod_multiple()
  local cls = meta.class()
  function cls.a( self ) return self end

  function cls.b( self ) return self end

  meta.classmethod( cls, { 'a', 'b' } )
  local obj = cls:new()
  assert( obj:a() == cls,
          'a should return class itself after classmethod' )
  assert( obj:b() == cls,
          'b should return class itself after classmethod' )
end

local function test_classmethod_missing()
  local cls = meta.class()
  local ok, err = pcall( function()
    meta.classmethod( cls, 'not_exist' )
  end )
  assert( ok == false and err ~= nil and err:match( 'must exist in class and is a function' ),
          'classmethod should fail if method does not exist' )
end

local function test_classmethod_not_function()
  local cls = meta.class()
  cls.value = 123
  local ok, err = pcall( function()
    meta.classmethod( cls, 'value' )
  end )
  assert( ok == false and err ~= nil and err:match( 'must exist in class and is a function' ),
          'classmethod should fail if target is not function' )
end

function M.run()
  test_metaclassof()
  test_mroof()
  test_is_base_of()
  test_super()
  test_c3()
  test_class_conflict()
  test_type_layer()
  test_object_new()
  test_init_super()
  test_class_with_metaclass()
  test_object_init()
  test_classmethod_basic()
  test_classmethod_multiple()
  test_classmethod_missing()
  test_classmethod_not_function()
  print( 'meta tests all passed.' )
end

local filename = (arg or { ... })[0]
if filename and filename:match( 'test_meta.lua$' ) then
  M.run()
end

return M
