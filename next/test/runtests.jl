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
    for entry in sort(readdir(root))
        dirpath = joinpath(root, entry)
        isdir(dirpath) || continue
        for f in sort(readdir(dirpath))
            startswith(f, "test_") && endswith(f, ".jl") || continue
            label = joinpath(entry, splitext(f)[1])   # e.g. "core/test_rules"
            push!(result, (label, joinpath(dirpath, f)))
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
