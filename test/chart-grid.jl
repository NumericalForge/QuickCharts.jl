using QuickPlots
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

QuickPlots.configure!(grid)
nested_header_width = QuickPlots.getsize("Nested", grid.font_size)[1]
@test grid.row_header_boxes[2].frame.width < nested_header_width
subgrid_frame = grid.cell_frames[(2, 1)]
QuickPlots._set_grid_frame!(subgrid, subgrid_frame)
QuickPlots.configure!(subgrid)
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
