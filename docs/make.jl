using Documenter, Dualization

makedocs(
    modules = [Dualization],
    doctest  = false,
    clean    = true,
    format   = Documenter.HTML(),
    sitename = "Dualization.jl",
    authors = "Guilherme Bodin.",
    pages = [
        "Home" => "index.md",
        "manual.md"
    ]
)

deploydocs(
    repo = "github.com/guilhermebodin/Dualization.jl.git",
)