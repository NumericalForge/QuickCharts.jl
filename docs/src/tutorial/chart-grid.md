# ChartGrid Tutorial

`ChartGrid` arranges charts into rows and columns. It is useful for comparing
related plots while keeping each child chart responsible for its own axes,
series, and legend.

## Build Child Charts

Create the child charts first. Each child can use its own labels, limits, and
legend placement.

```@example chart_grid_tutorial
using QuickPlots

x = collect(0:0.25:2π)

signal = Chart(
    title = "Signals",
    xlabel = "`x`",
    ylabel = "amplitude",
    legend = :bottom_right,
)
add_line(signal, x, sin.(x); label = "`sin(x)`")
add_line(signal, x, cos.(x); color = :royal_blue, line_style = :dash, label = "`cos(x)`")

energy = Chart(
    title = "Energy",
    xlabel = "`x`",
    ylabel = "`sin^2(x)`",
    legend = :top_right,
)
add_line(energy, x, sin.(x).^2; color = :dark_orange, label = "`sin^2(x)`")

samples = Chart(
    title = "Samples",
    xlabel = "`x`",
    ylabel = "`sin(x)`",
    legend = :bottom_left,
)
add_scatter(samples, x[1:3:end], sin.(x[1:3:end]); color = :green, label = "samples")

bars = Chart(
    title = "Categories",
    xlabel = "category",
    ylabel = "value",
    legend = :top_left,
)
add_bar(bars, 1:4, [1.2, 0.8, 1.6, 1.1]; color = :steel_blue, label = "value")
nothing
```

## Place Charts in a Grid

Use `add_chart(grid, chart, (row, column))` to place each child. Rows and
columns are one-based, and the grid grows to fit the largest occupied row and
column.

```@example chart_grid_tutorial
grid = ChartGrid(
    title = "Signal Summary",
    size = (18cm, 12cm),
    background = :old_paper,
    column_headers = ["Continuous", "Discrete"],
    row_headers = ["Waveforms", "Derived"],
    hgap = 10.0,
    vgap = 10.0,
)

add_chart(grid, signal, (1, 1))
add_chart(grid, samples, (1, 2))
add_chart(grid, energy, (2, 1))
add_chart(grid, bars, (2, 2))

save(grid, "tutorial-chart-grid.svg")
nothing
```

Child chart backgrounds are ignored while drawing inside a grid. The grid
background supplies the page fill, while each child keeps its own axes, series,
legend, and annotations.

## Nested Grids

A `ChartGrid` can also be placed inside another `ChartGrid`, which is handy when
one panel needs its own sub-layout.

```@example chart_grid_tutorial
left = ChartGrid(
    title = "Trigonometry",
    column_headers = ["Signal", "Energy"],
    hgap = 8.0,
)
add_chart(left, signal, (1, 1))
add_chart(left, energy, (1, 2))

nested = ChartGrid(
    title = "Nested Layout",
    size = (18cm, 9cm),
    column_headers = ["Grouped Charts", "Bars"],
    background = :white_smoke,
)
add_chart(nested, left, (1, 1))
add_chart(nested, bars, (1, 2))

save(nested, "tutorial-nested-grid.svg")
nothing
```

Use nested grids sparingly: they are best when the grouping itself communicates
structure, not just to squeeze more plots onto a page.
