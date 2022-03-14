# Manual

!!! note 

    This package only works for optimization models that can be written in the conic-form.

## Conic Duality

### MOI stardard form and duality

Conic duality is the starting point for MOI's duality conventions. When all functions are affine (or coordinate projections), and all constraint sets are closed convex cones, the model may be called a conic optimization problem.

The following formulations follow strictly MOI´s definition of duality we shall refer to them as *MOI stardard form*.

For minimization problems, the primal is:

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

For maximization problems, the primal is:
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

### MOI compact form and duality

An equivalent formulation for conic duality explicitly constrains variables into cones. The implicit version can be achieved with the above formulation (MOI standard form) by considering `A_i` that are projections onto some of the canonical axis.

The explicit constraints on variable convey additional strutuctural information that can be exploitex by some solver. Therefore MOI includes the method `add_constrained_variables` for such purpose. These constraints are special because they are created together with the corresponding constrained variables. Therefore each variable can only belong to one of such.

Next, we precisely define the *MOI compact form* and present their respective dual problems. The reader will notice that the models are more verbose than the MOI standard form, but actually the solvers receives fewer constraints and slack variables are avoided. Consequently, the dual will have fewer variables.

#### Minimization problem in MOI compact form

The primal is:

```math
\begin{align}
& \min_{x_1, \dots, x_n} & \sum_{j=1}^n a_j^T x_j + b_0
\\
& \;\;\text{s.t.} & \sum_{j=1}^n A_{ij} x_j + b_i & \in \mathcal{C}_i & i = 1 \ldots m
\\
& & x_j & \in \mathcal{V}_j & j = 1 \ldots n
\end{align}
```

and the dual is:

```math
\begin{align}
& \max_{y_1, \ldots, y_m} & -\sum_{i=1}^m b_i^T y_i + b_0
\\
& \;\;\text{s.t.} & - \sum_{i=1}^m A_{ij}^T y_i + a_j & \in \mathcal{V}_j^* & j = 1 \ldots n
\\
& & y_i & \in \mathcal{C}_i^* & i = 1 \ldots m
\end{align}
```
where each ``\mathcal{C}_i`` and ``\mathcal{V}_j`` are closed convex cones and ``\mathcal{C}_i^*`` and ``\mathcal{V}_j^*`` the respective dual cones.

#### Maximization problem in MOI compact form

The primal is:

```math
\begin{align}
& \max_{x_1, \dots, x_n} & \sum_{j=1}^n a_j^T x_j + b_0
\\
& \;\;\text{s.t.} & \sum_{j=1}^n A_{ij} x_j + b_i & \in \mathcal{C}_i & i = 1 \ldots m
\\
& & x_j & \in \mathcal{V}_j & j = 1 \ldots n
\end{align}
```

and the dual is:

```math
\begin{align}
& \min_{y_1, \ldots, y_m} & \sum_{i=1}^m b_i^T y_i + b_0
\\
& \;\;\text{s.t.} & - \sum_{i=1}^m A_{ij}^T y_i - a_j & \in \mathcal{V}_j^* & j = 1 \ldots n
\\
& & y_i & \in \mathcal{C}_i^* & i = 1 \ldots m
\end{align}
```

Note that signs changed in the constraints of the dual compared to the standard form. This is because the standard form would have negative signs in all terms in a equality constraint, which were inverted for simplicity. However, in the compact form, this operation is not allowed because it would change a nontrivial cone ``\mathcal{C}_i``.

##### Linear Programming

TODO

## Supported constraints

This is the list of supported `Function-in-Set` constraints of the package. If you try to dualize
a constraint not listed here, it will return an unsupported error.

|  MOI Function | MOI Set |
|:-------|:---------------|
|    `VariableIndex`    |    `GreaterThan`    |
|    `VariableIndex`    |    `LessThan`    |
|    `VariableIndex`    |    `EqualTo`    |
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

Note that some of MOI constraints can be bridged, see [Bridges](http://jump.dev/MathOptInterface.jl/stable/apireference/#Bridges-1), to constraints in this list.

## Supported objective functions

|  MOI Function |
|:-------:|
|   `VariableIndex`   |
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

## Advanced

### KKT Conditions

The KKT conditions are a set of inequalities for which the feasible solution is equivalent to the optimal solution of an optimization problem, as long as strong duality holds and constraint qualification rules such as Slater's are valid. The KKT is used in many branches of optimization and it might be interesting to write them programatically.

#### MOI standard form

The KKT conditions of the minimization problem of the first section are the following:

* Primal Feasibility:

```math
A_i x + b_i  \in \mathcal{C}_i , \ \ i = 1 \ldots m
```

* Dual Feasibility:

```math
y_i \in \mathcal{C}_i^*, \ \ i = 1 \ldots m
```

* Complementary slackness:

```math
y_i^T (A_i x + b_i) = 0, \ \ i = 1 \ldots m
```

* Stationarity:

```math
a_0 - \sum_{i=1}^m A_i^T y_i  = 0
```

Note that "Dual Feasibility" and "Stationarity" correspond to the two constraints of the dual problem. Therefore, after writing the primal problem, Dualization.jl can obtain the dual problem automatically and then we simply have to write the "Complementary slackness" to complete the KKT conditions.

One important use case is Bilevel optimization, see [BilevelJuMP.jl](https://github.com/joaquimg/BilevelJuMP.jl). In this case, variables of an upstream model are considered as parameters in a lower level model. One classical solution method for bilevel programs is to write the KKT conditions of the lower (or inner) problem and consider them as (non-linear) constraints of the upper (or outer) problem. Dualization can be used to derive parts of KKT conditions.

#### MOI compact form

* Primal Feasibility:

```math
\sum_{j=1}^n A_{ij} x_j + b_i \in \mathcal{C}_i , \ \ i = 1 \ldots m \\
x_j \in \mathcal{V}_j , \ \ j = 1 \ldots n
```

* Dual Feasibility:

```math
y_i \in \mathcal{C}_i^*, \ \ i = 1 \ldots m \\
u_j \in \mathcal{V}_j^*, \ \ j = 1 \ldots n
```

* Complementary slackness:

```math
y_i^T (\sum_{j=1}^n A_{ij} x_j + b_i) = 0, \ \ i = 1 \ldots m \\
u_j^T x_j = 0, \ \ j = 1 \ldots n
```

* Stationarity:

```math
 - \sum_{i=1}^m A_{ij}^T y_i + a_j = u_j, \ \ j = 1 \ldots n
```

### Parametric problems

It is also possible to deal with parametric models. In regular optimization problems we only have a single (vector) variable represented by ``x`` in the duality section, there are many use cases in which we can represent parameters that will not be considered in the optimization, these are treated as constants and, hence, not "dualized".

In the following, we will use ``x`` to denote primal optimization variables, ``y`` for dual optimization variables and ``z`` for parameters.

#### MOI standard form

##### Primal

```math
\begin{align}
& \min_{x \in \mathbb{R}^n} & a_0^T x + b_0 + d_0^Tz
\\
& \;\;\text{s.t.} & A_i x + b_i + D_i z & \in \mathcal{C}_i & i = 1 \ldots m
\end{align}
```

##### Dual

```math
\begin{align}
& \max_{y_1, \ldots, y_m} & -\sum_{i=1}^m (b_i + D_iz)^T y_i + b_0 + d_0^Tz
\\
& \;\;\; \text{s.t.} & a_0 - \sum_{i=1}^m A_i^T y_i & = 0
\\
& & y_i & \in \mathcal{C}_i^* & i = 1 \ldots m
\end{align}
```

##### KKT

* Primal Feasibility:

```math
A_i x + b_i + D_i z \in \mathcal{C}_i , \ \ i = 1 \ldots m
```

* Dual Feasibility:

```math
y_i \in \mathcal{C}_i^*, \ \ i = 1 \ldots m
```

* Complementary slackness:

```math
y_i^T (A_i x + b_i + D_i z) = 0, \ \ i = 1 \ldots m
```

* Stationarity:

```math
a_0 - \sum_{i=1}^m A_i^T y_i  = 0
```

#### MOI compact form

##### Primal

```math
\begin{align}
& \min_{x_1, \dots, x_n} & \sum_{j=1}^n a_j^T x_j + d^T z + b_0
\\
& \;\;\text{s.t.} & \sum_{j=1}^n A_{ij} x_j + D_i z + b_i & \in \mathcal{C}_i & i = 1 \ldots m
\\
& & x_j & \in \mathcal{V}_j & j = 1 \ldots n
\end{align}
```

##### Dual

```math
\begin{align}
& \max_{y_1, \ldots, y_m} & - \sum_{i=1}^m (D_i z + b_i)^T y_i + d^T z + b_0
\\
& \;\;\text{s.t.} & - \sum_{i=1}^m A_{ij}^T y_i + a_j & \in \mathcal{V}_j^* & j = 1 \ldots n
\\
& & y_i & \in \mathcal{C}_i^* & i = 1 \ldots m
\end{align}
```

##### KKT


* Primal Feasibility:

```math
\sum_{j=1}^n A_{ij} x_j + b_i + D_i z \in \mathcal{C}_i , \ \ i = 1 \ldots m \\
x_j \in \mathcal{V}_j , \ \ j = 1 \ldots n
```

* Dual Feasibility:

```math
y_i \in \mathcal{C}_i^*, \ \ i = 1 \ldots m \\
u_j \in \mathcal{V}_j^*, \ \ j = 1 \ldots n
```

* Complementary slackness:

```math
y_i^T (\sum_{j=1}^n A_{ij} x_j + b_i + D_i z) = 0, \ \ i = 1 \ldots m \\
u_j^T x_j = 0, \ \ j = 1 \ldots n
```

* Stationarity:

```math
- \sum_{i=1}^m A_{ij}^T y_i + a_j  = u_j, \ \ j = 1 \ldots n
```

### Quadratic problems

Optimization problems with conic constraints and quadratic objective are straightforward extensions to the conic problems with linear constraints usually defined in MOI. More information [here](http://www.seas.ucla.edu/~vandenbe/publications/coneprog.pdf).

#### MOI standard form

##### Primal

```math
\begin{align}
& \min_{x \in \mathbb{R}^n} & \frac{1}{2} x^T P x + a_0^T x + b_0
\\
& \;\;\text{s.t.} & A_i x + b_i & \in \mathcal{C}_i & i = 1 \ldots m
\end{align}
```

Where `P` is a positive semidefinite matrix.

##### Dual

A compact formulation for the dual problem requires pseudo-inverses, however, we can add an extra slack variable `w` to the dual problem and obtain the following dual problem:

```math
\begin{align}
& \max_{y_1, \ldots, y_m} & - \frac{1}{2} w^T P w - \sum_{i=1}^m b_i^T y_i + b_0
\\
& \;\;\text{s.t.} & a_0 - \sum_{i=1}^m A_i^T y_i + P w & = 0
\\
& & y_i & \in \mathcal{C}_i^* & i = 1 \ldots m
\end{align}
```

note that, in the constraint, the sign in front of the `P` matrix can be changed because `w` is free and the only other term depending in `w` is quadratic and symmetric.
The sign choice is interesting to keep the dual problem closer to the KKT conditions that reads as follows.

##### KKT

* Primal Feasibility:

```math
A_i x + b_i \in \mathcal{C}_i , \ \ i = 1 \ldots m
```

* Dual Feasibility:

```math
y_i \in \mathcal{C}_i^*, \ \ i = 1 \ldots m
```

* Complementary slackness:

```math
y_i^T (A_i x + b_i) = 0, \ \ i = 1 \ldots m
```

* Stationarity:

```math
P x + a_0 - \sum_{i=1}^m A_i^T y_i  = 0
```

#### MOI compact form

##### Primal

```math
\begin{align}
& \min_{x_1, \dots, x_n} &  \frac{1}{2} \sum_{k=1}^n\sum_{j=1}^n x_j^T P_{j,k} x_k + \sum_{j=1}^n a_j^T x_j + b_0
\\
& \;\;\text{s.t.} & \sum_{j=1}^n A_{ij} x_j + b_i & \in \mathcal{C}_i & i = 1 \ldots m
\\
& & x_j & \in \mathcal{V}_j & j = 1 \ldots n
\end{align}
```

##### Dual

```math
\begin{align}
& \max_{y_1, \ldots, y_m, w_1, \ldots, w_n} & - \frac{1}{2} \sum_{k=1}^n\sum_{j=1}^n w_j^T P_{j,k} w_k - \sum_{i=1}^m b_i^T y_i + b_0
\\
& \;\;\text{s.t.} & - \sum_{i=1}^m A_{ij}^T y_i + a_j & \in \mathcal{V}_j^* & j = 1 \ldots n
\\
& & y_i & \in \mathcal{C}_i^* & i = 1 \ldots m
\end{align}
```

##### KKT


* Primal Feasibility:

```math
\sum_{j=1}^n A_{ij} x_j + b_i \in \mathcal{C}_i , \ \ i = 1 \ldots m \\
x_j \in \mathcal{V}_j , \ \ j = 1 \ldots n
```

* Dual Feasibility:

```math
y_i \in \mathcal{C}_i^*, \ \ i = 1 \ldots m \\
u_j \in \mathcal{V}_j^*, \ \ j = 1 \ldots n
```

* Complementary slackness:

```math
y_i^T (\sum_{j=1}^n A_{ij} x_j + b_i) = 0, \ \ i = 1 \ldots m \\
u_j^T x_j = 0, \ \ j = 1 \ldots n
```

* Stationarity:

```math
\sum_{k=1}^n P_{j,k} x_k - \sum_{i=1}^m A_{ij}^T y_i + a_j = u_j, \ \ j = 1 \ldots n
```

### Parametric quadratic problems

#### MOI standard form

Just like the conic linear problems, these quadratic programs can be parametric.

##### Primal

```math
\begin{align}
& \min_{x \in \mathbb{R}^n} &  + \frac{1}{2} x^T P_1 x + x^T P_2 z + \frac{1}{2} z^T P_3 z
\\
& &  + a_0^T x + b_0 + d_0^T z \notag
\\
& \;\;\text{s.t.} & A_i x + b_i + D_i z & \in \mathcal{C}_i & i = 1 \ldots m
\end{align}
```

##### Dual

```math
\begin{align}
& \max_{y_1, \ldots, y_m} & - \frac{1}{2} w^T P_1 w + \frac{1}{2} z^T P_3 z 
\\
& & -\sum_{i=1}^m (b_i + D_i z)^T y_i + d_0^T z + b_0 \notag
\\
& \;\;\text{s.t.} & a_0 + P_2 z - \sum_{i=1}^m A_i^T y_i + P_1 w & = 0
\\
& & y_i & \in \mathcal{C}_i^* & i = 1 \ldots m
\end{align}
```

##### KKT


* Primal Feasibility:

```math
A_i x + b_i + D_i z \in \mathcal{C}_i , \ \ i = 1 \ldots m
```

* Dual Feasibility:

```math
y_i \in \mathcal{C}_i^*, \ \ i = 1 \ldots m
```

* Complementary slackness:

```math
y_i^T (A_i x + b_i + D_i z) = 0, \ \ i = 1 \ldots m
```

* Stationarity:

```math
P_1 x + P_2 z + a_0 - \sum_{i=1}^m A_i^T y_i  = 0
```


#### MOI compact form

##### Primal

```math
\begin{align}
& \min_{x_1, \dots, x_n} &  \frac{1}{2} \sum_{k=1}^n\sum_{j=1}^n x_j^T P_{j,k} x_k + \sum_{j=1}^n x_j^T P_{j,0} z \\
& & + \frac{1}{2} z^T P_{0,0} z + \sum_{j=1}^n a_j^T x_j + d^T z + b_0
\\
& \;\;\text{s.t.} & \sum_{j=1}^n A_{ij} x_j + D_i z + b_i & \in \mathcal{C}_i & i = 1 \ldots m
\\
& & x_j & \in \mathcal{V}_j & j = 1 \ldots n
\end{align}
```

##### Dual

```math
\begin{align}
& \max_{y_1, \ldots, y_m, w_1, \ldots, w_n} & - \frac{1}{2} \sum_{k=1}^n\sum_{j=1}^n w_j^T P_{j,k} w_k - \sum_{i=1}^m (D_i z + b_i)^T y_i\\
& & + \frac{1}{2} z^T P_{0,0} z + d^T z + b_0
\\
& \;\;\text{s.t.} & \sum_{k=1}^n P_{j,k} w_k - \sum_{i=1}^m A_{ij}^T y_i + a_j + P_{j,0} z & \in \mathcal{V}_j^* & j = 1 \ldots n
\\
& & y_i & \in \mathcal{C}_i^* & i = 1 \ldots m
\end{align}
```

##### KKT


* Primal Feasibility:

```math
\sum_{j=1}^n A_{ij} x_j + b_i + D_i z \in \mathcal{C}_i , \ \ i = 1 \ldots m \\
x_j \in \mathcal{V}_j , \ \ j = 1 \ldots n
```

* Dual Feasibility:

```math
y_i \in \mathcal{C}_i^*, \ \ i = 1 \ldots m \\
u_j \in \mathcal{V}_j^*, \ \ j = 1 \ldots n
```

* Complementary slackness:

```math
y_i^T (\sum_{j=1}^n A_{ij} x_j + b_i + D_i z) = 0, \ \ i = 1 \ldots m \\
u_j^T x_j = 0, \ \ j = 1 \ldots n
```

* Stationarity:

```math
\sum_{k=1}^n P_{j,k} x_k - \sum_{i=1}^m A_{ij}^T y_i + a_j + P_{j,0} z  = u_j, \ \ j = 1 \ldots n
```