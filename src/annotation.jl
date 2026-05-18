
"""
    Annotation(text::AbstractString, x::Real, y::Real; kwargs...)

Create a plot-area annotation.

`x` and `y` are normalized coordinates in the chart canvas, where `(0, 0)` is
the lower-left of the plot area and `(1, 1)` is the upper-right. Set
`target=[xdata, ydata]` to draw a connector from the annotation to a point in
data coordinates.

# Keyword options
- `alignment`: `:auto`, `:left`, `:right`, `:top`, or `:bottom`.
- `target`: optional two-element data-coordinate target for a connector.
- `line_width`: positive connector stroke width.
- `font`: annotation font family.
- `font_size`: positive annotation font size.
- `color`: named annotation text and connector color.
"""
mutable struct Annotation <: FigureComponent
    text       ::AbstractString
    x          ::Float64
    y          ::Float64
    alignment  ::Symbol
    target     ::Vector{Float64}
    has_target ::Bool
    line_width ::Float64
    font       ::String
    font_size  ::Float64
    color      ::Symbol
    
    function Annotation(text::AbstractString, x::Real, y::Real;
        alignment::Symbol=:auto,
        target::Union{Nothing,AbstractArray{<:Real,1}}=nothing,
        line_width::Real=0.4,
        font::AbstractString="NewComputerModern",
        font_size::Real=6.0,
        color::Symbol=:black
    )

        0 <= x <= 1 || throw(ArgumentError("x must be in the range [0,1]"))
        0 <= y <= 1 || throw(ArgumentError("y must be in the range [0,1]"))
        alignment in (:auto, :left, :right, :top, :bottom) || throw(ArgumentError("Invalid alignment: $(repr(alignment))"))
        line_width > 0 || throw(ArgumentError("line_width must be positive"))
        font_size > 0 || throw(ArgumentError("font_size must be positive"))

        has_target = target !== nothing
        if has_target
            length(target) == 2 || throw(ArgumentError("target must be a 2D point"))
            target = float.(target)
        else
            target = [ NaN, NaN ]
        end

        return new(text, x, y, alignment, target, has_target, line_width, font, font_size, color)
    end
end


"""
    add_annotation(chart::Chart, annotation::Annotation)

Append `annotation` to `chart` and return the annotation.

Annotations are drawn over the plot canvas when the chart is saved or otherwise
rendered.
"""
function add_annotation(c::Figure, a::Annotation)
    push!(c.annotations, a)
    return a
end


function draw!(c::Figure, ctx::RenderContext, a::Annotation)
    cairo_ctx = ctx.cairo_ctx

    set_font_size(cairo_ctx, a.font_size)
    font = get_font(a.font)
    select_font_face(cairo_ctx, font, Cairo.FONT_SLANT_NORMAL, Cairo.FONT_WEIGHT_NORMAL)

    reset_matrix!(ctx)

    # convert from axes to Cairo coordinates
    x = c.canvas.frame.x + a.x * c.canvas.frame.width
    y = c.canvas.frame.y + (1 - a.y) * c.canvas.frame.height
    halign = a.alignment == :right ? "right" : "left"
    valign = a.alignment == :top ? "top" : "bottom"
    set_source_rgb(cairo_ctx, _colors_dict[a.color]...)
    draw_text(cairo_ctx, x, y, a.text, halign=halign, valign=valign, angle=0)

    if a.alignment == :auto
        a.alignment = :left
    end

    # draw arrow
    if a.has_target

        # compute text size
        w, h = getsize(cairo_ctx, a.text, a.font_size)
        text_outerpad = 0.1 * min(w, h)

        x = halign == "left" ? x + w/2 : x - w/2
        y = valign == "top" ? y + h/2 : y - h/2

        w += text_outerpad
        h += text_outerpad

        # target coordinates
        xa, ya = data2user(c.canvas, a.target[1], a.target[2])

        # deltas
        dx = xa - x
        dy = ya - y

        # compute lines
        if abs(dx) > abs(dy)
            if abs(dy) < h / 2
                lines = "-|"
                if dx > 0
                    x += w / 2 # right
                else
                    x -= w / 2 # left
                end
            else # two lines
                lines = "|-"
                if dy > 0 # top
                    y += h / 2
                else # bottom
                    y -= h / 2
                end
            end
        else
            if abs(dx) < w / 2
                lines = "|-"
                if dy > 0
                    y += h / 2 # top
                else
                    y -= h / 2 # bottom
                end
            else # two lines
                lines = "-|"
                if dx > 0 # right
                    x += w / 2
                else # left
                    x -= w / 2
                end
            end
        end

        set_source_rgb(cairo_ctx, _colors_dict[a.color]...)

        set_line_join(cairo_ctx, Cairo.CAIRO_LINE_JOIN_ROUND)
        set_line_width(cairo_ctx, a.line_width * ctx.width_scale)

        # update deltas
        dx = xa - x
        dy = ya - y

        # Draw line 1
        move_to(cairo_ctx, x, y)
        if lines[1] == '|'
            rel_line_to(cairo_ctx, 0, dy)
            y += dy
        else
            rel_line_to(cairo_ctx, dx, 0)
            x += dx
        end

        # Draw line 2
        x_prev, y_prev = x, y
        move_to(cairo_ctx, x, y)
        if lines[2] == '|'
            rel_line_to(cairo_ctx, 0, dy)
            y += dy
        else
            rel_line_to(cairo_ctx, dx, 0)
            x += dx
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
