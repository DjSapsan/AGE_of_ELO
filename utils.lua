local utils = {}

utils.extractDate = function(filename)
  -- Pattern to match the date in the filename
  local pattern = "(%d%d%d%d)%-(%d%d)%-(%d%d)"

  -- Find the year, month, and day in the filename
  local year, month, day = filename:match(pattern)

  if year and month and day then
    -- Convert these strings to numbers
    year, month, day = tonumber(year), tonumber(month), tonumber(day)

    -- Create a table in the format os.time expects
    local dateTable = {
      year = year,
      month = month,
      day = day,
      hour = 0,
      min = 0,
      sec = 0
    }

    -- Return the os.time representation of this date
    return os.time(dateTable)
  end
  return 0
end

-- probably unsafe for tables with loops
local deepCopy
deepCopy = function(orig)
  local copy = {}
  for orig_key, orig_value in next, orig, nil do
      if type(orig_value) == 'table' then
          copy[orig_key] = deepCopy(orig_value)
      else
          copy[orig_key] = orig_value
      end
  end
  return copy
end
utils.deepCopy = deepCopy

local want
want = function (name)
  local out; if xpcall(
      function()  out = require(name) end,
      function(e) out = e end)
  then return out          -- success
  else return nil, out end -- error
end
utils.want = want

return utils