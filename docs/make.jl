using Reversi
using Documenter
using Downloads

assets_dir = joinpath(@__DIR__, "src", "assets")
mkpath(assets_dir)
favicon_path = joinpath(assets_dir, "favicon.ico")
logo_path = joinpath(assets_dir, "logo.png")

Downloads.download("https://github.com/sotashimozono.png", favicon_path)
Downloads.download("https://github.com/sotashimozono.png", logo_path)

makedocs(;
    sitename="Reversi.jl",
    modules=[Reversi],
    format=Documenter.HTML(;
        canonical="https://codes.sota-shimozono.com/Reversi.jl/stable/",
        prettyurls=get(ENV, "CI", "false") == "true",
        mathengine=MathJax3(
            Dict(
                :tex => Dict(
                    :inlineMath => [["\$", "\$"], ["\\(", "\\)"]],
                    :tags => "ams",
                    :packages => ["base", "ams", "autoload", "physics"],
                ),
            ),
        ),
        assets=["assets/favicon.ico"],
    ),
    pages=[
        "Home" => "index.md",
        "API Reference" => [
            "Core game" => "api/core.md",
            "I/O" => "api/io.md",
            "UI" => "api/ui.md",
            "Training" => "api/training.md",
            "Analysis" => "api/analysis.md",
            "Tournament" => "api/tournament.md",
        ],
        "Examples" => [
            "Play (CUI)" => "examples/play.md",
            "Game records" => "examples/record.md",
            "WTHOR format" => "examples/wthor.md",
            "Custom players" => "examples/custom_player.md",
        ],
    ],
)

deploydocs(; repo="github.com/sotashimozono/Reversi.jl.git", devbranch="main")
