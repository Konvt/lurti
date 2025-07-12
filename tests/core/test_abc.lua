local abc = require( 'core.abc' )
local object = require( 'core.object' )
local M = {}

function M.test_ABCMeta_init()
  local cls = object.class( nil, abc.ABCMeta )
  assert( type( rawget( cls, '__abstract__' ) ) == 'table',
          'ABCMeta sets __abstract__' )
end

function M.test_abstract_mark()
  local C = object.class( nil, abc.ABCMeta )
  abc.abstract( C, 'foo' )
  assert( C.__abstract__.foo == C, 'abstract marks method' )
  abc.abstract( C, { 'bar', 'baz' } )
  assert( C.__abstract__.bar == C and C.__abstract__.baz == C,
          'abstract marks multiple methods' )
end

function M.test_is_abstract_false()
  local C = object.class()
  assert( abc.is_abstract( C ) == false,
          'is_abstract detects concrete without ABCMeta' )
  local D = object.class( nil, abc.ABCMeta )
  assert( abc.is_abstract( D ) == false,
          'is_abstract detects concrete with ABCMeta but no abstract methods' )
end

function M.test_is_abstract_true()
  local C = object.class( nil, abc.ABCMeta )
  abc.abstract( C, 'foo' )
  abc.foo = function() end -- ignored
  assert( abc.is_abstract( C ) == true,
          'is_abstract detects abstract' )
  local D = object.class( C )
  assert( abc.is_abstract( D ) == true,
          'is_abstract detects abstract' )
  D.foo = 114 -- non-functional value
  assert( abc.is_abstract( D ) == true,
          'is_abstract detects abstract' )

  D.foo = function() end
  assert( abc.is_abstract( D ) == false,
          'is_abstract detects implemented method' )
end

function M.test_abstract_on_non_abstract()
  local C = object.class()
  local ok, err = pcall( function() abc.abstract( C, 'foo' ) end )
  assert( not ok and err ~= nil and err:match( 'non%-abstract base classes' ),
          'abstract raises on non-abstract base class' )
end

function M.test_abstract_instantiation()
  local C = object.class( nil, abc.ABCMeta )
  abc.abstract( C, 'foo' )
  local ok, err = pcall( function() abc.ABCMeta._instantiate( C ) end )
  assert( not ok and err ~= nil and err:match( 'abstract class' ),
          'abstract prevents instantiation' )
end

function M.test_ICopyable_methods()
  local inst = abc.ICopyable()
  assert( type( inst.deepcopy ) == 'function',
          'ICopyable has deepcopy' )
  assert( type( inst.shallowcopy ) == 'function',
          'ICopyable has shallow copy' )
end

function M.run()
  M.test_ABCMeta_init()
  M.test_abstract_mark()
  M.test_is_abstract_false()
  M.test_is_abstract_true()
  M.test_abstract_on_non_abstract()
  M.test_abstract_instantiation()
  M.test_ICopyable_methods()
  print( 'abc tests all passed.' )
end

local filename = (arg or { ... })[0]
if filename and filename:match( 'test_abc.lua$' ) then
  M.run()
end

return M
