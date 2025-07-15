local object    = require( 'core.object' )
local pool      = {}

--- @class ObjectPool<T> : Object
--- @field private prototype ICopyable
--- @field buffer T[]
pool.ObjectPool = object.class()

--- Produce initial objects in the pool.
--- @param prototype ICopyable
--- @param num integer @ The number of objects to produce initially.
--- @return self
function pool.ObjectPool:init( prototype, num )
  object.init_super( pool.ObjectPool, self )
  self.prototype = prototype:clone()
  self.buffer = {}
  return self:produce( num )
end

--- Create a new pool without initial objects.
--- @generic T
--- @param cls T
--- @param prototype ICopyable
--- @return T
function pool.ObjectPool.new( cls, prototype )
  return cls():init( prototype, 0 )
end

--- Create a new pool with initial objects.
--- @generic T
--- @param cls T
--- @param prototype ICopyable
--- @param num integer @ The number of objects to produce initially.
--- @return T
function pool.ObjectPool.new_with( cls, prototype, num )
  return cls():init( prototype, num )
end

--- Get current pool size
--- @return integer
function pool.ObjectPool:size()
  return #self.buffer
end

--- Produce additional objects in the pool.
--- @generic T
--- @param num integer @ The number of objects to add.
--- @return self
function pool.ObjectPool:produce( num )
  for _ = 1, num do
    self.buffer[#self.buffer+1] = self.prototype:clone()
  end
  return self
end

--- Load specified number of objects from the pool.
--- @generic T
--- @param num integer @ The number of objects to load.
--- @return T[]
function pool.ObjectPool:load( num )
  num = math.max( 0, num )
  if num > #self.buffer then self:produce( num - #self.buffer ) end
  local ret = {}
  local starting = #self.buffer - num + 1
  for i = starting, #self.buffer do
    ret[i - starting + 1] = self.buffer[i]
    self.buffer[i] = nil
  end
  return ret
end

--- Pop one object from the pool, or create new if empty.
--- @generic T
--- @return T
function pool.ObjectPool:pop()
  if #self.buffer == 0 then
    return self.prototype:clone()
  end
  local ret = self.buffer[#self.buffer]
  self.buffer[#self.buffer] = nil
  return ret
end

--- Store a list of objects back into the pool.
--- @generic T
--- @param list T[]
--- @return self
function pool.ObjectPool:store( list )
  for i = 1, #list do
    self.buffer[#self.buffer+1] = list[i]
    list[i] = nil
  end
  return self
end

--- Push one object back into the pool.
--- @generic T
--- @param obj T
--- @return self
function pool.ObjectPool:push( obj )
  self.buffer[#self.buffer+1] = obj
  return self
end

--- Remove a specific object from the pool if present.
--- @generic T
--- @param obj T
--- @return T | nil
function pool.ObjectPool:remove( obj )
  for i = 1, #self.buffer do
    if self.buffer[i] == obj then
      return table.remove( self.buffer, i )
    end
  end
  return nil
end

--- Clear all objects from the pool.
--- @return nil
function pool.ObjectPool:clear()
  self.buffer = {}
end

return pool
