# Display transforms used for visualization thresholds.

display_transform_kind() = :neglog
display_transform_formula() = "-log(p + epsilon)"
display_transform_inverse_formula() = "exp(-level) - epsilon"
raw_focus_for_upper_display_levels() = "low_raw_deviation"

function display_transform_neglog(p::Real; epsilon::Real=CURRENT_LOG_EPSILON)
    return -log(p + epsilon)
end

function invert_display_level_neglog(level::Real; epsilon::Real=CURRENT_LOG_EPSILON)
    return exp(-level) - epsilon
end

function display_transform_metadata()
    return Dict(
        "kind" => String(display_transform_kind()),
        "formula" => display_transform_formula(),
        "inverse_formula" => display_transform_inverse_formula(),
        "epsilon" => CURRENT_LOG_EPSILON,
        "raw_focus_for_upper_levels" => raw_focus_for_upper_display_levels(),
    )
end
