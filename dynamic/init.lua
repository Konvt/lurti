--- @param mod_name string
--- @param modules table<string, string>
local function include( mod_name, modules )
  local prefix = mod_name .. '.'
  return setmetatable( {}, {
    __index = function( tbl, key )
      local ok, mod = pcall( require, prefix .. modules[key] )
      if not ok then error( 'module "' .. prefix .. modules[key] .. '" not found in ' .. mod_name ) end
      tbl[key] = mod
      return mod
    end,
  } )
end

return {
  core = include(
    'core',
    {
      panic = 'panic',
      rtti = 'rtti',
      meta = 'meta',
      abc = 'abc',
      result = 'result',
      extension = 'extension',
      utility = 'utility',
    } ),
  collections = include(
    'collections',
    {
      pool = 'pool',
    } ),
}
