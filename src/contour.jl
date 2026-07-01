# This file is part of the QuickCharts.jl package. It is licensed under the MIT License.

const _contour_colorbar_locations = (:none, :left, :right, :top, :bottom)

function _resize_contour_colormap(cmap::Colormap, levels::Vector{Float64})
    if length(levels) == 1
        level = levels[1]
        scale = max(abs(level), 1.0)
        return resize(cmap, level - 0.5 * scale, level + 0.5 * scale)
    end
    return resize(cmap, levels[1], levels[end])
end

function _normalize_contour_levels(levels, z::AbstractMatrix, filled::Bool, nlevels::Int)
    nlevels > 0 || throw(ArgumentError("ContourSeries: nlevels must be positive"))

    if levels !== nothing
        resolved_levels = sort!(collect(float.(levels)))
        length(resolved_levels) == length(unique(resolved_levels)) || throw(ArgumentError("ContourSeries: contour levels must be unique"))
    else
        finite_values = Float64[]
        for value in z
            isfinite(value) && push!(finite_values, float(value))
        end
        isempty(finite_values) && throw(ArgumentError("ContourSeries: z must contain at least one finite value"))

        zmin = minimum(finite_values)
        zmax = maximum(finite_values)

        if zmin == zmax
            if filled
                scale = max(abs(zmin), 1.0)
                resolved_levels = [zmin - 0.5 * scale, zmax + 0.5 * scale]
            else
                resolved_levels = [zmin]
            end
        else
            if filled
                count = max(nlevels, 2)
                resolved_levels = collect(range(zmin, zmax; length=count))
            else
                resolved_levels = collect(range(zmin, zmax; length=nlevels))
            end
        end
    end

    if filled
        length(resolved_levels) >= 2 || throw(ArgumentError("ContourSeries: filled contours require at least two levels"))
    else
        length(resolved_levels) >= 1 || throw(ArgumentError("ContourSeries: line contours require at least one level"))
    end

    return resolved_levels
end


function _strictly_monotone(values::AbstractVector)
    length(values) < 2 && return true
    deltas = diff(float.(collect(values)))
    all(>(0), deltas) || all(<(0), deltas)
end


"""
    ContourSeries(x::AbstractVector, y::AbstractVector, z::AbstractMatrix; kwargs...)

Store the data and styling for a contour series defined on a rectilinear grid.

`size(z)` must equal `(length(y), length(x))`. Set `filled=true` to draw filled
contour bands. Filled contours draw contour lines too unless
`line_style=:none`.
"""
mutable struct ContourSeries <: DataSeries
    x                    ::AbstractVector
    y                    ::AbstractVector
    z                    ::AbstractMatrix
    filled               ::Bool
    levels               ::Vector{Float64}
    color                ::Union{Symbol,Color}
    line_width           ::Float64
    line_style           ::Symbol
    colormap             ::Colormap
    alpha                ::Float64
    colorbar_location    ::Symbol
    colorbar_ratio       ::Float64
    colorbar_label       ::AbstractString
    colorbar_ticks       ::Vector{Float64}
    colorbar_tick_labels ::Vector{String}
    label                ::AbstractString
    order                ::Int
    line_segments        ::Vector{Tuple{Float64,NTuple{4,Float64}}}
    fill_polygons        ::Vector{Tuple{Int,Vector{NTuple{2,Float64}}}}

    function ContourSeries(
        x::AbstractVector,
        y::AbstractVector,
        z::AbstractMatrix;
        filled::Bool=false,
        levels=nothing,
        nlevels::Int=10,
        label::AbstractString="",
        order::Int=0,
        color=:auto,
        line_width::Real=0.5,
        line_style::Symbol=:solid,
        colormap=Colormap(:viridis),
        alpha::Real=1.0,
        colorbar::Symbol=:right,
        colorbar_ratio::Real=1.0,
        colorbar_label::AbstractString="",
        colorbar_ticks::AbstractVector{<:Real}=Float64[],
        colorbar_tick_labels::AbstractVector{<:AbstractString}=String[],
    )
        length(x) >= 2 || throw(ArgumentError("ContourSeries: x must contain at least two points"))
        length(y) >= 2 || throw(ArgumentError("ContourSeries: y must contain at least two points"))
        size(z) == (length(y), length(x)) || throw(ArgumentError("ContourSeries: size(z) must equal (length(y), length(x))"))
        _strictly_monotone(x) || throw(ArgumentError("ContourSeries: x must be strictly monotone"))
        _strictly_monotone(y) || throw(ArgumentError("ContourSeries: y must be strictly monotone"))
        line_style in _line_style_list || throw(ArgumentError("ContourSeries: invalid line_style $(repr(line_style))"))
        line_width > 0 || throw(ArgumentError("ContourSeries: line_width must be positive"))
        0.0 <= alpha <= 1.0 || throw(ArgumentError("ContourSeries: alpha must be in [0, 1]"))
        colorbar in _contour_colorbar_locations || throw(ArgumentError("ContourSeries: invalid colorbar location $(repr(colorbar))"))
        colorbar_ratio > 0 || throw(ArgumentError("ContourSeries: colorbar_ratio must be positive"))
        length(colorbar_tick_labels) == 0 || length(colorbar_ticks) == length(colorbar_tick_labels) || throw(ArgumentError("ContourSeries: colorbar tick labels must match colorbar ticks"))

        resolved_levels = _normalize_contour_levels(levels, z, filled, nlevels)
        resolved_color = color === :auto ? color : resolve_color(color)
        base_colormap = colormap isa Symbol ? Colormap(colormap) : colormap
        resolved_colormap = _resize_contour_colormap(base_colormap, resolved_levels)
        finite_z = float.(z)
        line_segments, fill_polygons = _contour_geometry(x, y, finite_z, resolved_levels, filled, line_style)

        return new(
            x,
            y,
            finite_z,
            filled,
            resolved_levels,
            resolved_color,
            float(line_width),
            line_style,
            resolved_colormap,
            float(alpha),
            colorbar,
            float(colorbar_ratio),
            colorbar_label,
            collect(float.(colorbar_ticks)),
            String.(colorbar_tick_labels),
            label,
            order,
            line_segments,
            fill_polygons,
        )
    end
end


_clip_eps() = 1.0e-12


function _triangle_edges(triangle)
    return (
        (triangle[1], triangle[2]),
        (triangle[2], triangle[3]),
        (triangle[3], triangle[1]),
    )
end


function _interp_point(p1, p2, value)
    v1 = p1[3]
    v2 = p2[3]
    if isapprox(v1, v2; atol=_clip_eps())
        t = 0.5
    else
        t = (value - v1) / (v2 - v1)
    end
    x = p1[1] + t * (p2[1] - p1[1])
    y = p1[2] + t * (p2[2] - p1[2])
    return (float(x), float(y), float(value))
end


function _same_xy(p1, p2; atol=_clip_eps())
    return isapprox(p1[1], p2[1]; atol=atol) && isapprox(p1[2], p2[2]; atol=atol)
end


function _dedupe_points(points)
    unique_points = typeof(points[1])[]
    for point in points
        any(existing -> _same_xy(existing, point), unique_points) || push!(unique_points, point)
    end
    return unique_points
end


function _triangle_level_segment(triangle, level)
    points = Tuple{Float64,Float64,Float64}[]
    for (p1, p2) in _triangle_edges(triangle)
        v1 = p1[3] - level
        v2 = p2[3] - level

        if isapprox(v1, 0.0; atol=_clip_eps()) && isapprox(v2, 0.0; atol=_clip_eps())
            continue
        elseif isapprox(v1, 0.0; atol=_clip_eps())
            push!(points, (p1[1], p1[2], level))
        elseif isapprox(v2, 0.0; atol=_clip_eps())
            push!(points, (p2[1], p2[2], level))
        elseif signbit(v1) != signbit(v2)
            push!(points, _interp_point(p1, p2, level))
        end
    end

    isempty(points) && return nothing
    points = _dedupe_points(points)
    length(points) < 2 && return nothing
    return (points[1][1], points[1][2], points[2][1], points[2][2])
end


function _clip_polygon_lower(poly, lower)
    isempty(poly) && return poly
    output = Tuple{Float64,Float64,Float64}[]
    prev = poly[end]
    prev_inside = prev[3] >= lower - _clip_eps()
    for current in poly
        current_inside = current[3] >= lower - _clip_eps()
        if current_inside
            if !prev_inside
                push!(output, _interp_point(prev, current, lower))
            end
            push!(output, current)
        elseif prev_inside
            push!(output, _interp_point(prev, current, lower))
        end
        prev = current
        prev_inside = current_inside
    end
    return output
end


function _clip_polygon_upper(poly, upper)
    isempty(poly) && return poly
    output = Tuple{Float64,Float64,Float64}[]
    prev = poly[end]
    prev_inside = prev[3] <= upper + _clip_eps()
    for current in poly
        current_inside = current[3] <= upper + _clip_eps()
        if current_inside
            if !prev_inside
                push!(output, _interp_point(prev, current, upper))
            end
            push!(output, current)
        elseif prev_inside
            push!(output, _interp_point(prev, current, upper))
        end
        prev = current
        prev_inside = current_inside
    end
    return output
end


function _triangle_band_polygon(triangle, lower, upper)
    clipped = _clip_polygon_lower(collect(triangle), lower)
    clipped = _clip_polygon_upper(clipped, upper)
    length(clipped) < 3 && return nothing
    points = [(point[1], point[2]) for point in clipped]
    return points
end


function _cell_triangles(x1, x2, y1, y2, z11, z21, z22, z12)
    xc = 0.5 * (x1 + x2)
    yc = 0.5 * (y1 + y2)
    zc = 0.25 * (z11 + z21 + z22 + z12)

    p_ll = (float(x1), float(y1), float(z11))
    p_lr = (float(x2), float(y1), float(z21))
    p_ur = (float(x2), float(y2), float(z22))
    p_ul = (float(x1), float(y2), float(z12))
    p_c = (float(xc), float(yc), float(zc))

    return (
        (p_ll, p_c, p_lr),
        (p_lr, p_c, p_ur),
        (p_ur, p_c, p_ul),
        (p_ul, p_c, p_ll),
    )
end


function _contour_geometry(x::AbstractVector, y::AbstractVector, z::AbstractMatrix, levels::Vector{Float64}, filled::Bool, line_style::Symbol)
    line_segments = Tuple{Float64,NTuple{4,Float64}}[]
    fill_polygons = Vector{Tuple{Int,Vector{NTuple{2,Float64}}}}()

    nx = length(x)
    ny = length(y)
    line_enabled = line_style != :none

    for j in 1:(ny - 1)
        for i in 1:(nx - 1)
            z11 = z[j, i]
            z21 = z[j, i + 1]
            z22 = z[j + 1, i + 1]
            z12 = z[j + 1, i]
            all(isfinite, (z11, z21, z22, z12)) || continue

            triangles = _cell_triangles(x[i], x[i + 1], y[j], y[j + 1], z11, z21, z22, z12)

            if filled
                for band_index in 1:(length(levels) - 1)
                    lower = levels[band_index]
                    upper = levels[band_index + 1]
                    for triangle in triangles
                        polygon = _triangle_band_polygon(triangle, lower, upper)
                        polygon === nothing && continue
                        push!(fill_polygons, (band_index, polygon))
                    end
                end
            end

            if line_enabled
                for level in levels
                    for triangle in triangles
                        segment = _triangle_level_segment(triangle, level)
                        segment === nothing && continue
                        push!(line_segments, (level, segment))
                    end
                end
            end
        end
    end

    return line_segments, fill_polygons
end
