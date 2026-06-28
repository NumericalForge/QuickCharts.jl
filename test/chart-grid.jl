using QuickCharts
using Test

X = collect(0:0.25:2π)

chart1 = Chart(
    title="Sine Curve",
    background=Color(:white),
    legend_background=(242/255, 232/255, 203/255),
    xlabel="`x`",
    ylabel="`sin(x)`",
    legend=:outer_right,
)
add_line(chart1, X, sin.(X); label="`sin(x)`", mark=:circle)

chart2 = Chart(
    title="Bar Values",
    xlabel="Category",
    ylabel="Value",
    legend=:top_left,
)
add_bar(chart2, 1:5, [1.0, 1.5, 0.7, 1.2, 1.8]; color=:steel_blue, label="bars")
add_line(
    chart2,
    1:5,
    [1.1, 1.3, 0.9, 1.0, 1.6];
    color=Color(:royal_blue),
    mark=:square,
    mark_color=(1.0, 1.0, 1.0),
    mark_stroke_color=Color(:black),
    label="overlay",
)

chart3 = Chart(
    title="Nested",
    xlabel="`x`",
    ylabel="`x^2`",
)
add_line(chart3, X, X .^ 2; color=:dark_orange, label="`x^2`")

subgrid = ChartGrid(
    title="Inset Grid",
    background=:bone,
)
add_chart(subgrid, chart3, (1, 1))

grid = ChartGrid(
    title="Composed Figure With `sigma_n` Charts",
    size=(18cm, 14cm),
    background=:old_paper,
    column_headers=["`sin(x)`", "Bar Plot", "Ignored"],
    row_headers=["`u_x`", "Nested", "Ignored"],
)

add_chart(grid, chart1, (1, 1))
add_chart(grid, chart2, (1, 2))
add_chart(grid, subgrid, (2, 1))
add_chart(grid, chart3, (2, 2))

QuickCharts.configure!(grid)
nested_header_width = QuickCharts.getsize("Nested", grid.font_size)[1]
@test grid.row_header_boxes[2].frame.width < nested_header_width
subgrid_frame = grid.cell_frames[(2, 1)]
QuickCharts._set_grid_frame!(subgrid, subgrid_frame)
QuickCharts.configure!(subgrid)
@test subgrid.figure_frame.x == subgrid_frame.x
@test subgrid.figure_frame.y == subgrid_frame.y
@test subgrid.title_box.frame.y >= subgrid_frame.y

save(grid, joinpath("output", "chart-grid.pdf"))
save(chart1, joinpath("output", "chart-grid-child.pdf"))
@test chart1.background == Color(:white)
@test chart1.legend.background == Color(:old_paper)
@test chart2.dataseries[2].color == Color(:royal_blue)
@test chart2.dataseries[2].mark_color == Color(:white)
@test chart2.dataseries[2].mark_stroke_color == Color(:black)

wide = Chart(size=(200, 50))
tall = Chart(size=(150, 120))
medium = Chart(size=(100, 70))
small = Chart(size=(80, 40))

auto = ChartGrid(hgap=10.0, vgap=5.0)
add_chart(auto, wide, (1, 1))
add_chart(auto, medium, (1, 2))
add_chart(auto, tall, (2, 1))
add_chart(auto, small, (2, 2))

QuickCharts.configure!(auto)
expected_auto_outerpad = 195 / 98
@test isapprox(auto.outerpad, expected_auto_outerpad; atol=1e-8)
@test isapprox(auto.width, 310 + 2 * expected_auto_outerpad; atol=1e-8)
@test isapprox(auto.height, 195 + 2 * expected_auto_outerpad; atol=1e-8)
@test isapprox(auto.cell_frames[(1, 1)].width, 200)
@test isapprox(auto.cell_frames[(1, 2)].width, 100)
@test isapprox(auto.cell_frames[(2, 1)].height, 120)
@test isapprox(auto.cell_frames[(1, 1)].height, 70)

scaled = ChartGrid(size=(600, 400), hgap=10.0, vgap=5.0)
add_chart(scaled, wide, (1, 1))
add_chart(scaled, medium, (1, 2))
add_chart(scaled, tall, (2, 1))
add_chart(scaled, small, (2, 2))

QuickCharts.configure!(scaled)
expected_scaled_outerpad = 4.0
expected_col_scale = (scaled.width - 2 * expected_scaled_outerpad - scaled.hgap) / 300
expected_row_scale = (scaled.height - 2 * expected_scaled_outerpad - scaled.vgap) / 190
@test isapprox(scaled.outerpad, expected_scaled_outerpad)
@test isapprox(scaled.cell_frames[(1, 1)].width, 200 * expected_col_scale; atol=1e-8)
@test isapprox(scaled.cell_frames[(1, 2)].width, 100 * expected_col_scale; atol=1e-8)
@test isapprox(scaled.cell_frames[(1, 1)].height, 70 * expected_row_scale; atol=1e-8)
@test isapprox(scaled.cell_frames[(2, 1)].height, 120 * expected_row_scale; atol=1e-8)

sub_auto = ChartGrid(hgap=6.0)
sub_left = Chart(size=(90, 50))
sub_right = Chart(size=(140, 60))
add_chart(sub_auto, sub_left, (1, 1))
add_chart(sub_auto, sub_right, (1, 2))
QuickCharts.configure!(sub_auto)

parent_auto = ChartGrid(hgap=8.0)
parent_right = Chart(size=(120, 80))
add_chart(parent_auto, sub_auto, (1, 1))
add_chart(parent_auto, parent_right, (1, 2))
QuickCharts.configure!(parent_auto)
@test isapprox(parent_auto.cell_frames[(1, 1)].width, sub_auto.width; atol=1e-8)
@test isapprox(parent_auto.cell_frames[(1, 1)].height, 80; atol=1e-8)

sparse = ChartGrid()
add_chart(sparse, Chart(size=(40, 30)), (1, 1))
add_chart(sparse, Chart(size=(40, 30)), (1, 3))
@test_throws ArgumentError QuickCharts.configure!(sparse)
