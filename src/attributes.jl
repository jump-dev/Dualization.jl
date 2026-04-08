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

fixed_variable_value(::MOI.VariablePrimal, ::Type{T}) where {T} = zero(T)

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
    data = primal_dual_map.primal_variable_data[vi]
    if !isnothing(data.primal_constrained_variable_constraint)
        msg = "Setting starting value for variables constrained at creation is not supported yet"
        throw(MOI.SetAttributeNotAllowed(attr, msg))
    end
    MOI.set(
        optimizer.dual_problem.dual_model,
        dual_attribute(attr),
        data.dual_constraint,
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
    data = primal_dual_map.primal_variable_data[vi]
    if isnothing(data.primal_constrained_variable_constraint)
        # Classical free variable
        return dual_attribute_value(
            attr,
            MOI.get(
                optimizer.dual_problem.dual_model,
                dual_attribute(attr),
                data.dual_constraint,
            ),
        )
    end
    if isnothing(data.dual_constraint)
        # Fixed variable: variable constrained to `MOI.EqualTo` or `MOI.Zeros`
        return fixed_variable_value(attr, T)
    end
    # Added as constrained variable
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
        # Added as part of a vector of constrained variable
        return value[data.primal_constrained_variable_index]
    else
        # Added as a scalar constrained variable
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
