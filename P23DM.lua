local component = require("component")
local shell = require("shell")
local fs = require("filesystem")
local table = require("table")

local printer = component.printer3d
local args = shell.parse(...)



-- Use OPPM 3dm file buffering. 
-- Still need this file to multiplex from a single copy-paste. but this time, we
-- will be using buffer files and calling print3d to handle individual blocks.
-- hopefully that circumvents issues with the resolution too, since the reported max print size is 256.

-- setting the minimum pixel size for drawing
-- this can be changed - but both this and the partner program need to be! 
-- 
RESOLUTION_LIMIT = 16
STEP_SIZE = 16 / RESOLUTION_LIMIT


-- from https://stackoverflow.com/questions/1426954/split-string-in-lua
function split (inputstr, sep)
  if sep == nil then
    sep = "%s"    
  end
  local t={}
  for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
    table.insert(t, str)
  end
  return t
end

-- due to file nature... need to specify the number of bytes I want
-- so just shooting for a big number
-- (maxint is way too big lol)

BIGNUMBER = 965332123348274797826204144723168738177180919299881250404026184124858368
file = fs.open(args[1], "r")
if not file then
  io.write("No file named " .. args[1])
  os.exit()
end

-- construct list from file contents
-- unfortunately. the max string size is 2048. as we are dealing with images
-- over 2kB in size, we need to be more clever about how we split the string.
-- ie. this will not work: list = split(file:read(BIGNUMBER), ",")

-- decided to solve this by adding a metadata length character at the start to help. 
-- this implicitly enforces up to 9 digits across width and height... that's a big max size.
-- don't need to make any larger solution as essential max limit would be like 9999x99999 
-- far outside minecraft dimensions. 

metadataSize = file:read(1)
-- offset by 3 to account for commas. 
-- recently changed from 2 to 3 - see if fix last pixel not printing lissue
metadataString = file:read(metadataSize + 3)
metadata = split(metadataString, ",")
width = metadata[1] / RESOLUTION_LIMIT
height = metadata[2] / RESOLUTION_LIMIT
list = {}
repeat
  -- Speed up by reading up to lcm(7,256) entries at once.
  -- 7 is unit size (6 hex numbers and split character)
  -- 256 is size of one 16x16 image.
  next = file:read(1792)
  if next == nil or type(next) == "function" then break end
  -- Debug
  -- io.write("Next: " .. #next .. "\n")
  intermediate = split(next,",")
  for index, element in pairs(intermediate) do
    table.insert(list, element)
  end
until false

-- debug
io.write("Total pixels: " .. #list .. " width: " .. width .. " height: " .. height .. "\n")


-- the current working offsets
blockOffsetX = -1 -- just to offset for entering loop
blockOffsetY = 0
primitiveCount = 0

if(args[2] == nil) then
  label = "3D Print"
else
  label = args[2]
end
if(args[3] == nil) then
  tooltip = ""
else
  tooltip = args[3]
end



function formatShape(x, y, xmax, ymax, colour)
  if colour == nil then colour = 0 end
  out = "\t{ " 
    .. x .. ", " 
    .. y .. ", " 
    .. 15 .. ", "
    .. xmax .. ", "
    .. ymax .. ", " 
    .. 16 .. ", "
    .. "texture = \"opencomputers:White\", tint = 0x" .. colour .. " }"
 

  return out
end



-- use # to get the length of an item? crazy language lol 
for index=0, (width * height) - 1,1 do


  -- calculate stage of printing (which block of the multiblock image?)
  blockOffsetX = blockOffsetX + 1
  if blockOffsetX >= width then
    blockOffsetX = 0
    blockOffsetY = blockOffsetY + 1
  end

  -- set up file IO to save buffer to pass to print3d
  p3dFilename = "buffer-" .. blockOffsetX .. "-" .. blockOffsetY .. ".3dm"
  p3dFile = fs.open(p3dFilename, "w")

  -- start off with header of 3dm file
  p3dString = "{\n" .. "\tlabel = \"" .. label .. "\",\n"

  p3dString = p3dString .. "\ttooltip = \"" .. " X: " .. blockOffsetX .. " Y: " .. blockOffsetY 
    .. " " .. tooltip .. "\",\n"
  p3dString = p3dString .. "\tlightlevel = 0,\n"
  p3dString = p3dString .. "\temitRedstone = false,\n"
  p3dString = p3dString .. "\tbuttonMode = false,\n"
  p3dString = p3dString .. "\tshapes = {\n"

  p3dFile:write(p3dString)

  -- debug to check how many primitive calls per block
  primitiveCallsThisBlock = 0


  -- optimisation to reduce p3dFile:write() calls
  buffer = ""
  -- for each of the pixels in the image
  -- loop is inclusive of both ends!!
  for pixel=0, (RESOLUTION_LIMIT * RESOLUTION_LIMIT) - 1,1 do
    -- n is the next char
    x = (pixel % RESOLUTION_LIMIT) * STEP_SIZE
  	y = math.floor(pixel / RESOLUTION_LIMIT) * STEP_SIZE
    -- tricky part: need to multiplex the file from the original ordering
    -- file offset + (x local offset) + (y local offset)
    -- + block offset x and y (RESOLUTION_LIMIT for x, RESOLUTION_LIMIT^2*width for y)
    listIndex = 1
    + pixel % RESOLUTION_LIMIT
    + math.floor(pixel / RESOLUTION_LIMIT) * (width * RESOLUTION_LIMIT)
    + blockOffsetX * RESOLUTION_LIMIT
    + blockOffsetY * RESOLUTION_LIMIT * RESOLUTION_LIMIT * width



    -- now we add the shape for the 2x2x1 (x * y * z) pixel primitive
    -- using tonumber to convert from colour hex encoding to integer for addShape req

    -- don't print anything in this pixel if it is transparent (0 colour val)
    if(list[listIndex] ~= nil
      and tonumber(list[listIndex], 16) ~= 0 
      and list[listIndex] ~= "000000" 
      ) then
      -- if pixel ~= (RESOLUTION_LIMIT * RESOLUTION_LIMIT) - 1 then
      -- we need commas on the end of all elements except the last.
      -- equivalently, comma at the start of each element except the first.
      if primitiveCallsThisBlock ~= 0 then
        -- p3dFile:write(",")
        buffer = buffer .. ","
      end
      -- append to buffer
      buffer = buffer 
        .. formatShape(x, y, x+STEP_SIZE, y+STEP_SIZE, list[listIndex]) 
        .. "\n"

      -- if buffer is big enough, push to the file
      if #buffer > 1000 then
        p3dFile:write(buffer)
        buffer = ""
      end
      -- increment primitive counts
      primitiveCount = primitiveCount + 1
      primitiveCallsThisBlock = primitiveCallsThisBlock + 1
--[[
      io.write("pixel:" .. pixel .. " x: " .. x .. " y: " .. y .. 
        " accessing index " .. listIndex  .. "X: " .. blockOffsetX .. " Y: " .. blockOffsetY .. 
        " colour sent: " .. list[listIndex] .. "\n")
--]]
    end

    -- I guess I have to prevent 
    -- https://www.reddit.com/r/feedthebeast/comments/5s64xa/opencomputers_too_long_without_yielding_error/
    -- also see https://oc.cil.li/topic/1364-too-long-without-yielding-in-robot-farming-loop/
    -- by adding a wait
    os.sleep(0)
  end  


  -- buffer might be non empty so we are gonna empty it here
  p3dFile:write(buffer)
  buffer = ""
  io.write("Primitive calls for block " 
  .. blockOffsetX .. "," .. blockOffsetY .. ": " .. primitiveCallsThisBlock .. "\n")
  p3dFile:write("\t}\n}\n")


  io.close(p3dFile)
  -- os.exit()


  -- if the block was empty (possibly due to transparent segment) we don't print anything
  if primitiveCallsThisBlock > 0 then

    -- print the file
    os.execute("print3d /" .. p3dFilename)

    
  end
  -- clean up the buffer file
  os.execute("rm /" .. p3dFilename)

end


-- debug
io.write("Called draw primitive a total of " .. primitiveCount .. " times.\n\n")
