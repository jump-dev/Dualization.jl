# Manual

## Dualize a JuMP model

Use [`dualize`](@ref) to formulat the dual of a JuMP model.

For example, consider this problem:

```@repl dualize_model
using JuMP, Dualization
begin
    model = Model()
    @variable(model, x)
    @variable(model, y >= 0)
    @variable(model, z)
    @constraint(model, soccon, [1.0 * x + 2.0, y, z] in SecondOrderCone())
    @constraint(model, eqcon, x == 1)
    @constraint(model, con_le, x + y >= 1)
    @objective(model, Min, y + z)
    print(model)
end
```
You can dualize the model by doing

```@repl dualize_model
dual_model = dualize(model)
print(dual_model)
```

Note that if you declare the model with an optimizer attached you will lose the
optimizer during the dualization. To dualize the model and attach the optimizer
to the dual model you should do `dualize(model, optimizer)`

```@repl dualize_model
using ECOS
dual_model = dualize(model, ECOS.Optimizer)
```

## Name the dual variables and dual constraints

Provide prefixes for the names of the variables and constraints using
[`DualNames`](@ref).

```@repl dualize_model
dual_model = dualize(model; dual_names = DualNames("dual_var_", "dual_con_"))
print(dual_model)
```

## Solve a problem using its dual formulation

Wrap an optimizer with [`dual_optimizer`](@ref) to solve the dual of the problem
instead of the primal:
```@repl
using JuMP, Dualization, ECOS
model = Model(dual_optimizer(ECOS.Optimizer))
@variable(model, x)
@variable(model, y)
@variable(model, z)
@constraint(model, soccon, [x; y; z] in SecondOrderCone())
@constraint(model, eqcon, x == 1)
@objective(model, Min, y + z)
optimize!(model)
```

Pass arguments to the solver by attaching them to the solver constructor:
```@repl
using JuMP, Dualization, ECOS
model = Model(dual_optimizer(optimizer_with_attributes(ECOS.Optimizer, "maxit" => 5)))
```
or by using `JuMP.set_attribute`:
```@repl
using JuMP, Dualization, ECOS
model = Model(dual_optimizer(ECOS.Optimizer))
set_attribute(model, "maxit", 5)
```

## The benefit of solving the dual formulation

Solving an optimization problem via its dual representation can be useful
because some conic solvers assume the model is in the standard form and others
use the geometric form.

The geometric conic form has affine expressions in cones:

```math
\begin{align}
& \min_{x \in \mathbb{R}^n} & c^T x
\\
& \;\;\text{s.t.} & A_i x + b_i & \in \mathcal{C}_i & i = 1 \ldots m
\end{align}
```

The standard form has variables in cones:

```math
\begin{align}
& \min_{x \in \mathbb{R}^n} & c^T x
\\
& \;\;\text{s.t.} & A x + s & = b
\\
& & s & \in \mathcal{C}
\end{align}
```

Solvers which use the geometric conic form include CDCS, SCS, ECOS, and SeDuMi.
Solvers which use the standard conic form include SDPT3, SDPNAL, CSDP, and SDPA.
Mosek v10 supports both affine constraints in cones and variables in cones,
hence both the standard and geometric form at the same time.

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
