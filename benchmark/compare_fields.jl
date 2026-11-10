# Compare observable arrays of two baseline_fields.jld2 files element by element.
#
# Usage: julia --project=. benchmark/compare_fields.jl REFERENCE.jld2 NEW.jld2

using JLD2
using Printf

function main(args)
    length(args) == 2 || error("usage: compare_fields.jl REFERENCE.jld2 NEW.jld2")
    ref = load(args[1])
    new = load(args[2])
    worst = 0.0
    for name in sort(collect(keys(ref)))
        haskey(new, name) || (println("$name: missing in NEW"); continue)
        a, b = ref[name], new[name]
        size(a) == size(b) || (println("$name: size $(size(a)) != $(size(b))"); continue)
        max_abs = maximum(abs.(a .- b))
        scale = maximum(abs.(a))
        identical = count(a .== b)
        @printf("%-30s max|diff| = %.3e  max|ref| = %.3e  relative = %.3e  identical %d / %d\n",
            name, max_abs, scale, max_abs / scale, identical, length(a))
        worst = max(worst, max_abs / scale)
    end
    @printf("worst relative difference: %.3e\n", worst)
end

main(ARGS)
