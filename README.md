# Dualization.jl
Repository with first implementations of the automatic dualization feature for MathOptInterface.jl

## First Approach

The first approach will be to define small MOI problems and try to dualize them.

This package will export only one function called `dualize` that receives a JuMP Model and returns its dual

The first step will be to create an empty model and then treat constraints separately, there will be a loop for each constraint of the problem, this means each couple {F, S} (Fucntion, Set). The following constraints will be ignored

* `{SingleVariable, Interval}` (I think we need to bridge and then dualize this one)
* `{ScalarQuadraticFunction, GreaterThan}`
* `{ScalarQuadraticFunction, LessThan}`
* `{ScalarQuadraticFunction, EqualTo}`
* `{VectorQuadraticFunction, PositiveSemidefiniteCone}`
* `{SingleVariable, Integer}`
* `{SingleVariable, ZeroOne}`
* `{SingleVariable, Semicontinuous}`
* `{SingleVariable, Semiinteger}`
* `{VectorOfVariables, SOS1}`
* `{VectorOfVariables, SOS2}`

Each type of constraint should have its own file `.jl`. For example `SAF_LessThan.jl` for `ScalarAffineFunction` MOI function in `LessThan` MOI set. In this file there should be a function that receives the constraint and the created model so it can fill the new model with the dual representation.

