# Copyright (c) 2017: Guilherme Bodin, and contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

using Documenter, Dualization

makedocs(
    modules = [Dualization],
    doctest = false,
    clean = true,
    # See https://github.com/JuliaDocs/Documenter.jl/issues/868
    format = Documenter.HTML(
        assets = ["assets/favicon.ico"],
        mathengine = Documenter.MathJax(),
        prettyurls = get(ENV, "CI", nothing) == "true",
    ),
    sitename = "Dualization.jl",
    authors = "Guilherme Bodin, and contributors",
    pages = ["Home" => "index.md", "manual.md", "examples.md", "reference.md"],
)

deploydocs(repo = "github.com/jump-dev/Dualization.jl.git")
