			-- Project diva F2nd like shader for MMD --
		MMD shader written to replicate the look of Project diva F2nd 
		Written in HLSL, requires at least shader model 3.0
			
		How to use : 
			- Load the models you need in MMD
			- Load f2nd.x
			- Load Controller.pmx (its in the same folder as f2nd.x
			- In the tab called "mainShader", subset extract and load nose.fx on the nose material
			- In the tab called "glowShader", load glowON.fx on the material you want to glow
		How set up model : 
			- Load the model in PMX editor and put the Specular texture in the SPA slot.
			- Put the Curve texture in the toon slot

		The controller has sliders for increasing/decreasing the gamma, decreasing the saturation, and increasing/decreasing the glow as well as sliders for controlling the materials stuff. A note, the saturation slider can also be used to increase the saturation by writing in a negative number. 
			