```@meta
CurrentModule = Dualization
```

# API Reference

This page lists the public API of `Dualization`.

!!! info
    This page is an unstructured list of the Dualization API. For a more
    structured overview, read the Manual or Tutorial parts of this
    documentation.

Load all of the public the API into the current scope with:
```julia
using Dualization
```
Alternatively, load only the module with:
```julia
import Dualization
```
and then prefix all calls with `Dualization.` to create `Dualization.<NAME>`.

## `dualize`
```@docs
dualize
```

## `dual_optimizer`
```@docs
dual_optimizer
```

## `DualOptimizer`
```@docs
DualOptimizer
```

## `DualNames`
```@docs
DualNames
```

## `Dualization.supported_constraints`
```@docs
Dualization.supported_constraints
```

## `Dualization.supported_objective`
```@docs
Dualization.supported_objective
```

## `Dualization.PrimalVariableData`
```@docs
Dualization.PrimalVariableData
```

## `Dualization.PrimalConstraintData`
```@docs
Dualization.PrimalConstraintData
```

## `Dualization.PrimalDualMap`
```@docs
Dualization.PrimalDualMap
```
