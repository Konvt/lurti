local panic = {}

--- @package
panic.errors = {
  TYPE_ERROR = 'Type error',
  MISSING_OVERRIDE = 'Attempt to call an unimplemented method',
  FIELD_CONFLICT = 'Field conflict',
  FATAL_ERROR = 'Fatal error',
}

panic.KIND = {}
for k in pairs( panic.errors ) do
  panic.KIND[k] = k
end
--- Raise a panic error with a specific kind and optional messages.
--- @param kind string
--- @param ... string @ Additional context messages appended to the error.
function panic.raise( kind, ... )
  local msg = panic.errors[kind]
  if not msg then
    error( '[panic] Unknown kind: ' .. tostring( kind ), 2 )
  end
  local extra = table.concat( { ... }, ' ' )
  error( '[panic] ' .. msg .. (extra ~= '' and (': ' .. extra) or ''), 2 )
end

return panic
