# Dualization.jl Documentation

Dualization.jl is a package written on top of MathOptInterface that allows users to write the dual of a JuMP model automatically.
This package has two main features: the `dualize` function, which enables users to get a dualized JuMP model, and the `DualOptimizer`, which enables users to solve a problem by providing the solver the dual of the problem. 

## Installation

This package is not yet registered so you can `Pkg.add` it as follows:
```julia
pkg> add https://github.com/guilhermebodin/Dualization.jl.git
```
