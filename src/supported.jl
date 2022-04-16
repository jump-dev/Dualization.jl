"""
    supported_constraints(con_types::Vector{Tuple{Type, Type}})

Returns `true` if `Function-in-Set` is supported for Dualization and throws an error if it is not.
"""
function supported_constraints(con_types::Vector{Tuple{Type,Type}})
    for (F, S) in con_types
        if !supported_constraint(F, S)
            error(
                "Constraints of the Function ",
                F,
                " in the Set ",
                S,
                " are not implemented",
            )
        end
    end
    return
end

supported_constraint(::Type, ::Type) = false
function supported_constraint(
    ::Type{<:Union{MOI.VariableIndex,MOI.ScalarAffineFunction}},
    S::Type{<:MOI.AbstractScalarSet},
)
    return _dual_set_type(S) !== nothing
end
function supported_constraint(
    ::Type{<:Union{MOI.VectorOfVariables,MOI.VectorAffineFunction}},
    S::Type{<:MOI.AbstractVectorSet},
)
    return _dual_set_type(S) !== nothing
end

"""
    supported_objective(primal_model::MOI.ModelLike)

Returns `true` if `MOI.ObjectiveFunctionType()` is supported for Dualization and throws an error if it is not.
"""
function supported_objective(primal_model::MOI.ModelLike)
    obj_func_type = MOI.get(primal_model, MOI.ObjectiveFunctionType())
    if !supported_obj(obj_func_type)
        error("Objective functions of type $obj_func_type are not implemented")
    end
    return
end

# General case
supported_obj(::Type) = false
# List of supported objective functions
supported_obj(::Type{VI}) = true
supported_obj(::Type{<:SAF}) = true
supported_obj(::Type{<:SQF}) = true
