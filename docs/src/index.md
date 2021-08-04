# Dualization.jl Documentation

Dualization.jl is a package written on top of MathOptInterface that allows users to write the dual of a JuMP model automatically.
This package has two main features: the `dualize` function, which enables users to get a dualized JuMP model, and the `DualOptimizer`, which enables users to solve a problem by providing the solver the dual of the problem. 

## Installation

To install the package you can use `Pkg.add` as follows:
```julia
pkg> add Dualization
```

## Contributing

Contributions to this package are more than welcome, if you find a bug or have any suggestions for the documentation please post it on the [github issue tracker](https://github.com/jump-dev/Dualization.jl/issues).

When contributing please note that the package follows the [JuMP style guide](https://jump.dev/JuMP.jl/stable/style/)
