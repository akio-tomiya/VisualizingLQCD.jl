# Gauge-configuration input: reading and generating configurations.
# This is the only layer that calls Gaugefields' construction, update, and I/O
# API; everything downstream only needs `U[mu][a, b, x, y, z, t]`.

const GAUGE_FORMATS = (:ildg, :jld2, :bridge)

function infer_gauge_format(filename::AbstractString)
    ext = lowercase(splitext(filename)[2])
    ext in (".ildg", ".lime") && return :ildg
    ext == ".jld2" && return :jld2
    throw(ArgumentError(
        "cannot infer the configuration format of $filename; pass format=:ildg, :jld2, or :bridge"))
end

function validate_gauge_format(format::Symbol)
    format in GAUGE_FORMATS ||
        throw(ArgumentError("unsupported configuration format: $format"))
    return format
end

"""
    load_gauge(filename; lattice=nothing, colors=3, format=:auto, kwargs...)

Read a gauge configuration and return the vector of link fields.
`format` is `:ildg`, `:jld2`, or `:bridge`; `:auto` infers it from the file
extension. ILDG and Bridge files need `lattice=(NX, NY, NZ, NT)`; JLD2 files
store their own lattice size. Remaining keywords go to
`Gaugefields.gauge_configuration` (for example `backend=LegacyBackend()`).
"""
function load_gauge(filename::AbstractString; lattice=nothing, colors::Integer=3,
    format::Symbol=:auto, kwargs...)

    isfile(filename) || throw(ArgumentError("configuration file not found: $filename"))
    fmt = validate_gauge_format(format === :auto ? infer_gauge_format(filename) : format)
    if fmt == :jld2 && lattice === nothing
        return load_configuration(filename; format=:jld2, kwargs...)
    end
    lattice === nothing &&
        throw(ArgumentError("lattice=(NX, NY, NZ, NT) is required to read format=$fmt"))
    U = gauge_configuration(Tuple(lattice); colors=colors, kwargs...)
    load_configuration!(U, filename; format=fmt)
    return U
end

"""
    save_gauge(filename, U; format=:auto)

Write a configuration in ILDG, JLD2, or Bridge format.
"""
function save_gauge(filename::AbstractString, U; format::Symbol=:auto)
    fmt = validate_gauge_format(format === :auto ? infer_gauge_format(filename) : format)
    save_configuration(filename, U; format=fmt)
    return filename
end

"""
    generate_gauge(lattice; beta, colors=3, sweeps=20, flow_steps=200,
        flow_step_size=0.01, start=:cold, seed=1234, report_interval=5, kwargs...)

Generate a quenched configuration with the plaquette heatbath, then smooth it
with `flow_steps` steps of the Wilson gradient flow (flow time
`flow_steps * flow_step_size` in lattice units). Without the flow the
configuration is dominated by ultraviolet noise and does not look good.
"""
function generate_gauge(lattice; beta::Real, colors::Integer=3,
    sweeps::Integer=CURRENT_HEATBATH_SWEEPS,
    flow_steps::Integer=CURRENT_FLOW_STEPS_ANIMATION_DEFAULT,
    flow_step_size::Real=CURRENT_FLOW_STEP_SIZE,
    start::Symbol=:cold,
    seed::Integer=CURRENT_GENERATION_SEED,
    report_interval::Integer=CURRENT_HEATBATH_REPORT_INTERVAL,
    verbose::Bool=true,
    kwargs...)

    sweeps >= 0 || throw(ArgumentError("sweeps should be nonnegative"))
    flow_steps >= 0 || throw(ArgumentError("flow_steps should be nonnegative"))
    U = gauge_configuration(Tuple(lattice); colors=colors, start=start, kwargs...)
    updater = heatbath_updater(U; beta=beta, seed=seed)
    for sweep in 1:sweeps
        heatbath!(U, updater)
        if verbose && report_interval > 0 && sweep % report_interval == 0
            println("$sweep plaquette = $(measure_plaquette(U))")
        end
    end
    if flow_steps > 0
        flow = gradient_flow(U; steps=flow_steps, step_size=flow_step_size)
        flow!(U, flow)
    end
    return U
end

export load_gauge, save_gauge, generate_gauge
