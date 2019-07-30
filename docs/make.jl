using Documenter, Dualization

makedocs(
    modules = [Dualization],
    doctest  = false,
    clean = true,
    # See https://github.com/JuliaDocs/Documenter.jl/issues/868
    format = Documenter.HTML(prettyurls = get(ENV, "CI", nothing) == "true"),
    # See https://github.com/JuliaOpt/JuMP.jl/issues/1576
    strict = true,
    sitename = "Dualization.jl",
    authors = "Guilherme Bodin, and contributors",
    pages = [
        "Home" => "index.md",
        "manual.md",
        "examples.md",
        "reference.md"
    ]
)

deploydocs(
    repo = "github.com/guilhermebodin/Dualization.jl.git",
)