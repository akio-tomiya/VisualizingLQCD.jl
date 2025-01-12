include("header.jl")
include("constants.jl")

# - A. Tomiya 2025/01/11

function automatic_level2(plaqs_t)
    min_val = minimum(plaqs_t)
    max_val = maximum(plaqs_t)
    mean_val = mean(plaqs_t)
    mode_val = mode(plaqs_t)
    println("mean=$mean_val, mode=$mode_val, min=$min_val, max=$max_val")
    level = mean_val
    isorange = std(plaqs_t)
    println("$level $isorange")
    return level,isorange,min_val,max_val
end

GLMakie.activate!()
# set constants
const LtoSec = 10/3
const myxlabel = L"$x$ [fm]"
const myylabel = L"$y$ [fm]"
const myzlabel = L"$z$ [fm]"
const r_0 = 0.48

# hep-lat/9806005
function ln_a(beta::Float64)::Float64
    if beta < 5.7 || beta > 6.57
        throw(ArgumentError("Beta should be in the range [5.7, 6.57]"))
    end
    delta_beta = beta - 6
    return -1.6805 - 1.7139*delta_beta + 0.8155*delta_beta^2 - 0.6667*delta_beta^3
end

function calculate_a(beta::Float64)::Float64
    return r_0 * exp(ln_a(beta))
end

function create_animation(NX, NY, NZ, NT, NC; beta=6.1, filename="conf_00000100.ildg")
    Nwing = 1
    a = calculate_a(beta)
    scale_factor = a

    U1 = Initialize_Gaugefields(NC, Nwing, NX, NY, NZ, NT, condition="cold")
    ildg = ILDG(filename)
    load_gaugefield!(U1, 1, ildg, [NX, NY, NZ, NT], NC)

    loop = [(1, +1), (2, +1), (1, -1), (2, -1)]
    w = Wilsonline(loop)
    Uloop = similar(U1[1])
    temps = [similar(U1[1]) for _ in 1:10]
    Gaugefields.evaluate_gaugelinks!(Uloop, w, U1, temps)

    # Calculating field strength using plaquette
    # In precise, we need 1/β
    plaqs_t = zeros(Float64, NX, NY, NZ, NT)
    for z in 1:NZ, y in 1:NY, x in 1:NX, t in 1:NT
        tmp = 1 - real(tr(Uloop[:, :, x, y, z, t]))/NC
        plaqs_t[x, y, z, t] = -log(tmp+0.0000001)
    end

    # show logarithm of histogram for plaquettes
    level, isorange, min_val, max_val = automatic_level2(plaqs_t)
    levels = [collect((level+isorange*1.2):0.05:max_val )...]

    #= To check iso-level, please use here
    hist_p = histogram(vec(plaqs_t))
    vline!(hist_p, levels)
    display(hist_p)
    =#
    
    # Set coordinate
    x_physical = (a, a * NX)  
    y_physical = (a, a * NY)  
    z_physical = (a, a * NZ)  
    
    fig = Figure(size=(800, 800))
    # label setting.
    x_positions = range(0, stop=a * NX, length=NX)
    x_labels = [string(round(x, digits=2)) for x in x_positions]

    y_positions = range(0, stop=a * NY, length=NY)
    y_labels = [string(round(y, digits=2)) for y in y_positions]

    z_positions = range(0, stop=a * NZ, length=NZ)
    z_labels = [string(round(z, digits=2)) for z in z_positions]

    for i in 1:2:length(x_labels)
        x_labels[i]=""
    end
    for i in 1:2:length(y_labels)
        y_labels[i]=""
    end
    for i in 1:2:length(z_labels)
        z_labels[i]=""
    end
    
    # Make Axis3
    ax = Axis3(fig[1, 1],
           xlabel=myxlabel, ylabel=myylabel, zlabel=myzlabel,
           title="3D Contour of Plaquette Values",
           xticks=(x_positions, x_labels),
           yticks=(y_positions, y_labels),
           zticks=(z_positions, z_labels), aspect = (1, 1, 1) )
    
    # Dummy plot 
    dummy_data = zeros(Float64, NX, NY, NZ)
    plot_obj = GLMakie.contour!(ax, x_physical, y_physical, z_physical, dummy_data;
                                levels=[levels[1]],
                                colormap=:viridis,
                                transparency=false,
                                alpha=1.0)

    framerate = 12
    t_end = NT*1 # If you want to loop the video manually, 1 should replaced by some large number.
    record(fig, videoname, 1:t_end; framerate=framerate) do i
        t = i%NT+1
        delete!(ax, plot_obj)

        plaqs = plaqs_t[:, :, :, t]

        t_phys = (t-1)*LtoSec*a
        t_phys = round(t_phys,digits=3)
        t_phys = lpad(t_phys, 6, '0')
        ax.title = "3D contour of field strength at t=$(t_phys) yocto-second"

        plot_obj = GLMakie.contour!(ax, x_physical, y_physical, z_physical, plaqs;
                                    levels=levels,
                                    colormap=:viridis,
                                    transparency=false,
                                    alpha=1.0)
    end
end

# Execute
create_animation(NX, NY, NZ, NT, NC; beta=β, filename=confname)
