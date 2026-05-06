function raw_high_color_range(raw_data; quantiles=CURRENT_RAW_HIGH_COLOR_QUANTILES)
    values = finite_level_values(raw_data)
    qs = collect(quantiles)
    range_values = quantile(values, qs)
    return Tuple(Float64.(range_values))
end

function contour_style_metadata(;
    render_style,
    colormap,
    alpha,
    transparency,
    color_quantity,
    color_method,
    color_quantiles=nothing,
    color_range=nothing,
)
    info = Dict(
        "render_style" => String(render_style),
        "colormap" => colormap_metadata_value(colormap),
        "alpha" => alpha,
        "transparency" => transparency,
        "color_quantity" => color_quantity,
        "color_method" => color_method,
    )
    if color_quantiles !== nothing
        info["color_quantiles"] = collect(color_quantiles)
    end
    if color_range !== nothing
        info["color_range"] = collect(color_range)
    end
    return info
end

colormap_metadata_value(colormap::Symbol) = String(colormap)
colormap_metadata_value(colormap) = [String(color) for color in colormap]

function legacy_contour_style()
    return (
        colormap=CURRENT_COLORMAP,
        colorrange=nothing,
        alpha=CURRENT_ALPHA,
        transparency=CURRENT_TRANSPARENCY,
        metadata=contour_style_metadata(
            render_style=RENDER_STYLE_CURRENT,
            colormap=CURRENT_COLORMAP,
            alpha=CURRENT_ALPHA,
            transparency=CURRENT_TRANSPARENCY,
            color_quantity="display_level",
            color_method="current_default",
        ),
    )
end

function raw_high_contour_style(raw_data;
    color_quantiles=CURRENT_RAW_HIGH_COLOR_QUANTILES,
    colormap=CURRENT_COLORMAP,
    alpha=CURRENT_RAW_HIGH_ALPHA,
    transparency=CURRENT_RAW_HIGH_TRANSPARENCY)
    color_range = raw_high_color_range(raw_data; quantiles=color_quantiles)
    return (
        colormap=colormap,
        colorrange=color_range,
        alpha=alpha,
        transparency=transparency,
        metadata=contour_style_metadata(
            render_style=RENDER_STYLE_CURRENT,
            colormap=colormap,
            alpha=alpha,
            transparency=transparency,
            color_quantity="raw_plaquette_deviation",
            color_method="quantile",
            color_quantiles=color_quantiles,
            color_range=color_range,
        ),
    )
end

function plaquette_thermal_contour_style(raw_data;
    color_quantiles=CURRENT_PLAQUETTE_THERMAL_COLOR_QUANTILES,
    colormap=CURRENT_PLAQUETTE_THERMAL_COLORMAP,
    alpha=CURRENT_PLAQUETTE_THERMAL_ALPHA,
    transparency=CURRENT_PLAQUETTE_THERMAL_TRANSPARENCY)
    color_range = raw_high_color_range(raw_data; quantiles=color_quantiles)
    return (
        colormap=collect(colormap),
        colorrange=color_range,
        alpha=alpha,
        transparency=transparency,
        metadata=contour_style_metadata(
            render_style=RENDER_STYLE_PLAQUETTE_THERMAL,
            colormap=colormap,
            alpha=alpha,
            transparency=transparency,
            color_quantity="raw_plaquette_deviation",
            color_method="quantile",
            color_quantiles=color_quantiles,
            color_range=color_range,
        ),
    )
end

function contour_plot_kwargs(style, levels)
    kwargs = Dict{Symbol,Any}(
        :levels => levels,
        :colormap => style.colormap,
        :transparency => style.transparency,
        :alpha => style.alpha,
    )
    if style.colorrange !== nothing
        kwargs[:colorrange] = style.colorrange
    end
    return kwargs
end

function default_raw_high_level_quantiles(render_style::Symbol)
    if render_style == RENDER_STYLE_CURRENT
        return CURRENT_RAW_HIGH_QUANTILES
    elseif render_style == RENDER_STYLE_PLAQUETTE_THERMAL
        return CURRENT_PLAQUETTE_THERMAL_LEVEL_QUANTILES
    else
        throw(ArgumentError("unsupported render_style: $render_style"))
    end
end

function default_raw_high_color_quantiles(render_style::Symbol)
    if render_style == RENDER_STYLE_CURRENT
        return CURRENT_RAW_HIGH_COLOR_QUANTILES
    elseif render_style == RENDER_STYLE_PLAQUETTE_THERMAL
        return CURRENT_PLAQUETTE_THERMAL_COLOR_QUANTILES
    else
        throw(ArgumentError("unsupported render_style: $render_style"))
    end
end

function raw_high_contour_style_for_render(raw_data, render_style::Symbol;
    color_quantiles,
    alpha=nothing,
    transparency=nothing)
    if render_style == RENDER_STYLE_CURRENT
        return raw_high_contour_style(raw_data;
            color_quantiles=color_quantiles,
            alpha=something(alpha, CURRENT_RAW_HIGH_ALPHA),
            transparency=something(transparency, CURRENT_RAW_HIGH_TRANSPARENCY))
    elseif render_style == RENDER_STYLE_PLAQUETTE_THERMAL
        return plaquette_thermal_contour_style(raw_data;
            color_quantiles=color_quantiles,
            alpha=something(alpha, CURRENT_PLAQUETTE_THERMAL_ALPHA),
            transparency=something(transparency, CURRENT_PLAQUETTE_THERMAL_TRANSPARENCY))
    else
        throw(ArgumentError("unsupported render_style: $render_style"))
    end
end

function effective_render_theme(render_style::Symbol, render_theme)
    if render_theme !== nothing
        return render_theme
    elseif render_style == RENDER_STYLE_PLAQUETTE_THERMAL
        return RENDER_THEME_DARK
    else
        return CURRENT_RENDER_THEME
    end
end

function render_theme_settings(render_theme::Symbol)
    if render_theme == RENDER_THEME_LIGHT
        return (
            theme=render_theme,
            figure_background=:white,
            axis_background=:white,
            text_color=:black,
            grid_color=:gray,
        )
    elseif render_theme == RENDER_THEME_DARK
        return (
            theme=render_theme,
            figure_background=:black,
            axis_background=:black,
            text_color=:white,
            grid_color=:gray,
        )
    else
        throw(ArgumentError("unsupported render_theme: $render_theme"))
    end
end

function render_theme_metadata(render_theme::Symbol)
    settings = render_theme_settings(render_theme)
    return Dict(
        "render_theme" => String(settings.theme),
        "figure_background" => String(settings.figure_background),
        "axis_background" => String(settings.axis_background),
        "text_color" => String(settings.text_color),
        "grid_color" => String(settings.grid_color),
    )
end
