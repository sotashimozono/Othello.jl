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
    modules=[Reversi],
    pages=[
        "Home" => "index.md",
        "Examples" => [
            "quickstart" => "example/demo.md",
            "play" => "example/play.md",
            "machine learning" => "example/ml_integration.md",
        ],
        "API Reference" => [
            "struct" => "api/struct.md",
            "rules" => "api/rules.md",
            "player" => "api/player.md",
            "game" => "api/game.md",
            "data" => "api/data.md",
        ],
    ],
)

deploydocs(; repo="github.com/sotashimozono/Reversi.jl.git", devbranch="main")
