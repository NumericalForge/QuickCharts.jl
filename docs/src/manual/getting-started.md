# Getting Started

QuickPlots builds figures from a small set of plotting primitives:

- `Chart` creates a single set of axes.
- `add_line`, `add_scatter`, and `add_bar` add data series.
- `Annotation` and `add_annotation` add plot-area notes.
- `ChartGrid` combines charts into multi-panel figures.
- `save` writes figures to `.pdf`, `.png`, `.svg`, or `.ps`.

Figure sizes are specified in typographic points. The exported `cm` constant is
provided for convenient centimeter-based sizes.

## A First Chart

Load the package, prepare data, and create a chart:

```@example getting_started
using QuickPlots

x = collect(0:0.5:6)
y = sin.(x)

chart = Chart(
    size = (9cm, 6cm),
    title = "Sine Response",
    xlabel = "`x`",
    ylabel = "`sin(x)`",
    legend = :bottom_right,
)
```

Add a line series. Series labels appear in the legend; an empty label keeps a
series out of the legend.

```@example getting_started
add_line(chart, x, y; mark = :circle, label = "`sin(x)`")
nothing
```

Export the figure:

```@example getting_started
save(chart, "getting-started.svg")
nothing
```

QuickPlots renders to `.pdf`, `.png`, `.svg`, and `.ps`.

## Text and Math

Titles, labels, legends, series tags, and annotations can include inline math.
Math spans can be delimited with backticks, such as `` `u_x(t)` ``, or with
escaped dollar signs in normal Julia strings, such as `"\$sigma_n\$"`.
Backticks are preferred because they do not need escaping.

```@example getting_started
math_chart = Chart(
    size = (9cm, 6cm),
    title = "Response `u_x(t)`",
    xlabel = "`t`",
    ylabel = "`u_x`",
    legend = :top_right,
)

add_line(math_chart, x, exp.(-0.2 .* x) .* sin.(x); label = "`e^(-0.2t) sin(t)`")
save(math_chart, "getting-started-math.svg")
nothing
```

The math syntax is Typst-like and supports common expression features,
including subscripts, superscripts, fractions, brackets, and bold text. Use
parentheses for grouping instead of braces; for example, write
`` `(a + b)/(c + d)` `` and `` `x_(i+1)^2` `` rather than brace-grouped forms.
The `frac` function is not required for fractions, because slash notation can
turn grouped expressions into fractions directly.

## Colors

Colors can be provided as named symbols, RGB/RGBA tuples, or `Color` values:

```@example getting_started
color_chart = Chart(
    size = (9cm, 6cm),
    title = "Styled Series",
    xlabel = "`x`",
    ylabel = "`y`",
    legend = :bottom_left,
)

add_line(color_chart, x, sin.(x); color = :royal_blue, line_width = 0.9, label = "line")
add_scatter(color_chart, x, cos.(x); color = (0.1, 0.5, 0.2), label = "points")
save(color_chart, "getting-started-colors.pdf")
```

When `color = :auto`, QuickPlots cycles through its default chart palette.
