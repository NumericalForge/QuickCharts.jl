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

number_nodes = QuickCharts.parse_typeset("`0.5`")
@test length(number_nodes) == 1
@test number_nodes[1].text == "0.5"
@test !number_nodes[1].italic

integer_nodes = QuickCharts.parse_typeset("`12`")
@test length(integer_nodes) == 1
@test integer_nodes[1].text == "12"

leading_decimal_nodes = QuickCharts.parse_typeset("`.5`")
@test length(leading_decimal_nodes) == 1
@test leading_decimal_nodes[1].text == ".5"

trailing_decimal_nodes = QuickCharts.parse_typeset("`5.`")
@test length(trailing_decimal_nodes) == 1
@test trailing_decimal_nodes[1].text == "5."

scientific_nodes = QuickCharts.parse_typeset("`1e-3`")
@test length(scientific_nodes) == 1
@test scientific_nodes[1].text == "1e-3"

scientific_upper_nodes = QuickCharts.parse_typeset("`2.0E5`")
@test length(scientific_upper_nodes) == 1
@test scientific_upper_nodes[1].text == "2.0E5"

signed_number_nodes = QuickCharts.parse_typeset("`-0.5`")
@test length(signed_number_nodes) == 2
@test [n.text for n in signed_number_nodes] == ["−", "0.5"]

num_fun_nodes = QuickCharts.parse_typeset("`0.5sin(x)`")
@test length(num_fun_nodes) == 3
@test num_fun_nodes[1].text == "0.5"
@test num_fun_nodes[2].text == "sin"
@test num_fun_nodes[3] isa QuickCharts.TSParenGroup

num_fun_spaced_nodes = QuickCharts.parse_typeset("`0.5 sin(x)`")
@test length(num_fun_spaced_nodes) == 3
@test num_fun_spaced_nodes[1].text == "0.5"
@test num_fun_spaced_nodes[2].text == "sin"

num_var_nodes = QuickCharts.parse_typeset("`2x`")
@test length(num_var_nodes) == 2
@test [n.text for n in num_var_nodes] == ["2", "x"]

num_identifier_nodes = QuickCharts.parse_typeset("`2foo`")
@test [n.text for n in num_identifier_nodes] == ["2", "f", "o", "o"]

@test isapprox(QuickCharts._implicit_atom_spacing(num_fun_nodes[1], num_fun_nodes[2], 10.0), 0.8)
@test QuickCharts._implicit_atom_spacing(num_var_nodes[1], num_var_nodes[2], 10.0) == 0.0
@test QuickCharts._implicit_atom_spacing(num_identifier_nodes[1], num_identifier_nodes[2], 10.0) == 0.0
@test QuickCharts._implicit_atom_spacing(signed_number_nodes[1], signed_number_nodes[2], 10.0) == 0.0

chart = Chart(
    title="Axial `sigma_n`",
    xlabel="`x`",
    ylabel="`u_x`",
)
add_line(chart, [0.0, 1.0], [0.0, 1.0]; label="`u_x`")
add_annotation(chart, "Load `P` at \$x\$", [0.2, 0.2])
outfile = joinpath("output", "typesetting-backtick.pdf")
save(chart, outfile)
@test isfile(outfile)
