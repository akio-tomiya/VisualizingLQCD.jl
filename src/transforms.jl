# Display transforms used for visualization thresholds.

display_transform_kind() = :neglog
display_transform_formula() = "-log(p + epsilon)"

function display_transform_neglog(p::Real; epsilon::Real=CURRENT_LOG_EPSILON)
    return -log(p + epsilon)
end

function display_transform_metadata()
    return Dict(
        "kind" => String(display_transform_kind()),
        "formula" => display_transform_formula(),
        "epsilon" => CURRENT_LOG_EPSILON,
    )
end
