# Visualization of QCD vacuum

- 2025/01/11
- A. Tomiya akio@yukawa.kyoto-u.ac.jp 

<img src="plaquette_3D_contour_animation24242432beta6.0.gif" alt="QCD vacuum" width="420">

[Another example (Youtube)](http://youtube.com/shorts/nscMhDamzfg)

# Introduction

This code set visualizes a configuration in **ILDG** format. This is written in Julia language. This contains configuration generation through [JuliaQCD](https://github.com/JuliaQCD).

The fourth lattice direction is shown as a sequence of Euclidean slices; it is not treated as real-time evolution. By default, the package renders local action-density blobs inspired by the VisualQCD / QCD Lava Lamp style. The older plaquette log iso-surface renderer is still available as a legacy mode.

# How to use

This uses [Julia](https://julialang.org/).
Please down load it from [here](https://julialang.org/downloads/).

## Install
In REPL, press ] key. 
```
add VisualizingLQCD.jl
```
If there are some problems, it might be better to use 
```
activate .
```
This means you can use clean environment. 

## Visualization from an existing configuration

```julia
using VisualizingLQCD
function main()
    NX = 24
    NY = 24
    NZ = 24
    NT = 32 # Euclidean fourth direction
    β = 6.0
    NC = 3

    confname = "Conf$(NX)$(NY)$(NZ)$(NT)beta$(β).ildg"
    videoname = "plaquette_3D_contour_animation$(NX)$(NY)$(NZ)$(NT)beta$(β).mp4"

    # Default: local action-density blob visualization
    create_animation(NX, NY, NZ, NT, NC, videoname; beta=β, filename=confname)
end
main()
```

One can use a sample [configuration file](https://www.dropbox.com/scl/fi/ujkmaeszcm33gku7kl67v/Conf24242432beta6.0.ildg?rlkey=4fyzg3krxsy7azlcjgl68nvsm&dl=0) (ILDG file).

To reproduce the older plaquette log iso-surface style, select the legacy mode explicitly:

```julia
create_animation(
    NX, NY, NZ, NT, NC, videoname;
    beta=β,
    filename=confname,
    level_target=VisualizingLQCD.LEVEL_TARGET_LEGACY_NEGLOG_HIGH,
    render_style=VisualizingLQCD.RENDER_STYLE_CURRENT,
)
```

To rotate the camera during the movie, use `camera_motion=:orbit`. By default,
one orbit follows the timing of the included rotated sample movie
(`640` frames at `14` fps, about `45.7` seconds). Orbit movies keep one
fourth-direction slice fixed by default, so the shape is not changed by the
slice sequence while the camera rotates. It also uses `viewmode=:fit` and
orthographic projection by default, avoiding the apparent zoom from Makie's
default `Axis3` fit-zoom behavior. Static movies keep the existing default
framerate; orbit movies use `14` fps unless `framerate` is passed explicitly.

```julia
create_animation(
    NX, NY, NZ, NT, NC, videoname;
    beta=β,
    filename=confname,
    camera_motion=VisualizingLQCD.CAMERA_MOTION_ORBIT,
    camera_orbit_turns=1,
)
```

To force a shorter or longer movie, pass `nloops` explicitly.
To rotate while stepping through fourth-direction slices, pass
`frame_mode=VisualizingLQCD.FRAME_MODE_SEQUENCE`.
Repeated action-density meshes are cached by slice by default; pass
`cache_render_slices=false` to disable this.

## Visualization from scratch

This takes time because of generation of a gauge configuration.

```julia
using VisualizingLQCD
function main()
    NX = 24
    NY = 24
    NZ = 24
    NT = 32 # Euclidean fourth direction
    β = 6.0
    NC = 3

    # the number of gradient flow steps in configuration generation
    flow_steps_in = 200

    confname = "Conf$(NX)$(NY)$(NZ)$(NT)beta$(β).ildg"
    videoname = "plaquette_3D_contour_animation$(NX)$(NY)$(NZ)$(NT)beta$(β).mp4"

    @time plaq_t = heatbathtest_4D(NX, NY, NZ, NT, β, NC, flow_steps_in, confname)
    # Default: local action-density blob visualization
    create_animation(NX, NY, NZ, NT, NC, videoname; beta=β, filename=confname)
end
main()
```

# Files

```
README.md : This file 
src
test
plaquette_3D_contour_animation24242432beta6.0.mp4 : sample video
plaquette_3D_contour_animation24242432beta6.0.gif : sample action-density blob video
```



# Note

- This package is inspired by [very nice visualization of QCD configurations](http://www.physics.adelaide.edu.au/theory/staff/leinweber/VisualQCD/Nobel/) by Derek B. Leinweber.
- Please mention this code set/video if you use in a presentation or paper.
- Similar package can be seen in [AnimateLQCD.jl](https://github.com/akio-tomiya/AnimateLQCD.jl).
- Pease feel free to contribute to this package.
