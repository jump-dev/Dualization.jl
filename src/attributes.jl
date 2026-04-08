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
    optimizer::DualOptimizer,
    attr::MOI.ConstraintDualStart,
    ci::MOI.ConstraintIndex,
    value,
)
    primal_dual_map = optimizer.dual_problem.primal_dual_map
    data = get(primal_dual_map.primal_constraint_data, ci, nothing)
    if isnothing(data)
        msg = "Setting starting value for variables constrained at creation is not supported yet"
        throw(MOI.SetAttributeNotAllowed(attr, msg))
    else
        MOI.set(
            optimizer.dual_problem.dual_model,
            _variable_dual_attribute(attr),
            primal_dual_map.primal_constraint_data[ci].dual_variables[],
            value,
        )
    end
    return
end

function MOI.set(
    optimizer::DualOptimizer,
    attr::Union{MOI.ConstraintPrimal,MOI.ConstraintPrimalStart},
    ci::MOI.ConstraintIndex{<:MOI.AbstractScalarFunction},
    value,
)
    primal_dual_map = optimizer.dual_problem.primal_dual_map
    data = get(primal_dual_map.primal_constraint_data, ci, nothing)
    if isnothing(data)
        error(
            "Setting starting value for variables constrained at creation is not supported yet",
        )
    else
        ci_dual_problem = data.dual_constrained_variable_constraint
        if !isnothing(value)
            value -= data.primal_set_constants[]
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

function get_for_fixed_constrained_variables(
    optimizer,
    attr::Union{MOI.ConstraintDual,MOI.ConstraintDualStart},
    dual_function::MOI.ScalarAffineFunction,
)
    function eval(inner_vi)
        return MOI.get(
            optimizer.dual_problem.dual_model,
            _variable_dual_attribute(attr),
            inner_vi,
        )
    end
    return MOI.Utilities.eval_variables(eval, dual_function)
end

function get_for_fixed_constrained_variables(
    ::DualOptimizer{T},
    ::Union{MOI.ConstraintPrimal,MOI.ConstraintPrimalStart},
    ::MOI.ScalarAffineFunction,
) where {T}
    # TODO evaluate functions
    return zero(T)
end

function get_for_constrained_variables(
    optimizer,
    attr::Union{MOI.ConstraintDual,MOI.ConstraintDualStart},
    dual_ci::MOI.ConstraintIndex{<:MOI.AbstractScalarFunction},
)
    set =
        MOI.get(optimizer.dual_problem.dual_model, MOI.ConstraintSet(), dual_ci)
    return MOI.get(
        optimizer.dual_problem.dual_model,
        dual_attribute(attr),
        dual_ci,
    ) - MOI.constant(set)
end

function get_for_constrained_variables(optimizer, attr, dual_ci)
    return MOI.get(
        optimizer.dual_problem.dual_model,
        dual_attribute(attr),
        dual_ci,
    )
end

function get_for_equality_constraint(
    optimizer,
    attr::Union{MOI.ConstraintDual,MOI.ConstraintDualStart},
    dual_variable::MOI.VariableIndex,
)
    # TODO do something else not relying on `_variable_dual_attribute`
    return MOI.get(
        optimizer.dual_problem.dual_model,
        _variable_dual_attribute(attr),
        dual_variable,
    )
end

function get_for_equality_constraint(
    ::DualOptimizer{T},
    ::Union{MOI.ConstraintPrimal,MOI.ConstraintPrimalStart},
    ::MOI.VariableIndex,
) where {T}
    return zero(T)
end

"""
    shift_constant_for_get(attr::MOI.AbstractConstraintAttribute, value)
"""
function shift_constant_for_get end

function shift_constant_for_get(
    ::Union{MOI.ConstraintDual,MOI.ConstraintDualStart},
    value,
    _,
)
    return value
end

function shift_constant_for_get(
    ::Union{MOI.ConstraintPrimal,MOI.ConstraintPrimalStart},
    value::Vector,
    constant::Vector,
)
    return value
end

function shift_constant_for_get(
    ::Union{MOI.ConstraintPrimal,MOI.ConstraintPrimalStart},
    value::Real,
    constant::Real,
)
    return value - constant
end

function _get_through_constraint_vectorize(::MOI.ConstraintIndex, _, value, _)
    return value
end

function _get_through_constraint_vectorize(
    ci::MOI.ConstraintIndex{
        <:MOI.AbstractScalarFunction,
        <:MOI.Utilities.ScalarLinearSet,
    },
    attr,
    value,
    constants,
)
    # Dualization handles scalar constraints like `f(x) >= lb` in a way that's equivalent
    # to applying a `MOI.Bridges.Constraint.VectorizeBridge`. That is, it is equivalent to
    # transforming it into `[f(x) - lb] in MOI.Nonnegatives(1)`.
    # For packages that define custom attributes, to avoid having them to deal with both
    # defining how it should go through the vectorize bridge and for a scalar constraint
    # in a dualization layer, we just use the vectorize bridge implementation here:
    return MOI.get(model, attr)
end

function _scalarize(::MOI.ConstraintIndex{<:MOI.AbstractVectorFunction}, v)
    return v
end

function _scalarize(::MOI.ConstraintIndex{<:MOI.AbstractScalarFunction}, v)
    return only(v)
end

struct _AfterVectorize{T,OT,F,S} <: MOI.ModelLike
    inner::DualOptimizer{T,OT}
    inner_ci::MOI.ConstraintIndex{F,S}
end

# Dualization handles scalar constraints like `f(x) >= lb` in a way that's equivalent
# to applying a `MOI.Bridges.Constraint.VectorizeBridge`. That is, it is equivalent to
# transforming it into `[f(x) - lb] in MOI.Nonnegatives(1)`.
# For packages that define custom attributes, to avoid having them to deal with both
# defining how it should go through the vectorize bridge and for a scalar constraint
# in a dualization layer, we just use the vectorize bridge implementation here:
# This also help us get the mechanism that detect if it is a ray or not.
# It's getting quite hacky, maybe we should just drop support for scalar constraint
# in Dualization and rely on a bridge layer.

function MOI.get(
    optimizer::DualOptimizer,
    attr::MOI.AbstractConstraintAttribute,
    ci::MOI.ConstraintIndex,
)
    return MOI.get(_AfterVectorize(optimizer, ci), attr, ci)
end

function _vectorize_bridge(
    ::Type{MOI.Bridges.Constraint.VectorizeBridge{T,F,S,G}},
    constant,
) where {T,F,S,G}
    dummy_ci = MOI.ConstraintIndex{F,S}(1)
    return MOI.Bridges.Constraint.VectorizeBridge{T,F,S,G}(dummy_ci, constant)
end

function MOI.get(
    optimizer::DualOptimizer{T},
    attr::MOI.AbstractConstraintAttribute,
    ci::MOI.ConstraintIndex{F,S},
) where {T,F<:MOI.AbstractScalarFunction,S<:MOI.Utilities.ScalarLinearSet}
    model = _AfterVectorize(optimizer, ci)
    primal_dual_map = optimizer.dual_problem.primal_dual_map
    data = get(primal_dual_map.primal_constraint_data, ci, nothing)
    if !isnothing(data)
        constant = data.primal_set_constants[]
        BT = MOI.Bridges.Constraint.concrete_bridge_type(
            MOI.Bridges.Constraint.VectorizeBridge{T},
            F,
            S,
        )
        ci = _vectorize_bridge(BT, -constant)
    end
    return MOI.get(model, attr, ci)
end

# Vectorize bridge uses this to check if it is a ray or not
function MOI.get(av::_AfterVectorize, attr::MOI.AbstractModelAttribute)
    return MOI.get(av.inner, attr)
end

function MOI.get(
    av::_AfterVectorize{T},
    attr::MOI.AbstractConstraintAttribute,
    ::MOI.ConstraintIndex,
) where {T}
    optimizer = av.inner
    ci = av.inner_ci
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
            return get_for_fixed_constrained_variables.(
                optimizer,
                attr,
                _scalarize(ci, dual_functions),
            )
        else
            return get_for_constrained_variables(
                optimizer,
                attr,
                data.dual_constraint,
            )
        end
    else
        @assert !haskey(primal_dual_map.primal_constrained_variables, ci)
        dual_ci = data.dual_constrained_variable_constraint
        if isnothing(dual_ci)
            # Primal equality constraint, so no dual constraint
            # TODO do something else not relying on `_variable_dual_attribute`
            return get_for_equality_constraint.(
                optimizer,
                attr,
                _scalarize(ci, data.dual_variables),
            )
        else
            return MOI.get(
                optimizer.dual_problem.dual_model,
                dual_attribute(attr),
                dual_ci,
            )
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
