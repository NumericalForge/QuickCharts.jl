using Test
using QuickCharts

X = collect(1:5)
Y = [1.5, 2.2, 0.1, 1.1, 2.8]

chart = Chart(
    xlabel="Category",
    ylabel="Value",
    legend=:top_left
)

add_bar(chart, X, Y;
    color=:steel_blue,
    label="bar series"
)

outfile = joinpath("output", "bar-chart.pdf")
save(chart, outfile)
@test isfile(outfile)
