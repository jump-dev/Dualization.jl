# Manual

## Supported problem types

Dualization.jl works only for optimization models that can be written in conic
form, and that are composed of the following constraints and objectives.

If you try to dualize an unsupported model, and error will be thrown.

### Constraints

| Function                   | Set                                    |
|:-------------------------- |:-------------------------------------- |
| `MOI.VariableIndex` or `MOI.ScalarAffineFunction` | `MOI.GreaterThan` |
| `MOI.VariableIndex` or `MOI.ScalarAffineFunction` | `MOI.LessThan`    |
| `MOI.VariableIndex` or `MOI.ScalarAffineFunction` | `MOI.EqualTo`     |
| `MOI.VectorOfVariables` or `MOI.VectorAffineFunction` | `MOI.Nonnegatives`                     |
| `MOI.VectorOfVariables` or `MOI.VectorAffineFunction` | `MOI.Nonpositives`                     |
| `MOI.VectorOfVariables` or `MOI.VectorAffineFunction` | `MOI.Zeros`                            |
| `MOI.VectorOfVariables` or `MOI.VectorAffineFunction` | `MOI.SecondOrderCone`                  |
| `MOI.VectorOfVariables` or `MOI.VectorAffineFunction` | `MOI.RotatedSecondOrderCone`           |
| `MOI.VectorOfVariables` or `MOI.VectorAffineFunction` | `MOI.PositiveSemidefiniteConeTriangle` |
| `MOI.VectorOfVariables` or `MOI.VectorAffineFunction` | `MOI.ExponentialCone`                  |
| `MOI.VectorOfVariables` or `MOI.VectorAffineFunction` | `MOI.DualExponentialCone`              |
| `MOI.VectorOfVariables` or `MOI.VectorAffineFunction` | `MOI.PowerCone`                        |
| `MOI.VectorOfVariables` or `MOI.VectorAffineFunction` | `MOI.DualPowerCone`                    |

Note that some of MOI constraints can be bridged, see [Bridges](http://jump.dev/MathOptInterface.jl/stable/apireference/#Bridges-1), to constraints in this list.

### Objective functions

| Function                      |
|:----------------------------- |
| `MOI.VariableIndex`           |
| `MOI.ScalarAffineFunction`    |
| `MOI.ScalarQuadraticFunction` |

## Dualize a model

## DualOptimizer

You can solve a primal problem by using its dual formulation using the `DualOptimizer`.

Solving an optimization problem via its dual representation can be useful because some conic solvers assume the model is in the standard form and others use the geometric form.

Geometric form has affine expressions in cones

```math
\begin{align}
& \min_{x \in \mathbb{R}^n} & c^T x
\\
& \;\;\text{s.t.} & A_i x + b_i & \in \mathcal{C}_i & i = 1 \ldots m
\end{align}
```

Standard form has variables in cones

```math
\begin{align}
& \min_{x \in \mathbb{R}^n} & c^T x
\\
& \;\;\text{s.t.} & A x + s & = b
\\
& & s & \in \mathcal{C}
\end{align}
```

|  Standard form | Geometric form |
|:-------:|:-------:|
| SDPT3 | CDCS |
| SDPNAL | SCS |
| CSDP | ECOS |
| SDPA | SeDuMi |
| Mosek v9 |

!!! note
    Mosek v10 now supports both affine constraints in cones and variables in
    cones hence both the standard and geometric form at the same time.

!!! note
    MOI standard form is the Geometric form and not the "textbook" Standard form.

## Adding new sets

Dualization.jl can automatically dualize models with custom sets.
To do this, the user needs to define the set and its dual set and provide the functions:

* `supported_constraint`
* `dual_set`

If the custom set has some special scalar product (see the [link](https://jump.dev/MathOptInterface.jl/stable/apireference/#MathOptInterface.AbstractSymmetricMatrixSetTriangle)), the user also needs
to provide a `set_dot` function.

For example, let us define a fake cone and its dual, the fake dual cone. We will write a JuMP model
with the fake cone and dualize it.

```julia
using Dualization, JuMP, MathOptInterface, LinearAlgebra

# Rename MathOptInterface to simplify the code
const MOI = MathOptInterface

# Define the custom cone and its dual
struct FakeCone <: MOI.AbstractVectorSet
    dimension::Int
end

struct FakeDualCone <: MOI.AbstractVectorSet
    dimension::Int
end

# Define a model with your FakeCone
model = Model()
@variable(model, x[1:3])
@constraint(model, con, x in FakeCone(3)) # Note that the constraint name is "con"
@objective(model, Min, sum(x))
```
The resulting JuMP model is

```math
\begin{align}
    & \min_{x} & x_1 + x_2 + x_3 &
    \\
    & \;\;\text{s.t.}
    &x \in FakeCone(3)\\
\end{align}
```

Now in order to dualize we must overload the methods as described above.

```julia
# Overload the methods dual_set and supported_constraints
Dualization.dual_set(s::FakeCone) = FakeDualCone(MOI.dimension(s))
Dualization.supported_constraint(::Type{MOI.VectorOfVariables}, ::Type{<:FakeCone}) = true

# If your set has some specific scalar product you also need to define a new set_dot function
# Our FakeCone has this weird scalar product
MOI.Utilities.set_dot(x::Vector, y::Vector, set::FakeCone) = 2dot(x, y)

# Dualize the model
dual_model = dualize(model)
```

The resulting dual model is

```math
\begin{align}
    & \max_{con} & 0 &
    \\
    & \;\;\text{s.t.}
    &2con_1 & = 1\\
    &&2con_2 & = 1\\
    &&2con_3 & = 1\\
    && con & \in FakeDualCone(3)\\
\end{align}
```

If the model has constraints that are `MOI.VectorAffineFunction`

```julia
model = Model()
@variable(model, x[1:3])
@constraint(model, con, x + 3 in FakeCone(3))
@objective(model, Min, sum(x))
```

```math
\begin{align}
    & \min_{x} & x_1 + x_2 + x_3 &
    \\
    & \;\;\text{s.t.}
    &[x_1 + 3, x_2 + 3, x_3 + 3] & \in FakeCone(3)\\
\end{align}
```

the user only needs to extend the `supported_constraints` function.

```julia
# Overload the supported_constraints for VectorAffineFunction
Dualization.supported_constraint(::Type{<:MOI.VectorAffineFunction}, ::Type{<:FakeCone}) = true

# Dualize the model
dual_model = dualize(model)
```

The resulting dual model is

```math
\begin{align}
    & \max_{con} & - 3con_1& - 3con_2 - 3con_3
    \\
    & \;\;\text{s.t.}
    &2con_1 & = 1\\
    &&2con_2 & = 1\\
    &&2con_3 & = 1\\
    && con & \in FakeDualCone(3)\\
\end{align}
```
