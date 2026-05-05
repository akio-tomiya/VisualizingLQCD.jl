using Statistics

function _finite_positive_values(raw)
    values = Float64[]
    for x in raw
        if isfinite(x) && x > 0
            push!(values, Float64(x))
        end
    end
    return values
end

function choose_epsilon(raw, spec::TransformSpec)
    if spec.epsilon_policy == :fixed
        return spec.epsilon
    elseif spec.epsilon_policy == :auto_quantile
        values = sort(_finite_positive_values(raw))
        isempty(values) && return spec.epsilon
        idx = max(1, round(Int, 0.001 * length(values)))
        return max(eps(Float64), values[idx] * 1e-3)
    else
        error("unknown epsilon policy: $(spec.epsilon_policy)")
    end
end

function raw_focus(spec::TransformSpec)
    spec.kind == :neglog && return "low_raw_deviation"
    spec.kind == :log && return "high_raw_deviation"
    spec.kind == :identity && return "high_raw_deviation"
    return "unknown"
end

function transform_formula(spec::TransformSpec)
    spec.kind == :neglog && return "-log(raw + epsilon)"
    spec.kind == :log && return "log(raw + epsilon)"
    spec.kind == :identity && return "raw"
    return string(spec.kind)
end

function display_transform(raw::AbstractArray, spec::TransformSpec)
    p = clamp.(Float64.(raw), 0.0, Inf)
    epsilon = choose_epsilon(p, spec)

    if spec.kind == :identity
        data = p
    elseif spec.kind == :log
        data = log.(p .+ epsilon)
    elseif spec.kind == :neglog
        data = .-log.(p .+ epsilon)
    else
        error("unknown transform kind: $(spec.kind)")
    end

    return ScalarField(data, transform_formula(spec), "dimensionless", "display transform"), epsilon
end

function invert_display_level(level::Real, spec::TransformSpec, epsilon::Real)
    if spec.kind == :identity
        return max(Float64(level), 0.0)
    elseif spec.kind == :log
        return max(exp(level) - epsilon, 0.0)
    elseif spec.kind == :neglog
        return max(exp(-level) - epsilon, 0.0)
    else
        error("level inversion is not defined for $(spec.kind)")
    end
end

function build_display_field(raw::ScalarField, spec::TransformSpec)
    display, epsilon = display_transform(raw.data, spec)
    return FieldBundle(raw, display, transform_formula(spec), epsilon, raw_focus(spec))
end
