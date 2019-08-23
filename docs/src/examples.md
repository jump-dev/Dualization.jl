# Examples 

Here we discuss some useful examples of usage.

## Dualize a JuMP model

Let us dualize the following Second Order Cone program

```math
\begin{align}
    & \min_{x, y, z} & y + z &
    \\
    & \;\;\text{s.t.}
    &x & = 1\\
    && x & = 1\\
    &&x & \geq ||(y,z)||_2\\
\end{align}
```

The corresponding code in JuMP is

```julia
using JuMP, Dualization
model = Model()
@variable(model, x)
@variable(model, y)
@variable(model, z)
@constraint(model, soccon, [x; y; z] in SecondOrderCone())
@constraint(model, eqcon, x == 1)
@objective(model, Min, y + z)
```
You can dualize the model by doing

```julia
dual_model = dualize(model)
```
And you should get the model

```math
\begin{align}
    & \max_{eqcon, soccon} & eqcon &
    \\
    & \;\;\text{s.t.}
    &eqcon + soccon_1 & = 0\\
    && soccon_2 & = 1\\
    && soccon_3 & = 1\\
    &&soccon_1 & \geq ||(soccon_2,soccon_3)||_2\\
\end{align}
```

Note that if you declare the model with an optimizer attached you will lose the optimizer during the dualization. 
To dualize the model and attach the optimizer to the dual model you should do `dualize(dual_model; with_optimizer(...))`

```julia
using JuMP, Dualization, ECOS
model = Model(with_optimizer(ECOS.Optimizer))
@variable(model, x)
@variable(model, y)
@variable(model, z)
@constraint(model, soccon, [x; y; z] in SecondOrderCone())
@constraint(model, eqcon, x == 1)
@objective(model, Min, y + z)

dual_model = dualize(model, with_optimizer(ECOS.Optimizer))
```

## Naming the dual variables and dual constraints

You can provide prefixes for the name of the variables and the name of the constraints using the a `DualNames` variable.
Everytime you use the dualize function you can provide a `DualNames` as keyword argument. Consider the following example.

You want to dualize this JuMP problem and add a prefix to the name of each constraint to be more clear on what the variables 
represent. For instance you want to put `"dual"` before the name of the constraint.

```julia
using JuMP, Dualization
model = Model()
@variable(model, x)
@variable(model, y)
@variable(model, z)
@constraint(model, soccon, [x; y; z] in SecondOrderCone())
@constraint(model, eqcon, x == 1)
@objective(model, Min, y + z)

# The first field of DualNames is the prefix of the dual variables
# and the second field is the prefix of the dual constraint
dual_model = dualize(model; dual_names = DualNames("dual", ""))
```

The dual_model will be registered as 

```math
\begin{align}
    & \max_{dualeqcon, dualsoccon} & dualeqcon &
    \\
    & \;\;\text{s.t.}
    &dualeqcon + dualsoccon_1 & = 0\\
    && dualsoccon_2 & = 1\\
    && dualsoccon_3 & = 1\\
    &&dualsoccon_1 & \geq ||(dualsoccon_2, dualsoccon_3)||_2\\
\end{align}
```


## Solving a problem using its dual formulation

Depending on the solver and on the type of formulation, solving the dual problem could be faster than solving the primal.
To solve the problem via its dual formulation can be done using the `DualOptimizer`.

```julia
using JuMP, Dualization, ECOS

# Solving a problem the standard way
model = Model(with_optimizer(ECOS.Optimizer))
@variable(model, x)
@variable(model, y)
@variable(model, z)
@constraint(model, soccon, [x; y; z] in SecondOrderCone())
@constraint(model, eqcon, x == 1)
@objective(model, Min, y + z)

# Solving a problem by providing its dual representation
model = Model(with_optimizer(DualOptimizer, ECOS.Optimizer()))
@variable(model, x)
@variable(model, y)
@variable(model, z)
@constraint(model, soccon, [x; y; z] in SecondOrderCone())
@constraint(model, eqcon, x == 1)
@objective(model, Min, y + z)

# You can pass arguments to the solver by putting them as arguments inside the solver `Optimizer`
model = Model(with_optimizer(DualOptimizer, ECOS.Optimizer(maxit = 5)))
@variable(model, x)
@variable(model, y)
@variable(model, z)
@constraint(model, soccon, [x; y; z] in SecondOrderCone())
@constraint(model, eqcon, x == 1)
@objective(model, Min, y + z)
```
