# QuickPlots.jl

`QuickPlots.jl` is a lightweight Julia package for chart-oriented plotting with Cairo output.

The package in this repository was extracted from the chart plotting subsystem of `Serendip.jl`. It intentionally excludes `DomainPlot` and keeps the focus on `Chart`, `ChartGrid`, annotations, legends, colors, and math-aware text rendering.

## Installation

```julia
using Pkg
Pkg.develop(path=".")
```

## Quick Start

```julia
using QuickPlots

x = collect(0:0.2:2π)
chart = Chart(
    size = (10cm, 7cm),
    title = "Trigonometric Curves",
    xlabel = "`x`",
    ylabel = "`y`",
    legend = :bottom_right,
)

add_line(chart, x, sin.(x); label = "`sin(x)`", mark = :circle)
add_line(chart, x, cos.(x); label = "`cos(x)`", color = :royalblue)

save(chart, "chart.svg", "chart.pdf")
```

## Documentation

Build the docs locally with:

```julia
using Pkg
Pkg.activate("docs")
Pkg.instantiate()
include("docs/make.jl")
```

## License

This project is licensed under the MIT License. See [LICENSE.md](LICENSE.md) for details.
