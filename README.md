# Dualization.jl

[![Build Status](https://github.com/jump-dev/Dualization.jl/workflows/CI/badge.svg?branch=master)](https://github.com/jump-dev/Dualization.jl/actions?query=workflow%3ACI)
[![codecov](https://codecov.io/gh/jump-dev/Dualization.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/jump-dev/Dualization.jl)
[![DOI](https://zenodo.org/badge/182854997.svg)](https://zenodo.org/badge/latestdoi/182854997)

[Dualization.jl](https://github.com/jump-dev/Dualization.jl) is an extension
package for [MathOptInterface.jl](https://github.com/jump-dev/MathOptInterface.jl)
that formulates the dual of conic optimization problems.

Dualization.jl has two main features:

 * The `Dualization.dualize` function that computes the dual formulation of either
   a [MathOptInterface.jl](https://github.com/jump-dev/MathOptInterface.jl) or a
   [JuMP](https://github.com/jump-dev/JuMP.jl) model.
 * The `Dualization.dual_optimizer` function that creates a MathOptInterface-compatible
   optimizer that solves the dual of the problem instead of the primal.

## License

`Dualization.jl` is licensed under the
[MIT License](https://github.com/jump-dev/Dualization.jl/blob/master/LICENSE.md).

## Installation

Install Dualization using `Pkg.add`:
```julia
import Pkg
Pkg.add("Dualization")
```

## Use with JuMP

To compute the dual formulation of a JuMP model, use `dualize`:
```julia
using JuMP, Dualization
model = Model()
# ... build model ...
dual_model = dualize(model)
```

To solve the dual formulation of a JuMP model, create a `dual_optimizer`:
```julia
using JuMP, Dualization, SCS
model = Model(dual_optimizer(SCS.Optimizer))
# ... build model ...
optimize!(model)  # Solves the dual instead of the primal
```

## Documentation

The [documentation for Dualization.jl](https://jump.dev/Dualization.jl/stable/)
includes a detailed description of the dual reformulation, along with examples
and an API reference.
