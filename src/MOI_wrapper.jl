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
    S::Type{MOI.Reals},
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
    dualize(
        src,
        dest.dual_problem,
        assume_min_if_feasibility = dest.assume_min_if_feasibility,
    )
    idx_map = MOI.Utilities.IndexMap()
    vis_src = MOI.get(src, MOI.ListOfVariableIndices())
    for vi in vis_src
        setindex!(idx_map, vi, vi)
    end
    MOI.Utilities.pass_attributes(dest, src, idx_map, vis_src)
    for (F, S) in MOI.get(src, MOI.ListOfConstraintTypesPresent())
        for con in MOI.get(src, MOI.ListOfConstraintIndices{F,S}())
            setindex!(idx_map, con, con)
        end
    end
    return idx_map
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

_minus(::Nothing) = nothing
_minus(x) = -x

function constraint_attribute(attr::MOI.VariablePrimal)
    return MOI.ConstraintPrimal(attr.result_index)
end
function constraint_attribute(attr::MOI.VariablePrimalStart)
    return MOI.ConstraintPrimalStart()
end

struct DualModelAttributeNotDefined <: MOI.AbstractModelAttribute end
struct DualVariableAttributeNotDefined <: MOI.AbstractVariableAttribute end
struct DualConstraintAttributeNotDefined <: MOI.AbstractConstraintAttribute end

dual_attribute(::MOI.AbstractModelAttribute) = DualModelAttributeNotDefined()
function dual_attribute(::MOI.AbstractVariableAttribute)
    return DualConstraintAttributeNotDefined()
end
function dual_attribute(::MOI.AbstractConstraintAttribute)
    return DualVariableAttributeNotDefined()
end

dual_attribute(attr::MOI.ResultCount) = attr

function dual_attribute(attr::Union{MOI.VariablePrimal,MOI.ConstraintPrimal})
    return MOI.ConstraintDual(attr.result_index)
end

function dual_attribute(
    ::Union{MOI.VariablePrimalStart,MOI.ConstraintPrimalStart},
)
    return MOI.ConstraintDualStart()
end

function dual_attribute_value(
    ::Union{MOI.VariablePrimal,MOI.VariablePrimalStart},
    value,
)
    return _minus(value)
end

function dual_attribute_value(
    ::Union{MOI.ConstraintPrimal,MOI.ConstraintPrimalStart},
    value,
)
    return value
end

function dual_attribute(attr::MOI.ConstraintDual)
    return MOI.ConstraintPrimal(attr.result_index)
end

function dual_attribute(::MOI.ConstraintDualStart)
    return MOI.ConstraintPrimalStart()
end

function _variable_dual_attribute(attr::MOI.ConstraintDual)
    return MOI.VariablePrimal(attr.result_index)
end

function _variable_dual_attribute(::MOI.ConstraintDualStart)
    return MOI.VariablePrimalStart()
end

# The inner optimizer may not support equality constraints (e.g. MOI.FileFormats.SDPA.Model)
# In this case, if all variables are created using constrained variables then dualization won't
# have to create any equality constraints so it will work.
# In that case, we have two choices:
# 1) say we don't support `MOI.VariablePrimalStart` and ignore them, rely on the value set to
#    `MOI.ConstraintPrimalStart` to the constraint associated to the constrained variables
# 2) use the value in `MOI.VariablePrimalStart` as fallback in case `MOI.ConstraintPrimalStart`
#    is not set
# The issue with option 2) is that it is difficult to know what type of constraints we should use
# in `MOI.supports` here so we should basically just return `true`.
# But if we `return true` and the solver don't support starting values then it will error, and we
# don't benefit from the silent ignoring of starting values relying on
# https://github.com/jump-dev/MathOptInterface.jl/blob/9884cfacb044724427a7d6c7a21f4bd6ff5a8c15/src/Utilities/copy.jl#L73-L74
# So let's go for option 1) for now
function MOI.supports(
    optimizer::DualOptimizer{T},
    attr::MOI.AbstractVariableAttribute,
    ::Type{MOI.VariableIndex},
) where {T}
    return MOI.supports(
        optimizer.dual_problem.dual_model,
        dual_attribute(attr),
        MOI.ConstraintIndex{MOI.ScalarAffineFunction{T},MOI.EqualTo{T}},
    )
end

function MOI.set(
    optimizer::DualOptimizer,
    attr::MOI.AbstractVariableAttribute,
    vi::MOI.VariableIndex,
    value,
)
    primal_dual_map = optimizer.dual_problem.primal_dual_map
    if vi in keys(primal_dual_map.constrained_var_idx)
        msg = "Setting starting value for variables constrained at creation is not supported yet"
        throw(MOI.SetAttributeNotAllowed(attr, msg))
    end
    MOI.set(
        optimizer.dual_problem.dual_model,
        dual_attribute(attr),
        get_ci_dual_problem(optimizer, vi),
        dual_attribute_value(attr, value),
    )
    return
end

function MOI.get(
    optimizer::DualOptimizer{T},
    attr::MOI.AbstractVariableAttribute,
    vi::MOI.VariableIndex,
)::T where {T}
    primal_dual_map = optimizer.dual_problem.primal_dual_map
    data = get(primal_dual_map.primal_variable_data, vi, nothing)
    if data === nothing
        # error
    elseif data.dual_constraint === nothing
        return zero(T)
    elseif data.primal_constrained_variable_constraint === nothing
        return dual_attribute_value(
            attr,
            MOI.get(
                optimizer.dual_problem.dual_model,
                dual_attribute(attr),
                data.dual_constraint,
            ),
        )
    end
    con_attr = constraint_attribute(attr)
    value = dual_attribute_value(
        con_attr,
        MOI.get(
            optimizer.dual_problem.dual_model,
            dual_attribute(con_attr),
            data.dual_constraint,
        ),
    )
    if data.dual_constraint isa
       MOI.ConstraintIndex{<:MOI.AbstractVectorFunction}
        return value[data.primal_constrained_variable_index]
    else
        return value
    end
end

function MOI.supports(
    optimizer::DualOptimizer,
    attr::MOI.AbstractConstraintAttribute,
    ::Type{<:MOI.ConstraintIndex},
)
    return MOI.supports(
        optimizer.dual_problem.dual_model,
        _variable_dual_attribute(attr),
        MOI.VariableIndex,
    )
end

function MOI.set(
    optimizer::DualOptimizer,
    attr::MOI.ConstraintDualStart,
    ci::MOI.ConstraintIndex,
    value,
)
    primal_dual_map = optimizer.dual_problem.primal_dual_map
    if ci in keys(primal_dual_map.primal_constrained_variables)
        msg = "Setting starting value for variables constrained at creation is not supported yet"
        throw(MOI.SetAttributeNotAllowed(attr, msg))
    end
    MOI.set(
        optimizer.dual_problem.dual_model,
        _variable_dual_attribute(attr),
        primal_dual_map.primal_constraint_data[ci].dual_variables[],
        value,
    )
    return
end

function MOI.get(
    optimizer::DualOptimizer,
    attr::Union{MOI.ConstraintDual,MOI.ConstraintDualStart},
    ci::MOI.ConstraintIndex{F,S},
) where {F<:MOI.AbstractScalarFunction,S<:MOI.AbstractScalarSet}
    primal_dual_map = optimizer.dual_problem.primal_dual_map
    if haskey(primal_dual_map.primal_constrained_variables, ci)
        vi = primal_dual_map.primal_constrained_variables[ci][]
        ci_dual = primal_dual_map.primal_variable_data[vi].dual_constraint
        if ci_dual === nothing
            return MOI.Utilities.eval_variables(
                primal_dual_map.primal_variable_data[vi].dual_function,
            ) do inner_vi
                return MOI.get(
                    optimizer.dual_problem.dual_model,
                    _variable_dual_attribute(attr),
                    inner_vi,
                )
            end
        end
        set = MOI.get(
            optimizer.dual_problem.dual_model,
            MOI.ConstraintSet(),
            ci_dual,
        )
        return MOI.get(
            optimizer.dual_problem.dual_model,
            dual_attribute(attr),
            ci_dual,
        ) - MOI.constant(set)
    else
        data = primal_dual_map.primal_constraint_data[ci]
        ci_dual = data.dual_constrained_variable_constraint
        if ci_dual === nothing
            # TODO do something else not relying on `_variable_dual_attribute`
            return MOI.get(
                optimizer.dual_problem.dual_model,
                _variable_dual_attribute(attr),
                primal_dual_map.primal_constraint_data[ci].dual_variables[],
            )
        end
        return MOI.get(
            optimizer.dual_problem.dual_model,
            dual_attribute(attr),
            ci_dual,
        )
    end
end

function MOI.get(
    optimizer::DualOptimizer,
    attr::Union{MOI.ConstraintDual,MOI.ConstraintDualStart},
    ci::MOI.ConstraintIndex{F,S},
) where {F<:MOI.AbstractVectorFunction,S<:MOI.AbstractVectorSet}
    primal_dual_map = optimizer.dual_problem.primal_dual_map
    if !haskey(primal_dual_map.primal_constraint_data, ci)
        vis = primal_dual_map.primal_constrained_variables[ci]
        ci_dual = primal_dual_map.primal_variable_data[vis[1]].dual_constraint
        if ci_dual === nothing
            return [
                MOI.Utilities.eval_variables(
                    primal_dual_map.primal_variable_data[vi].dual_function,
                ) do inner_vi
                    return MOI.get(
                        optimizer.dual_problem.dual_model,
                        _variable_dual_attribute(attr),
                        inner_vi,
                    )
                end for vi in vis
            ]
        end
        return MOI.get(
            optimizer.dual_problem.dual_model,
            dual_attribute(attr),
            ci_dual,
        )
    else
        data = primal_dual_map.primal_constraint_data[ci]
        ci_dual = data.dual_constrained_variable_constraint
        if ci_dual === nothing
            # TODO do something else not relying on `_variable_dual_attribute`
            return MOI.get.(
                optimizer.dual_problem.dual_model,
                _variable_dual_attribute(attr),
                primal_dual_map.primal_constraint_data[ci].dual_variables,
            )
        end
        return MOI.get(
            optimizer.dual_problem.dual_model,
            dual_attribute(attr),
            ci_dual,
        )
    end
end

function MOI.supports(
    ::DualOptimizer,
    attr::MOI.ConstraintPrimalStart,
    C::Type{<:MOI.ConstraintIndex},
)
    return MOI.supports(
        optimizer.dual_problem.dual_model,
        dual_attribute(attr),
        C,
    )
end

function MOI.set(
    optimizer::DualOptimizer,
    attr::Union{MOI.ConstraintPrimal,MOI.ConstraintPrimalStart},
    ci::MOI.ConstraintIndex{<:MOI.AbstractScalarFunction},
    value,
)
    primal_dual_map = optimizer.dual_problem.primal_dual_map
    if ci in keys(primal_dual_map.constrained_var_dual)
        error(
            "Setting starting value for variables constrained at creation is not supported yet",
        )
    elseif haskey(primal_dual_map.primal_con_dual_con, ci)
        # If it has no key then there is no dual constraint
        ci_dual_problem = get_ci_dual_problem(optimizer, ci)
        if !isnothing(value) && (F <: MOI.AbstractScalarFunction)
            value -= get_primal_ci_constant(optimizer, ci)
        end
        MOI.set(
            optimizer.dual_problem.dual_model,
            dual_attribute(attr),
            ci_dual_problem,
            value,
        )
    end
    return
end

function MOI.get(
    optimizer::DualOptimizer{T},
    attr::MOI.ConstraintPrimal,
    ci::MOI.ConstraintIndex{F,S},
) where {T,F<:MOI.AbstractScalarFunction,S<:MOI.AbstractScalarSet}
    primal_dual_map = optimizer.dual_problem.primal_dual_map
    data = get(primal_dual_map.primal_constraint_data, ci, nothing)
    if data === nothing
        first_vi = primal_dual_map.primal_constrained_variables[ci][1]
        ci_dual = primal_dual_map.primal_variable_data[first_vi].dual_constraint
        if ci_dual === nothing
            return zero(T)
        else
            return MOI.get(
                optimizer.dual_problem.dual_model,
                dual_attribute(attr),
                ci_dual,
            )
        end
    else
        primal_ci_constant = data.primal_set_constants[]
        # If it has no key then there is no dual constraint
        ci_dual = data.dual_constrained_variable_constraint
        if ci_dual === nothing
            return -primal_ci_constant
        end
        return MOI.get(
            optimizer.dual_problem.dual_model,
            dual_attribute(attr),
            ci_dual,
        ) - primal_ci_constant
    end
end

function MOI.get(
    optimizer::DualOptimizer{T},
    attr::Union{MOI.ConstraintPrimal,MOI.ConstraintPrimalStart},
    ci::MOI.ConstraintIndex{F,S},
) where {T,F<:MOI.AbstractVectorFunction,S<:MOI.AbstractVectorSet}
    primal_dual_map = optimizer.dual_problem.primal_dual_map
    data = get(primal_dual_map.primal_constraint_data, ci, nothing)
    if data === nothing
        vis = primal_dual_map.primal_constrained_variables[ci]
        ci_dual = primal_dual_map.primal_variable_data[vis[1]].dual_constraint
        if ci_dual === nothing
            return zeros(T, length(vis))
        else
            return MOI.get(
                optimizer.dual_problem.dual_model,
                dual_attribute(attr),
                ci_dual,
            )
        end
    else
        ci_dual = data.dual_constrained_variable_constraint
        # If it has no key then there is no dual constraint
        if ci_dual === nothing
            # The number of dual variable associated with the primal constraint is the ci dimension
            ci_dimension = length(data.dual_variables)
            return zeros(T, ci_dimension)
        end
        return MOI.get(
            optimizer.dual_problem.dual_model,
            dual_attribute(attr),
            ci_dual,
        )
    end
end

function MOI.get(optimizer::DualOptimizer, ::MOI.TerminationStatus)
    return _dual_status(
        MOI.get(optimizer.dual_problem.dual_model, MOI.TerminationStatus()),
    )
end

function _dual_status(term::MOI.TerminationStatusCode)
    if term == MOI.INFEASIBLE
        return MOI.DUAL_INFEASIBLE
    elseif term == MOI.DUAL_INFEASIBLE
        return MOI.INFEASIBLE
    elseif term == MOI.ALMOST_INFEASIBLE
        return MOI.ALMOST_DUAL_INFEASIBLE
    elseif term == MOI.ALMOST_DUAL_INFEASIBLE
        return MOI.ALMOST_INFEASIBLE
    end
    return term
end

function MOI.supports(
    optimizer::DualOptimizer,
    attr::MOI.AbstractOptimizerAttribute,
)
    return MOI.supports(optimizer.dual_problem.dual_model, attr)
end

function MOI.set(
    optimizer::DualOptimizer,
    attr::MOI.AbstractOptimizerAttribute,
    value,
)
    return MOI.set(optimizer.dual_problem.dual_model, attr, value)
end

function MOI.get(optimizer::DualOptimizer, attr::MOI.AbstractOptimizerAttribute)
    return MOI.get(optimizer.dual_problem.dual_model, attr)
end

dual_attribute(attr::MOI.PrimalStatus) = MOI.DualStatus(attr.result_index)
dual_attribute(attr::MOI.DualStatus) = MOI.PrimalStatus(attr.result_index)
function dual_attribute(attr::MOI.ObjectiveValue)
    return MOI.DualObjectiveValue(attr.result_index)
end
function dual_attribute(attr::MOI.DualObjectiveValue)
    return MOI.ObjectiveValue(attr.result_index)
end

# For now we don't support setting arbitrary AbstractModelAttribute because
# we don't know if they need to be modified via the dualization. One example
# would be `MOI.set(model, MOI.ObjectiveFunction{F}(), f)`. We currently
# don't support the incremental interface.
function MOI.get(optimizer::DualOptimizer, attr::MOI.AbstractModelAttribute)
    return MOI.get(optimizer.dual_problem.dual_model, dual_attribute(attr))
end
