local meta = require( 'core.meta' )
local M = {}

local function test_metaclassof()
  local cls = meta.class( 'TestClass', {}, meta.Type )
  local mc = meta.metaclassof( cls )
  assert( mc == meta.Type,
          'metaclassof returns meta.Type' )
end

local function test_mroof()
  local A = meta.class( 'A', {}, meta.Type )
  local B = meta.class( 'B', { A }, meta.Type )
  local C = meta.class( 'C', { A }, meta.Type )
  local D = meta.class( 'D', { B, C }, meta.Type )

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
  local A = meta.class( 'A', {}, meta.Type )
  local B = meta.class( 'B', { A }, meta.Type )
  local C = meta.class( 'C', {}, meta.Type )

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
  local A = meta.class( 'A', {}, meta.Type )
  local B = meta.class( 'B', { A }, meta.Type )
  local b_inst = B()
  local s = meta.super( b_inst )
  assert( s == A,
          'super returns base class' )
end

local function test_c3()
  local A = meta.class( 'A', {}, meta.Type )
  A.foo = 'foo'
  local B = meta.class( 'B', { A }, meta.Type )
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
  local M1 = meta.extend()
  function M1:_init( ns, req )
    ns.conflict = 'm1'
    return ns
  end

  local M2 = meta.extend()
  function M2:_init( ns, req )
    ns.conflict = 'm2'
    return ns
  end

  local C1 = meta.class( 'C1', {}, M1 )
  local C2 = meta.class( 'C2', {}, M2 )

  local ok, err = pcall( function()
    meta.class( 'Conflict', { C1, C2 } )
  end )
  assert( not ok and err ~= nil and err:match( 'conflicting metaclasses' ),
          'class detects conflicting metaclasses' )
end

function M.run()
  test_metaclassof()
  test_mroof()
  test_is_base_of()
  test_super()
  test_c3()
  test_class_conflict()
  print( 'meta tests all passed.' )
end

local filename = (arg or { ... })[0]
if filename and filename:match( 'test_meta.lua$' ) then
  M.run()
end

return M
