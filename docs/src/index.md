# Dualization.jl

[Dualization.jl](https://github.com/jump-dev/Dualization.jl) is an extension
package for [MathOptInterface.jl](https://github.com/jump-dev/MathOptInterface.jl)
that formulates the dual of conic optimization problems.

Dualization.jl has two main features:

 * The [`dualize`](@ref) function that computes the dual formulation of either
   a [MathOptInterface.jl](https://github.com/jump-dev/MathOptInterface.jl) or a
   [JuMP](https://github.com/jump-dev/JuMP.jl) model.
 * The [`dual_optimizer`](@ref) function that creates a MathOptInterface-compatible
   optimizer that solves the dual of the problem instead of the primal.

## License

[Dualization.jl](https://github.com/jump-dev/Dualization.jl) is licensed under
the [MIT License](https://github.com/jump-dev/Dualization.jl/blob/master/LICENSE.md).

## Installation

Install Dualization using `Pkg.add`:
```julia
import Pkg
Pkg.add("Dualization")
```

## Contributing

Contributions to this package are more than welcome, if you find a bug or have
any suggestions for the documentation please post it on the
[GitHub issue tracker](https://github.com/jump-dev/Dualization.jl/issues).

When contributing, please note that the package follows the
[JuMP style guide](https://jump.dev/JuMP.jl/stable/developers/style/).
