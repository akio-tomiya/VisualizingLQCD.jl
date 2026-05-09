#!/usr/bin/env julia

using VisualizingLQCD

function print_diagnostics(name, density)
    diagnostics = VisualizingLQCD.topological_density_fixture_diagnostics(density)
    setup = VisualizingLQCD.topological_charge_display_level_setup(density;
        level_quantiles=(0.90, 0.97),
        color_quantile=0.995)

    println("[$name]")
    println("  total_charge   = $(diagnostics["total_charge"])")
    println("  positive_charge= $(diagnostics["positive_charge"])")
    println("  negative_charge= $(diagnostics["negative_charge"])")
    println("  max            = $(diagnostics["max"])")
    println("  min            = $(diagnostics["min"])")
    println("  levels         = $(setup.levels)")
    println("  color_range    = $(setup.render_style_info["color_range"])")
    println()
end

function main()
    lattice = (24, 24, 24, 24)
    cases = [
        ("single-plus-centered",
            VisualizingLQCD.su2_instanton_topological_density(lattice;
                rho=2.4, center=(12, 12, 12, 12), charge_sign=1)),
        ("single-minus-centered",
            VisualizingLQCD.su2_instanton_topological_density(lattice;
                rho=2.4, center=(12, 12, 12, 12), charge_sign=-1)),
        ("single-plus-boundary",
            VisualizingLQCD.su2_instanton_topological_density(lattice;
                rho=1.8, center=(1, 1, 1, 1), charge_sign=1)),
        ("diga-plus-plus",
            VisualizingLQCD.su2_diga_topological_density(lattice, [
                (rho=1.8, center=(7, 7, 7, 7), charge_sign=1),
                (rho=2.2, center=(17, 17, 17, 17), charge_sign=1),
            ])),
        ("diga-plus-minus",
            VisualizingLQCD.su2_diga_topological_density(lattice, [
                (rho=1.8, center=(7, 7, 7, 7), charge_sign=1),
                (rho=2.2, center=(17, 17, 17, 17), charge_sign=-1),
            ])),
    ]

    for (name, density) in cases
        print_diagnostics(name, density)
    end
end

main()
