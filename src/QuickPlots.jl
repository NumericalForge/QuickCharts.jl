__precompile__()

"""
QuickPlots provides lightweight chart-oriented plotting primitives backed by
Cairo, including single charts, chart grids, annotations, legends, colors, and
math-aware text rendering.
"""
module QuickPlots

using Cairo
using LinearAlgebra
using Printf
import FreeTypeAbstraction

mutable struct QuickPlotsException <: Exception
    message::String
end

Base.showerror(io::IO, e::QuickPlotsException) = printstyled(io, "QuickPlotsException: ", e.message, "\n", color = :red)

include("include.jl")

export cm, Color, Colormap, Chart, ChartGrid, DataSeries, Legend, Annotation
export add_series, add_line, add_scatter, add_bar, add_annotation, add_chart
export lighten, darken, gray, render, save

end
