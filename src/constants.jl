# - A. Tomiya 2025/01/11

# Parameters
NX = 24
NY = 24
NZ = 24 
NT = 32 # Time direction
β = 6.0
NC = 3

# the number of gradient flow steps in configuration generation
flow_steps_in = 200 

confname = "Conf$(NX)$(NY)$(NZ)$(NT)beta$(β).ildg";
videoname = "plaquette_3D_contour_animation$(NX)$(NY)$(NZ)$(NT)beta$(β).mp4";
