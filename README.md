# Visualization of LQCD

- 2025/01/11
- A. Tomiya akio@yukawa.kyoto-u.ac.jp 



<img src="plaquette_3D_contour_animation24242432beta6.0.gif" alt="QCD vacuum" width="400">



# Introduction

This code set visualizes a configuration of lattice gauge theory with ildg format. This is written in Julia language. This contains configuration generation through [JuliaQCD](https://github.com/JuliaQCD).

The temporal extent is regarded as the *real time* direction. An iso-surface of the plaquette (field strength) are plotted.



# How to use

This uses [Julia](https://julialang.org/downloads/).

## Install
Please install all packages in ``install_packages.jl.``
Please execute julia install_packages.jl'' then they are installed.



## Visualization from an existing configuration

1. Set parameters in ``constants.jl`` (size and the name of the configuration)

2. Use ``visualization.jl``

   

## Visualization from an existing configuration

1. Set parameters in ``constants.jl`` (size and the name of the configuration)
2. Execute configuration_generation.jl (it takes time)
3. Use ``visualization.jl``



# Files

```
README.md : This file 
Conf24242432beta6.0.ildg : A sample configuration (SU(3) quenched, Wilson plaquette)
configuration_generation.jl : Configuration generation with the heatbath algorithm
constants.jl : constants are defined
header.jl : packages 
install_packages.jl : package installer
plaquette_3D_contour_animation24242432beta6.0.mp4 : sample video
plaquette_3D_contour_animation24242432beta6.0.gif : sample video
visualization.jl : A code for visulalization
```



# Note

- This package is inspired by [very nice visualization of QCD configurations](http://www.physics.adelaide.edu.au/theory/staff/leinweber/VisualQCD/Nobel/) by Derek B. Leinweber.
- Please mention this code set/video if you use in a presentation or paper.
- Pease feel free to contribute to this package.

