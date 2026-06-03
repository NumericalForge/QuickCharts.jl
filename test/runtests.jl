using Test
using QuickCharts

@testset "QuickCharts" begin
    include("axis.jl")
    include("chart.jl")
    include("bar-chart.jl")
    include("chart-grid.jl")
    include("colormap.jl")
    include("colors.jl")
    include("video-builder.jl")
    include("typesetting.jl")
    include("units.jl")
end
