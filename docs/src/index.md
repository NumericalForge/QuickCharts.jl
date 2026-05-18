```@meta
DocTestSetup = quote
    using QuickPlots
end
```

# QuickPlots.jl

`QuickPlots.jl` provides chart-focused plotting primitives extracted from `Serendip.jl`:

- `Chart` for line, scatter, and bar plots.
- `ChartGrid` for multi-panel layouts.
- `Annotation`, `Legend`, `Color`, and math-aware text rendering utilities.

This package intentionally does not include `DomainPlot`.

## Installation

```julia
using Pkg
Pkg.develop(path=".")
```

## Documentation Map

The docs are organized in two parts:

1. `Manual`: package setup and a short chart tutorial.
2. `API Reference`: exported plotting types and functions.
