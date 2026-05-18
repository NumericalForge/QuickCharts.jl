using Test
using QuickPlots
using Cairo: read_from_png, width, height, image_surface_get_data

function svg_dimension(svg, attr)
    m = match(Regex(attr * "=\"([0-9.]+)\""), svg)
    m === nothing && error("missing SVG $attr")
    return parse(Float64, m.captures[1])
end

chart = Chart(size=(5cm, 4cm))
@test isapprox(chart.width, 5cm)
@test isapprox(chart.height, 4cm)

series = add_line(chart, 0:1, 0:1; label="line")
series_show = sprint(show, series)
@test series_show == "DataSeries(:line, n=2, label=\"line\", style=:solid, mark=:none, order=1)"
@test sprint(show, MIME("text/plain"), series) == series_show
@test !occursin("[0, 1]", series_show)

chart_show = sprint(show, chart)
@test chart_show == "Chart(size=$(chart.width) x $(chart.height) pt, axes=\"`x`\" vs \"`y`\", series=1, annotations=0, legend=:top_right)"
@test sprint(show, MIME("text/plain"), chart) == chart_show
@test !occursin("QuickPlots.Frame", chart_show)
@test !occursin("QuickPlots.Axis", chart_show)

chart_pdf = joinpath("output", "chart-cm.pdf")
QuickPlots.save(chart, chart_pdf)

chart_svg = render(chart)
@test startswith(chart_svg, "<?xml")
@test occursin("<svg", chart_svg)
@test isapprox(svg_dimension(chart_svg, "width"), 1.5 * chart.width)
@test isapprox(svg_dimension(chart_svg, "height"), 1.5 * chart.height)
@test occursin("fill=\"rgb(100%, 100%, 100%)\"", chart_svg)

chart_svg_unscaled = render(chart; scale=1)
@test isapprox(svg_dimension(chart_svg_unscaled, "width"), chart.width)
@test isapprox(svg_dimension(chart_svg_unscaled, "height"), chart.height)

chart_svg_io = IOBuffer()
render(chart_svg_io, chart)
chart_svg_io_text = String(take!(chart_svg_io))
@test startswith(chart_svg_io_text, "<?xml")
@test occursin("<svg", chart_svg_io_text)
@test isapprox(svg_dimension(chart_svg_io_text, "width"), 1.5 * chart.width)
@test isapprox(svg_dimension(chart_svg_io_text, "height"), 1.5 * chart.height)
@test occursin("fill=\"rgb(100%, 100%, 100%)\"", chart_svg_io_text)

chart_svg_show = sprint(show, MIME("image/svg+xml"), chart)
@test startswith(chart_svg_show, "<?xml")
@test occursin("<svg", chart_svg_show)
@test isapprox(svg_dimension(chart_svg_show, "width"), 1.5 * chart.width)
@test isapprox(svg_dimension(chart_svg_show, "height"), 1.5 * chart.height)
@test occursin("fill=\"rgb(100%, 100%, 100%)\"", chart_svg_show)
@test_throws ArgumentError render(chart; format=:png)
@test_throws ArgumentError render(chart; scale=0)

grid = ChartGrid(size=(12cm, 8cm))
@test isapprox(grid.width, 12cm)
@test isapprox(grid.height, 8cm)
add_chart(grid, chart, (1, 1))
grid_show = sprint(show, grid)
@test grid_show == "ChartGrid(size=$(grid.width) x $(grid.height) pt, layout=1 x 1, children=1, column_headers=0, row_headers=0)"
@test sprint(show, MIME("text/plain"), grid) == grid_show
@test !occursin("QuickPlots.Frame", grid_show)
@test !occursin("Dict", grid_show)

grid_png_file = joinpath("output", "chart-grid-cm.png")
QuickPlots.save(grid, grid_png_file)
grid_png = read_from_png(grid_png_file)
@test Int(width(grid_png)) == round(Int, QuickPlots._png_raster_scale * grid.width)
@test Int(height(grid_png)) == round(Int, QuickPlots._png_raster_scale * grid.height)
