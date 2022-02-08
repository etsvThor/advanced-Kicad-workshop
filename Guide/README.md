# Kicad advanced guide
By Rutger van Anrooij
## Intro
In this guide we will explore more advanced features that Kicad has to offer. 
The main feature that will be shown is the scripting interface which is included since kicad 5 by default. 
Al functions and datastructures of this Python API are given in <https://docs.kicad.org/doxygen-python/namespacepcbnew.html> which is helpful to open in a new tab and can be used for future reference. 
This guide is based on the documentation of Kicad <https://github.com/KiCad/kicad-doc/blob/master/src/pcbnew/pcbnew_python_scripting.adoc> and <https://www.youtube.com/watch?v=_zVJ96SdYrs&t=1152s&ab_channel=ContextualElectronics>.
The example project which we will be scripting is a WS2812B RGB LED clock powered by an ESP8266.
The main part where scripting can be very helpful is the placement of the 60 WS2812B LEDs. 
Futhermore, this guide also highlights some design considerations when using scripting within Kicad. 
## Schematic Notes 
Open the project `Kicad_workshop_volundr_clock.zip` given  with this guide, and use the unarchive function of Kicad. You can browse the schematic to view which components we will be using in our design. 
Some notes on the schematic: the design is made out of hierarchical sheets which has some advantages for scripting and using existing plugins. 
For instance a simple copy of a drawn layout can be copied with the duplicate shortcut (CTRL+D), however in this case the references and netnames are not updated.
For duplicating layouts where the refereces and netnames are updated we can use a scripts which need hierachical sheets to work.
> Duplicating layout scripts examples
> - <https://github.com/tlantela/KiCAD_layout_cloner/blob/master/layout_cloner.py>
> - <https://kicad.mmccoo.com/2017/02/01/replicating-pcbnew-new-for-arrayed-sheets/>
 
## Setup and first commands
After opening PCBnew the first step to start is to use the scripting console. 
When PCBnew is open you can start it by clicking on the console button or going to Tools -> Scripting console.
To use the module for PCBnew we need to import it first. To import the module use the code below(very basic Python programming skils could come in handy).
```python
from pcbnew import * 
```
Now we can start using the module. To interact with our layout we first need to tell to get the current open board files. 
```python
board=GetBoard()
```
The PCB only has one component imported so far the ESP8266 moduele which we will be moving with a command to a desired location.
We will be using the `GetFootprint()` function, which needs `'wxPoint' aPosition`, `'PCB_LAYER_ID' aActiveLayer` and `'bool' aVisibleOnly` as arguments.
So first save the position as a `wxPoint` which uses the internal Kicad reference of nanometers. 
We can use two methods to transform from mm to nm:`FromMM()` and `wxPointMM()` which coverses both x and y in one command. We will use the last one.
Our ESP8266 module is at coordinates (0,0) which is in the top left corner which is due to legacy conventions in coordinate systems.
In Kicad 6(which is still in development) the coordinate system can be changed to user preferences.
```python
esp8266pos=wxPointMM(0,0)   
```
To get the `LayerID` we will use the function `GetLayerID('wxString' aLayerName)` which takes the the layername given in the editor as argument. 
The last argument we just set as `True`, because our ESP8266 module is visible in the editor.
The footprint object can be saved so we can interact with it further.
Tying this all together gives the following command.
```python
esp8266=board.GetFootprint(esp8266pos,board.GetLayerID("F.Cu"),True)
```
We can now use the the footprint object to change the position to somewhere in the middle of the sheet.
```python
esp8266.SetPosition(wxPointMM(100,100))
```
Nothing changes after firing the command. To see the changes also apear in the editor. 
PCBnew must be given a sign that the display must be refreshed by running `Refresh()`
## Making the script
Now that you have some basic understanding of the scripting process we will now be making a script.
Some things you may have noticed is that if you typed the commands themself that there is no previous command button(like arrow up), but there is autocomple.
For the next part we will be using some for-loops to speed things up and really get scripting. To make this easier we will be using an external editor.
You can use your favorite editor. If you don't have one Notepad++ is a good choice.
- Make a file `place_leds.py` and save it in a path without spaces, so make the direcroy C://KicadScripts.
- Open it in the editor.
- Place the following code in the file.

```python
from pcbnew import * 
board=GetBoard()
esp8266pos=wxPointMM(100,100)   
esp8266=board.GetFootprint(esp8266pos,board.GetLayerID("F.Cu"),True)
esp8266.SetPosition(wxPointMM(50,50))
Refresh()
```

- Save the file.
- Save the PCB and close and open the Scripting console.
- Paste the following in the scripting console `exec(open("C://KicadScripts/place_leds.py").read())`
Now the ESP8266 should be moved to (50,50).

Till now we have only played with one footprint, now import all footprints onto the PCB with the button 'Update PCB with changes made to schematic (F8)'
Getting al the needed footprints by position is not very practical so we want to get them by reference with the function `FindFootprintByReference()`.

The below example places all the WS2812 LEDs in a circle with the correct orientation.
```python
import math #needed for sine/cosine
from pcbnew import * 
board=GetBoard()
circle_center=wxPointMM(50,50)
ledposition=wxPointMM(100,50)
angle=360/60
radius=50
for i in range(0,60):
    LED=board.FindFootprintByReference("D"+str(i+1))
    ledposition.x=circle_center.x+FromMM(radius*math.cos(math.radians(angle*i)))
    ledposition.y=circle_center.y-FromMM(radius*math.sin(math.radians(angle*i))) #minus because of coordinate system
    LED.SetPosition(ledposition)
    LED.SetOrientationDegrees(270+angle)
```
Ok, we have placed some LEDs. Now we want to be good Electrical Engineers and also place some decoupling capacitors at the LEDs.
This can be done in the same loop.
```python 
import math #needed for sine/cosine
from pcbnew import * 
board=GetBoard()     
circle_center=wxPointMM(50,50)
ledposition=wxPointMM(100,50)
capposition=wxPointMM(100,50)
angle=360/60
radius=50
radius_cap=5*sqrt(2)+3
angle_cap=45
for i in range(0,60):
    LED=board.FindFootprintByReference()("D"+str(i+1))
    ledposition.x=circle_center.x+FromMM(radius*math.cos(math.radians(angle*i)))
    ledposition.y=circle_center.y-FromMM(radius*math.sin(math.radians(angle*i))) #minus because of coordinate system
    LED.SetPosition(ledposition)
    LED.SetOrientationDegrees(270+angle)
    CAP=board.FindFootprintByReference("C"+str(i+1))
    capposition.x=ledposition.x+FromMM(radius_cap*math.cos(math.radians(angle*i+angle_cap))) 
    capposition.y=ledposition.y-FromMM(radius_cap*math.sin(math.radians(angle*i+angle_cap))) 
    CAP.SetPosition(cappositon) 
    CAP.SetOrientationDegrees(angle)
```
The final part of our script is to add tracks and vias to our layout.
For this we also need some information of the properties of vias and tracks. These properties are contained in netclasses. For this workshop we stick to the defaultclass.
The netclassptr object of the default class can be found by:
```python
defaultclass=board.GetDesignSettings().GetNetClasses().GetDefault()
```
Previously this was also possible via from the net itself because all new nets get the default netclass:
```python
class=net.GetNetClass()
```
However this is not yet fixed for the latest version of Kicad (6.01).

- This code shows how to make a track segment from a startpoint to an endpoint. 
```python
newtrack=PCB_TRACK(board) #create a trackobject
board.Add(newtrack) #add the track to our board
newtrack.SetNet(net) #set which net the track is
newtrack.SetStart(startpoint) #set startpoint
newtrack.SetEnd(endpoint) #set endpoint
newtrack.SetWidth(defaultclass.GetTrackWidth()) #set the trackwidth from the default netclass
newtrack.SetLayer(layerID) #set the layer from the LayerId the LayerId can be found by GetLayerID('layername')
```
- Adding a via to the board is similar but slightly different.
```python
via=PCB_VIA(board) #create new via
board.Add(via) #add via to board
via.SetNet(vianets) #set net of via
via.SetWidth(defaultclass.GetViaDiameter()) #set the width of the via from the default netclass
via.SetPosition(viapoint) #set the postion of the via through a point
via.SetViaType(VIATYPE_THROUGH) #set viatype 
via.SetLayerPair(0,31)#set layerpair by layerid 0=top and 31=bottom GetLayerID() can also be used
```
Try to finish the script by yourself by adding:
1. A track between the capacitor and the +5V pin of the WS2812B.
2. A track between the DOUT pin of the current WS2812B and DIN pin of the next WS2812B
3. A via close to the GND pin of the capacitor.
4. A track between the GND pin of the cap and the via. 
5. (optional) Change variables to the layout better.

Tip: to get the pad from a footprint the function `FindPadByNumber()` can be used and to get the position of a pad the `GetCenter()` function can be used.
Not all information is given and there are more ways to achieve this result. 
The API reference can be used to look for the missing information.

If you are stuck you can look at the final script in the Scripts folder.

# Using action plugins

Action plugins are small script that can be used within pcbnew to speed up some actions or to extend pcbnew's functionality.
For instance pcbnew does not have capabilities to import custom copper fils by DXF. So we will use an external plugin to do this.

An Openscad script `copper_fills.scad` is used to generate the copper fill geometry. Due to the limitations on how the copper fill is generated, the outer ring needs a small gap.
The action plugin is located in the project folder as `dxf_zone` folder to install it copy it to the Plugins Folder.
The location of this folder can be found in pcbnew by Tools -> External Plugins -> Open Plugin Directory.
After copying it in the folder the plugin should show up in: 

Tools -> External Plugins -> Convert a DXF to a zone (after clicking refresh plugins in the same menu)

The needed DXF files are in the DXF folder of the project.
Try to get them onto the pcb layout.

Other usefull plugins are: Place Footprints(this can also be used to make a circle of components), replicate layout(to copy with changed referencing), Kikit(for easy penalization), pcb-action tools(this has a lot of action plugins).
These can all be installed via the Plugin and Content Manager. The shortcut for this is located at the kicad startscreen.

# Conclusion
This is the end of the workshop. Al other parts are of the pcb layout are probably not worth spending time on to script and can be routed by hand more easily.
Scripting can be a very powerful tool in the right situation and can make your life easier if done right.
If you want to know more about Kicad scripting and using Plugins, you can check the appendix for some interesting examples and projects.  

## Appendix
### Further reading
- Kicad can also be used as a simulator, but this is not as functional out-of-the-box yet compared to non-free simulators such as Multisim.
- Schematics can also be made in a code style fashion by using a Python library <https://github.com/xesscorp/skidl>(very usefull for large number of copies of a (sub)circuit)
- Producing fabricating outputs as wel as schematic prints can also be scripted. 
KiPlot<https://github.com/johnbeard/kiplot> for generating gerbers and Kicad Automations Tool<https://github.com/obra/kicad-tools> for outputing everything.  
- The DXFZonePlugin is made to work with kicad 5.1.x and adapted from <https://github.com/mmccoo/kicad_mmccoo> which only support earlier versions of pcbnew,
more plugins can be found here <https://github.com/MitjaNemec/Kicad_action_plugins>
