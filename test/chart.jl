using Test
using QuickCharts


X = collect(0:0.4:8)
Y1 = sin.(X)
Y2 = cos.(X)
Y3 = sin.(X) .* cos.(X)

chart = Chart(
    title="Trigonometric Responses",
    background=:white,
    xlabel="`x` coordinate [mm]",
    ylabel="`y` coordinate [mm]",
    legend=:bottom_right
)

add_line(chart, X, Y1, mark=:circle, line_width=0.5, label="`sin(x)`")
add_line(chart, X, Y2, mark=:utriangle, color=:royal_blue, label="`cos(x)`")
add_scatter(chart, X, Y3, mark=:square, color=:green, line_style=:dash, label="`sin(x) cos(x)`")

add_annotation(chart, " `-2 + bold(A)^(1/2) - (A^2/B_3^2 + x^2/y^2 )^2 + f_2^2/g_2^2`", [0.3, 0.9]; target=[1.5, 1], anchor=:top)
ann = add_annotation(chart, "A `+ sigma`", [0.1, 0.2]; target=[4.0, 0], anchor=:top)
@test ann.anchor == :top
@test ann.font_size === nothing
add_annotation(chart, "`A_2^2 F_2^2 T_2^2`", [0.15, 0.3])
add_annotation(chart, Annotation("`a_2^2 f_2^2 a^2 f t_2^2`", [0.15, 0.4]))
add_annotation(chart, "Legend overlap", [0.88, 0.08]; anchor=:right)
@test_throws MethodError add_annotation(chart, "old", [0.5, 0.5]; alignment=:right)
@test_throws ArgumentError add_annotation(chart, "bad", [0.2, 0.2]; font_size=0.0)

hpoints = QuickCharts._annotation_connector_points(0.0, 0.0, 4.0, 2.0, 10.0, 0.25)
@test hpoints == [(2.0, 0.25), (10.0, 0.25)]

vpoints = QuickCharts._annotation_connector_points(0.0, 0.0, 4.0, 2.0, 0.5, 10.0)
@test vpoints == [(0.5, 1.0), (0.5, 10.0)]

epoints = QuickCharts._annotation_connector_points(0.0, 0.0, 4.0, 2.0, 10.0, 10.0)
@test length(epoints) == 3
@test epoints[1] == (0.0, 1.0)
@test epoints[2] == (0.0, 10.0)
@test epoints[3] == (10.0, 10.0)

epoints_h = QuickCharts._annotation_connector_points(0.0, 0.0, 4.0, 2.0, 10.0, 3.0)
@test length(epoints_h) == 3
@test epoints_h[1] == (2.0, 0.0)
@test epoints_h[2] == (10.0, 0.0)
@test epoints_h[3] == (10.0, 3.0)

outfile = joinpath("output", "chart.pdf")
save(chart, outfile)
@test isfile(outfile)

tag_chart = Chart(
    size=(12cm, 8cm),
    title="Tag anchors",
    background=:white,
    xlabel="`x`",
    ylabel="`y`",
    legend=:top_right,
    xlimits=[0.0, 2π],
)

anchors = [:top, :top_right, :right, :bottom_right, :bottom, :bottom_left, :left, :top_left]
orientations = [:horizontal, :vertical, :parallel]
# orientations = [:parallel]
tag_x = collect(range(0, 2π; length=10))

for (i, anchor) in enumerate(anchors)
    y = sin.(tag_x) .+ 0.35 * Float64(i)
    series = add_line(
        tag_chart,
        tag_x,
        y;
        color=:royal_blue,
        tag=string(anchor),
        tag_anchor=anchor,
        tag_orientation=orientations[mod1(i, length(orientations))],
        tag_pos=0.1 + 0.1*i,
        tag_padding=1.0,
        tag_font_size=7.5,
    )
    @test series.tag_anchor == anchor
    @test series.tag_padding == 1.0
    @test series.tag_font_size == 7.5
end

tag_outfile = joinpath("output", "chart-tags.svg")
QuickCharts._debug_tag_points[] = true
save(tag_chart, tag_outfile)
QuickCharts._debug_tag_points[] = false
@test isfile(tag_outfile)

pad = 3.0
tangent_angle = 40.0

ha, va, dx, dy, angle = QuickCharts._resolve_tag_layout(:bottom, :parallel, tangent_angle, pad)
@test (ha, va, angle) == ("center", "bottom", tangent_angle)
@test isapprox(dx, -pad * sind(tangent_angle))
@test isapprox(dy, -pad * cosd(tangent_angle))

ha_br, va_br, dx_br, dy_br, angle_br = QuickCharts._resolve_tag_layout(:bottom_right, :parallel, tangent_angle, pad)
@test (ha_br, va_br, angle_br) == ("right", "bottom", tangent_angle)
@test !isapprox(dx, dx_br)
@test !isapprox(dy, dy_br)

padding_series = add_line(tag_chart, [0.0, 1.0], [0.0, 0.0]; tag="gap", tag_padding=0.5)
@test padding_series.tag_padding == 0.5
default_font_series = add_line(tag_chart, [0.0, 1.0], [1.0, 1.0]; tag="default-font")
@test default_font_series.tag_font_size === nothing
font_series = add_line(tag_chart, [0.0, 1.0], [0.0, 0.0]; tag="font", tag_font_size=8.0)
@test font_series.tag_font_size == 8.0
@test_throws ArgumentError add_line(tag_chart, [0.0, 1.0], [0.0, 0.0]; tag="bad-gap", tag_padding=-0.1)
@test_throws ArgumentError add_line(tag_chart, [0.0, 1.0], [0.0, 0.0]; tag="bad-font", tag_font_size=0.0)

peak_chart = Chart(
    size=(8cm, 6cm),
    background=:white,
    xlabel="`x`",
    ylabel="`y`",
    legend=:top_right,
    xlimits=[0.0, 2.0],
    ylimits=[0.0, 1.0],
)
peak_x = [0.0, 1.0, 2.0]
peak_y = [0.0, 1.0, 0.0]
add_line(peak_chart, peak_x, peak_y; color=:black, label="peak")
configure!(peak_chart)

x_peak, y_peak, angle_peak = QuickCharts._resolve_tag_point_and_tangent(peak_chart.canvas, peak_x, peak_y, 0.5)
x_vertex, y_vertex = data2user(peak_chart.canvas, 1.0, 1.0)
@test isapprox(x_peak, x_vertex)
@test isapprox(y_peak, y_vertex)
@test isapprox(angle_peak, 0.0; atol=1.0e-8)

x_seg, y_seg, angle_seg = QuickCharts._resolve_tag_point_and_tangent(peak_chart.canvas, peak_x, peak_y, 0.25)
expected_angle_seg = QuickCharts._segment_tangent_angle(peak_chart.canvas, peak_x, peak_y, 1)
@test isapprox(angle_seg, expected_angle_seg; atol=1.0e-8)
@test x_seg < x_vertex
