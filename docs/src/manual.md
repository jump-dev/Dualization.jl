# Manual

!!! note 

    This package only works for optimization models that can be written in the conic-form.

## Conic Duality

Conic duality is the starting point for MOI's duality conventions. When all functions are affine (or coordinate projections), and all constraint sets are closed convex cones, the model may be called a conic optimization problem.
For conic-form minimization problems, the primal is:

```math
\begin{align}
& \min_{x \in \mathbb{R}^n} & a_0^T x + b_0
\\
& \;\;\text{s.t.} & A_i x + b_i & \in \mathcal{C}_i & i = 1 \ldots m
\end{align}
```

and the dual is:

```math
\begin{align}
& \max_{y_1, \ldots, y_m} & -\sum_{i=1}^m b_i^T y_i + b_0
\\
& \;\;\text{s.t.} & a_0 - \sum_{i=1}^m A_i^T y_i & = 0
\\
& & y_i & \in \mathcal{C}_i^* & i = 1 \ldots m
\end{align}
```

where each ``\mathcal{C}_i`` is a closed convex cone and ``\mathcal{C}_i^*`` is its dual cone.

For conic-form maximization problems, the primal is:
```math
\begin{align}
& \max_{x \in \mathbb{R}^n} & a_0^T x + b_0
\\
& \;\;\text{s.t.} & A_i x + b_i & \in \mathcal{C}_i & i = 1 \ldots m
\end{align}
```

and the dual is:

```math
\begin{align}
& \min_{y_1, \ldots, y_m} & \sum_{i=1}^m b_i^T y_i + b_0
\\
& \;\;\text{s.t.} & a_0 + \sum_{i=1}^m A_i^T y_i & = 0
\\
& & y_i & \in \mathcal{C}_i^* & i = 1 \ldots m
\end{align}
```

A linear inequality constraint ``a^T x + b \ge c`` should be interpreted as ``a^T x + b - c \in \mathbb{R}_+``, and similarly ``a^T x + b \le c`` should be interpreted as ``a^T x + b - c \in \mathbb{R}_-``.
Variable-wise constraints should be interpreted as affine constraints with the appropriate identity mapping in place of ``A_i``.

For the special case of minimization LPs, the MOI primal form can be stated as
```math
\begin{align}
& \min_{x \in \mathbb{R}^n} & a_0^T x &+ b_0
\\
& \;\;\text{s.t.}
&A_1 x & \ge b_1\\
&& A_2 x & \le b_2\\
&& A_3 x & = b_3
\end{align}
```

By applying the stated transformations to conic form, taking the dual, and transforming back into linear inequality form, one obtains the following dual:

```math
\begin{align}
& \max_{y_1,y_2,y_3} & b_1^Ty_1 + b_2^Ty_2 + b_3^Ty_3 &+ b_0
\\
& \;\;\text{s.t.}
&A_1^Ty_1 + A_2^Ty_2 + A_3^Ty_3 & = a_0\\
&& y_1 &\ge 0\\
&& y_2 &\le 0
\end{align}
```

For maximization LPs, the MOI primal form can be stated as:
```math
\begin{align}
& \max_{x \in \mathbb{R}^n} & a_0^T x &+ b_0
\\
& \;\;\text{s.t.}
&A_1 x & \ge b_1\\
&& A_2 x & \le b_2\\
&& A_3 x & = b_3
\end{align}
```

and similarly, the dual is:
```math
\begin{align}
& \min_{y_1,y_2,y_3} & -b_1^Ty_1 - b_2^Ty_2 - b_3^Ty_3 &+ b_0
\\
& \;\;\text{s.t.}
&A_1^Ty_1 + A_2^Ty_2 + A_3^Ty_3 & = -a_0\\
&& y_1 &\ge 0\\
&& y_2 &\le 0
\end{align}
```

## Supported constraints

This is the list of supported `Function-in-Set` constraints of the package. If you try to dualize
a constraint not listed here, it will return an unsupported error.

|  MOI Function | MOI Set |
|:-------|:---------------|
|    `SingleVariable`    |    `GreaterThan`    |
|    `SingleVariable`    |    `LessThan`    |
|    `SingleVariable`    |    `EqualTo`    |
|    `ScalarAffineFunction`    |    `GreaterThan`    |
|    `ScalarAffineFunction`    |    `LessThan`    |
|    `ScalarAffineFunction`    |    `EqualTo`    |
|    `VectorOfVariables`    |    `Nonnegatives`    |
|    `VectorOfVariables`    |    `Nonpositives`    |
|    `VectorOfVariables`    |    `Zeros`    |
|    `VectorOfVariables`    |    `SecondOrderCone`    |
|    `VectorOfVariables`    |    `RotatedSecondOrderCone`    |
|    `VectorOfVariables`    |    `PositiveSemidefiniteConeTriangle`    |
|    `VectorOfVariables`    |    `ExponentialCone`    |
|    `VectorOfVariables`    |    `DualExponentialCone`    |
|    `VectorOfVariables`    |    `PowerCone`    |
|    `VectorOfVariables`    |    `DualPowerCone`    |
|    `VectorAffineFunction`    |    `Nonnegatives`    |
|    `VectorAffineFunction`    |    `Nonpositives`    |
|    `VectorAffineFunction`    |    `Zeros`    |
|    `VectorAffineFunction`    |    `SecondOrderCone`    |
|    `VectorAffineFunction`    |    `RotatedSecondOrderCone`    |
|    `VectorAffineFunction`    |    `PositiveSemidefiniteConeTriangle`    |
|    `VectorAffineFunction`    |    `ExponentialCone`    |
|    `VectorAffineFunction`    |    `DualExponentialCone`    |
|    `VectorAffineFunction`    |    `PowerCone`    |
|    `VectorAffineFunction`    |    `DualPowerCone`    |

Note that some of MOI constraints can be bridged, see [Bridges](http://www.juliaopt.org/MathOptInterface.jl/stable/apireference/#Bridges-1), to constraints in this list.

## Supported objective functions

|  MOI Function |
|:-------:|
|   `SingleVariable`   |
|   `ScalarAffineFunction`   |

## Dualize a model

```@docs
dualize
```

## DualOptimizer

You can solve a primal problem by using its dual formulation using the `DualOptimizer`.

```@docs
DualOptimizer
```

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
| Mosek |

## Adding new sets

Dualization.jl can automatically dualize models with custom sets.
To do this, the user needs to define the set and its dual set and provide the functions:

* `supported_constraint`
* `dual_set` 

If the custom set has some special scalar product (see the [link](https://www.juliaopt.org/MathOptInterface.jl/stable/apireference/#MathOptInterface.AbstractSymmetricMatrixSetTriangle)), the user also needs
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
