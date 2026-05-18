# QuickCharts.jl


[![docs-stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://numericalforge.github.io/QuickCharts.jl/stable/)
[![docs-dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://numericalforge.github.io/QuickCharts.jl/dev/)


`QuickCharts.jl` is a lightweight Julia package for chart-oriented plotting with Cairo output.

It focuses on a compact set of figure-building tools: `Chart` for single plots, `ChartGrid` for composed layouts, and supporting types for colors, legends, annotations, and math-aware text rendering.

![QuickCharts showcase](docs/src/assets/readme-showcase.svg)

## Installation

Until `QuickCharts.jl` is registered, install it directly from the GitHub repository:

```julia
using Pkg
Pkg.add(url="https://github.com/NumericalForge/QuickCharts.jl")
```

## Quick Start

```julia
using QuickCharts

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

Online documentation is available at:

https://numericalforge.github.io/QuickCharts.jl/dev/


## License

This project is licensed under the MIT License. See [LICENSE.md](LICENSE.md) for details.
