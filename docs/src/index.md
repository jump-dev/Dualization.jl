# Dualization.jl Documentation

Dualization.jl is a package written on top of MathOptInterface that allows users to write the dual of a JuMP model automatically.
This package has two main features, the function dualize that enables users to get a dualized JuMP model and the DualOptimizer that
enables users to solve a problem providing the solver it's dual version. 

## Installation

This package is not yet registered so you can `Pkg.add` it as follows:
```julia
pkg> add https://github.com/guilhermebodin/Dualization.jl.git
```