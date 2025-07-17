local is_windows = package.config:sub( 1, 1 ) == '\\'
local function list_files( dir )
  local files = {}
  local command
  if is_windows then
    command = 'dir "' .. dir .. '" /b /a-d'
  else
    command = 'ls -p "' .. dir .. '"'
  end

  local p = io.popen( command )
  if not p then
    error( 'Failed to run command: ' .. command )
  end

  for filename in p:lines() do
    if is_windows or filename:sub( -1 ) ~= '/' then
      files[#files+1] = filename
    end
  end
  p:close()
  return files
end

local function list_dirs( dir )
  local dirs = {}
  local command = is_windows
    and ('dir "' .. dir .. '" /b /ad')
    or ('ls -p "' .. dir .. '"')

  local p = io.popen( command )
  if not p then error( 'failed to run command' ) end

  for name in p:lines() do
    if is_windows then
      dirs[#dirs+1] = name
    elseif name:sub( -1 ) == '/' then
      dirs[#dirs+1] = name:sub( 1, -2 )
    end
  end
  p:close()
  return dirs
end

local function list_tests( dir, prefix )
  local tests = {}

  for _, file in ipairs( list_files( dir ) ) do
    if file:match( '^test_.*%.lua$' ) then
      tests[#tests+1] = prefix .. file:sub( 1, -5 )
    end
  end

  for _, subdir in ipairs( list_dirs( dir ) ) do
    local sub_tests = list_tests( dir .. '/' .. subdir, prefix .. subdir .. '.' )
    for _, v in ipairs( sub_tests ) do
      tests[#tests+1] = v
    end
  end

  return tests
end

local function run_test( mod )
  local ok, t = pcall( require, mod )
  if not ok then
    error( 'Failed to load ' .. mod .. ': ' .. tostring( t ), 2 )
  end
  if type( t.run ) == 'function' then
    t.run()
  else
    error( 'Test module ' .. mod .. ' has no run function' )
  end
end

local args = { ... }
local all_tests = list_tests( './tests', 'tests.' )
local to_run = {}
package.path = '../?.lua;' .. package.path
package.path = '../?/init.lua;' .. package.path

if #args == 0 then
  to_run = all_tests
else
  for _, pattern in ipairs( args ) do
    local matched = false
    for _, mod in ipairs( all_tests ) do
      if mod:match( pattern ) then
        to_run[#to_run+1] = mod
        matched = true
      end
    end
    if not matched then
      error( 'No test files matched pattern: ' .. pattern )
    end
  end
end

for _, mod in ipairs( to_run ) do
  print( 'running_test: ' .. mod )
  run_test( mod )
end

print( 'all_requested_tests_passed.' )
