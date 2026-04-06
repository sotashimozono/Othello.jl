ENV["GKSwstype"] = "100"   # headless GLMakie

using Test

# ---------------------------------------------------------------------------
# Auto-discovery: run every test_*.jl file found under subdirectories.
#
# Convention:
#   test/core/test_struct.jl   → @testset "core/test_struct"
#   test/core/test_rules.jl    → @testset "core/test_rules"
#   test/UI/test_data.jl       → @testset "UI/test_data"
#   …
#
# To run a single file directly (e.g. during development):
#   julia --project=next test/core/test_wthor.jl
# ---------------------------------------------------------------------------

const TEST_ROOT = @__DIR__

function discover_tests(root::String)
    result = Tuple{String,String}[]   # (label, filepath)
    for d1 in sort(readdir(root))
        p1 = joinpath(root, d1)
        isdir(p1) || continue
        for entry in sort(readdir(p1))
            p2 = joinpath(p1, entry)
            if isdir(p2)
                # two levels deep: e.g. ext/ReversiGLMakieExt/test_foo.jl
                for f in sort(readdir(p2))
                    startswith(f, "test_") && endswith(f, ".jl") || continue
                    label = joinpath(d1, entry, splitext(f)[1])
                    push!(result, (label, joinpath(p2, f)))
                end
            elseif startswith(entry, "test_") && endswith(entry, ".jl")
                # one level deep: e.g. core/test_rules.jl
                label = joinpath(d1, splitext(entry)[1])
                push!(result, (label, p2))
            end
        end
    end
    return result
end

@testset "Reversi.jl" begin
    for (label, filepath) in discover_tests(TEST_ROOT)
        @testset "$label" begin
            include(filepath)
        end
    end
end
