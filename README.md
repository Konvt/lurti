# Lua Runtime Type Infomation
**Lurti** is a class library for Lua that, in conjunction with LSP type annotations, builds a type system similar to Python's at runtime, providing features such as meta classes, MRO support, abstract base classes/methods and class method declarations.

The core of Lurti's operation relies on runtime type information, which is implemented referenced from C++'s RTTI mechanism, and all of Lurti's meta-programming support is built upon this mechanism.

Other features include: method mixin support inspired by C# extension methods and recoverable error types modeled after Rust's Result.

> This is a personal experimental library.

# Usage
## Require Lurti
Lurti supports two types of requiring methods: dynamic and static (default).

In generals, you can introduce Lurti into your project in the following ways.

```lua
local lurti = require( 'path.to.lurti' ) -- it's equal to the following
local lurti = require( 'path.to.lurti.static' )

-- lazily import modules
local lurti = require( 'path.to.lurti.dynamic' )
```

## Define a class
```lua
local lurti = require( 'path.to.lurti' )
local meta = lurti.core.meta

--- @class Dog : Object @ By default, it is derived from Object.
--- @field name string
local Dog = meta.class()

--- @param name string
--- @return self
function Dog:init( name ) -- an override
  meta.init_super( Dog, self )
  self.name = name
  return self
end

function Dog:bark()
  print( self.name .. ' is barking' )
end

local doggy = Dog:new( 'Buddy' ) -- Construct and initialize a new object
doggy:bark()

-- or
local empty_doggy = Dog() -- Construct an empty object
empty_doggy:init( 'Zoe' ) -- Then initialize it.
empty_doggy:bark()
```

## Multiple inheritance
Lurti uses MRO to handle multiple inheritance relationships, so its usage methods and behaviors are basically the same as those of Python.

```lua
local lurti = require( 'path.to.lurti' )
local meta = lurti.core.meta

local A = meta.class()
function A:init()
  meta.init_super( A, self )
  print( 'A' )
end

local B = meta.class( A )
function B:init()
  meta.init_super( B, self )
  print( 'B' )
end


local C = meta.class( A )
function C:init()
  meta.init_super( C, self )
  print( 'C' )
end


local D = meta.class( { B, C } )
function D:init()
  meta.init_super( D, self )
  print( 'D' )
end

local object_d = D:new()
--- Expected output sequence:
--- A C B D

--- Get the super class in MRO with `super()` in lurti.core.meta
assert( B == lurti.core.meta.super( object_d ) )
```

## Class constructor
Lurti provides the following construction methods by default:

```lua
local lurti = require( 'path.to.lurti' )
local meta = lurti.core.meta

--- Construct an emtpy object:
local obj = meta.Object()

--- Initialize an existing object
obj:init()

--- Construct and initialize an object:
local onestep = meta.Object:new()
```

Normally, types derived from `Object` only need to provide an override of the `init()` function and call `meta.init_super()` within `init()` to initialize the base class.

```lua
--- @class Cat : Object
--- @field name string
local Cat = meta.class()

--- @param name string
--- @return self
function Cat:init( name )
  meta.init_super( Cat, self )
  self.name = name
  return self
end
```

When using the `new()` inherited from object, since LSP is not so intelligent, the prompt for the function parameter list is not very friendly.

At this point, you can explicitly provide a rewrite of `new()`.

```lua
--- @generic T
--- @param cls T
--- @param name string
--- @return T
function Cat.new( cls, name ) -- Please note: The new() should be a class method
  return cls():init( name ) -- or:
  -- return meta.Object:new( name )
end

--- If you don't mind the performance overhead, then you can use the meta.classMethod() decorator
--- to mark the new() as a classmethod.
---
--- In this way, even if the method is called on an instance object,
--- it can be correctly called as the type itself.
meta.classmethod( Cat, 'new' )

--- If you attempt to bind a non-existent function, an error will be triggered.
--- Therefore, you should mark a function as a class method after defining it.
```

Function that construct empty objects do not support overriding unless another metaclass is explicitly specified during inheritance.

## Meta class
Like Python, Lurti's subtype system is built on top of the metaclass `lurti.core.meta.Type`.

Its usage is the same as in Python. For creating a new metaclass, you can refer to the implementation of `ABCMeta` in `lurti.core.abc` or the implementation of `EnumMeta` in `lurti.core.enum`.

## Define abstract classes/methods
An abstract base class can be created using the metaclass `lurti.core.abc.ABCMeta`, but just like in python: if all the abstract methods of an abstract base class are implemented, then the abstract base class itself can also be instantiated.

```lua
local lurti = require( 'path.to.lurti' )
local object = lurti.core.object
local abc = lurti.core.abc

--- @class IFlyable
local IFlyable = meta.class( nil, abc.ABCMeta )

assert( abc.is_abstract( IFlyable ) == false )

abc.abstract( IFlyable, 'fly' )

assert( abc.is_abstract( IFlyable ) == true )
```

For types inherited from abstract base classes, during their creation process, `lurti.core.abc.ABCMeta` will reverse the MRO to collect all unimplemented abstract methods and check for any unimplemented abstract methods during the type instantiation process.

You cannot mark abstract methods to a non-abstract base class

If so, an error will be triggered.

```lua
--- @class NormalClass
local NormalClass = meta.class()

local ok, err = pcall( function()
  abc.abstract( NormalClass, 'dosomething' )
end )
assert( ok == false )
```

## Mixin methods
At certain times, if you need to mix new methods into a type, you can use `lurti.core.extension.mixin()`.

The functional implementation of this module is based on the extension methods of C#.

Just like C#, `lurti.core.extension.mixin()` follows the following principles when mixing methods:

1. An error will be triggered when a field with the same name is repeatedly mixed in;
2. Fields of the type itself (including those obtained through inheritance) always take precedence over those that have been mixed in.

The latter is achieved by overwriting the `__index` of the type itself, so the blending process itself will introduce an additional tiny amount of runtime overhead (approximately several hundred nanoseconds).

If you do not want to introduce these overheads, you can manually mix fields into the instance object yourself instead of into the type itself.

## Meta-programming
In the modules `lurti.core.meta` and `lurti.core.rtti`, many meta-methods for reflecting the runtime type system itself are provided, including: obtaining instance types, checking whether an identifier is a type/object, and checking whether a lua object conforms to the RTTI layout, etc.

For more information, you can directly refer to the corresponding file.

## Raise an irrecoverable error
Use the function `raise` in `lurti.core.panic`.

```lua
local lurti = require( 'path.to.lurti' )

lurti.core.panic.raise( lurti.core.panic.KIND.FATAL_ERROR, 'a fatal error occurred' )
```

This function will call the `error()` of lua and position the call stack at the caller's location (that is, where the `raise()` is called).

## Return a recoverable error
Use the type `Result` in `lurti.core.result`.

It's as same as the `Result` in rust.

## Run Tests
There are several basic unit tests in `test/`, and you can run all the test cases at once through the command `lua tests/run.lua`.

Or use `lua tests/test_*.lua` to run a test case alone.

You can also use `lua tests/run.lua xxx` to run the test files with the name `xxx` in `tests/`.

The `xxx` here is a Lua pattern string used to match test module names.

For example, using `math` will run all tests with `math` anywhere in their module name, and `^tests%.sub` will run all tests in the `tests.sub` submodule.

Patterns support Lua's basic pattern syntax for flexible matching.

# LICENSE
This project is licensed under the [MIT license](./LICENSE).
