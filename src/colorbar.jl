# This file is part of the QuickCharts.jl package. It is licensed under the MIT License.

const _colorbar_locations = (:none, :left, :right, :top, :bottom)

"""
    Colorbar(; kwargs...)

Configure a contour colorbar.

`location` controls where the colorbar is placed relative to the chart.
Supported values are `:none`, `:left`, `:right`, `:top`, and `:bottom`.
"""
mutable struct Colorbar <: FigureComponent
    location::Symbol
    colormap::Colormap
    axis::Union{Axis,Nothing}
    length_factor::Float64
    inner_sep::Float64
    width::Float64
    height::Float64
    thickness::Float64
    frame::Frame

    function Colorbar(;
        location::Symbol=:right,
        colormap=Colormap(:viridis),
        limits::AbstractVector{<:Real}=[0.0, 1.0],
        label::AbstractString="",
        font_size::Real=9.0,
        font::AbstractString="NewComputerModern",
        ticks::AbstractVector{<:Real}=Float64[],
        tick_labels::AbstractVector{<:AbstractString}=String[],
        tick_length::Real=3.0,
        bins::Int=6,
        inner_sep::Real=3.0,
        length_factor::Real=1.0,
    )
        location in _colorbar_locations || throw(ArgumentError("Colorbar location must be one of $(_colorbar_locations)"))
        length_factor > 0 || throw(ArgumentError("Colorbar length_factor must be positive"))
        font_size > 0 || throw(ArgumentError("Colorbar font_size must be positive"))
        length(limits) == 2 || throw(ArgumentError("Colorbar limits must contain exactly two values"))
        bins > 0 || throw(ArgumentError("Colorbar bins must be positive"))

        resolved_colormap = colormap isa Symbol ? Colormap(colormap) : colormap

        axis = nothing
        if location != :none
            direction = location in (:left, :right) ? :vertical : :horizontal
            axis = Axis(
                direction=direction,
                location=location,
                limits=collect(float.(limits)),
                label=label,
                font_size=font_size,
                font=String(font),
                ticks=collect(float.(ticks)),
                tick_labels=String.(tick_labels),
                tick_length=tick_length,
                nticks=bins,
            )
        end

        return new(
            location,
            resolved_colormap,
            axis,
            float(length_factor),
            float(inner_sep),
            0.0,
            0.0,
            0.0,
            Frame(),
        )
    end
end


function configure!(fig::Figure, cb::Colorbar)
    cb.location == :none && return cb

    configure!(cb.axis)
    cb.thickness = 1.33 * cb.axis.font_size
    cb.inner_sep = cb.thickness

    if cb.location in (:left, :right)
        cb.height = cb.length_factor * (fig.height - 2 * fig.outerpad)
        cb.axis.height = cb.height
        cb.width = cb.inner_sep + cb.thickness + cb.axis.tick_length + cb.axis.width
    else
        cb.width = cb.length_factor * (fig.width - 2 * fig.outerpad)
        cb.axis.width = cb.width
        cb.height = cb.inner_sep + cb.thickness + cb.axis.tick_length + cb.axis.height
    end

    return cb
end


function draw!(::Figure, ctx::RenderContext, cb::Colorbar)
    cb.location == :none && return nothing

    cairo_ctx = ctx.cairo_ctx
    reset_matrix!(ctx)

    x0 = cb.frame.x
    y0 = cb.frame.y
    x1 = cb.frame.x + cb.frame.width
    y1 = cb.frame.y + cb.frame.height
    fmin, fmax = cb.axis.limits

    if cb.location == :right
        bar_x = x0 + cb.inner_sep
        bar_y = y0 + 0.5 * (cb.frame.height - cb.height)
        cb.axis.frame = Frame(bar_x + cb.thickness + cb.axis.tick_length, bar_y, cb.axis.width, cb.height)
        draw!(cb.axis, ctx)

        pat = pattern_create_linear(0.0, bar_y + cb.height, 0.0, bar_y)
        for (stop, color) in zip(cb.colormap.stops, cb.colormap.colors)
            normalized_stop = round((stop - fmin) / (fmax - fmin), digits=8)
            pattern_add_color_stop_rgb(pat, normalized_stop, color...)
        end

        set_source(cairo_ctx, pat)
        rectangle(cairo_ctx, bar_x, bar_y, cb.thickness, cb.height)
        fill(cairo_ctx)
    elseif cb.location == :left
        bar_x = x1 - cb.inner_sep - cb.thickness
        bar_y = y0 + 0.5 * (cb.frame.height - cb.height)
        cb.axis.frame = Frame(x0, bar_y, cb.axis.width, cb.height)
        draw!(cb.axis, ctx)

        pat = pattern_create_linear(0.0, bar_y + cb.height, 0.0, bar_y)
        for (stop, color) in zip(cb.colormap.stops, cb.colormap.colors)
            normalized_stop = round((stop - fmin) / (fmax - fmin), digits=8)
            pattern_add_color_stop_rgb(pat, normalized_stop, color...)
        end

        set_source(cairo_ctx, pat)
        rectangle(cairo_ctx, bar_x, bar_y, cb.thickness, cb.height)
        fill(cairo_ctx)
    elseif cb.location == :bottom
        bar_x = x0 + 0.5 * (cb.frame.width - cb.width)
        bar_y = y0 + cb.inner_sep
        cb.axis.frame = Frame(bar_x, bar_y + cb.thickness + cb.axis.tick_length, cb.width, cb.axis.height)
        draw!(cb.axis, ctx)

        pat = pattern_create_linear(bar_x, 0.0, bar_x + cb.width, 0.0)
        for (stop, color) in zip(cb.colormap.stops, cb.colormap.colors)
            normalized_stop = round((stop - fmin) / (fmax - fmin), digits=8)
            pattern_add_color_stop_rgb(pat, normalized_stop, color...)
        end

        set_source(cairo_ctx, pat)
        rectangle(cairo_ctx, bar_x, bar_y, cb.width, cb.thickness)
        fill(cairo_ctx)
    else
        bar_x = x0 + 0.5 * (cb.frame.width - cb.width)
        bar_y = y1 - cb.inner_sep - cb.thickness
        cb.axis.frame = Frame(bar_x, y0, cb.width, cb.axis.height)
        draw!(cb.axis, ctx)

        pat = pattern_create_linear(bar_x, 0.0, bar_x + cb.width, 0.0)
        for (stop, color) in zip(cb.colormap.stops, cb.colormap.colors)
            normalized_stop = round((stop - fmin) / (fmax - fmin), digits=8)
            pattern_add_color_stop_rgb(pat, normalized_stop, color...)
        end

        set_source(cairo_ctx, pat)
        rectangle(cairo_ctx, bar_x, bar_y, cb.width, cb.thickness)
        fill(cairo_ctx)
    end

    return nothing
end
