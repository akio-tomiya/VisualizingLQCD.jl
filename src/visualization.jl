#include("header.jl")
#include("constants.jl")

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
    return level, isorange, min_val, max_val
end

GLMakie.activate!()
# set constants
const myxlabel = L"$x$ [fm]"
const myylabel = L"$y$ [fm]"
const myzlabel = L"$z$ [fm]"
const r_0 = CURRENT_R0_FM

# hep-lat/9806005
function ln_a(beta::Float64)::Float64
    beta_min, beta_max = CURRENT_BETA_RANGE
    if beta < beta_min || beta > beta_max
        throw(ArgumentError("Beta should be in the range [$beta_min, $beta_max]"))
    end
    delta_beta = beta - 6
    c0, c1, c2, c3 = CURRENT_LN_A_COEFFS
    return c0 + c1 * delta_beta + c2 * delta_beta^2 + c3 * delta_beta^3
end

function calculate_a(beta::Float64)::Float64
    return r_0 * exp(ln_a(beta))
end

function slice4_for_frame(frame::Integer, NT::Integer)::Int
    frame > 0 || throw(ArgumentError("frame should be positive"))
    NT > 0 || throw(ArgumentError("NT should be positive"))
    return (frame - 1) % NT + 1
end

function create_animation(NX, NY, NZ, NT, NC, videoname;
    beta=CURRENT_BETA_ANIMATION_DEFAULT,
    flow_steps_in=CURRENT_FLOW_STEPS_ANIMATION_DEFAULT,
    filename=CURRENT_FILENAME_DEFAULT)

    #function create_animation(NX, NY, NZ, NT, NC; beta=6.1, filename="conf_00000100.ildg")
    Nwing = CURRENT_NWING
    a = calculate_a(beta)
    scale_factor = a

    U1 = Initialize_Gaugefields(
        NC, Nwing, NX, NY, NZ, NT, condition=CURRENT_GENERATION_INITIAL_CONDITION)
    ildg = ILDG(filename)
    load_gaugefield!(U1, 1, ildg, [NX, NY, NZ, NT], NC)

    loop = CURRENT_WILSONLINE_LOOP
    w = Wilsonline(loop)
    Uloop = similar(U1[1])
    temps = [similar(U1[1]) for _ in 1:CURRENT_WILSONLINE_TEMP_COUNT]
    Gaugefields.evaluate_gaugelinks!(Uloop, w, U1, temps)

    # Calculating field strength using plaquette
    # In precise, we need 1/β
    plaqs_t = zeros(Float64, NX, NY, NZ, NT)
    for z in 1:NZ, y in 1:NY, x in 1:NX, t in 1:NT
        tmp = 1 - real(tr(Uloop[:, :, x, y, z, t])) / NC
        plaqs_t[x, y, z, t] = -log(tmp + CURRENT_LOG_EPSILON)
    end

    # show logarithm of histogram for plaquettes
    level, isorange, min_val, max_val = automatic_level2(plaqs_t)
    levels = [collect((level+isorange*CURRENT_LEVEL_STD_MULTIPLIER):CURRENT_LEVEL_STEP:max_val)...]

    #= To check iso-level, please use here
    hist_p = histogram(vec(plaqs_t))
    vline!(hist_p, levels)
    display(hist_p)
    =#

    # Set coordinate
    x_physical = (a, a * NX)
    y_physical = (a, a * NY)
    z_physical = (a, a * NZ)

    fig = Figure(size=CURRENT_FIGURE_SIZE)
    # label setting.
    x_positions = range(0, stop=a * NX, length=NX)
    x_labels = [string(round(x, digits=CURRENT_TICK_DIGITS)) for x in x_positions]

    y_positions = range(0, stop=a * NY, length=NY)
    y_labels = [string(round(y, digits=CURRENT_TICK_DIGITS)) for y in y_positions]

    z_positions = range(0, stop=a * NZ, length=NZ)
    z_labels = [string(round(z, digits=CURRENT_TICK_DIGITS)) for z in z_positions]

    for i in 1:CURRENT_TICK_STRIDE:length(x_labels)
        x_labels[i] = ""
    end
    for i in 1:CURRENT_TICK_STRIDE:length(y_labels)
        y_labels[i] = ""
    end
    for i in 1:CURRENT_TICK_STRIDE:length(z_labels)
        z_labels[i] = ""
    end

    # Make Axis3
    ax = Axis3(fig[1, 1],
        xlabel=myxlabel, ylabel=myylabel, zlabel=myzlabel,
        title=DEFAULT_MOVIE_TITLE,
        xticks=(x_positions, x_labels),
        yticks=(y_positions, y_labels),
        zticks=(z_positions, z_labels), aspect=CURRENT_ASPECT)

    # Dummy plot 
    dummy_data = zeros(Float64, NX, NY, NZ)
    plot_obj = GLMakie.contour!(ax, x_physical, y_physical, z_physical, dummy_data;
        levels=[levels[1]],
        colormap=CURRENT_COLORMAP,
        transparency=CURRENT_TRANSPARENCY,
        alpha=CURRENT_ALPHA)

    framerate = CURRENT_MOVIE_FRAMERATE
    t_end = NT * CURRENT_MOVIE_NLOOPS # If you want to loop the video manually, 1 should replaced by some large number.
    record(fig, videoname, 1:t_end; framerate=framerate) do i
        slice4 = slice4_for_frame(i, NT)
        delete!(ax, plot_obj)

        plaqs = plaqs_t[:, :, :, slice4]

        ax.title = DEFAULT_MOVIE_TITLE

        plot_obj = GLMakie.contour!(ax, x_physical, y_physical, z_physical, plaqs;
            levels=levels,
            colormap=CURRENT_COLORMAP,
            transparency=CURRENT_TRANSPARENCY,
            alpha=CURRENT_ALPHA)
    end
end

export create_animation
