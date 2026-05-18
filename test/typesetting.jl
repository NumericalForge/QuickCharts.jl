using Test
using QuickPlots

w1, h1 = QuickPlots.getsize("Axial \$sigma_n\$", 8.0)
w2, h2 = QuickPlots.getsize("Axial `sigma_n`", 8.0)
@test isapprox(w1, w2; atol=1.0e-6)
@test isapprox(h1, h2; atol=1.0e-6)

wm, hm = QuickPlots.getsize("Load `P` at \$x\$", 8.0)
@test wm > 0
@test hm > 0

math_nodes = QuickPlots.parse_typeset("`xAh`")
@test [n.text for n in math_nodes] == string.([Char(0x1D465), Char(0x1D434), Char(0x210E)])
@test all(!n.italic for n in math_nodes)

greek_nodes = QuickPlots.parse_typeset("`alpha Gamma varepsilon times partial`")
@test [n.text for n in greek_nodes] == ["𝛼", "𝛤", "𝜖", "×", "∂"]
@test all(!n.italic for n in greek_nodes)

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
