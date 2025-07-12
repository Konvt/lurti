local utility = {}

--- @param orig any
--- @return any
function utility.shallowcopy( orig )
  if type( orig ) ~= 'table' then return orig end
  local copy = {}
  for k, v in pairs( orig ) do
    copy[k] = v
  end
  return copy
end

--- @generic T
--- @param orig T
--- @param cache? table
--- @return T
function utility.deepcopy( orig, cache )
  if type( orig ) ~= 'table' then return orig end
  cache = cache or {}
  if cache[orig] then
    return cache[orig]
  end

  local copy = {}
  cache[orig] = copy
  for k, v in pairs( orig ) do
    copy[utility.deepcopy( k, cache )] = utility.deepcopy( v, cache )
  end
  -- metatable is used as type info and it is unique.
  setmetatable( copy, getmetatable( orig ) )
  return copy
end

return utility
