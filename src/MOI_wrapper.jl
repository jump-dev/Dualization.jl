# Copyright (c) 2017: Guilherme Bodin, and contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

"""
    dual_optimizer(
        optimizer_constructor;
        coefficient_type::Type{T} = Float64,
        kwargs...,
    ) where {T<:Number}

A user-friendly constructor for [`DualOptimizer`](@ref) that can be passed
directly to the JuMP `Model` constructor.

## Example

```julia
julia> using Dualization, JuMP, HiGHS

julia> model = Model(dual_optimizer(HiGHS.Optimizer))
A JuMP Model
Feasibility problem with:
Variables: 0
Model mode: AUTOMATIC
CachingOptimizer state: EMPTY_OPTIMIZER
Solver name: Dual model with HiGHS attached
```
"""
function dual_optimizer(
    optimizer_constructor;
    coefficient_type::Type{T} = Float64,
    kwargs...,
) where {T<:Number}
    return () ->
        DualOptimizer{T}(MOI.instantiate(optimizer_constructor); kwargs...)
end

struct DualOptimizer{T,OT<:MOI.ModelLike} <: MOI.AbstractOptimizer
    dual_problem::DualProblem{T,OT}
    assume_min_if_feasibility::Bool

    function DualOptimizer{T,OT}(
        dual_problem::DualProblem{T,OT};
        assume_min_if_feasibility::Bool = false,
    ) where {T,OT<:MOI.ModelLike}
        return new{T,OT}(dual_problem, assume_min_if_feasibility)
    end
end

"""
    DualOptimizer(dual_optimizer::OT) where {OT <: MOI.ModelLike}

The DualOptimizer finds the solution for a problem by solving its dual
representation. It builds the dual model internally and solve it using the
`dual_optimizer` as the solver.

Primal results are obtained by querying dual results of the internal problem
solved by `dual_optimizer`. Analogously, dual results are obtained by querying
primal results of the internal problem.

The user can define the model providing the `DualOptimizer` and the solver of
its choice.

## Example

```julia
julia> using Dualization, JuMP, HiGHS

julia> model = Model(dual_optimizer(HiGHS.Optimizer))
A JuMP Model
Feasibility problem with:
Variables: 0
Model mode: AUTOMATIC
CachingOptimizer state: EMPTY_OPTIMIZER
Solver name: Dual model with HiGHS attached
```
"""
function DualOptimizer(dual_optimizer::OT; kwargs...) where {OT<:MOI.ModelLike}
    return DualOptimizer{Float64}(dual_optimizer; kwargs...)
end

function DualOptimizer{T}(
    dual_optimizer::OT;
    kwargs...,
) where {T,OT<:MOI.ModelLike}
    dual_problem = DualProblem{T}(
        MOI.Bridges.full_bridge_optimizer(
            MOI.Utilities.CachingOptimizer(
                MOI.Utilities.UniversalFallback(MOI.Utilities.Model{T}()),
                dual_optimizer,
            ),
            T,
        ),
    )
    # discover the type of
    # MOI.Utilities.CachingOptimizer(MOI.Utilities.Model{T}(), dual_optimizer)
    OptimizerType = typeof(dual_problem.dual_model)
    return DualOptimizer{T,OptimizerType}(dual_problem; kwargs...)
end

DualOptimizer() = error("DualOptimizer must have a solver attached")

MOI.supports(::DualOptimizer, ::MOI.ObjectiveSense) = true

function MOI.supports(
    optimizer::DualOptimizer{T},
    ::MOI.ObjectiveFunction{F},
) where {T,F}
    # If the objective function is `MOI.VariableIndex` or
    # `MOI.ScalarAffineFunction`, then a `MOI.ScalarAffineFunction` is set as
    # the objective function for the dual problem.
    # If it is `MOI.ScalarQuadraticFunction` , a `MOI.ScalarQuadraticFunction`
    # is set as objective function for the dual problem.
    attr = if F <: MOI.ScalarQuadraticFunction
        MOI.ObjectiveFunction{MOI.ScalarQuadraticFunction{T}}()
    else
        MOI.ObjectiveFunction{MOI.ScalarAffineFunction{T}}()
    end
    return supported_objective(F) &&
           MOI.supports(optimizer.dual_problem.dual_model, attr)
end

function MOI.supports_constraint(
    optimizer::DualOptimizer{T},
    ::Type{<:Union{MOI.VariableIndex,MOI.ScalarAffineFunction{T}}},
    S::Type{<:MOI.AbstractScalarSet},
) where {T}
    D = _dual_set_type(S)
    if D === nothing
        return false
    end
    model = optimizer.dual_problem.dual_model
    if D <: MOI.AbstractVectorSet # The dual of `EqualTo` is `Reals`
        return MOI.supports_add_constrained_variables(model, D)
    else
        return MOI.supports_add_constrained_variable(model, D)
    end
end

function MOI.supports_constraint(
    optimizer::DualOptimizer{T},
    ::Type{<:Union{MOI.VectorOfVariables,MOI.VectorAffineFunction{T}}},
    S::Type{<:MOI.AbstractVectorSet},
) where {T}
    D = _dual_set_type(S)
    if D === nothing
        return false
    end
    model = optimizer.dual_problem.dual_model
    return MOI.supports_add_constrained_variables(model, D)
end

function _change_constant(
    model,
    ci::MOI.ConstraintIndex{<:MOI.ScalarAffineFunction,S},
    constant,
    ::Int,
) where {S}
    MOI.set(model, MOI.ConstraintSet(), ci, S(constant))
    return
end

function _change_constant(
    model,
    ci::MOI.ConstraintIndex{<:MOI.VectorAffineFunction},
    constant,
    idx::Int,
)
    func = MOI.get(model, MOI.ConstraintFunction(), ci)
    constants = copy(func.constant)
    constants[idx] = -constant
    MOI.modify(model, ci, MOI.VectorConstantChange(constants))
    return
end

function MOI.modify(
    optimizer::DualOptimizer{T},
    ::MOI.ObjectiveFunction{MOI.ScalarAffineFunction{T}},
    obj_change::MOI.ScalarCoefficientChange{T},
) where {T}
    primal_dual_map = optimizer.dual_problem.primal_dual_map
    # We must find the constraint corresponding to the variable in the objective
    # function and change its coefficient on the constraint.
    constant = obj_change.new_coefficient
    if MOI.get(optimizer.dual_problem.dual_model, MOI.ObjectiveSense()) ==
       MOI.MIN_SENSE
        constant = -constant
    end
    vi = obj_change.variable
    data = get(primal_dual_map.primal_variable_data, vi, nothing)
    if data === nothing
        # error
    elseif data.dual_constraint === nothing
        return
    elseif data.primal_constrained_variable_constraint !== nothing
        constant = -constant
    end
    _change_constant(
        optimizer.dual_problem.dual_model,
        data.dual_constraint,
        constant,
        data.primal_constrained_variable_index,
    )
    return
end

function MOI.supports_add_constrained_variables(
    optimizer::DualOptimizer{T},
    ::Type{MOI.Reals},
) where {T}
    return MOI.supports_constraint(
        optimizer.dual_problem.dual_model,
        MOI.ScalarAffineFunction{T},
        MOI.EqualTo{T},
    )
    # If `_dual_set_type(MOI.Reals)` was `MOI.Zeros`,
    # we would not need this method as special case of the one below
end

function MOI.supports_add_constrained_variables(
    optimizer::DualOptimizer{T},
    S::Type{<:MOI.AbstractVectorSet},
) where {T}
    D = _dual_set_type(S)
    if D === nothing
        return false
    end
    return MOI.supports_constraint(
        optimizer.dual_problem.dual_model,
        MOI.VectorAffineFunction{T},
        D,
    )
end

function MOI.copy_to(dest::DualOptimizer, src::MOI.ModelLike)
    MOI.empty!(dest)
    dualize(
        src,
        dest.dual_problem,
        assume_min_if_feasibility = dest.assume_min_if_feasibility,
    )
    # Copy attributes except names which have already been passed in `dualize`
    primal_without_names = MOI.Utilities.ModelFilter(src) do attr
        return !(attr isa Union{MOI.VariableName,MOI.ConstraintName})
    end
    index_map = MOI.Utilities.identity_index_map(src)
    vis = MOI.get(src, MOI.ListOfVariableIndices())
    MOI.Utilities.pass_attributes(
        dest,
        primal_without_names,
        index_map,
        vis,
    )
    for (F, S) in MOI.get(src, MOI.ListOfConstraintTypesPresent())
        cis = MOI.get(src, MOI.ListOfConstraintIndices{F,S}())
        MOI.Utilities.pass_attributes(
            dest,
            primal_without_names,
            index_map,
            cis,
        )
    end
    return index_map
end

function MOI.optimize!(optimizer::DualOptimizer)
    return MOI.optimize!(optimizer.dual_problem.dual_model)
end

function MOI.is_empty(optimizer::DualOptimizer)
    return (MOI.is_empty(optimizer.dual_problem.dual_model)) &&
           is_empty(optimizer.dual_problem.primal_dual_map)
end

function MOI.empty!(optimizer::DualOptimizer)
    MOI.empty!(optimizer.dual_problem.dual_model)
    empty!(optimizer.dual_problem.primal_dual_map)
    return
end

function MOI.get(optimizer::DualOptimizer, ::MOI.SolverName)
    name = MOI.get(optimizer.dual_problem.dual_model, MOI.SolverName())
    return "Dual model with $name attached"
end
