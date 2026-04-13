_minus(::Nothing) = nothing
_minus(x) = -x

"""
    constraint_attribute(attr::MOI.AbstractVariableAttribute)

When a variable is added as a constrained variable, this function is used to
get the value of the variable from the corresponding constraint.
"""
function constraint_attribute end

function constraint_attribute(attr::MOI.VariablePrimal)
    return MOI.ConstraintPrimal(attr.result_index)
end

function constraint_attribute(::MOI.VariablePrimalStart)
    return MOI.ConstraintPrimalStart()
end

"""
    dual_attribute(attr::MOI.AbstractModelAttribute)
    dual_attribute(attr::MOI.AbstractVariableAttribute)
    dual_attribute(attr::MOI.AbstractConstraintAttribute)

Corresponding attribute to get `MOI.set` or `MOI.get` `attr` from the primal
model with the dual model.
"""
function dual_attribute end

dual_attribute(attr::MOI.ResultCount) = attr

function dual_attribute(attr::Union{MOI.VariablePrimal,MOI.ConstraintPrimal})
    return MOI.ConstraintDual(attr.result_index)
end

function dual_attribute(
    ::Union{MOI.VariablePrimalStart,MOI.ConstraintPrimalStart},
)
    return MOI.ConstraintDualStart()
end

function dual_attribute(attr::MOI.ConstraintDual)
    return MOI.VariablePrimal(attr.result_index)
end

function dual_attribute(::MOI.ConstraintDualStart)
    return MOI.VariablePrimalStart()
end

"""
    dual_attribute_value_set(attr::MOI.AbstractVariableAttribute, value)

Used as pre-processing for `MOI.set`ting `value` for a variable.
"""
function dual_attribute_value_set end

"""
    dual_attribute_value_get(attr::MOI.AbstractVariableAttribute, value)

Used as pre-processing for `MOI.get`ting `value` for a variable.
"""
function dual_attribute_value_get end

function dual_attribute_value_set(
    ::Union{MOI.VariablePrimal,MOI.VariablePrimalStart},
    value,
)
    return _minus(value)
end

function dual_attribute_value_get(
    ::Union{MOI.VariablePrimal,MOI.VariablePrimalStart},
    value,
)
    return _minus(value)
end

"""
    constrained_variable_dual_attribute(attr::MOI.AbstractConstraintAttribute)

Same as [`dual_attribute`](@ref) but used in case a constraint was added as
part of constrained variables.
"""
function constrained_variable_dual_attribute end

function constrained_variable_dual_attribute(
    attr::Union{MOI.ConstraintDual,MOI.ConstraintDualStart},
)
    return constraint_attribute(dual_attribute(attr))
end

function constrained_variable_dual_attribute(
    attr::MOI.AbstractConstraintAttribute,
)
    return dual_attribute(attr)
end

"""
    fixed_variable_value(attr::MOI.AbstractVariableAttribute, ::Type{T}) where {T}

Value of `attr` for a value constrained to be equal to zero. This should be the
same as how `MOI.get` is implemented for the `MOI.Bridges.Variable.ZerosBridge`.
"""
function fixed_variable_value end

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
        msg = "Setting $attr for variables constrained at creation is not supported yet"
        throw(MOI.SetAttributeNotAllowed(attr, msg))
    end
    MOI.set(
        optimizer.dual_problem.dual_model,
        dual_attribute(attr),
        data.dual_constraint,
        dual_attribute_value_set(attr, value),
    )
    return
end

function MOI.get(
    optimizer::DualOptimizer{T},
    attr::MOI.AbstractVariableAttribute,
    vi::MOI.VariableIndex,
) where {T}
    primal_dual_map = optimizer.dual_problem.primal_dual_map
    data = primal_dual_map.primal_variable_data[vi]
    if isnothing(data.primal_constrained_variable_constraint)
        # Classical free variable
        return dual_attribute_value_get(
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
    value = dual_attribute_value_get(
        attr,
        MOI.get(
            optimizer.dual_problem.dual_model,
            dual_attribute(attr),
            data.dual_constraint,
        ),
    )
    if !isnothing(value) &&
       data.dual_constraint isa
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
        dual_attribute(attr),
        MOI.VariableIndex,
    )
end

function MOI.supports(
    optimizer::DualOptimizer,
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
    av::_AfterVectorize,
    attr::MOI.AbstractConstraintAttribute,
    ci::MOI.ConstraintIndex,
    value,
)
    optimizer = av.inner
    if !isnothing(av.ci)
        ci = av.ci
        # Needed because the Vectorize bridge has vectorized it
        value = _scalarize(ci, value)
    end
    primal_dual_map = optimizer.dual_problem.primal_dual_map
    data = get(primal_dual_map.primal_constraint_data, ci, nothing)
    if isnothing(data)
        msg = "Setting $attr for variables constrained at creation is not supported yet"
        throw(MOI.SetAttributeNotAllowed(attr, msg))
    else
        dual_attr = dual_attribute(attr)
        if dual_attr isa MOI.AbstractVariableAttribute
            index = _scalarize(
                ci,
                primal_dual_map.primal_constraint_data[ci].dual_variables,
            )
        else
            @assert dual_attr isa MOI.AbstractConstraintAttribute
            index = data.dual_constrained_variable_constraint
        end
        # `index` is `nothing` for affine equality constraints
        if !isnothing(index)
            MOI.set(optimizer.dual_problem.dual_model, dual_attr, index, value)
        end
    end
    return
end

"""
    fixed_constrained_variables_get(
        optimizer::DualOptimizer,
        attr::MOI.AbstractConstraintAttribute,
        primal_vi::MOI.VariableIndex,
        dual_function::MOI.ScalarAffineFunction,
    )

Given a fixed variable `primal_vi`, so part of a
`MOI.VariableIndex`-in-`MOI.EqualTo` constraint or a
`MOI.VectorOfVariables`-in-`MOI.Zeros` constraint, return the value of the
attribute `attr` at the entry corresponding to `primal_vi`.
The terms of `dual_function` are the product of the coefficient of `primal_vi`
in each constraint multiplied by the corresponding dual variable.
The constant is the coefficient of `primal_vi` in the objective function.
"""
function fixed_constrained_variables_get end

function fixed_constrained_variables_get(
    optimizer,
    attr::Union{MOI.ConstraintDual,MOI.ConstraintDualStart},
    ::MOI.VariableIndex,
    dual_function::MOI.ScalarAffineFunction,
)
    function eval(inner_vi)
        return MOI.get(
            optimizer.dual_problem.dual_model,
            dual_attribute(attr),
            inner_vi,
        )
    end
    return MOI.Utilities.eval_variables(eval, dual_function)
end

function _variable_attr(attr::MOI.ConstraintPrimal)
    return MOI.VariablePrimal(attr.result_index)
end
function _variable_attr(::MOI.ConstraintPrimalStart)
    return MOI.VariablePrimalStart()
end

function fixed_constrained_variables_get(
    optimizer::DualOptimizer{T},
    attr::Union{MOI.ConstraintPrimal,MOI.ConstraintPrimalStart},
    primal_vi::MOI.VariableIndex,
    ::MOI.ScalarAffineFunction,
) where {T}
    return MOI.get(optimizer, _variable_attr(attr), primal_vi)
end

# Not sure how to rely on a bridge for this one.
# What we did is equivalent to applying `MOI.Bridges.Variable.VectorizeBridge`
# so we substituted the variable, hence it's a bit trickier.
# Anyway I think we should just drop support for scalar constraints.
# We can revisit if we have a custom attribute that needs to extend this.
function _maybe_shift_for_vectorize(
    optimizer,
    attr,
    dual_ci::MOI.ConstraintIndex{
        <:MOI.AbstractScalarFunction,
        <:MOI.Utilities.ScalarLinearSet,
    },
    value,
)
    return _shift_for_vectorize(optimizer, attr, dual_ci, value)
end

function _maybe_shift_for_vectorize(
    optimizer,
    attr,
    dual_ci::MOI.ConstraintIndex,
    value,
)
    return value
end

function _shift_for_vectorize(
    optimizer,
    ::Union{MOI.ConstraintDual,MOI.ConstraintDualStart},
    dual_ci,
    value,
)
    set =
        MOI.get(optimizer.dual_problem.dual_model, MOI.ConstraintSet(), dual_ci)
    return value - MOI.constant(set)
end

function _shift_for_vectorize(
    optimizer,
    ::Union{MOI.ConstraintPrimal,MOI.ConstraintPrimalStart},
    dual_ci,
    value,
)
    return value
end

"""
    equality_constraint_get(
        optimizer::DualOptimizer,
        attr::MOI.AbstractConstraintAttribute,
        dual_variable::MOI.ScalarAffineFunction,
    )

Return the value of `attr` for an equality constraint whose dual variable
is `dual_variable`.
"""
function equality_constraint_get end

function equality_constraint_get(
    optimizer,
    attr::Union{MOI.ConstraintDual,MOI.ConstraintDualStart},
    dual_variable::MOI.VariableIndex,
)
    return MOI.get(
        optimizer.dual_problem.dual_model,
        dual_attribute(attr),
        dual_variable,
    )
end

function equality_constraint_get(
    ::DualOptimizer{T},
    ::Union{MOI.ConstraintPrimal,MOI.ConstraintPrimalStart},
    ::MOI.VariableIndex,
) where {T}
    return zero(T)
end

function _scalarize(::MOI.ConstraintIndex{<:MOI.AbstractVectorFunction}, v)
    return v
end

function _scalarize(::MOI.ConstraintIndex{<:MOI.AbstractScalarFunction}, v)
    return only(v)
end

function MOI.get(
    av::_AfterVectorize{T},
    attr::MOI.AbstractConstraintAttribute,
    ci::MOI.ConstraintIndex,
) where {T}
    optimizer = av.inner
    if !isnothing(av.ci)
        ci = av.ci
    end
    primal_dual_map = optimizer.dual_problem.primal_dual_map
    data = get(primal_dual_map.primal_constraint_data, ci, nothing)
    if isnothing(data)
        # Constraint associated to variables constrained at creation
        vis = primal_dual_map.primal_constrained_variables[ci]
        data = primal_dual_map.primal_variable_data[first(vis)]
        if isnothing(data.dual_constraint)
            # Fixed variables (constrained in `MOI.Zeros` or `MOI.EqualTo`)
            dual_functions = MOI.ScalarAffineFunction{T}[
                primal_dual_map.primal_variable_data[vi].dual_function for
                vi in vis
            ]
            return fixed_constrained_variables_get.(
                optimizer,
                attr,
                _scalarize(ci, vis),
                _scalarize(ci, dual_functions),
            )
        else
            return _maybe_shift_for_vectorize(
                optimizer,
                attr,
                data.dual_constraint,
                MOI.get(
                    optimizer.dual_problem.dual_model,
                    constrained_variable_dual_attribute(attr),
                    data.dual_constraint,
                ),
            )
        end
    else
        @assert !haskey(primal_dual_map.primal_constrained_variables, ci)
        dual_ci = data.dual_constrained_variable_constraint
        if isnothing(dual_ci)
            # Primal equality constraint, so no dual constraint
            return equality_constraint_get.(
                optimizer,
                attr,
                _scalarize(ci, data.dual_variables),
            )
        else
            dual_attr = dual_attribute(attr)
            if dual_attr isa MOI.AbstractVariableAttribute
                index = _scalarize(
                    ci,
                    primal_dual_map.primal_constraint_data[ci].dual_variables,
                )
                return _scalarize(
                    ci,
                    MOI.get.(
                        optimizer.dual_problem.dual_model,
                        dual_attr,
                        data.dual_variables,
                    ),
                )
            else
                @assert dual_attr isa MOI.AbstractConstraintAttribute
                return MOI.get(
                    optimizer.dual_problem.dual_model,
                    dual_attr,
                    dual_ci,
                )
            end
        end
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
