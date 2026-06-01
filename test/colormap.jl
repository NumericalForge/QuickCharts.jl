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

    @test_throws AssertionError Colormap([0.0], [:red, :blue])
end
