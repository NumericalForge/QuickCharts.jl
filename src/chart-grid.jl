# This file is part of the QuickCharts.jl package. It is licensed under the MIT License.

"""
    ChartGrid(; title="", size=nothing, font="serif", font_size=10.0,
                background=nothing,
                column_headers=String[], row_headers=String[],
                outerpad=0.0, hgap=8.0, vgap=8.0)

Create a composed figure that arranges child figures in a grid with
row/column sizes derived from its contents.

# Keywords
- `title::AbstractString`: grid title centered above the cells.
- `size::Union{Nothing,Tuple{<:Real,<:Real}}`: figure size in points. `nothing`
  enables autosize based on child figures. Use `cm` as a convenience helper,
  e.g. `size=(16cm, 10cm)`.
- `font::AbstractString`: font family used for the grid title and headers.
- `font_size::Real`: title and header font size.
- `background`: full-figure background fill; `nothing` leaves the figure unfilled.
- `column_headers::Vector{<:AbstractString}`: optional headers centered above columns.
- `row_headers::Vector{<:AbstractString}`: optional headers drawn on the left, rotated like y-axis labels.
- `outerpad::Real`: outer figure margin.
- `hgap::Real`, `vgap::Real`: horizontal and vertical gaps between cells.

# Notes
- Add child figures with `add_chart`.
- The grid can contain any `Figure`, including `Chart` or another `ChartGrid`.
- Prefer backticks for inline math in titles and headers, e.g. `` `sigma_n` ``.
  Dollar delimiters are also accepted, but must be escaped in Julia strings,
  e.g. `"\$sigma_n\$"`.
- `background=nothing` leaves the grid background unfilled in vector outputs and uses a white page background in PNG.
- Child chart backgrounds are ignored when charts are rendered inside a grid.
- Headers and titles use the same math-aware text rendering as the rest of the plotting API.
"""
mutable struct ChartGrid <: Figure
    width::Float64
    height::Float64
    figure_frame::Frame
    title_box::TextBox
    font::String
    font_size::Float64
    background::Union{Nothing,Color}
    column_header_boxes::Vector{TextBox}
    row_header_boxes::Vector{TextBox}
    outerpad::Float64
    requested_outerpad::Float64
    hgap::Float64
    vgap::Float64
    children::Dict{Tuple{Int,Int},Figure}
    cell_frames::Dict{Tuple{Int,Int},Frame}
    nrows::Int
    ncols::Int
    auto_size::Bool

    function ChartGrid(;
        title::AbstractString="",
        size::Union{Nothing,Tuple{<:Real,<:Real}}=nothing,
        font::AbstractString="NewComputerModern",
        font_size::Real=12.0,
        background=nothing,
        column_headers::Vector{<:AbstractString}=String[],
        row_headers::Vector{<:AbstractString}=String[],
        outerpad::Real=0.0,
        hgap::Real=8.0,
        vgap::Real=8.0,
    )
        font_size > 0 || throw(ArgumentError("ChartGrid: font_size must be positive"))
        hgap >= 0 || throw(ArgumentError("ChartGrid: hgap must be non-negative"))
        vgap >= 0 || throw(ArgumentError("ChartGrid: vgap must be non-negative"))

        auto_size = size === nothing
        width, height = auto_size ? (0.0, 0.0) : size
        background = resolve_color(background)
        title_box = TextBox(title)
        column_header_boxes = TextBox[TextBox(String(s)) for s in column_headers]
        row_header_boxes = TextBox[TextBox(String(s); angle=90.0) for s in row_headers]
        return new(
            width,
            height,
            Frame(0.0, 0.0, width, height),
            title_box,
            String(font),
            float(font_size),
            background,
            column_header_boxes,
            row_header_boxes,
            float(outerpad),
            float(outerpad),
            float(hgap),
            float(vgap),
            Dict{Tuple{Int,Int},Figure}(),
            Dict{Tuple{Int,Int},Frame}(),
            0,
            0,
            auto_size,
        )
    end
end

_figure_background(grid::ChartGrid) = grid.background
_figure_renderable(grid::ChartGrid) = !isempty(grid.children) && all(_figure_renderable, values(grid.children))


"""
    add_chart(grid::ChartGrid, child::Figure, pos::Tuple{Int,Int})

Insert `child` into `grid` at position `(row, col)`.

# Arguments
- `grid::ChartGrid`: target grid.
- `child::Figure`: child figure to place in the grid.
- `pos::Tuple{Int,Int}`: one-based `(row, col)` cell coordinates.

# Notes
- Grid dimensions grow automatically to accommodate the largest inserted row/column.
- Inserting into an occupied cell throws an error.
"""
function add_chart(grid::ChartGrid, child::Figure, pos::Tuple{Int,Int})
    i, j = pos
    i > 0 && j > 0 || throw(ArgumentError("ChartGrid: cell indices must be positive"))
    !haskey(grid.children, pos) || throw(ArgumentError("ChartGrid: position $pos is already occupied"))

    grid.children[pos] = child
    grid.nrows = max(grid.nrows, i)
    grid.ncols = max(grid.ncols, j)
    return child
end


function _measure_grid_title(grid::ChartGrid)
    surf = CairoImageSurface(4, 4, Cairo.FORMAT_ARGB32)
    cc = CairoContext(surf)
    select_font_face(cc, get_font(grid.font), Cairo.FONT_SLANT_NORMAL, Cairo.FONT_WEIGHT_NORMAL)
    set_font_size(cc, grid.font_size)
    return _measure_text_box(grid.title_box, cc, grid.font_size)
end


function _measure_grid_headers(grid::ChartGrid)
    surf = CairoImageSurface(4, 4, Cairo.FORMAT_ARGB32)
    cc = CairoContext(surf)
    select_font_face(cc, get_font(grid.font), Cairo.FONT_SLANT_NORMAL, Cairo.FONT_WEIGHT_NORMAL)
    set_font_size(cc, grid.font_size)

    ncol_headers = min(length(grid.column_header_boxes), grid.ncols)
    nrow_headers = min(length(grid.row_header_boxes), grid.nrows)

    col_height = 0.0
    for i in 1:ncol_headers
        _, h = _measure_text_box_extent(grid.column_header_boxes[i], cc, grid.font_size)
        col_height = max(col_height, h)
    end

    row_width = 0.0
    for i in 1:nrow_headers
        w, _ = _measure_text_box_extent(grid.row_header_boxes[i], cc, grid.font_size)
        row_width = max(row_width, w)
    end

    return col_height, row_width
end


function _grid_validate_tracks(grid::ChartGrid)
    grid.nrows > 0 && grid.ncols > 0 || throw(ArgumentError("ChartGrid: invalid grid dimensions"))

    occupied_rows = falses(grid.nrows)
    occupied_cols = falses(grid.ncols)
    for (i, j) in keys(grid.children)
        occupied_rows[i] = true
        occupied_cols[j] = true
    end

    missing_row = findfirst(!, occupied_rows)
    missing_col = findfirst(!, occupied_cols)
    missing_row === nothing || throw(ArgumentError("ChartGrid: row $missing_row has no child figures"))
    missing_col === nothing || throw(ArgumentError("ChartGrid: column $missing_col has no child figures"))
    return nothing
end


function _grid_child_natural_size!(child::Chart)
    return child.width, child.height
end


function _grid_child_natural_size!(child::ChartGrid)
    child.auto_size && configure!(child)
    return child.width, child.height
end


function _grid_track_sizes(grid::ChartGrid)
    col_widths = zeros(grid.ncols)
    row_heights = zeros(grid.nrows)

    for ((i, j), child) in grid.children
        width, height = _grid_child_natural_size!(child)
        col_widths[j] = max(col_widths[j], width)
        row_heights[i] = max(row_heights[i], height)
    end

    all(>(0.0), col_widths) || throw(ArgumentError("ChartGrid: every occupied column must have positive natural width"))
    all(>(0.0), row_heights) || throw(ArgumentError("ChartGrid: every occupied row must have positive natural height"))
    return col_widths, row_heights
end


function _grid_effective_outerpad(grid::ChartGrid, width::Real, height::Real)
    return max(grid.requested_outerpad, 0.01 * min(width, height))
end


function _grid_auto_outerpad(grid::ChartGrid, base_width::Real, base_height::Real)
    return max(grid.requested_outerpad, min(base_width, base_height) / 98.0)
end


function _grid_scaled_tracks(track_sizes::Vector{Float64}, available_size::Real, axis_name::AbstractString)
    available_size > 0 || throw(ArgumentError("ChartGrid: insufficient space for grid $axis_name"))
    total_size = sum(track_sizes)
    total_size > 0 || throw(ArgumentError("ChartGrid: natural $axis_name sizes sum to zero"))
    return track_sizes .* (available_size / total_size)
end


function configure!(grid::ChartGrid)
    length(grid.children) > 0 || throw(QuickChartsException("ChartGrid: no child figures added"))
    _grid_validate_tracks(grid)

    title_height = _measure_grid_title(grid)[2]
    column_header_height, row_header_width = _measure_grid_headers(grid)
    col_widths, row_heights = _grid_track_sizes(grid)

    title_gap = isempty(grid.title_box.text) ? 0.0 : 0.6 * grid.font_size
    column_header_gap = column_header_height > 0 ? 0.5 * grid.font_size : 0.0
    row_header_gap = row_header_width > 0 ? 0.5 * grid.font_size : 0.0

    natural_track_width = sum(col_widths)
    natural_track_height = sum(row_heights)
    total_hgap = (grid.ncols - 1) * grid.hgap
    total_vgap = (grid.nrows - 1) * grid.vgap

    base_width = row_header_width + row_header_gap + natural_track_width + total_hgap
    base_height = title_height + title_gap + column_header_height + column_header_gap + natural_track_height + total_vgap

    if grid.auto_size
        grid.outerpad = _grid_auto_outerpad(grid, base_width, base_height)
        grid.width = base_width + 2 * grid.outerpad
        grid.height = base_height + 2 * grid.outerpad
        final_col_widths = copy(col_widths)
        final_row_heights = copy(row_heights)
    else
        grid.outerpad = _grid_effective_outerpad(grid, grid.width, grid.height)
        content_width = grid.width - 2 * grid.outerpad - row_header_width - row_header_gap
        content_height = grid.height - 2 * grid.outerpad - title_height - title_gap - column_header_height - column_header_gap
        track_width = content_width - total_hgap
        track_height = content_height - total_vgap
        final_col_widths = _grid_scaled_tracks(col_widths, track_width, "columns")
        final_row_heights = _grid_scaled_tracks(row_heights, track_height, "rows")
    end

    grid.figure_frame = Frame(grid.figure_frame.x, grid.figure_frame.y, grid.width, grid.height)
    content_x = grid.figure_frame.x + grid.outerpad + row_header_width + row_header_gap
    content_y = grid.figure_frame.y + grid.outerpad + title_height + title_gap + column_header_height + column_header_gap
    content_width = sum(final_col_widths) + total_hgap
    content_height = sum(final_row_heights) + total_vgap

    content_width > 0 && content_height > 0 || throw(ArgumentError("ChartGrid: insufficient space for grid content"))

    grid.title_box.frame = Frame(content_x, grid.figure_frame.y + grid.outerpad, content_width, title_height)
    grid.title_box.angle = 0.0
    empty!(grid.cell_frames)

    y = content_y
    for i in 1:grid.nrows
        x = content_x
        for j in 1:grid.ncols
            grid.cell_frames[(i, j)] = Frame(x, y, final_col_widths[j], final_row_heights[i])
            x += final_col_widths[j] + grid.hgap
        end
        y += final_row_heights[i] + grid.vgap
    end

    if column_header_height > 0
        y = grid.figure_frame.y + grid.outerpad + title_height + title_gap
        x = content_x
        for j in 1:grid.ncols
            j <= length(grid.column_header_boxes) || continue
            box = grid.column_header_boxes[j]
            box.frame = Frame(x, y, final_col_widths[j], column_header_height)
            box.angle = 0.0
            x += final_col_widths[j] + grid.hgap
        end
    end

    if row_header_width > 0
        x = grid.figure_frame.x + grid.outerpad
        y = content_y
        for i in 1:grid.nrows
            i <= length(grid.row_header_boxes) || continue
            box = grid.row_header_boxes[i]
            box.frame = Frame(x, y, row_header_width, final_row_heights[i])
            box.angle = 90.0
            y += final_row_heights[i] + grid.vgap
        end
    end
end


function _set_grid_frame!(child::Chart, frame::Frame)
    child.width = frame.width
    child.height = frame.height
    child.figure_frame = Frame(frame.x, frame.y, frame.width, frame.height)
end


function _set_grid_frame!(child::ChartGrid, frame::Frame)
    child.width = frame.width
    child.height = frame.height
    child.figure_frame = Frame(frame.x, frame.y, frame.width, frame.height)
end


function _draw_grid_child!(ctx::RenderContext, child::Figure, frame::Frame)
    old_width = child.width
    old_height = child.height
    old_frame = Frame(child.figure_frame.x, child.figure_frame.y, child.figure_frame.width, child.figure_frame.height)
    old_background = child isa Union{Chart,ChartGrid} ? child.background : nothing
    old_auto_size = child isa ChartGrid ? child.auto_size : false

    try
        _set_grid_frame!(child, frame)
        if child isa Union{Chart,ChartGrid}
            child.background = nothing
        end
        child isa ChartGrid && (child.auto_size = false)
        configure!(child)
        draw_contents!(child, ctx)
    finally
        child.width = old_width
        child.height = old_height
        child.figure_frame = old_frame
        if child isa Union{Chart,ChartGrid}
            child.background = old_background
        end
        child isa ChartGrid && (child.auto_size = old_auto_size)
    end
end


function draw_background!(grid::ChartGrid, ctx::RenderContext)
    _draw_figure_background!(ctx, grid.figure_frame, ctx.background)
end

function draw_contents!(grid::ChartGrid, ctx::RenderContext)
    cairo_ctx = ctx.cairo_ctx
    reset_matrix!(ctx)
    select_font_face(cairo_ctx, get_font(grid.font), Cairo.FONT_SLANT_NORMAL, Cairo.FONT_WEIGHT_NORMAL)
    set_font_size(cairo_ctx, grid.font_size)
    set_source_rgb(cairo_ctx, 0.0, 0.0, 0.0)

    _draw_text_box!(ctx, grid.title_box)

    for j in 1:min(length(grid.column_header_boxes), grid.ncols)
        _draw_text_box!(ctx, grid.column_header_boxes[j])
    end

    for i in 1:min(length(grid.row_header_boxes), grid.nrows)
        _draw_text_box!(ctx, grid.row_header_boxes[i])
    end

    for pos in sort(collect(keys(grid.children)))
        _draw_grid_child!(ctx, grid.children[pos], grid.cell_frames[pos])
    end
end
