using Test
using QuickCharts

w1, h1 = QuickCharts.getsize("Axial \$sigma_n\$", 8.0)
w2, h2 = QuickCharts.getsize("Axial `sigma_n`", 8.0)
@test isapprox(w1, w2; atol=1.0e-6)
@test isapprox(h1, h2; atol=1.0e-6)

wm, hm = QuickCharts.getsize("Load `P` at \$x\$", 8.0)
@test wm > 0
@test hm > 0

math_nodes = QuickCharts.parse_typeset("`xAh`")
@test [n.text for n in math_nodes] == ["x", "A", "h"]
@test all(n.italic for n in math_nodes)

greek_nodes = QuickCharts.parse_typeset("`alpha Gamma varepsilon times partial`")
@test [n.text for n in greek_nodes] == ["α", "Γ", "ε", "×", "∂"]
@test [n.italic for n in greek_nodes] == [true, true, true, false, false]

chart = Chart(
    title="Axial `sigma_n`",
    xlabel="`x`",
    ylabel="`u_x`",
)
add_line(chart, [0.0, 1.0], [0.0, 1.0]; label="`u_x`")
add_annotation(chart, Annotation("Load `P` at \$x\$", 0.2, 0.2))
outfile = joinpath("output", "typesetting-backtick.pdf")
save(chart, outfile)
@test isfile(outfile)
