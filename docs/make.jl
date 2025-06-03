# Copyright (c) 2017: Guilherme Bodin, and contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

import Documenter
import Dualization

Documenter.makedocs(
    sitename = "Dualization.jl",
    authors = "Guilherme Bodin, and contributors",
    format = Documenter.HTML(
        assets = ["assets/favicon.ico"],
        mathengine = Documenter.MathJax(),
        prettyurls = get(ENV, "CI", nothing) == "true",
    ),
    pages = [
        "Home" => "index.md",
        "manual.md",
        "mathematical_background.md",
        "reference.md",
    ],
    modules = [Dualization],
    checkdocs = :exports,
    doctest = true,
    clean = true,
)

Documenter.deploydocs(;
    repo = "github.com/jump-dev/Dualization.jl.git",
    push_preview = true,
)
