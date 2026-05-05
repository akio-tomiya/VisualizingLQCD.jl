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

function level_selection_metadata(levels, summary)
    return Dict(
        "method" => "mean_std",
        "std_multiplier" => CURRENT_LEVEL_STD_MULTIPLIER,
        "step" => CURRENT_LEVEL_STEP,
        "display_levels" => collect(levels),
        "summary" => Dict(
            "level" => summary.level,
            "isorange" => summary.isorange,
            "min" => summary.min,
            "max" => summary.max,
        ),
    )
end
