# Image to 3DM 
This project is in 2 parts:
- A java program that serialises images to a compatible format
- A Lua program that converts the serialised images to a collection of buffer 3DM files, executes print3d on each of them sequentially and then removes them. 

The standard config for OpenComputers 3d printing now is 256 shapes per block. This means that unlike previously, there is no need to "optimise out" similar images with sharpening or colour depth reduction. 





See the demo video: TODO

## Features
- Import PNG or JPEG files
- Specify size in blocks 
- Transparency supported (PNG only) 
- Printed blocks have labelled coordinates in-image
- Includes serialization multiplexing  (java+lua) and segmented file IO (lua)

## How to use


## TODO
Java more commandline arg support
- add option to apply on file 
- or option to apply on many files
- BufferedImage- do not render partially transparent pixels (if red blue or green == 0)
- Option to not render partially transparent pixels (See below)

Lua more commandline arg support
- option to debug not print files just generate in folder
Demo video





- Option to not render partially transparent pixels (See below) PREMULTIPLIED ALPHA

## Known issues
Holo inventory: Use an AE2 drive to store the output. Chests that contain a certain number of 3D printed items exceeding a cap will cause a Holoinventory server kick for invalid render. AE2 does not use holoinventory so it is safe. 

Framerate drops when printing: 3D printer calls its animation model update too frequently

Framerate drops when nearby block updates occur: Due to the on/off redstone render state of 3D printed blocks, even when they are not active they perform render updates. 

## Examples


## Partial transparent render issue


## References
- Opencomputers source code https://github.com/MightyPirates/OpenComputers
- https://github.com/OpenPrograms/Sangar-Programs/blob/master/models/example.3dm
- https://ocdoc.cil.li/api:filesystem
- https://ocdoc.cil.li/block:3d_printer
- https://www.youtube.com/watch?v=1AR8TVdyUWM 
- https://stackoverflow.com/questions/1426954/split-string-in-lua
- https://oc.cil.li/topic/1364-too-long-without-yielding-in-robot-farming-loop/
- https://www.reddit.com/r/feedthebeast/comments/5s64xa/opencomputers_too_long_without_yielding_error/
- https://stackoverflow.com/questions/23457754/how-to-flip-bufferedimage-in-java

