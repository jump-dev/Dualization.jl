# Examples

Here we discuss some useful examples of usage.

## Dualize a JuMP model

Let us dualize the following Second Order Cone program

```math
\begin{align}
    &  \min_{x, y, z} & y + z & \\
    & \;\;\text{s.t.} & x     & = 1 \\
    &                 &x      & \geq ||(y, z)||_2 \\
\end{align}
```

The corresponding code in JuMP is:

```@repl dualize_model
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

```@repl dualize_model
dual_model = dualize(model)
print(dual_model)
```

Note that if you declare the model with an optimizer attached you will lose the
optimizer during the dualization.

To dualize the model and attach the optimizer to the dual model you should do
`dualize(dual_model, SolverName.Optimizer)`

```@repl
using JuMP, Dualization, ECOS
model = Model(ECOS.Optimizer)
@variable(model, x)
@variable(model, y)
@variable(model, z)
@constraint(model, soccon, [x; y; z] in SecondOrderCone())
@constraint(model, eqcon, x == 1)
@objective(model, Min, y + z)
dual_model = dualize(model, ECOS.Optimizer)
```

## Naming the dual variables and dual constraints

You can provide prefixes for the name of the variables and the name of the
constraints using the a `DualNames` variable.

Every time you use the dualize function you can provide a `DualNames` as keyword
argument. Consider the following example.

You want to dualize this JuMP problem and add a prefix to the name of each
constraint to be more clear on what the variables represent. For instance you
want to put `"dual"` before the name of the constraint.

```@repl
using JuMP, Dualization
model = Model()
@variable(model, x)
@variable(model, y)
@variable(model, z)
@constraint(model, soccon, [x; y; z] in SecondOrderCone())
@constraint(model, eqcon, x == 1)
@objective(model, Min, y + z)
dual_model = dualize(model; dual_names = DualNames("dual", ""))
print(dual_model)
```

## Solving a problem using its dual formulation

Depending on the solver and on the type of formulation, solving the dual problem could be faster than solving the primal.
To solve the problem via its dual formulation can be done using the `DualOptimizer`.

Solving a problem the standard way:
```@repl
using JuMP, Dualization, ECOS
model = Model(ECOS.Optimizer)
@variable(model, x)
@variable(model, y)
@variable(model, z)
@constraint(model, soccon, [x; y; z] in SecondOrderCone())
@constraint(model, eqcon, x == 1)
@objective(model, Min, y + z)
optimize!(model)
```

Solving a problem by providing its dual representation:
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

You can pass arguments to the solver by attaching them to the solver constructor:
```@repl
using JuMP, Dualization, ECOS
model = Model(dual_optimizer(optimizer_with_attributes(ECOS.Optimizer, "maxit" => 5)))
@variable(model, x)
@variable(model, y)
@variable(model, z)
@constraint(model, soccon, [x; y; z] in SecondOrderCone())
@constraint(model, eqcon, x == 1)
@objective(model, Min, y + z)
optimize!(model)
```
