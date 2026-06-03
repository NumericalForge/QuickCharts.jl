using Test
using QuickCharts

@testset "Color utilities" begin
    @test lighten(:royal_blue, 0.25) == lighten(Color(:royal_blue), 0.25)
    @test lighten(:royalblue, 0.25) == lighten(Color(:royal_blue), 0.25)
    @test all(isapprox.(rgba(lighten(Color(0.2, 0.4, 0.6, 0.3), 0.25)), (0.325, 0.55, 0.775, 0.3)))

    @test darken(:tomato, 0.4) == darken(Color(:tomato), 0.4)
    @test darken(:lightsteelblue, 0.4) == darken(Color(:light_steel_blue), 0.4)
    @test all(isapprox.(rgba(darken(Color(0.2, 0.4, 0.6, 0.3), 0.25)), (0.15, 0.3, 0.45, 0.3)))

    err = try
        Color(:ligthblue)
        nothing
    catch ex
        ex
    end
    @test err isa ArgumentError
    @test occursin("Did you mean :lightblue?", sprint(showerror, err))
end
