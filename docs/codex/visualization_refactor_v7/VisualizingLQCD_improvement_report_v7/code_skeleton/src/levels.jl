using Statistics
using StatsBase

function finite_values(data)
    values = Float64[]
    for x in data
        isfinite(x) && push!(values, Float64(x))
    end
    return values
end

function choose_levels(display_data, spec::LevelSpec)
    values = finite_values(display_data)
    isempty(values) && error("display field has no finite values")

    if spec.method == :quantile
        qs = clamp.(spec.quantiles, 0.0, 1.0)
        return unique(sort(quantile(values, qs)))
    elseif spec.method == :fixed
        return unique(sort(Float64.(spec.values)))
    elseif spec.method == :mean_std
        mu, sigma = mean(values), std(values)
        sigma == 0 && return [mu]
        return collect((mu + 1.2 * sigma):0.05:maximum(values))
    else
        error("unknown level-selection method: $(spec.method)")
    end
end

function voxel_count_at_level(display_data, level; tail=:upper)
    if tail == :upper
        return count(x -> isfinite(x) && x >= level, display_data)
    elseif tail == :lower
        return count(x -> isfinite(x) && x <= level, display_data)
    else
        error("unknown tail: $tail")
    end
end

function level_sensitivity(display_data, level, delta; tail=:upper)
    v0 = voxel_count_at_level(display_data, level; tail=tail)
    vp = voxel_count_at_level(display_data, level + delta; tail=tail)
    vm = voxel_count_at_level(display_data, level - delta; tail=tail)
    return abs(vp - vm) / (v0 + 1)
end
