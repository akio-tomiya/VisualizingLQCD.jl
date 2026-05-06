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
