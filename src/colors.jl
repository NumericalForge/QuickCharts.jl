# This file is part of the QuickPlots.jl package. It is licensed under the MIT License.

export Color, lighten, darken, gray

_rgb255(r::Integer, g::Integer, b::Integer) = (r/255, g/255, b/255)

const _browser_colors_dict = Dict(
    :alice_blue              => _rgb255(240, 248, 255),
    :antique_white           => _rgb255(250, 235, 215),
    :aqua                    => _rgb255(0, 255, 255),
    :aquamarine              => _rgb255(127, 255, 212),
    :azure                   => _rgb255(240, 255, 255),
    :beige                   => _rgb255(245, 245, 220),
    :bisque                  => _rgb255(255, 228, 196),
    :black                   => _rgb255(0, 0, 0),
    :blanched_almond         => _rgb255(255, 235, 205),
    :blue                    => _rgb255(0, 0, 255),
    :blue_violet             => _rgb255(138, 43, 226),
    :brown                   => _rgb255(165, 42, 42),
    :burly_wood              => _rgb255(222, 184, 135),
    :cadet_blue              => _rgb255(95, 158, 160),
    :chartreuse              => _rgb255(127, 255, 0),
    :chocolate               => _rgb255(210, 105, 30),
    :coral                   => _rgb255(255, 127, 80),
    :cornflower_blue         => _rgb255(100, 149, 237),
    :cornsilk                => _rgb255(255, 248, 220),
    :crimson                 => _rgb255(220, 20, 60),
    :cyan                    => _rgb255(0, 255, 255),
    :dark_blue               => _rgb255(0, 0, 139),
    :dark_cyan               => _rgb255(0, 139, 139),
    :dark_golden_rod         => _rgb255(184, 134, 11),
    :dark_gray               => _rgb255(169, 169, 169),
    :dark_grey               => _rgb255(169, 169, 169),
    :dark_green              => _rgb255(0, 100, 0),
    :dark_khaki              => _rgb255(189, 183, 107),
    :dark_magenta            => _rgb255(139, 0, 139),
    :dark_olive_green        => _rgb255(85, 107, 47),
    :dark_orange             => _rgb255(255, 140, 0),
    :dark_orchid             => _rgb255(153, 50, 204),
    :dark_red                => _rgb255(139, 0, 0),
    :dark_salmon             => _rgb255(233, 150, 122),
    :dark_sea_green          => _rgb255(143, 188, 143),
    :dark_slate_blue         => _rgb255(72, 61, 139),
    :dark_slate_gray         => _rgb255(47, 79, 79),
    :dark_slate_grey         => _rgb255(47, 79, 79),
    :dark_turquoise          => _rgb255(0, 206, 209),
    :dark_violet             => _rgb255(148, 0, 211),
    :deep_pink               => _rgb255(255, 20, 147),
    :deep_sky_blue           => _rgb255(0, 191, 255),
    :dim_gray                => _rgb255(105, 105, 105),
    :dim_grey                => _rgb255(105, 105, 105),
    :dodger_blue             => _rgb255(30, 144, 255),
    :fire_brick              => _rgb255(178, 34, 34),
    :floral_white            => _rgb255(255, 250, 240),
    :forest_green            => _rgb255(34, 139, 34),
    :fuchsia                 => _rgb255(255, 0, 255),
    :gainsboro               => _rgb255(220, 220, 220),
    :ghost_white             => _rgb255(248, 248, 255),
    :gold                    => _rgb255(255, 215, 0),
    :golden_rod              => _rgb255(218, 165, 32),
    :gray                    => _rgb255(128, 128, 128),
    :green                   => _rgb255(0, 128, 0),
    :green_yellow            => _rgb255(173, 255, 47),
    :grey                    => _rgb255(128, 128, 128),
    :honey_dew               => _rgb255(240, 255, 240),
    :hot_pink                => _rgb255(255, 105, 180),
    :indian_red              => _rgb255(205, 92, 92),
    :indigo                  => _rgb255(75, 0, 130),
    :ivory                   => _rgb255(255, 255, 240),
    :khaki                   => _rgb255(240, 230, 140),
    :lavender                => _rgb255(230, 230, 250),
    :lavender_blush          => _rgb255(255, 240, 245),
    :lawn_green              => _rgb255(124, 252, 0),
    :lemon_chiffon           => _rgb255(255, 250, 205),
    :light_blue              => _rgb255(173, 216, 230),
    :light_coral             => _rgb255(240, 128, 128),
    :light_cyan              => _rgb255(224, 255, 255),
    :light_golden_rod_yellow => _rgb255(250, 250, 210),
    :light_gray              => _rgb255(211, 211, 211),
    :light_green             => _rgb255(144, 238, 144),
    :light_grey              => _rgb255(211, 211, 211),
    :light_pink              => _rgb255(255, 182, 193),
    :light_salmon            => _rgb255(255, 160, 122),
    :light_sea_green         => _rgb255(32, 178, 170),
    :light_sky_blue          => _rgb255(135, 206, 250),
    :light_slate_gray        => _rgb255(119, 136, 153),
    :light_slate_grey        => _rgb255(119, 136, 153),
    :light_steel_blue        => _rgb255(176, 196, 222),
    :light_yellow            => _rgb255(255, 255, 224),
    :lime                    => _rgb255(0, 255, 0),
    :lime_green              => _rgb255(50, 205, 50),
    :linen                   => _rgb255(250, 240, 230),
    :magenta                 => _rgb255(255, 0, 255),
    :maroon                  => _rgb255(128, 0, 0),
    :medium_aqua_marine      => _rgb255(102, 205, 170),
    :medium_blue             => _rgb255(0, 0, 205),
    :medium_orchid           => _rgb255(186, 85, 211),
    :medium_purple           => _rgb255(147, 112, 219),
    :medium_sea_green        => _rgb255(60, 179, 113),
    :medium_slate_blue       => _rgb255(123, 104, 238),
    :medium_spring_green     => _rgb255(0, 250, 154),
    :medium_turquoise        => _rgb255(72, 209, 204),
    :medium_violet_red       => _rgb255(199, 21, 133),
    :midnight_blue           => _rgb255(25, 25, 112),
    :mint_cream              => _rgb255(245, 255, 250),
    :misty_rose              => _rgb255(255, 228, 225),
    :moccasin                => _rgb255(255, 228, 181),
    :navajo_white            => _rgb255(255, 222, 173),
    :navy                    => _rgb255(0, 0, 128),
    :old_lace                => _rgb255(253, 245, 230),
    :olive                   => _rgb255(128, 128, 0),
    :olive_drab              => _rgb255(107, 142, 35),
    :orange                  => _rgb255(255, 165, 0),
    :orange_red              => _rgb255(255, 69, 0),
    :orchid                  => _rgb255(218, 112, 214),
    :pale_golden_rod         => _rgb255(238, 232, 170),
    :pale_green              => _rgb255(152, 251, 152),
    :pale_turquoise          => _rgb255(175, 238, 238),
    :pale_violet_red         => _rgb255(219, 112, 147),
    :papaya_whip             => _rgb255(255, 239, 213),
    :peach_puff              => _rgb255(255, 218, 185),
    :peru                    => _rgb255(205, 133, 63),
    :pink                    => _rgb255(255, 192, 203),
    :plum                    => _rgb255(221, 160, 221),
    :powder_blue             => _rgb255(176, 224, 230),
    :purple                  => _rgb255(128, 0, 128),
    :rebecca_purple          => _rgb255(102, 51, 153),
    :red                     => _rgb255(255, 0, 0),
    :rosy_brown              => _rgb255(188, 143, 143),
    :royal_blue              => _rgb255(65, 105, 225),
    :saddle_brown            => _rgb255(139, 69, 19),
    :salmon                  => _rgb255(250, 128, 114),
    :sandy_brown             => _rgb255(244, 164, 96),
    :sea_green               => _rgb255(46, 139, 87),
    :sea_shell               => _rgb255(255, 245, 238),
    :sienna                  => _rgb255(160, 82, 45),
    :silver                  => _rgb255(192, 192, 192),
    :sky_blue                => _rgb255(135, 206, 235),
    :slate_blue              => _rgb255(106, 90, 205),
    :slate_gray              => _rgb255(112, 128, 144),
    :slate_grey              => _rgb255(112, 128, 144),
    :snow                    => _rgb255(255, 250, 250),
    :spring_green            => _rgb255(0, 255, 127),
    :steel_blue              => _rgb255(70, 130, 180),
    :tan                     => _rgb255(210, 180, 140),
    :teal                    => _rgb255(0, 128, 128),
    :thistle                 => _rgb255(216, 191, 216),
    :tomato                  => _rgb255(255, 99, 71),
    :turquoise               => _rgb255(64, 224, 208),
    :violet                  => _rgb255(238, 130, 238),
    :wheat                   => _rgb255(245, 222, 179),
    :white                   => _rgb255(255, 255, 255),
    :white_smoke             => _rgb255(245, 245, 245),
    :yellow                  => _rgb255(255, 255, 0),
    :yellow_green            => _rgb255(154, 205, 50),
)

const _series_colors_dict = Dict(
    :c1           => (0.769, 0.306, 0.322),       # red
    :c2           => (0.333, 0.659, 0.408).*0.85, # green
    :c3           => (0.298, 0.447, 0.690),       # blue
    :c4           => (0.867, 0.522, 0.322),       # orange
    :c5           => (0.749, 0.992, 0.188).*0.75, # green
    :c6           => (0.000, 0.667, 0.682).*0.9,  # aquamarine
    :c7           => (0.647, 0.318, 0.580),       # purple
    :c8           => (0.576, 0.471, 0.376),       # brown
    :c9           => (0.647, 0.318, 0.580),
    :c10          => (0.647, 0.318, 0.580),
    :c11          => (0.647, 0.318, 0.580),
    :c12          => (0.647, 0.318, 0.580),
)

const _other_colors_dict = Dict(
    :bone         => _rgb255(227, 218, 201),
    :old_paper    => _rgb255(242, 232, 203),
)

const _colors_dict = merge(_series_colors_dict, _browser_colors_dict, _other_colors_dict)
const _colors_list = collect(keys(_colors_dict))


"""
    Color(r::Float64, g::Float64, b::Float64[, a::Float64=1.0])
    Color(r::Int, g::Int, b::Int[, a::Float64=1.0])
    Color((r, g, b[, a]))
    Color(name::Symbol)
    Color(color::Color)

Represent an RGBA color with channel values stored in `[0, 1]`.

Float constructors interpret `r`, `g`, `b`, and `a` as normalized channels.
Integer constructors interpret RGB channels as 8-bit values in `0:255` and the
alpha channel as a normalized value. Tuple inputs may contain either 3 or 4
channels and are dispatched to the numeric constructors. Symbol inputs use the
built-in named color table, including browser-style names such as `:royal_blue`
and QuickPlots palette names such as `:c1`.

Out-of-range channel values are clamped.
"""
struct Color
    r::Float64
    g::Float64
    b::Float64
    a::Float64

    function Color(c::Color)
        return new(c.r, c.g, c.b, c.a)
    end

    function Color(r::Float64, g::Float64, b::Float64, a::Float64=1.0)
        return new( clamp(r, 0.0, 1.0), clamp(g, 0.0, 1.0), clamp(b, 0.0, 1.0), clamp(a, 0.0, 1.0) )
    end

    function Color(r::Int, g::Int, b::Int, a::Float64=1.0)
        return new( clamp(r, 0, 255)/255, clamp(g, 0, 255)/255, clamp(b, 0, 255)/255, clamp(a, 0.0, 1.0) )
    end

    function Color(t::Tuple)
        a::Float64 = length(t)==4 ? t[4] : 1.0
        return Color(t[1], t[2], t[3], a)
    end

    function Color(s::Symbol)
        haskey(_colors_dict, s) || throw(ArgumentError("Color: unknown color symbol $(repr(s))"))
        return Color(_colors_dict[s])
    end

end

rgb(c::Color)  = (c.r, c.g, c.b)
rgba(c::Color) = (c.r, c.g, c.b, c.a)

"""
    resolve_color(color)

Convert a supported color input to a fresh `Color`, or return `nothing` for
`nothing`.

Accepted non-`nothing` inputs are `Color`, `Symbol`, and `Tuple`, matching the
constructors accepted by [`Color`](@ref).
"""
resolve_color(color::Nothing) = nothing
resolve_color(color::Color) = Color(color)
resolve_color(color::Symbol) = Color(color)
resolve_color(color::Tuple) = Color(color)


const _default_colors = [ :c1, :c2, :c3, :c4, :c5, :c6, :c7, :c8, :c9, :c10, :c11, :c12 ]

"""
    gray(x::Real)

Create an opaque grayscale `Color` with red, green, and blue channels all set to
`x`. Values are clamped by the [`Color`](@ref) constructor.
"""
gray(x::Real) = Color(float(x), float(x), float(x))

function grayscale(c::Color)
    gray = 0.299*c.r + 0.587*c.g + 0.114*c.b
    return Color(gray, gray, gray, c.a)
end


"""
    lighten(c::Color, ratio::Float64)

Return a lighter copy of `c` by linearly mixing its RGB channels toward white.

`ratio` must be in `[0, 1]`; `0` returns the original color and `1` returns
white with the original alpha channel.
"""
function lighten(c::Color, ratio::Float64)
    @assert 0.0 ≤ ratio ≤ 1.0 "Ratio must be between 0 and 1"
    return Color(
        c.r + (1.0 - c.r) * ratio,
        c.g + (1.0 - c.g) * ratio,
        c.b + (1.0 - c.b) * ratio,
        c.a
    )
end


"""
    darken(c::Color, ratio::Float64)

Return a darker copy of `c` by linearly mixing its RGB channels toward black.

`ratio` must be in `[0, 1]`; `0` returns the original color and `1` returns
black with the original alpha channel.
"""
function darken(c::Color, ratio::Float64)
    @assert 0.0 ≤ ratio ≤ 1.0 "Ratio must be between 0 and 1"
    return Color(
        c.r * (1.0 - ratio),
        c.g * (1.0 - ratio),
        c.b * (1.0 - ratio),
        c.a
    )
end


"""
    Colormap(stops, colors)
    Colormap(name::Symbol; limits=Float64[], rev=false)

Represent a scalar-to-color lookup table.

`stops` are normalized scalar positions and `colors` are RGB tuples of equal
length. A `Colormap` is callable: `cmap(x)` returns an interpolated RGB tuple,
clamped to the first or last color outside the stop range.

The named constructor loads one of QuickPlots' built-in maps. `limits=[lo, hi]`
clips the stop range before use, and `rev=true` reverses the map.
"""
struct Colormap
    stops::Vector{Float64} # might be resized according to actual data
    colors::Array{Tuple}

    function Colormap(stops, colors)
        @assert length(stops)==length(colors)
        return new(stops, colors)
    end
end


function Colormap(cmap_name::Symbol; limits=Float64[], rev=false)
    cmap_name in _colormaps_list || throw(QuickPlotsException("Colormap: colormap not found which must be one of $(_colormaps_list)"))
    colormap = _colormaps_dict[cmap_name]

    length(limits)==2 && (colormap = clip_colormap(colormap, limits))
    rev && (colormap = reverse(colormap))

    return colormap
end

# Interpolate a color
function (cmap::Colormap)(rval)
    rval<=cmap.stops[1] && return cmap.colors[1]
    rval>=cmap.stops[end] && return cmap.colors[end]
    idx = findfirst(>(rval), cmap.stops)

    t = (rval-cmap.stops[idx-1])/(cmap.stops[idx]-cmap.stops[idx-1])
    c =  (1-t).*cmap.colors[idx-1] .+ t.*cmap.colors[idx]
    return Tuple(c)
end


function resize(cmap::Colormap, min, max; diverging=false)  # diverging from zero
    rmin = cmap.stops[1]
    rmax = cmap.stops[end]

    (min>=0 || max<=0) && (diverging=false)

    if diverging
        rmid = 0.5*(rmax-rmin)

        stops = []
        for rval in cmap.stops
            if rval<rmid
                s = min - min*(rval-rmin)/(rmid-rmin)
            else
                s = max*(rval-rmid)/(rmax-rmid)
            end
            push!(stops, s)
        end
    else
        stops = [ min + (rval-rmin)/(rmax-rmin)*(max-min) for rval in cmap.stops ]
    end

    return Colormap(stops, cmap.colors)
end


function Base.reverse(cmap::Colormap)
    stops = [ round(1-stop, digits=3) for stop in reverse(cmap.stops) ]
    colors = reverse(cmap.colors)
    return Colormap(stops, colors)
end


function clip_colormap(cmap::Colormap, limits=Float64[])
    n = 21
    minstop, maxstop = extrema(cmap.stops)
    @assert limits[1]>=minstop && limits[2]<=maxstop
    minstop, maxstop = limits
    stops = [ x for x in range(minstop, maxstop, n) ]
    colors = [ cmap(x) for x in range(minstop,maxstop,n) ]
    return Colormap(stops, colors)
end


const _colormaps_dict = Dict(
    :coolwarm => Colormap(
        [0.000, 0.050, 0.100, 0.150, 0.200, 0.250, 0.300, 0.350, 0.400, 0.450, 0.500, 0.550, 0.600, 0.650, 0.700, 0.750, 0.800, 0.850, 0.900, 0.950, 1.000, ],
        [(0.230, 0.299, 0.754), (0.290, 0.387, 0.829), (0.353, 0.472, 0.893), (0.415, 0.547, 0.939), (0.484, 0.622, 0.975), (0.554, 0.690, 0.996), (0.619, 0.744, 0.999), (0.688, 0.793, 0.988), (0.754, 0.830, 0.961), (0.814, 0.854, 0.918), (0.867, 0.864, 0.863), (0.913, 0.837, 0.795), (0.947, 0.795, 0.717), (0.966, 0.740, 0.637), (0.969, 0.679, 0.563), (0.958, 0.604, 0.483), (0.932, 0.519, 0.406), (0.892, 0.425, 0.333), (0.839, 0.322, 0.265), (0.780, 0.210, 0.207), (0.706, 0.016, 0.150), ]
    ),
    :coolwarm2 => Colormap(
        [0.000, 0.050, 0.100, 0.150, 0.200, 0.250, 0.300, 0.350, 0.400, 0.450, 0.500, 0.550, 0.600, 0.650, 0.700, 0.750, 0.800, 0.850, 0.900, 0.950, 1.000, ],
        [(0, 0.273, 0.511), (0, 0.291, 0.544), (0, 0.309, 0.578), (0, 0.327, 0.612), (0, 0.345, 0.646), (0, 0.364, 0.681), (0.204, 0.431, 0.685), (0.329, 0.493, 0.686), (0.444, 0.553, 0.683), (0.556, 0.61, 0.677), (0.667, 0.667, 0.667), (0.678, 0.608, 0.564), (0.684, 0.548, 0.461), (0.686, 0.487, 0.354), (0.685, 0.423, 0.238), (0.68, 0.355, 0.072), (0.665, 0.318, 0.091), (0.649, 0.281, 0.104), (0.633, 0.241, 0.114), (0.617, 0.2, 0.122), (0.6, 0.153, 0.127) ]
    ),
    :bone => Colormap(
        [0.000, 0.050, 0.100, 0.150, 0.200, 0.250, 0.300, 0.350, 0.400, 0.450, 0.500, 0.550, 0.600, 0.650, 0.700, 0.750, 0.800, 0.850, 0.900, 0.950, 1.000, ],
        [(0.000, 0.000, 0.000), (0.045, 0.045, 0.062), (0.089, 0.089, 0.124), (0.130, 0.130, 0.181), (0.175, 0.175, 0.243), (0.220, 0.220, 0.306), (0.261, 0.261, 0.363), (0.305, 0.305, 0.425), (0.350, 0.361, 0.475), (0.395, 0.423, 0.520), (0.439, 0.484, 0.564), (0.480, 0.541, 0.605), (0.525, 0.602, 0.650), (0.570, 0.663, 0.695), (0.611, 0.720, 0.736), (0.657, 0.780, 0.780), (0.727, 0.825, 0.825), (0.796, 0.870, 0.870), (0.866, 0.914, 0.914), (0.930, 0.955, 0.955), (1.000, 1.000, 1.000), ]
    ),
    :inferno => Colormap(
        [0.000, 0.050, 0.100, 0.150, 0.200, 0.250, 0.300, 0.350, 0.400, 0.450, 0.500, 0.550, 0.600, 0.650, 0.700, 0.750, 0.800, 0.850, 0.900, 0.950, 1.000, ],
        [(0.001, 0.000, 0.014), (0.029, 0.022, 0.115), (0.093, 0.046, 0.234), (0.170, 0.042, 0.341), (0.258, 0.039, 0.406), (0.342, 0.062, 0.429), (0.416, 0.090, 0.433), (0.497, 0.119, 0.424), (0.578, 0.148, 0.404), (0.658, 0.179, 0.373), (0.736, 0.216, 0.330), (0.802, 0.259, 0.283), (0.865, 0.317, 0.226), (0.916, 0.387, 0.165), (0.952, 0.462, 0.105), (0.977, 0.551, 0.039), (0.988, 0.645, 0.040), (0.983, 0.744, 0.138), (0.964, 0.844, 0.273), (0.946, 0.931, 0.442), (0.988, 0.998, 0.645), ]
    ),
    :spectral => Colormap(
        [0.000, 0.050, 0.100, 0.150, 0.200, 0.250, 0.300, 0.350, 0.400, 0.450, 0.500, 0.550, 0.600, 0.650, 0.700, 0.750, 0.800, 0.850, 0.900, 0.950, 1.000, ],
        [(0.620, 0.004, 0.259), (0.730, 0.126, 0.285), (0.838, 0.247, 0.309), (0.895, 0.333, 0.287), (0.957, 0.427, 0.263), (0.975, 0.557, 0.323), (0.991, 0.677, 0.378), (0.994, 0.778, 0.461), (0.996, 0.878, 0.545), (0.998, 0.940, 0.649), (0.998, 0.999, 0.746), (0.952, 0.981, 0.674), (0.902, 0.961, 0.596), (0.784, 0.913, 0.620), (0.675, 0.869, 0.642), (0.538, 0.815, 0.645), (0.400, 0.761, 0.647), (0.296, 0.645, 0.695), (0.199, 0.529, 0.739), (0.281, 0.424, 0.689), (0.369, 0.310, 0.635), ]
    ),
    :seismic => Colormap(
        [0.000, 0.050, 0.100, 0.150, 0.200, 0.250, 0.300, 0.350, 0.400, 0.450, 0.500, 0.550, 0.600, 0.650, 0.700, 0.750, 0.800, 0.850, 0.900, 0.950, 1.000, ],
        [(0.000, 0.000, 0.300), (0.000, 0.000, 0.443), (0.000, 0.000, 0.585), (0.000, 0.000, 0.717), (0.000, 0.000, 0.860), (0.004, 0.004, 1.000), (0.192, 0.192, 1.000), (0.396, 0.396, 1.000), (0.600, 0.600, 1.000), (0.804, 0.804, 1.000), (1.000, 0.992, 0.992), (1.000, 0.804, 0.804), (1.000, 0.600, 0.600), (1.000, 0.396, 0.396), (1.000, 0.208, 0.208), (1.000, 0.004, 0.004), (0.900, 0.000, 0.000), (0.798, 0.000, 0.000), (0.696, 0.000, 0.000), (0.602, 0.000, 0.000), (0.500, 0.000, 0.000), ]
    ),
    :bwr => Colormap(
        [0.000, 0.050, 0.100, 0.150, 0.200, 0.250, 0.300, 0.350, 0.400, 0.450, 0.500, 0.550, 0.600, 0.650, 0.700, 0.750, 0.800, 0.850, 0.900, 0.950, 1.000, ],
        [(0.000, 0.000, 1.000), (0.102, 0.102, 1.000), (0.204, 0.204, 1.000), (0.298, 0.298, 1.000), (0.400, 0.400, 1.000), (0.502, 0.502, 1.000), (0.596, 0.596, 1.000), (0.698, 0.698, 1.000), (0.800, 0.800, 1.000), (0.902, 0.902, 1.000), (1.000, 0.996, 0.996), (1.000, 0.902, 0.902), (1.000, 0.800, 0.800), (1.000, 0.698, 0.698), (1.000, 0.604, 0.604), (1.000, 0.502, 0.502), (1.000, 0.400, 0.400), (1.000, 0.298, 0.298), (1.000, 0.196, 0.196), (1.000, 0.102, 0.102), (1.000, 0.000, 0.000), ]
    ),
    :rainbow => Colormap(
        [0.000, 0.025, 0.050, 0.075, 0.100, 0.125, 0.150, 0.175, 0.200, 0.225, 0.250, 0.275, 0.300, 0.325, 0.350, 0.375, 0.400, 0.425, 0.450, 0.475, 0.500, 0.525, 0.550, 0.575, 0.600, 0.625, 0.650, 0.675, 0.700, 0.725, 0.750, 0.775, 0.800, 0.825, 0.850, 0.875, 0.900, 0.925, 0.950, 0.975, 1.000, ],
        [(0.500, 0.000, 1.000), (0.453, 0.074, 0.999), (0.398, 0.159, 0.997), (0.351, 0.232, 0.993), (0.296, 0.315, 0.987), (0.249, 0.384, 0.981), (0.202, 0.451, 0.973), (0.147, 0.526, 0.962), (0.100, 0.588, 0.951), (0.053, 0.646, 0.939), (0.002, 0.709, 0.923), (0.049, 0.759, 0.908), (0.096, 0.805, 0.892), (0.151, 0.853, 0.872), (0.198, 0.890, 0.853), (0.253, 0.926, 0.830), (0.300, 0.951, 0.809), (0.347, 0.971, 0.787), (0.402, 0.988, 0.759), (0.449, 0.997, 0.735), (0.504, 1.000, 0.705), (0.551, 0.997, 0.678), (0.598, 0.988, 0.651), (0.653, 0.971, 0.617), (0.700, 0.951, 0.588), (0.747, 0.926, 0.557), (0.802, 0.890, 0.521), (0.849, 0.853, 0.489), (0.896, 0.813, 0.457), (0.951, 0.759, 0.418), (0.998, 0.709, 0.384), (1.000, 0.646, 0.344), (1.000, 0.588, 0.309), (1.000, 0.526, 0.274), (1.000, 0.451, 0.232), (1.000, 0.384, 0.196), (1.000, 0.303, 0.153), (1.000, 0.232, 0.117), (1.000, 0.159, 0.080), (1.000, 0.074, 0.037), (1.000, 0.000, 0.000), ]
    ),
    :jet => Colormap(
        [0.000, 0.025, 0.050, 0.075, 0.100, 0.125, 0.150, 0.175, 0.200, 0.225, 0.250, 0.275, 0.300, 0.325, 0.350, 0.375, 0.400, 0.425, 0.450, 0.475, 0.500, 0.525, 0.550, 0.575, 0.600, 0.625, 0.650, 0.675, 0.700, 0.725, 0.750, 0.775, 0.800, 0.825, 0.850, 0.875, 0.900, 0.925, 0.950, 0.975, 1.000, ],
        [(0.000, 0.000, 0.500), (0.000, 0.000, 0.607), (0.000, 0.000, 0.732), (0.000, 0.000, 0.839), (0.000, 0.000, 0.963), (0.000, 0.002, 1.000), (0.000, 0.096, 1.000), (0.000, 0.206, 1.000), (0.000, 0.300, 1.000), (0.000, 0.394, 1.000), (0.000, 0.504, 1.000), (0.000, 0.598, 1.000), (0.000, 0.692, 1.000), (0.000, 0.802, 1.000), (0.000, 0.896, 0.971), (0.085, 1.000, 0.882), (0.161, 1.000, 0.806), (0.237, 1.000, 0.731), (0.326, 1.000, 0.642), (0.402, 1.000, 0.566), (0.490, 1.000, 0.478), (0.566, 1.000, 0.402), (0.642, 1.000, 0.326), (0.731, 1.000, 0.237), (0.806, 1.000, 0.161), (0.882, 1.000, 0.085), (0.971, 0.959, 0.000), (1.000, 0.872, 0.000), (1.000, 0.785, 0.000), (1.000, 0.683, 0.000), (1.000, 0.596, 0.000), (1.000, 0.495, 0.000), (1.000, 0.407, 0.000), (1.000, 0.320, 0.000), (1.000, 0.219, 0.000), (1.000, 0.131, 0.000), (0.946, 0.030, 0.000), (0.839, 0.000, 0.000), (0.732, 0.000, 0.000), (0.607, 0.000, 0.000), (0.500, 0.000, 0.000), ]
    ),
    :turbo => Colormap(
        [0.000, 0.025, 0.050, 0.075, 0.100, 0.125, 0.150, 0.175, 0.200, 0.225, 0.250, 0.275, 0.300, 0.325, 0.350, 0.375, 0.400, 0.425, 0.450, 0.475, 0.500, 0.525, 0.550, 0.575, 0.600, 0.625, 0.650, 0.675, 0.700, 0.725, 0.750, 0.775, 0.800, 0.825, 0.850, 0.875, 0.900, 0.925, 0.950, 0.975, 1.000, ],
        [(0.190, 0.072, 0.232), (0.217, 0.141, 0.400), (0.242, 0.219, 0.569), (0.259, 0.285, 0.693), (0.271, 0.359, 0.812), (0.276, 0.421, 0.891), (0.276, 0.481, 0.951), (0.269, 0.550, 0.993), (0.244, 0.609, 0.997), (0.207, 0.669, 0.974), (0.158, 0.736, 0.923), (0.122, 0.789, 0.866), (0.098, 0.837, 0.803), (0.097, 0.885, 0.733), (0.127, 0.917, 0.676), (0.197, 0.949, 0.595), (0.276, 0.971, 0.517), (0.366, 0.987, 0.437), (0.474, 0.998, 0.350), (0.560, 0.999, 0.286), (0.644, 0.990, 0.234), (0.706, 0.973, 0.210), (0.766, 0.946, 0.203), (0.832, 0.906, 0.208), (0.883, 0.866, 0.217), (0.927, 0.820, 0.226), (0.965, 0.764, 0.228), (0.985, 0.713, 0.216), (0.995, 0.653, 0.196), (0.995, 0.575, 0.164), (0.986, 0.505, 0.134), (0.966, 0.422, 0.098), (0.941, 0.356, 0.070), (0.910, 0.296, 0.048), (0.868, 0.237, 0.031), (0.824, 0.192, 0.020), (0.765, 0.144, 0.010), (0.707, 0.107, 0.006), (0.642, 0.074, 0.004), (0.559, 0.040, 0.006), (0.480, 0.016, 0.011), ]
    ),
)

const _colormaps_list = collect(keys(_colormaps_dict))
