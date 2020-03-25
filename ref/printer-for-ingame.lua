local component = require("component")
local shell = require("shell")
local fs = require("filesystem")

local printer = component.printer3d
local args = shell.parse(...)

-- we re intelligent -> make big images from one command possible
-- a + = new file

file = fs.open(args[1], "rb")
if not file then
  io.write("No file named " .. args[1])
end


n = file:read(1)
while n do
  printer.reset()
  printer.setLabel(args[2])
  printer.setTooltip(args[3])
  printer.setLightLevel(15)
  printer.setRedstoneEmitter(false)
  printer.setButtonMode(false)
  
  while n and n~='+' do
    -- n is the next char
    x = tonumber(n, 16)
	y = file:read(1)
	l = file:read(1)
	y = tonumber(y, 16)
	l = tonumber(l, 16)+1
	printer.addShape(x, y, 15, x+1, y+l, 16, "opencomputers:White", false, tonumber(file:read(6), 16))
	n = file:read(1)
  end
  printer.commit(1)
  n = file:read(1)
end