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

function MOI.get(
    optimizer::DualOptimizer{T},
    ::MOI.ConstraintBridgingCost{
        <:Union{MOI.VariableIndex,MOI.ScalarAffineFunction{T}},
        S<:MOI.AbstractScalarSet,
    },
) where {T}
    D = _dual_set_type(S)
    if D === nothing
        return Inf
    end
    return MOI.get(
        optimizer.dual_problem.dual_model,
        MOI.VariableBridgingCost{D}(),
    )
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

function MOI.get(
    optimizer::DualOptimizer{T},
    ::MOI.ConstraintBridgingCost{
        <:Union{MOI.VectorOfVariables,MOI.VectorAffineFunction{T}},
        S<:MOI.AbstractVectorSet,
    },
) where {T}
    D = _dual_set_type(S)
    if D === nothing
        return Inf
    end
    return MOI.get(
        optimizer.dual_problem.dual_model,
        MOI.VariableBridgingCost{D}(),
    )
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

function MOI.get(
    optimizer::DualOptimizer{T},
    ::MOI.VariableBridgingCost{MOI.Reals},
) where {T}
    return MOI.get(
        optimizer.dual_problem.dual_model,
        MOI.ConstraintBridgingCost{MOI.ScalarAffineFunction{T},MOI.EqualTo{T}}(),
    )
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

function MOI.get(
    optimizer::DualOptimizer{T},
    ::MOI.VariableBridgingCost{MOI.AbstractVectorSet},
) where {T}
    D = _dual_set_type(S)
    if D === nothing
        return Inf
    end
    return MOI.get(
        optimizer.dual_problem.dual_model,
        MOI.ConstraintBridgingCost{MOI.VectorAffineFunction{T},D}(),
    )
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
