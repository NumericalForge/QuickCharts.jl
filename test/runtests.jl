using Test
using QuickPlots

@testset "QuickPlots" begin
    include("axis.jl")
    include("chart.jl")
    include("bar-chart.jl")
    include("chart-grid.jl")
    include("typesetting.jl")
    include("units.jl")
end
