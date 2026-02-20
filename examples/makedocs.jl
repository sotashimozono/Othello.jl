using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))
using Literate, Reversi

input_dir = @__DIR__
base_dir = pkgdir(Reversi)
output_dir = joinpath(base_dir, "docs", "src", "example")
mkpath(output_dir)

for file in readdir(input_dir)
    if endswith(file, ".jl") && file != basename(@__FILE__)
        println("Generating markdown for: $file")
        Literate.markdown(joinpath(input_dir, file), output_dir; documenter=true)
    end
end
