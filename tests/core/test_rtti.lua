local rtti = require( 'core.rtti' )
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

local function test_has_rtti()
  assert( rtti.has_rtti( Duck ) == true,
          'Duck has RTTI.' )
  assert( rtti.has_rtti( donald ) == true,
          'donald has RTTI.' )
  assert( rtti.has_rtti( {} ) == false,
          'Normal table has not RTTI.' )
end

local function test_typeof()
  assert( rtti.typeof( Duck ) == Duck,
          'For types, typeof returns itself.' )
  assert( rtti.typeof( donald ) == Duck,
          'For instances, typeof returns its type.' )
  assert( rtti.typeof( {} ) == nil,
          'For normal tables, typeof returns nil.' )
end

local function test_metaof()
  assert( rtti.metaof( Duck ) == getmetatable( Duck ),
          'For types, metaof returns its metatable.' )
  assert( rtti.metaof( donald ) == getmetatable( Duck ),
          'For instances, metaof returns the metatable of its type.' )
  assert( rtti.metaof( {} ) == nil,
          'For normal tables, metaof returns nil.' )
end

local function test_typeid()
  local typeinfo_from_type = rtti.typeid( Duck )
  assert( typeinfo_from_type ~= nil and typeinfo_from_type.metatype == 'class',
          'For types, typeid returns its RTTI table.' )
  local typeinfo_from_instance = rtti.typeid( donald )
  assert( typeinfo_from_instance ~= nil and typeinfo_from_instance.metatype == 'class',
          'For instances, typeid returns the RTTI table of its type.' )
  assert( rtti.typeid( {} ) == nil,
          'For normal tables, typeid returns nil.' )
end

local function test_metaname()
  assert( type( rtti.metaname( Duck ) ) == 'string',
          'For types, metaname returns its name of meta type.' )
  assert( type( rtti.metaname( donald ) ) == 'string',
          'For instances, metaname returns the name of meta type of its type.' )
  assert( type( rtti.metaname( {} ) ) == 'string'
          and rtti.metaname( {} ) == '',
          'For normal tables, metaname returns an empty string.' )
end

local function test_is_type()
  assert( rtti.is_type( Duck ) == true,
          'Duck is a type.' )
  assert( rtti.is_type( donald ) == false,
          'donald is not a type.' )
  assert( rtti.is_type( {} ) == false,
          'Normal table is not a type.' )
end

local function test_is_object()
  assert( rtti.is_object( Duck ) == false,
          'Duck is not a object.' )
  assert( rtti.is_object( donald ) == true,
          'donald is a object.' )
  assert( rtti.is_object( {} ) == false,
          'Normal table is not a object.' )
end

function M.run()
  test_has_rtti()
  test_typeof()
  test_metaof()
  test_typeid()
  test_metaname()
  test_is_type()
  test_is_object()
  print( 'rtti tests all passed.' )
end

local filename = (arg or { ... })[0]
if filename and filename:match( 'test_rtti.lua$' ) then
  M.run()
end

return M
