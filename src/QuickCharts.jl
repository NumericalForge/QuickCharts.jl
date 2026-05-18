__precompile__()

"""
QuickCharts provides lightweight chart-oriented plotting primitives backed by
Cairo, including single charts, chart grids, annotations, legends, colors, and
math-aware text rendering.
"""
module QuickCharts

using Cairo
using LinearAlgebra
using Printf
import FreeTypeAbstraction

mutable struct QuickChartsException <: Exception
    message::String
end

Base.showerror(io::IO, e::QuickChartsException) = printstyled(io, "QuickChartsException: ", e.message, "\n", color = :red)

include("include.jl")

export cm, Color, Colormap, Chart, ChartGrid, DataSeries, Legend, Annotation
export add_series, add_line, add_scatter, add_bar, add_annotation, add_chart
export lighten, darken, gray, render, save

end
