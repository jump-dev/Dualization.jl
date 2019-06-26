"""
    supported_constraints(con_types::Vector{Tuple{DataType, DataType}})

Throws an error if a constraint is not supported to be dualized 
"""
function supported_constraints(con_types::Vector{Tuple{DataType, DataType}})
    for (F, S) in con_types
        if !supported_constraint(F, S)
            error("Constraints of funtion ", F, " in the Set ", S," are not implemented")
        end
    end
    return 
end

# General case
supported_constraint(::DataType, ::DataType) = false
# List of supported constraints
# SAF
supported_constraint(::Type{SAF{T}}, ::Type{MOI.GreaterThan{T}}) where T = true
supported_constraint(::Type{SAF{T}}, ::Type{MOI.LessThan{T}}) where T = true
supported_constraint(::Type{SAF{T}}, ::Type{MOI.EqualTo{T}}) where T = true
# SVF
supported_constraint(::Type{SVF}, ::Type{MOI.GreaterThan{T}}) where T = true
supported_constraint(::Type{SVF}, ::Type{MOI.LessThan{T}}) where T = true
supported_constraint(::Type{SVF}, ::Type{MOI.EqualTo{T}}) where T = true
#VAF
supported_constraint(::Type{VAF{T}}, ::Type{MOI.Nonpositives}) where T = true
supported_constraint(::Type{VAF{T}}, ::Type{MOI.Nonnegatives}) where T = true
supported_constraint(::Type{VAF{T}}, ::Type{MOI.Zeros}) where T = true

"""
    supported_objective(obj_func_type::DataType)

Throws an error if an objective function is not supported to be dualized in this case
as ObjectiveFunctions can only be `AbstractScalarFunction` it only supports 
`SingleVariableFunction` and `ScalarAffineFunction`
"""
function supported_objective(primal_model::MOI.ModelLike) where T
    obj_func_type = MOI.get(primal_model, MOI.ObjectiveFunctionType())
    if !supported_obj(obj_func_type)
        error("Objective functions of type ", obj_func_type," are not implemented")
    end
    return 
end

# General case
supported_obj(::DataType) = false
# List of supported objective functions
supported_obj(::Type{SVF}) = true
supported_obj(::Type{SAF{T}}) where T = true