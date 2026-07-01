using Test
using QuickCharts

@testset "Contour series" begin
    x = [0.0, 1.0]
    y = [0.0, 1.0]
    z = [0.0 1.0; 1.0 2.0]

    line_series = ContourSeries(x, y, z; levels=[1.0], label="diag")
    @test !line_series.filled
    @test !isempty(line_series.line_segments)
    @test isempty(line_series.fill_polygons)
    @test line_series.color === :auto
    @test line_series.colormap.stops[1] < line_series.levels[1] < line_series.colormap.stops[end]
    @test sprint(show, line_series) == "ContourSeries(mode=:line, size=2x2, levels=1, label=\"diag\", order=0)"
    @test all(segment[1] == 1.0 for segment in line_series.line_segments)
    for (_, (x1, y1, x2, y2)) in line_series.line_segments
        @test isapprox(x1 + y1, 1.0; atol=1.0e-8)
        @test isapprox(x2 + y2, 1.0; atol=1.0e-8)
    end

    filled_series = ContourSeries(x, y, z; filled=true, levels=[0.0, 1.0, 2.0], colorbar=:right)
    @test filled_series.filled
    @test !isempty(filled_series.fill_polygons)
    @test !isempty(filled_series.line_segments)
    @test filled_series.colormap.stops[1] ≈ 0.0
    @test filled_series.colormap.stops[end] ≈ 2.0

    filled_no_lines = ContourSeries(x, y, z; filled=true, levels=[0.0, 1.0, 2.0], line_style=:none)
    @test isempty(filled_no_lines.line_segments)

    @test_throws ArgumentError ContourSeries([0.0], y, z)
    @test_throws ArgumentError ContourSeries(x, [0.0], z)
    @test_throws ArgumentError ContourSeries(x, y, [0.0 1.0 2.0; 1.0 2.0 3.0])
    @test_throws ArgumentError ContourSeries([0.0, 0.0], y, z)
    @test_throws ArgumentError ContourSeries(x, [0.0, 0.0], z)
    @test_throws ArgumentError ContourSeries(x, y, z; nlevels=0)
    @test_throws ArgumentError ContourSeries(x, y, z; filled=true, levels=[1.0])
    @test_throws ArgumentError ContourSeries(x, y, z; colorbar=:bad)
    @test_throws ArgumentError ContourSeries(x, y, z; colorbar_ratio=0.0)

    hole_series = ContourSeries(
        [0.0, 1.0, 2.0],
        [0.0, 1.0, 2.0],
        [0.0 1.0 2.0; 1.0 NaN 3.0; 2.0 3.0 4.0];
        levels=[1.0, 2.0, 3.0],
        filled=true,
    )
    @test isempty(hole_series.fill_polygons)
    @test isempty(hole_series.line_segments)
end

@testset "Contour charts" begin
    x = collect(range(-1, 1; length=11))
    y = collect(range(-1, 1; length=9))
    z = [xi + yi for yi in y, xi in x]

    chart = Chart(size=(8cm, 6cm), background=:white, xlabel="`x`", ylabel="`y`")
    add_contour(chart, x, y, z; levels=[-1.0, 0.0, 1.0], label="plane")
    QuickCharts.configure!(chart)
    @test chart.xaxis.limits[1] < minimum(x)
    @test chart.xaxis.limits[2] > maximum(x)
    @test chart.yaxis.limits[1] < minimum(y)
    @test chart.yaxis.limits[2] > maximum(y)
    @test length(chart.right_items) == 1
    @test chart.right_items[1] isa Colorbar
    @test chart.right_items[1].axis.label == "plane"
    @test chart.legend.frame.width == 0.0
    @test chart.legend.frame.height == 0.0

    no_colorbar_chart = Chart(size=(8cm, 6cm), background=:white, xlabel="`x`", ylabel="`y`")
    add_contour(no_colorbar_chart, x, y, z; levels=[-1.0, 0.0, 1.0], colorbar=:none)
    QuickCharts.configure!(no_colorbar_chart)
    @test chart.canvas.frame.y > no_colorbar_chart.canvas.frame.y
    @test chart.canvas.frame.height < no_colorbar_chart.canvas.frame.height

    filled_chart = Chart(size=(8cm, 6cm), background=:white)
    add_contour(filled_chart, x, y, z; filled=true, levels=[-1.0, 0.0, 1.0], colorbar=:right, label="first")
    add_contour(filled_chart, x, y, z .+ 0.25; filled=true, levels=[-0.75, 0.25, 1.25], colorbar=:right, label="second")
    QuickCharts.configure!(filled_chart)
    @test length(filled_chart.right_items) == 2
    @test filled_chart.legend.frame.width == 0.0
    @test filled_chart.legend.frame.height == 0.0
    first_cb = filled_chart.right_items[1]::Colorbar
    second_cb = filled_chart.right_items[2]::Colorbar
    @test first_cb.axis.label == "first"
    @test second_cb.axis.label == "second"
    @test first_cb.frame.y != second_cb.frame.y

    overlay_chart = Chart(size=(8cm, 6cm), background=:white)
    overlay = add_contour(overlay_chart, x, y, z; filled=true, levels=[-1.0, 0.0, 1.0], colorbar=:right)
    @test !isempty(overlay.fill_polygons)
    @test !isempty(overlay.line_segments)

    no_line_overlay = add_contour(overlay_chart, x, y, z .+ 0.2; filled=true, levels=[-0.8, 0.2, 1.2], line_style=:none, colorbar=:left)
    @test isempty(no_line_overlay.line_segments)

    line_file = joinpath("output", "contour-lines.svg")
    filled_file = joinpath("output", "contour-filled.svg")
    filled_png = joinpath("output", "contour-filled.png")
    save(chart, line_file)
    save(filled_chart, filled_file, filled_png)
    @test isfile(line_file)
    @test isfile(filled_file)
    @test isfile(filled_png)
    @test occursin("stroke-width=\"0.25\"", read(filled_file, String))
end
