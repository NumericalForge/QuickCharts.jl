using Test
using QuickCharts

@testset "Colormap construction" begin
    tuple_cmap = Colormap([0, 1], [(0.0, 0.0, 0.0), (1.0, 1.0, 1.0)])
    @test tuple_cmap.stops == [0.0, 1.0]
    @test eltype(tuple_cmap.stops) == Float64
    @test tuple_cmap.colors == [(0.0, 0.0, 0.0), (1.0, 1.0, 1.0)]

    mixed_numeric_tuple_cmap = Colormap([0.0, 1.0], [(0, 0.25, 0.5), (1.0, 1.0, 1.0)])
    @test mixed_numeric_tuple_cmap.colors == [(0.0, 0.25, 0.5), (1.0, 1.0, 1.0)]

    symbol_cmap = Colormap([0.0, 1.0], [:red, :royalblue])
    @test symbol_cmap.colors == [rgb(Color(:red)), rgb(Color(:royal_blue))]

    color_cmap = Colormap([0.0, 1.0], [Color(:steelblue), Color(0.2, 0.3, 0.4, 0.1)])
    @test color_cmap.colors == [rgb(Color(:steel_blue)), (0.2, 0.3, 0.4)]

    mixed_cmap = Colormap(
        [0.0, 0.5, 1.0],
        [:black, (0.5, 0.25, 0.75, 0.2), Color(:white)],
    )
    @test mixed_cmap.colors == [(0.0, 0.0, 0.0), (0.5, 0.25, 0.75), (1.0, 1.0, 1.0)]

    interp = mixed_cmap(0.75)
    @test interp isa Tuple
    @test all(isapprox.(interp, (0.75, 0.625, 0.875)))

    viridis = Colormap(:viridis)
    @test viridis.stops == [x for x in 0.0:0.05:1.0]
    @test viridis.colors[1] == (0.267, 0.005, 0.329)
    @test viridis.colors[end] == (0.993, 0.906, 0.144)
    @test all(isapprox.(viridis(0.125), (0.278, 0.173, 0.480)))

    magma = Colormap(:magma)
    @test magma.stops == [x for x in 0.0:0.05:1.0]
    @test magma.colors[1] == (0.001, 0.000, 0.014)
    @test magma.colors[end] == (0.987, 0.991, 0.750)
    @test all(isapprox.(magma(0.125), (0.113, 0.0615, 0.273)))

    diverging = QuickCharts.resize(Colormap(:spectral), -1.0, 1.0; diverging=true)
    diverging_twice = QuickCharts.resize(diverging, -1.0, 1.0; diverging=true)
    @test all(isfinite, diverging_twice.stops)
    @test diverging_twice.stops[1] == -1.0
    @test diverging_twice.stops[end] == 1.0
    @test all(isapprox.(diverging_twice(0.0), diverging(0.0)))

    @test_throws AssertionError Colormap([0.0], [:red, :blue])
end
