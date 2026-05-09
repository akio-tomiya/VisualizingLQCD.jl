# Legacy level selection helpers. These preserve the current threshold policy.

function legacy_level_summary(display_data)
    min_val = minimum(display_data)
    max_val = maximum(display_data)
    mean_val = mean(display_data)
    mode_val = mode(display_data)
    isorange = std(display_data)
    return (level=mean_val, isorange=isorange, min=min_val, max=max_val, mode=mode_val)
end

function print_legacy_level_summary(summary)
    println("mean=$(summary.level), mode=$(summary.mode), min=$(summary.min), max=$(summary.max)")
    println("$(summary.level) $(summary.isorange)")
    return nothing
end

function legacy_mean_std_levels(summary;
    multiplier::Real=CURRENT_LEVEL_STD_MULTIPLIER,
    step::Real=CURRENT_LEVEL_STEP)
    return [collect((summary.level + summary.isorange * multiplier):step:summary.max)...]
end

raw_equivalent_levels_neglog(levels) = [invert_display_level_neglog(level) for level in levels]

function finite_level_values(data)
    values = Float64[]
    for x in data
        isfinite(x) && push!(values, Float64(x))
    end
    isempty(values) && throw(ArgumentError("level data has no finite values"))
    return values
end

function raw_high_quantile_levels(raw_data; quantiles=CURRENT_RAW_HIGH_QUANTILES)
    values = finite_level_values(raw_data)
    qs = collect(quantiles)
    levels = quantile(values, qs)
    return unique(sort(Float64.(levels)))
end

function finite_nonzero_abs_values(data)
    values = Float64[]
    for x in data
        if isfinite(x)
            magnitude = abs(Float64(x))
            magnitude > 0 && push!(values, magnitude)
        end
    end
    isempty(values) && throw(ArgumentError("signed level data has no nonzero finite values"))
    return values
end

function signed_symmetric_levels(data; quantiles=CURRENT_TOPOLOGICAL_CHARGE_LEVEL_QUANTILES)
    values = finite_nonzero_abs_values(data)
    magnitudes = unique(sort(Float64.(quantile(values, collect(quantiles)))))
    levels = Float64[]
    for magnitude in reverse(magnitudes)
        magnitude > 0 && push!(levels, -magnitude)
    end
    for magnitude in magnitudes
        magnitude > 0 && push!(levels, magnitude)
    end
    return levels
end

function signed_symmetric_color_range(data;
    quantile_level=CURRENT_TOPOLOGICAL_CHARGE_COLOR_QUANTILE)

    values = finite_nonzero_abs_values(data)
    0 <= quantile_level <= 1 ||
        throw(ArgumentError("signed color quantile should be between 0 and 1"))
    magnitude = Float64(quantile(values, quantile_level))
    return (-magnitude, magnitude)
end

function level_selection_metadata(levels, summary)
    return Dict(
        "level_target" => String(LEVEL_TARGET_LEGACY_NEGLOG_HIGH),
        "method" => "mean_std",
        "std_multiplier" => CURRENT_LEVEL_STD_MULTIPLIER,
        "step" => CURRENT_LEVEL_STEP,
        "display_levels" => collect(levels),
        "raw_equivalent_levels" => raw_equivalent_levels_neglog(levels),
        "raw_focus_for_upper_levels" => raw_focus_for_upper_display_levels(),
        "summary" => Dict(
            "level" => summary.level,
            "isorange" => summary.isorange,
            "min" => summary.min,
            "max" => summary.max,
        ),
    )
end

function raw_high_level_selection_metadata(levels, summary; quantiles=CURRENT_RAW_HIGH_QUANTILES)
    return Dict(
        "level_target" => String(LEVEL_TARGET_RAW_HIGH),
        "method" => "quantile",
        "quantiles" => collect(quantiles),
        "display_levels" => collect(levels),
        "raw_equivalent_levels" => collect(levels),
        "raw_focus_for_upper_levels" => raw_high_focus_for_upper_levels(),
        "summary" => Dict(
            "level" => summary.level,
            "isorange" => summary.isorange,
            "min" => summary.min,
            "max" => summary.max,
        ),
    )
end

function topological_charge_level_selection_metadata(levels, summary;
    quantiles=CURRENT_TOPOLOGICAL_CHARGE_LEVEL_QUANTILES)

    return Dict(
        "level_target" => String(LEVEL_TARGET_TOPOLOGICAL_CHARGE_DENSITY),
        "method" => "signed_symmetric_magnitude_quantile",
        "quantiles" => collect(quantiles),
        "display_levels" => collect(levels),
        "raw_equivalent_levels" => collect(levels),
        "raw_focus_for_upper_levels" => "positive_and_negative_topological_charge_density",
        "summary" => Dict(
            "level" => summary.level,
            "isorange" => summary.isorange,
            "min" => summary.min,
            "max" => summary.max,
        ),
    )
end
