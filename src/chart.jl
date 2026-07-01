# This file is part of the QuickCharts.jl package. It is licensed under the MIT License.

"""
    Chart(;
        size=(8cm, 5cm), font="NewComputerModern", font_size=10.0,
        xlimits, ylimits, aspect_ratio=:auto,
        nxticks=7, nyticks=6,
        title="", background=nothing,
        xlabel="`x`", ylabel="`y`",
        xticks=Float64[], yticks=Float64[],
        xtick_labels=String[], ytick_labels=String[],
        legend=:top_right, legend_font_size=0, legend_background=nothing)

Construct a 2D chart figure with axes, legend, and optional tick customization.

# Arguments
- `size::Tuple{<:Real,<:Real}`: width × height in points. Use `cm` as a convenience helper, e.g. `size=(8cm, 6cm)`.
- `font::AbstractString`: font family for axes and legend.
- `font_size::Real`: base font size.
- `xlimits::Vector{<:Real}`, `ylimits::Vector{<:Real}`: axis limits `[min,max]`; use empty vectors for auto scaling.
- `aspect_ratio::Symbol`: `:auto` or `:equal`.
- `nxticks::Int`, `nyticks::Int`: target number of tick intervals on each axis.
- `title::AbstractString`: chart title, centered above the plot area.
- `background::Union{Nothing,Symbol,Color,Tuple}`: full-figure background fill; `nothing` leaves the figure unfilled.
- `xlabel::AbstractString`, `ylabel::AbstractString`: axis labels.
- `xticks::Vector{<:Real}`, `yticks::Vector{<:Real}`: explicit tick positions; empty vectors enable auto ticks.
- `xtick_labels::Vector{<:AbstractString}`, `ytick_labels::Vector{<:AbstractString}`: custom tick labels; if provided, lengths must match the corresponding tick arrays.
- `legend::Symbol`: legend location (e.g., `:top_right`, `:top_left`, `:bottom_left`, `:outer_right`).
- `legend_font_size::Real`: legend font size; `0` uses `font_size`.
- `legend_background::Union{Nothing,Symbol,Color,Tuple}`: legend box fill color; if unset it defaults to white standalone and follows the grid background when drawn inside a `ChartGrid`.

# Notes
- Use `add_series` to append data series to the chart.
- Use `add_annotation` to add plot-relative overlay annotations.
- Prefer backticks for inline math in plot text, e.g. `` `sin(x)` ``. Dollar
  delimiters are also accepted, but must be escaped in Julia strings, e.g.
  `"\$sin(x)\$"`.
- The legend is drawn after annotations.
- `background=nothing` leaves the chart background unfilled in vector outputs and uses a white page background in PNG.
- Use `save` to export the chart to a file.

# Returns
- A `Chart` object.

# Example
```julia
using QuickCharts: Chart, cm

ch = Chart(size=(8cm, 6cm),
           title="Response History",
           xlabel="Time [s]",
           ylabel="Displacement [mm]",
           xlimits=[0.0,10.0],
           ylimits=[-5.0,5.0],
           legend=:bottom_right)
```
"""
mutable struct Chart <: Figure
    width::Float64
    height::Float64
    figure_frame::Frame
    background::Union{Nothing,Color}
    title_box::TextBox
    canvas::Canvas
    xaxis::Axis
    yaxis::Axis
    dataseries::Vector{DataSeries}
    legend::Legend
    annotations::AbstractArray

    aspect_ratio::Symbol
    outerpad::Float64
    left_items::Vector{FigureComponent}
    right_items::Vector{FigureComponent}
    top_items::Vector{FigureComponent}
    bottom_items::Vector{FigureComponent}
    overlay_items::Vector{FigureComponent}
    icolor::Int
    iorder::Int

    function Chart(;
        size=(8cm, 5cm),
        font="NewComputerModern",
        font_size::Real=10.0,
        xlimits=Float64[],
        ylimits=Float64[],
        aspect_ratio=:auto,
        nxticks::Int=7,
        nyticks::Int=6,
        title::AbstractString="",
        background::Union{Nothing,Symbol,Color,Tuple}=nothing,
        xlabel::AbstractString="`x`",
        ylabel::AbstractString="`y`",
        xticks::Vector{<:Real}=Float64[],
        yticks::Vector{<:Real}=Float64[],
        xtick_labels::Vector{<:AbstractString}=String[],
        ytick_labels::Vector{<:AbstractString}=String[],
        legend::Symbol=:top_right,
        legend_font_size::Real=0,
        legend_background::Union{Nothing,Symbol,Color,Tuple}=nothing
    )
        if legend_font_size == 0
            legend_font_size = font_size
        end

        font_size > 0 || throw(ArgumentError("Chart: font_size must be positive"))
        legend_font_size > 0 || throw(ArgumentError("Chart: legend_font_size must be positive"))
        aspect_ratio in (:auto, :equal) || throw(ArgumentError("Chart: Invalid aspect_ratio: $aspect_ratio. Use :auto or :equal. Got $(repr(aspect_ratio))."))

        width, height = size
        outerpad = 0.01 * min(width, height)
        the_legend = Legend(; location=legend, font=font, font_size=legend_font_size, background=legend_background, ncols=1)
        xaxis = Axis(direction=:horizontal, limits=xlimits, label=xlabel, font=font, font_size=font_size, ticks=xticks, tick_labels=xtick_labels, nticks=nxticks)
        yaxis = Axis(direction=:vertical, limits=ylimits, label=ylabel, font=font, font_size=font_size, ticks=yticks, tick_labels=ytick_labels, nticks=nyticks)
        background = resolve_color(background)
        title_box = TextBox(title)

        this = new(width, height, Frame(0.0, 0.0, width, height), background, title_box, Canvas(), xaxis, yaxis, [], the_legend, [],
            aspect_ratio, outerpad, FigureComponent[], FigureComponent[], FigureComponent[], FigureComponent[], FigureComponent[], 1, 1)

        return this
    end
end


_figure_background(c::Chart) = c.background
_figure_renderable(c::Chart) = !isempty(c.dataseries)

function _chart_gridline_color(c::Chart, ctx::RenderContext)
    background = ctx.background === nothing ? c.background : ctx.background
    return background === nothing ? Color(0.9, 0.9, 0.9) : darken(grayscale(background), 0.15)
end

"""
    add_series(chart::Chart, kind::Symbol, X::AbstractArray, Y::AbstractArray; kwargs...)
    add_series(chart::Chart, X::AbstractArray, Y::AbstractArray; kwargs...)

Append a `DataSeries` to `chart`.
The second version uses `kind = :line`.

# Arguments
- `chart::Chart` : Target chart (mutated).
- `kind::Symbol` : Plot type: `:line`, `:scatter`, `:bar`.
- `X, Y::AbstractArray` : Data vectors.

# Keyword options
- `line_style::Symbol = :solid` : Line style (e.g. `:solid`, `:dash`, ...).
- `dash::Vector{Float64} = Float64[]` : Custom dash pattern. If nonempty, overrides `line_style`.
- `color::Union{Symbol,Color,Tuple} = :auto` : Line/marker color. `:auto` selects from the chart palette cyclically.
- `line_width::Float64 = 0.5` : Line width (> 0).
- `mark::Symbol = :none` : Mark shape.
- `mark_size::Float64 = 2.5` : Mark size (> 0).
- `mark_color::Union{Symbol,Color,Tuple} = :white` : Mark fill color.
- `mark_stroke_color::Union{Symbol,Color,Tuple} = :auto` : Mark edge color (`:auto` follows `color`).
- `label::AbstractString = ""` : Legend label.
- `tag::AbstractString = ""` : On-curve annotation text.
- `tag_anchor::Symbol = :top` : Anchor side of the tag (`:top`, `:top_right`, `:right`, `:bottom_right`, `:bottom`, `:bottom_left`, `:left`, `:top_left`).
- `tag_pos::Float64 = 0.5` : Position along the curve in [0,1].
- `tag_orientation::Symbol = :horizontal` : Tag orientation (`:horizontal`, `:vertical`, `:parallel`).
- `tag_padding::Union{Nothing,Real} = nothing` : Padding between the curve and tag in points. `nothing` uses the default based on font size.
- `tag_font_size::Union{Nothing,Real} = nothing` : Tag font size in points. `nothing` uses `0.8 * chart.xaxis.font_size`.
- `bar_width::Float64 = 0.0` : Bar width in x-data units (`0` enables auto width).
- `bar_base::Float64 = 0.0` : Bar baseline in y-data units.
- `order::Int = 0` : Z-order. If `0`, an incremental order is assigned.

# Returns
- The series object.

# Examples
```julia
ch = Chart(size=(300,200), xlabel="Time [s]", ylabel="Displacement [mm]",
           xlimits=[0.0,10.0], ylimits=[-5.0,5.0], legend=:bottom_right)

add_line(ch, 0:0.1:10, sin.(0:0.1:10); label="sin")
```
"""
function add_series(chart::Chart, kind::Symbol, X::AbstractArray, Y::AbstractArray;
    line_style=:solid, dash=Float64[],
    color::Union{Symbol,Color,Tuple}=:auto,
    line_width=0.5,
    mark=:none, mark_size=2.5,
    mark_color::Union{Symbol,Color,Tuple}=:white,
    mark_stroke_color::Union{Symbol,Color,Tuple}=:auto,
    label="", tag="", tag_anchor=:top, tag_pos=0.5,
    tag_orientation=:horizontal,
    tag_padding::Union{Nothing,Real}=nothing,
    tag_font_size::Union{Nothing,Real}=nothing,
    bar_width=0.0,
    bar_base=0.0,
    order=0
)

    line_width > 0 || throw(ArgumentError("Line width must be positive"))
    mark_size > 0 || throw(ArgumentError("Mark size must be positive"))
    0 <= tag_pos <= 1 || throw(ArgumentError("Tag position along the curve must be in [0,1]"))
    order >= 0 || throw(ArgumentError("Order must be non-negative"))
    bar_width >= 0 || throw(ArgumentError("Bar width must be non-negative"))
    kind in (:line, :scatter, :bar) || throw(ArgumentError("Invalid series kind: $kind. Use :line, :scatter, or :bar"))
    length(X) == length(Y) || throw(ArgumentError("X and Y must have the same length"))
    mark in _mark_list || throw(ArgumentError("Invalid mark: $mark. Use one of $_mark_list"))
    tag_anchor in _tag_anchor_list || throw(ArgumentError("Invalid tag anchor: $tag_anchor. Use one of $_tag_anchor_list"))
    tag_orientation in (:horizontal, :vertical, :parallel) || throw(ArgumentError("Invalid tag orientation: $tag_orientation. Use :horizontal, :vertical, or :parallel"))
    tag_padding === nothing || tag_padding >= 0 || throw(ArgumentError("Tag padding must be non-negative"))
    tag_font_size === nothing || tag_font_size > 0 || throw(ArgumentError("Tag font size must be positive"))

    series = DataSeries(kind, X, Y;
        line_style=line_style, dash=dash,
        color=color,
        line_width=line_width,
        mark=mark, mark_size=mark_size,
        mark_color=mark_color, mark_stroke_color=mark_stroke_color,
        label=label, tag=tag, tag_anchor=tag_anchor, tag_pos=tag_pos,
        tag_orientation=tag_orientation, tag_padding=tag_padding,
        tag_font_size=tag_font_size,
        bar_width=bar_width, bar_base=bar_base,
        order=order
    )

    if series.color === :auto # update colors
        series.color = Color(_default_colors[chart.icolor])
        chart.icolor = mod(chart.icolor, length(_default_colors)) + 1
    end

    if series.order === 0
        series.order = chart.iorder
        chart.iorder += 1
    end

    push!(chart.dataseries, series)

    return series
end


function add_series(chart::Chart, X::AbstractArray, Y::AbstractArray; kwargs...)
    return add_series(chart, :line, X, Y; kwargs...)
end

"""
    add_line(chart::Chart, X::AbstractArray, Y::AbstractArray; kwargs...)

Add a line series to `chart`.

# Arguments
- `chart::Chart`: Target chart (mutated).
- `X, Y::AbstractArray`: Data vectors.
- `kwargs...`: Keyword arguments controlling series appearance and metadata.

# Keyword options
- `line_style::Symbol = :solid`: Line style (e.g. `:solid`, `:dash`, ...).
- `dash::Vector{Float64} = Float64[]`: Custom dash pattern. If nonempty, overrides `line_style`.
- `color::Union{Symbol,Color,Tuple} = :auto`: Line/marker color. `:auto` selects from the chart palette cyclically.
- `line_width::Float64 = 0.5`: Line width (> 0).
- `mark::Symbol = :none`: Mark shape.
- `mark_size::Float64 = 2.5`: Mark size (> 0).
- `mark_color::Union{Symbol,Color,Tuple} = :white`: Mark fill color.
- `mark_stroke_color::Union{Symbol,Color,Tuple} = :auto`: Mark edge color (`:auto` follows `color`).
- `label::AbstractString = ""`: Legend label.
- `tag::AbstractString = ""`: On-curve annotation text.
- `tag_anchor::Symbol = :top`: Anchor side of the tag (`:top`, `:top_right`, `:right`, `:bottom_right`, `:bottom`, `:bottom_left`, `:left`, `:top_left`).
- `tag_pos::Float64 = 0.5`: Position along the curve in [0,1].
- `tag_orientation::Symbol = :horizontal`: Tag orientation (`:horizontal`, `:vertical`, `:parallel`).
- `tag_padding::Union{Nothing,Real} = nothing`: Padding between the curve and tag in points. `nothing` uses the default based on font size.
- `tag_font_size::Union{Nothing,Real} = nothing`: Tag font size in points. `nothing` uses `0.8 * chart.xaxis.font_size`.
- `bar_width::Float64 = 0.0`: Bar width in x-data units (`0` enables auto width).
- `bar_base::Float64 = 0.0`: Bar baseline in y-data units.
- `order::Int = 0`: Z-order. If `0`, an incremental order is assigned.

# Returns
- The created series object.
"""
function add_line(chart::Chart, X::AbstractArray, Y::AbstractArray; kwargs...)
    return add_series(chart, :line, X, Y; kwargs...)
end

"""
    add_scatter(chart::Chart, X::AbstractArray, Y::AbstractArray; kwargs...)

Add a scatter series to `chart`.

This is a convenience wrapper around [`add_series`](@ref) with
`line_style=:none` and `mark=:circle` unless those keywords are supplied.

# Arguments
- `chart::Chart`: Target chart (mutated).
- `X, Y::AbstractArray`: Data vectors.
- `kwargs...`: Keyword arguments accepted by [`add_line`](@ref); explicit values override the defaults above.

# Returns
- The created series object.
"""
function add_scatter(chart::Chart, X::AbstractArray, Y::AbstractArray; kwargs...)
    defaults = (line_style=:none, mark=:circle)
    return add_series(chart, :scatter, X, Y; merge(defaults, kwargs)...)
end

"""
    add_bar(chart::Chart, X::AbstractArray, Y::AbstractArray; kwargs...)

Add a bar series to `chart`.

This is a convenience wrapper around [`add_series`](@ref) with
`line_style=:none` and `mark=:none` unless those keywords are supplied.

# Arguments
- `chart::Chart`: Target chart (mutated).
- `X, Y::AbstractArray`: Data vectors.
- `kwargs...`: Keyword arguments accepted by [`add_line`](@ref); explicit values override the defaults above.

# Returns
- The created series object.
"""
function add_bar(chart::Chart, X::AbstractArray, Y::AbstractArray; kwargs...)
    defaults = (line_style=:none, mark=:none)
    return add_series(chart, :bar, X, Y; merge(defaults, kwargs)...)
end


function _tag_anchor_alignment(anchor::Symbol)
    anchor == :top && return "center", "top"
    anchor == :top_right && return "right", "top"
    anchor == :right && return "right", "center"
    anchor == :bottom_right && return "right", "bottom"
    anchor == :bottom && return "center", "bottom"
    anchor == :bottom_left && return "left", "bottom"
    anchor == :left && return "left", "center"
    anchor == :top_left && return "left", "top"
    throw(ArgumentError("Invalid tag anchor: $anchor"))
end


function _tag_anchor_offset(anchor::Symbol, pad::Float64)
    anchor == :top && return 0.0, pad
    anchor == :top_right && return -pad, pad
    anchor == :right && return -pad, 0.0
    anchor == :bottom_right && return -pad, -pad
    anchor == :bottom && return 0.0, -pad
    anchor == :bottom_left && return pad, -pad
    anchor == :left && return pad, 0.0
    anchor == :top_left && return pad, pad
    throw(ArgumentError("Invalid tag anchor: $anchor"))
end


function _rotate_offset(dx::Float64, dy::Float64, angle::Float64)
    c = cosd(angle)
    s = sind(angle)
    return dx * c + dy * s, -dx * s + dy * c
end

const _debug_tag_points = Ref(false)


function _resolve_tag_layout(anchor::Symbol, orientation::Symbol, tangent_angle::Float64, pad::Float64)
    ha, va = _tag_anchor_alignment(anchor)
    dx, dy = _tag_anchor_offset(anchor, pad)

    angle = if orientation == :parallel
        tangent_angle
    elseif orientation == :vertical
        90.0
    else
        0.0
    end

    if angle != 0.0
        dx, dy = _rotate_offset(dx, dy, angle)
    end

    return ha, va, dx, dy, angle
end


_tag_vertex_tolerance(total_length::Float64) = max(1.0e-12, sqrt(eps(Float64)) * max(total_length, 1.0))


function _segment_tangent_angle(canvas::Canvas, X::AbstractArray, Y::AbstractArray, i::Int)
    x1, y1 = data2user(canvas, float(X[i]), float(Y[i]))
    x2, y2 = data2user(canvas, float(X[i + 1]), float(Y[i + 1]))
    return -atand(y2 - y1, x2 - x1)
end


function _vertex_tangent_angle(canvas::Canvas, X::AbstractArray, Y::AbstractArray, i::Int)
    xprev, yprev = data2user(canvas, float(X[i - 1]), float(Y[i - 1]))
    xnext, ynext = data2user(canvas, float(X[i + 1]), float(Y[i + 1]))
    dx = xnext - xprev
    dy = ynext - yprev

    if isapprox(dx, 0.0; atol=1.0e-12) && isapprox(dy, 0.0; atol=1.0e-12)
        return _segment_tangent_angle(canvas, X, Y, i)
    end

    return -atand(dy, dx)
end


function _resolve_tag_point_and_tangent(canvas::Canvas, X::AbstractArray, Y::AbstractArray, tag_pos::Float64)
    len = 0.0
    lengths = Float64[0.0]
    for i in 2:length(X)
        len += norm((float(X[i]) - float(X[i - 1]), float(Y[i]) - float(Y[i - 1])))
        push!(lengths, len)
    end

    lpos = tag_pos * len
    tol = _tag_vertex_tolerance(len)
    vertex = findfirst(value -> abs(value - lpos) <= tol, lengths)

    if vertex !== nothing
        x, y = data2user(canvas, float(X[vertex]), float(Y[vertex]))
        tangent_angle = if vertex == 1
            _segment_tangent_angle(canvas, X, Y, 1)
        elseif vertex == length(lengths)
            _segment_tangent_angle(canvas, X, Y, length(lengths) - 1)
        else
            _vertex_tangent_angle(canvas, X, Y, vertex)
        end
        return x, y, tangent_angle
    end

    i = clamp(searchsortedlast(lengths, lpos), 1, length(lengths) - 1)
    t = (lpos - lengths[i]) / (lengths[i + 1] - lengths[i])
    x = float(X[i]) + t * (float(X[i + 1]) - float(X[i]))
    y = float(Y[i]) + t * (float(Y[i + 1]) - float(Y[i]))
    x, y = data2user(canvas, x, y)
    tangent_angle = _segment_tangent_angle(canvas, X, Y, i)
    return x, y, tangent_angle
end


"""
    configure!(figure)

Compute layout-dependent fields for `figure` in place.

`save` calls this automatically before rendering, so users usually do not need
to call it directly. Calling it manually is useful when inspecting computed axis
limits, tick labels, plot frames, legend frames, or grid cell frames before
rendering. `Chart` values must contain at least one data series, and
`ChartGrid` values must contain at least one child figure.

Returns the configured object for methods that expose a return value; callers
should rely on the mutation, not on a particular return.
"""
function configure!(c::Chart)

    length(c.dataseries) > 0 || throw(QuickChartsException("No dataseries added to the chart"))

    c.outerpad = 0.01 * min(c.width, c.height)
    c.figure_frame = Frame(c.figure_frame.x, c.figure_frame.y, c.width, c.height)

    configure!(c, c.xaxis, c.yaxis)

    if c.aspect_ratio == :equal
        plot_frame = _chart_plot_frame(c)
        xmin, xmax = c.xaxis.limits
        ymin, ymax = c.yaxis.limits
        r = min(plot_frame.width / (xmax - xmin), plot_frame.height / (ymax - ymin))
        dx = 0.5 * (plot_frame.width / r - (xmax - xmin))
        dy = 0.5 * (plot_frame.height / r - (ymax - ymin))

        c.xaxis.limits = [xmin - dx, xmax + dx]
        c.yaxis.limits = [ymin - dy, ymax + dy]
        if !c.xaxis.manual_ticks
            c.xaxis.ticks = Float64[]
        end
        if !c.yaxis.manual_ticks
            c.yaxis.ticks = Float64[]
        end
        if !c.xaxis.manual_tick_labels
            c.xaxis.tick_labels = String[]
        end
        if !c.yaxis.manual_tick_labels
            c.yaxis.tick_labels = String[]
        end

        configure!(c.xaxis)
        configure!(c.yaxis)
    end

    _assign_chart_frames!(c)

end


function configure!(c::Chart, canvas::Canvas)
    canvas.limits = [c.xaxis.limits[1], c.yaxis.limits[1], c.xaxis.limits[2], c.yaxis.limits[2]]
end


function configure!(chart::Chart, xax::Axis, yax::Axis)

    for ax in (xax, yax)
        if ax.auto_limits
            extent = ax.manual_ticks ? collect(extrema(ax.ticks)) : _chart_axis_data_extent(chart, ax)
            ax.limits = compute_auto_limits(extent)
        end
    end

    configure!(xax)
    configure!(yax)

end


function _chart_bar_width(series::DataSeries)
    w = series.bar_width
    if w == 0
        Xu = unique(sort(collect(series.X)))
        if length(Xu) > 1
            w = 0.56 * abs(minimum(diff(Xu)))
        else
            xspan = abs(maximum(series.X) - minimum(series.X))
            w = xspan > 0 ? 0.035 * xspan : 1.0
        end
    end
    return w
end


function _chart_legend_plots(c::Chart)
    return [p for p in c.dataseries if p.label != ""]
end


function _legend_measure_context(legend::Legend)
    surf = CairoImageSurface(4, 4, Cairo.FORMAT_ARGB32)
    cc = CairoContext(surf)
    font = get_font(legend.font)
    select_font_face(cc, font, Cairo.FONT_SLANT_NORMAL, Cairo.FONT_WEIGHT_NORMAL)
    set_font_size(cc, legend.font_size)
    return cc
end


function _legend_layout(legend::Legend, plots, cairo_ctx::CairoContext)
    nlabels = length(plots)
    ncols = legend.ncols
    nrows = ceil(Int, nlabels / ncols)
    nlabels == 0 && return zeros(ncols), Float64[], 0.0, 0.0

    col_widths = zeros(ncols)
    row_heights = zeros(nrows)
    vertical_pad = legend.row_sep

    for (k, plot) in enumerate(plots)
        i = ceil(Int, k / ncols)  # row
        j = k % ncols == 0 ? ncols : k % ncols # column
        label_width, current_height = getsize(cairo_ctx, plot.label, legend.font_size)
        item_width = legend.handle_length + 2 * legend.inner_pad + label_width
        col_widths[j] = max(col_widths[j], item_width)
        row_heights[i] = max(row_heights[i], current_height)
    end

    width = sum(col_widths) + (ncols - 1) * legend.col_sep + 2 * legend.inner_pad
    height = sum(row_heights) + (nrows - 1) * legend.row_sep + 2 * vertical_pad

    return col_widths, row_heights, width, height
end


function _chart_axis_data_extent(chart::Chart, ax::Axis)
    lower = Inf
    upper = -Inf

    for series in chart.dataseries
        series isa DataSeries || continue
        if ax.direction == :horizontal
            isempty(series.X) && continue
            if series.kind == :bar
                w = _chart_bar_width(series)
                lower = min(lower, minimum(series.X) - 0.5 * w)
                upper = max(upper, maximum(series.X) + 0.5 * w)
            else
                lower = min(lower, minimum(series.X))
                upper = max(upper, maximum(series.X))
            end
        else
            isempty(series.Y) && continue
            if series.kind == :bar
                base = series.bar_base
                lower = min(lower, minimum(min.(series.Y, base)))
                upper = max(upper, maximum(max.(series.Y, base)))
            else
                lower = min(lower, minimum(series.Y))
                upper = max(upper, maximum(series.Y))
            end
        end
    end

    return isfinite(lower) && isfinite(upper) ? [lower, upper] : [0.0, 1.0]
end


function configure!(c::Chart, legend::Legend)
    legend.handle_length = 1.9 * legend.font_size
    legend.row_sep = 0.3 * legend.font_size
    legend.col_sep = 1.5 * legend.font_size
    legend.inner_pad = 1.5 * legend.row_sep
    legend.outer_pad = legend.inner_pad

    plots = _chart_legend_plots(c)
    cc = _legend_measure_context(legend)
    _, _, legend.width, legend.height = _legend_layout(legend, plots, cc)
end


function _chart_title_font_size(c::Chart)
    return 1.2 * c.xaxis.font_size
end


function _chart_title_height(c::Chart)
    isempty(c.title_box.text) && return 0.0
    surf = CairoImageSurface(4, 4, Cairo.FORMAT_ARGB32)
    cc = CairoContext(surf)
    select_font_face(cc, get_font(c.xaxis.font), Cairo.FONT_SLANT_NORMAL, Cairo.FONT_WEIGHT_NORMAL)
    set_font_size(cc, _chart_title_font_size(c))
    return getsize(cc, c.title_box.text, _chart_title_font_size(c))[2]
end


function _chart_has_legend(c::Chart)
    return !isempty(_chart_legend_plots(c))
end


function _chart_plot_frame(c::Chart)
    left_margin = c.outerpad + c.yaxis.width
    right_margin = c.outerpad
    top_margin = c.outerpad + axis_top_overhang(c.yaxis)
    bottom_margin = c.outerpad + c.xaxis.height
    title_height = _chart_title_height(c)
    title_gap = isempty(c.title_box.text) ? 0.0 : 0.6 * c.xaxis.font_size

    top_margin += title_height + title_gap

    if _chart_has_legend(c)
        legend = c.legend
        if legend.location in (:outer_top_right, :outer_right, :outer_bottom_right)
            right_margin += c.outerpad + legend.width
        elseif legend.location in (:outer_top_left, :outer_left, :outer_bottom_left)
            left_margin += c.outerpad + legend.width
        elseif legend.location == :outer_top
            top_margin += legend.height + c.outerpad
        elseif legend.location == :outer_bottom
            bottom_margin += legend.height + c.outerpad
        end
    end

    width = c.width - left_margin - right_margin
    height = c.height - top_margin - bottom_margin
    frame = Frame(c.figure_frame.x + left_margin, c.figure_frame.y + top_margin, width, height)

    # Ensure the last horizontal tick label fits inside the figure frame.
    right_gap = minimum((frame.x + frame.width) - (frame.x + frame.width / (c.xaxis.limits[2] - c.xaxis.limits[1]) * (tick - c.xaxis.limits[1])) for tick in c.xaxis.ticks)
    extra_right = max(0.0, getsize(c.xaxis.tick_labels[end], c.xaxis.font_size)[1] / 2 - right_gap)

    # Ensure the top-most vertical tick label fits inside the figure frame.
    top_gap = minimum(frame.y + frame.height / (c.yaxis.limits[2] - c.yaxis.limits[1]) * (c.yaxis.limits[2] - tick) - frame.y for tick in c.yaxis.ticks)
    extra_top = max(0.0, getsize(c.yaxis.tick_labels[end], c.yaxis.font_size)[2] / 2 - top_gap)

    return Frame(c.figure_frame.x + left_margin, c.figure_frame.y + top_margin + extra_top, width - extra_right, height - extra_top)
end


function _assign_chart_frames!(c::Chart)
    _chart_has_legend(c) && configure!(c, c.legend)

    plot_frame = _chart_plot_frame(c)
    plot_frame.width > 0 && plot_frame.height > 0 || throw(ArgumentError("Chart: insufficient space for plot area"))

    c.canvas.frame = plot_frame
    configure!(c, c.canvas)

    c.xaxis.width = plot_frame.width
    c.xaxis.frame = Frame(plot_frame.x, plot_frame.y + plot_frame.height, plot_frame.width, c.xaxis.height)

    c.yaxis.height = plot_frame.height
    c.yaxis.frame = Frame(plot_frame.x - c.yaxis.width, plot_frame.y, c.yaxis.width, plot_frame.height)

    c.left_items = FigureComponent[c.yaxis]
    c.right_items = FigureComponent[]
    c.top_items = FigureComponent[]
    c.bottom_items = FigureComponent[c.xaxis]
    c.overlay_items = FigureComponent[a for a in c.annotations]

    if !isempty(c.title_box.text)
        title_height = _chart_title_height(c)
        y = c.figure_frame.y + c.outerpad
        c.title_box.frame = Frame(plot_frame.x, y, plot_frame.width, title_height)
        c.title_box.angle = 0.0
    else
        c.title_box.frame = Frame()
    end

    if _chart_has_legend(c)
        _assign_legend_frame!(c, c.legend)
    else
        c.legend.frame = Frame()
    end
end


function _assign_legend_frame!(c::Chart, legend::Legend)
    plot = c.canvas.frame
    outer_pad = legend.outer_pad

    if legend.location in (:top_right, :right, :bottom_right)
        x1 = plot.x + plot.width - outer_pad - legend.width
    elseif legend.location in (:top, :bottom, :outer_top, :outer_bottom)
        x1 = plot.x + 0.5 * (plot.width - legend.width)
    elseif legend.location in (:top_left, :left, :bottom_left)
        x1 = plot.x + outer_pad
    elseif legend.location in (:outer_top_left, :outer_left, :outer_bottom_left)
        x1 = c.figure_frame.x + c.outerpad
    elseif legend.location in (:outer_top_right, :outer_right, :outer_bottom_right)
        x1 = c.figure_frame.x + c.width - legend.width - c.outerpad
    else
        error("Chart: unsupported legend location $(legend.location)")
    end

    if legend.location in (:top_left, :top, :top_right)
        y1 = plot.y + outer_pad
    elseif legend.location in (:left, :right, :outer_left, :outer_right)
        y1 = plot.y + 0.5 * (plot.height - legend.height)
    elseif legend.location in (:bottom_left, :bottom, :bottom_right)
        y1 = plot.y + plot.height - outer_pad - legend.height
    elseif legend.location == :outer_top
        y1 = c.figure_frame.y + c.outerpad + _chart_title_height(c) + (isempty(c.title_box.text) ? 0.0 : 0.6 * c.xaxis.font_size)
    elseif legend.location == :outer_bottom
        y1 = c.figure_frame.y + c.height - legend.height - c.outerpad
    elseif legend.location in (:outer_top_left, :outer_top_right)
        y1 = plot.y
    elseif legend.location in (:outer_bottom_left, :outer_bottom_right)
        y1 = plot.y + plot.height - legend.height
    else
        error("Chart: unsupported legend location $(legend.location)")
    end

    legend.frame = Frame(x1, y1, legend.width, legend.height)

    if legend.location in (:outer_top_right, :outer_right, :outer_bottom_right)
        push!(c.right_items, legend)
    elseif legend.location in (:outer_top_left, :outer_left, :outer_bottom_left)
        push!(c.left_items, legend)
    elseif legend.location in (:outer_top,)
        push!(c.top_items, legend)
    elseif legend.location in (:outer_bottom,)
        push!(c.bottom_items, legend)
    else
        push!(c.overlay_items, legend)
    end
end


function draw!(c::Chart, ctx::RenderContext, canvas::Canvas)
    # draw grid
    cairo_ctx = ctx.cairo_ctx
    reset_matrix!(ctx)
    set_source_rgba(cairo_ctx, rgba(_chart_gridline_color(c, ctx))...)
    set_line_width(cairo_ctx, 0.2 * ctx.width_scale)
    x0 = canvas.frame.x
    y0 = canvas.frame.y
    x1 = canvas.frame.x + canvas.frame.width
    y1 = canvas.frame.y + canvas.frame.height

    xmin, xmax = c.xaxis.limits
    for x in c.xaxis.ticks
        min(xmax, xmin) <= x <= max(xmax, xmin) || continue
        xc = x0 + canvas.frame.width / (xmax - xmin) * (x - xmin)
        move_to(cairo_ctx, xc, y0)
        line_to(cairo_ctx, xc, y1)
        stroke(cairo_ctx)
    end

    ymin, ymax = c.yaxis.limits
    for y in c.yaxis.ticks
        min(ymax, ymin) <= y <= max(ymax, ymin) || continue
        yc = y0 + canvas.frame.height / (ymax - ymin) * (ymax - y)
        move_to(cairo_ctx, x0, yc)
        line_to(cairo_ctx, x1, yc)
        stroke(cairo_ctx)
    end

    # draw border
    set_source_rgb(cairo_ctx, 0.0, 0.0, 0.0)
    set_line_width(cairo_ctx, 0.5 * ctx.width_scale)
    rectangle(cairo_ctx, x0, y0, canvas.frame.width, canvas.frame.height)
    stroke(cairo_ctx)
end


function draw!(chart::Chart, ctx::RenderContext, p::DataSeries)
    cairo_ctx = ctx.cairo_ctx

    p.mark_color = p.mark_color == :auto ? p.color : p.mark_color
    p.mark_stroke_color = p.mark_stroke_color == :auto ? p.color : p.mark_stroke_color

    # p.mark_color = get_color(p.mark_color, p.color)
    # p.mark_stroke_color = get_color(p.mark_stroke_color, p.color)

    reset_matrix!(ctx)
    set_source_rgb(cairo_ctx, rgb(p.color)...)
    set_line_width(cairo_ctx, p.line_width * ctx.width_scale)
    set_line_join(cairo_ctx, Cairo.CAIRO_LINE_JOIN_ROUND)

    # Draw lines
    new_path(cairo_ctx)
    n = length(p.X)
    X = float.(p.X)
    Y = float.(p.Y)
    if p.kind == :bar
        xmin, xmax = chart.xaxis.limits
        xspan = abs(xmax - xmin)

        w = p.bar_width
        if w == 0
            if n > 1
                Xu = unique(sort(collect(X)))
                if length(Xu) > 1
                    dx = minimum(diff(Xu))
                    w = 0.56 * abs(dx)
                end
            end
            w == 0 && (w = xspan > 0 ? 0.035 * xspan : 1.0)
        end
        base = p.bar_base

        for (x, y) in zip(X, Y)
            y0 = base
            h = y - y0
            xleft = x - 0.5 * w
            ytop = h >= 0 ? y : y0
            rect_x, rect_y = data2user(chart.canvas, xleft, ytop)
            xden = abs(chart.xaxis.limits[2] - chart.xaxis.limits[1])
            yden = abs(chart.yaxis.limits[2] - chart.yaxis.limits[1])
            rect_w = xden > 0 ? chart.canvas.frame.width / xden * w : 0.0
            rect_h = yden > 0 ? chart.canvas.frame.height / yden * abs(h) : 0.0

            rectangle(cairo_ctx, rect_x, rect_y, rect_w, rect_h)
            fill_preserve(cairo_ctx)
            set_source_rgb(cairo_ctx, 0.0, 0.0, 0.0)
            set_line_width(cairo_ctx, p.line_width * ctx.width_scale)
            stroke(cairo_ctx)
            set_source_rgb(cairo_ctx, rgb(p.color)...)
        end
        return
    end

    if p.kind != :scatter && p.line_style !== :none
        x1, y1 = data2user(chart.canvas, X[1], Y[1])

        if p.line_style == :solid
            move_to(cairo_ctx, x1, y1)
            for i in 2:n
                x, y = data2user(chart.canvas, X[i], Y[i])
                line_to(cairo_ctx, x, y)
            end
            stroke(cairo_ctx)
        else # dashed
            len = sum(p.dash)
            offset = 0.0
            set_dash(cairo_ctx, p.dash, offset)
            move_to(cairo_ctx, x1, y1)
            for i in 2:n
                x, y = data2user(chart.canvas, X[i], Y[i])
                line_to(cairo_ctx, x, y)
                offset = mod(offset + norm((x1 - x, y1 - y)), len)
                set_dash(cairo_ctx, p.dash, offset)
                x1, y1 = x, y
            end
            stroke(cairo_ctx)
            set_dash(cairo_ctx, Float64[])
        end
    end

    # Draw marks
    for (x, y) in zip(X, Y)
        x, y = data2user(chart.canvas, x, y)
        draw_mark(cairo_ctx, x, y, p.mark, p.mark_size, p.mark_color, p.mark_stroke_color)
    end

    # Draw tag
    if p.tag != ""
        x, y, tangent_angle = _resolve_tag_point_and_tangent(chart.canvas, X, Y, p.tag_pos)

        pad = something(p.tag_padding, chart.xaxis.font_size * 0.3)
        tag_font_size = something(p.tag_font_size, chart.xaxis.font_size * 0.8)
        ha, va, dx, dy, α = _resolve_tag_layout(p.tag_anchor, p.tag_orientation, tangent_angle, pad)

        set_font_size(cairo_ctx, tag_font_size)
        font = get_font(chart.xaxis.font)
        select_font_face(cairo_ctx, font, Cairo.FONT_SLANT_NORMAL, Cairo.FONT_WEIGHT_NORMAL)
        set_source_rgb(cairo_ctx, 0, 0, 0)

        if _debug_tag_points[]
            # Debug overlay: red marks the sampled on-curve tag position, dark red
            # marks the final anchor point used to place the text box.
            set_source_rgb(cairo_ctx, 1.0, 0.0, 0.0)
            arc(cairo_ctx, x, y, 2.2, 0, 2pi)
            fill(cairo_ctx)
            set_source_rgb(cairo_ctx, 0.65, 0.0, 0.0)
            arc(cairo_ctx, x + dx, y + dy, 2.2, 0, 2pi)
            fill(cairo_ctx)
        end

        draw_text(cairo_ctx, x + dx, y + dy, p.tag, halign=ha, valign=va, angle=α)
    end

end


function draw!(c::Chart, ctx::RenderContext, legend::Legend)
    cairo_ctx = ctx.cairo_ctx

    plots = _chart_legend_plots(c)

    set_font_size(cairo_ctx, legend.font_size)
    font = get_font(legend.font)
    select_font_face(cairo_ctx, font, Cairo.FONT_SLANT_NORMAL, Cairo.FONT_WEIGHT_NORMAL)

    inner_pad = legend.inner_pad
    col_sep = legend.col_sep
    ncols = legend.ncols

    col_widths, row_heights, legend.width, legend.height = _legend_layout(legend, plots, cairo_ctx)

    x1 = legend.frame.x
    y1 = legend.frame.y
    x2 = legend.frame.x + legend.frame.width
    y2 = legend.frame.y + legend.frame.height

    reset_matrix!(ctx)

    # draw rounded rectangle
    r = 0.02 * min(c.canvas.frame.width, c.canvas.frame.height)
    move_to(cairo_ctx, x1, y1 + r)
    line_to(cairo_ctx, x1, y2 - r)
    curve_to(cairo_ctx, x1, y2, x1, y2, x1 + r, y2)
    line_to(cairo_ctx, x2 - r, y2)
    curve_to(cairo_ctx, x2, y2, x2, y2, x2, y2 - r)
    line_to(cairo_ctx, x2, y1 + r)
    curve_to(cairo_ctx, x2, y1, x2, y1, x2 - r, y1)
    line_to(cairo_ctx, x1 + r, y1)
    curve_to(cairo_ctx, x1, y1, x1, y1, x1, y1 + r)
    close_path(cairo_ctx)
    legend_background = something(legend.background, ctx.background, Color(:white))
    set_source_rgba(cairo_ctx, rgba(legend_background)...)
    fill_preserve(cairo_ctx)
    set_source_rgb(cairo_ctx, 0, 0, 0) # black
    set_line_width(cairo_ctx, 0.4 * ctx.width_scale)
    stroke(cairo_ctx)

    for (k, plot) in enumerate(plots)
        i = ceil(Int, k / ncols)  # line
        j = k % ncols == 0 ? ncols : k % ncols # column
        x2 = x1 + inner_pad + sum(col_widths[1:j-1]) + (j - 1) * col_sep

        y2 = y1 + legend.row_sep + sum(row_heights[1:i-1]) + (i - 1) * legend.row_sep + row_heights[i] / 2

        set_source_rgb(cairo_ctx, rgb(plot.color)...)
        if plot.kind == :bar
            hbar = 0.6 * legend.font_size
            rectangle(cairo_ctx, x2, y2 - 0.5 * hbar, legend.handle_length, hbar)
            fill_preserve(cairo_ctx)
            set_source_rgb(cairo_ctx, 0.0, 0.0, 0.0)
            set_line_width(cairo_ctx, max(plot.line_width, 0.4) * ctx.width_scale)
            stroke(cairo_ctx)
            set_source_rgb(cairo_ctx, rgb(plot.color)...)
        elseif plot.line_style != :none
            move_to(cairo_ctx, x2, y2)
            rel_line_to(cairo_ctx, legend.handle_length, 0)
            set_line_width(cairo_ctx, plot.line_width * ctx.width_scale)
            plot.line_style != :solid && set_dash(cairo_ctx, plot.dash)
            stroke(cairo_ctx)
            set_dash(cairo_ctx, Float64[])
        end

        # draw mark
        if plot.kind != :bar
            x = x2 + legend.handle_length / 2
            draw_mark(cairo_ctx, x, y2, plot.mark, plot.mark_size, plot.mark_color, plot.mark_stroke_color)
        end

        # draw label
        x = x2 + legend.handle_length + 2 * inner_pad
        y = y2

        set_source_rgb(cairo_ctx, 0, 0, 0)
        draw_text(cairo_ctx, x, y, plot.label, halign="left", valign="center", angle=0)
    end

end


function draw_background!(c::Chart, ctx::RenderContext)
    _draw_figure_background!(ctx, c.figure_frame, ctx.background)
end

function draw_contents!(c::Chart, ctx::RenderContext)
    cairo_ctx = ctx.cairo_ctx
    reset_matrix!(ctx)
    # draw canvas grid
    draw!(c, ctx, c.canvas)

    # draw axes
    draw!(c.xaxis, ctx)

    draw!(c.yaxis, ctx)

    # draw plots
    rectangle(cairo_ctx, c.canvas.frame.x, c.canvas.frame.y, c.canvas.frame.width, c.canvas.frame.height)
    Cairo.clip(cairo_ctx)

    # draw dataseries
    sorted = sort(c.dataseries, by=x -> x.order)
    for p in sorted
        draw!(c, ctx, p)
    end
    reset_clip(cairo_ctx)

    if !isempty(c.title_box.text)
        reset_matrix!(ctx)
        select_font_face(cairo_ctx, get_font(c.xaxis.font), Cairo.FONT_SLANT_NORMAL, Cairo.FONT_WEIGHT_NORMAL)
        set_font_size(cairo_ctx, _chart_title_font_size(c))
        set_source_rgb(cairo_ctx, 0.0, 0.0, 0.0)
        _draw_text_box!(ctx, c.title_box)
    end

    # draw overlay annotations before legend
    for item in c.overlay_items
        item isa Annotation || continue
        draw!(c, ctx, item)
    end

    # draw legend last
    if _chart_has_legend(c)
        draw!(c, ctx, c.legend)
    end
end


function add_annotation(c::Chart, a::Annotation)
    push!(c.annotations, a)
    push!(c.overlay_items, a)
    return a
end
