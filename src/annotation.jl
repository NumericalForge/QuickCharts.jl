# This file is part of the QuickCharts.jl package. It is licensed under the MIT License.

"""
    Annotation(text::AbstractString, x::Real, y::Real; kwargs...)
    Annotation(text::AbstractString, pos; kwargs...)

Create a plot-area annotation.

`x` and `y` are normalized coordinates in the chart canvas, where `(0, 0)` is
the lower-left of the plot area and `(1, 1)` is the upper-right. Set
`target=[xdata, ydata]` to draw a connector from the annotation to a point in
data coordinates.

# Keyword options
- `anchor`: `:auto`, `:left`, `:right`, `:top`, or `:bottom`.
- `target`: optional two-element data-coordinate target for a connector.
- `line_width`: positive connector stroke width.
- `font`: annotation font family.
- `font_size`: annotation font size in points. `nothing` uses `0.8 * chart.xaxis.font_size`.
- `color`: named annotation text and connector color.
"""
mutable struct Annotation <: FigureComponent
    text       ::AbstractString
    x          ::Float64
    y          ::Float64
    anchor     ::Symbol
    target     ::Vector{Float64}
    has_target ::Bool
    line_width ::Float64
    font       ::String
    font_size  ::Union{Nothing,Float64}
    color      ::Symbol
    
    function Annotation(text::AbstractString, x::Real, y::Real;
        anchor::Symbol=:auto,
        target::Union{Nothing,AbstractArray{<:Real,1}}=nothing,
        line_width::Real=0.4,
        font::AbstractString="serif",
        font_size::Union{Nothing,Real}=nothing,
        color::Symbol=:black
    )

        0 <= x <= 1 || throw(ArgumentError("x must be in the range [0,1]"))
        0 <= y <= 1 || throw(ArgumentError("y must be in the range [0,1]"))
        anchor in (:auto, :left, :right, :top, :bottom) || throw(ArgumentError("Invalid anchor: $(repr(anchor))"))
        line_width > 0 || throw(ArgumentError("line_width must be positive"))
        font_size === nothing || font_size > 0 || throw(ArgumentError("font_size must be positive"))

        has_target = target !== nothing
        if has_target
            length(target) == 2 || throw(ArgumentError("target must be a 2D point"))
            target = float.(target)
        else
            target = [ NaN, NaN ]
        end

        return new(text, x, y, anchor, target, has_target, line_width, font, font_size === nothing ? nothing : float(font_size), color)
    end
end


"""
    add_annotation(chart::Chart, annotation::Annotation)
    add_annotation(chart::Chart, text::AbstractString, pos; kwargs...)

Append an annotation to `chart` and return it.

Annotations are drawn over the plot canvas when the chart is saved or otherwise
rendered.
"""
function add_annotation(c::Figure, a::Annotation)
    push!(c.annotations, a)
    return a
end


function Annotation(text::AbstractString, pos::NTuple{2,<:Real}; kwargs...)
    return Annotation(text, pos[1], pos[2]; kwargs...)
end


function Annotation(text::AbstractString, pos::AbstractArray{<:Real,1}; kwargs...)
    length(pos) == 2 || throw(ArgumentError("annotation position must be a 2D point"))
    return Annotation(text, pos[1], pos[2]; kwargs...)
end


function add_annotation(c::Figure, text::AbstractString, pos; kwargs...)
    return add_annotation(c, Annotation(text, pos; kwargs...))
end


function _annotation_anchor_alignment(anchor::Symbol)
    anchor == :left && return "left", "center"
    anchor == :right && return "right", "center"
    anchor == :top && return "center", "top"
    anchor == :bottom && return "center", "bottom"
    anchor == :auto && return "left", "center"
    throw(ArgumentError("Invalid annotation anchor: $(repr(anchor))"))
end


function _annotation_box_center(x::Float64, y::Float64, w::Float64, h::Float64, halign::AbstractString, valign::AbstractString)
    cx = halign == "left" ? x + w / 2 : halign == "right" ? x - w / 2 : x
    cy = valign == "top" ? y + h / 2 : valign == "bottom" ? y - h / 2 : y
    return cx, cy
end


function _annotation_connector_points(cx::Float64, cy::Float64, w::Float64, h::Float64, xa::Float64, ya::Float64)
    hx = 0.5 * w
    hy = 0.5 * h
    dx = xa - cx
    dy = ya - cy

    # Single horizontal connector when the target projects onto a vertical side.
    if abs(dy) <= hy
        x0 = dx >= 0 ? cx + hx : cx - hx
        return [(x0, ya), (xa, ya)]
    end

    # Single vertical connector when the target projects onto a horizontal side.
    if abs(dx) <= hx
        y0 = dy >= 0 ? cy + hy : cy - hy
        return [(xa, y0), (xa, ya)]
    end

    # Otherwise use a two-segment orthogonal connector. Choose the first leg
    # using distance normalized by the box half-size so aspect ratio matters.
    sx = abs(dx) / max(hx, eps(Float64))
    sy = abs(dy) / max(hy, eps(Float64))

    if sx >= sy
        x0 = dx >= 0 ? cx + hx : cx - hx
        y0 = cy
        return [(x0, y0), (xa, y0), (xa, ya)]
    else
        x0 = cx
        y0 = dy >= 0 ? cy + hy : cy - hy
        return [(x0, y0), (x0, ya), (xa, ya)]
    end
end


function draw!(c::Figure, ctx::RenderContext, a::Annotation)
    cairo_ctx = ctx.cairo_ctx
    font_size = something(a.font_size, c.xaxis.font_size * 0.8)

    set_font_size(cairo_ctx, font_size)
    font = get_font(a.font)
    select_font_face(cairo_ctx, font, Cairo.FONT_SLANT_NORMAL, Cairo.FONT_WEIGHT_NORMAL)

    reset_matrix!(ctx)

    # convert from axes to Cairo coordinates
    x = c.canvas.frame.x + a.x * c.canvas.frame.width
    y = c.canvas.frame.y + (1 - a.y) * c.canvas.frame.height
    halign, valign = _annotation_anchor_alignment(a.anchor)
    set_source_rgb(cairo_ctx, _colors_dict[a.color]...)
    draw_text(cairo_ctx, x, y, a.text, halign=halign, valign=valign, angle=0)

    # draw arrow
    if a.has_target

        # compute text size
        w, h = getsize(cairo_ctx, a.text, font_size)
        text_outerpad = 0.1 * min(w, h)

        x, y = _annotation_box_center(x, y, w, h, halign, valign)

        w += text_outerpad
        h += text_outerpad

        # target coordinates
        xa, ya = data2user(c.canvas, a.target[1], a.target[2])
        points = _annotation_connector_points(x, y, w, h, xa, ya)

        set_source_rgb(cairo_ctx, _colors_dict[a.color]...)

        set_line_join(cairo_ctx, Cairo.CAIRO_LINE_JOIN_ROUND)
        set_line_width(cairo_ctx, a.line_width * ctx.width_scale)

        x_prev, y_prev = points[1]
        move_to(cairo_ctx, x_prev, y_prev)
        for (xp, yp) in points[2:end]
            line_to(cairo_ctx, xp, yp)
        end
        if length(points) >= 2
            x_prev, y_prev = points[end - 1]
            x, y = points[end]
        else
            x, y = points[end]
        end

        stroke(cairo_ctx)

        # Draw a concave (chevron/notched) arrowhead at target.
        vx = xa - x_prev
        vy = ya - y_prev
        vlen = hypot(vx, vy)
        if vlen < 1e-8
            vx = xa - x
            vy = ya - y
            vlen = hypot(vx, vy)
        end
        if vlen > 1e-8
            ux = vx / vlen
            uy = vy / vlen
            nx = -uy
            ny = ux

            head_len = max(6.0 * a.line_width, 4.0)
            head_w = 0.9 * head_len
            notch_depth = 0.45 * head_len

            tipx, tipy = xa, ya
            basex = tipx - head_len * ux
            basey = tipy - head_len * uy
            leftx = basex + 0.5 * head_w * nx
            lefty = basey + 0.5 * head_w * ny
            rightx = basex - 0.5 * head_w * nx
            righty = basey - 0.5 * head_w * ny
            notchx = tipx - (head_len - notch_depth) * ux
            notchy = tipy - (head_len - notch_depth) * uy

            move_to(cairo_ctx, tipx, tipy)
            line_to(cairo_ctx, leftx, lefty)
            line_to(cairo_ctx, notchx, notchy)
            line_to(cairo_ctx, rightx, righty)
            close_path(cairo_ctx)
            fill(cairo_ctx)
        end
    end
end
