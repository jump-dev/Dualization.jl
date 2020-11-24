# Dualization.jl

| **Documentation** | **Build Status** | **Social** |
|:-----------------:|:----------------:|:----------:|
| [![][docs-stable-img]][docs-stable-url] [![][docs-dev-img]][docs-dev-url] | [![Build Status][build-img]][build-url] [![Codecov branch][codecov-img]][codecov-url] | [![Gitter][gitter-img]][gitter-url] [<img src="https://upload.wikimedia.org/wikipedia/commons/thumb/a/af/Discourse_logo.png/799px-Discourse_logo.png" width="64">][discourse-url] |

[docs-stable-img]: https://img.shields.io/badge/docs-stable-blue.svg
[docs-dev-img]: https://img.shields.io/badge/docs-dev-blue.svg
[docs-stable-url]: https://jump.dev/Dualization.jl/stable/
[docs-dev-url]: https://jump.dev/Dualization.jl/dev/

[build-img]: https://github.com/jump-dev/Dualization.jl/workflows/CI/badge.svg?branch=master
[build-url]: https://github.com/jump-dev/Dualization.jl/actions?query=workflow%3ACI
[codecov-img]: http://codecov.io/github/jump-dev/Dualization.jl/coverage.svg?branch=master
[codecov-url]: http://codecov.io/github/jump-dev/Dualization.jl?branch=master

[gitter-url]: https://gitter.im/AutomaticDualization/community#
[gitter-img]: https://badges.gitter.im/jump-dev/JuMP-dev.svg
[discourse-url]: https://discourse.julialang.org/c/domain/opt

Repository with implementations of the automatic dualization feature for MathOptInterface.jl conic optimization problems

Dualization.jl has two main features.
 * The function `dualize` that can dualize either a [`MathOptInterface.jl`](https://github.com/jump-dev/MathOptInterface.jl) or [`JuMP.jl`](https://github.com/jump-dev/JuMP.jl) model.

```julia
dual_model = dualize(model)
```

 * The `DualOptimizer` that will pass the dual representation of the model to the solver of your choice.

```julia
model = Model(dual_optimizer(SOLVER.Optimizer))
```

## Common use cases

### Solve problems via dual representation

This is specially useful for conic optimization because some solvers
can only represent specific formulation types. Dualizing the problem can leave
a problem closer to the form expected by the solver without adding
slack variables and constraints.

Solving an optimization problem via its dual representation can be useful because some conic solvers assume the model is in the standard form and others use the geometric form.

|  Standard form | Geometric form |
|:-------:|:-------:|
| SDPT3 | CDCS |
| SDPNAL | SCS |
| CSDP | ECOS |
| SDPA | SeDuMi |
| Mosek | MOI.FileFormats.SDPA |

For more informations please read the [documentation][docs-stable-url]

### Bilevel optimization

One classic method employed to solve bilevel optimization programs is to add the
KKT conditions of the second level problem to the upper level problem.
This package is used to obtain the dual feasibility constraint of the KKT conditions
in [`BilevelJuMP.jl`](https://github.com/joaquimg/BilevelJuMP.jl).
