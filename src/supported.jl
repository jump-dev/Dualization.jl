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
# SVF - Linear
supported_constraint(::Type{SVF}, ::Type{MOI.GreaterThan{T}}) where T = true
supported_constraint(::Type{SVF}, ::Type{MOI.LessThan{T}}) where T = true
supported_constraint(::Type{SVF}, ::Type{MOI.EqualTo{T}}) where T = true
# SAF - Linear
supported_constraint(::Type{SAF{T}}, ::Type{MOI.GreaterThan{T}}) where T = true
supported_constraint(::Type{SAF{T}}, ::Type{MOI.LessThan{T}}) where T = true
supported_constraint(::Type{SAF{T}}, ::Type{MOI.EqualTo{T}}) where T = true
# VVF - Linear
supported_constraint(::Type{VVF}, ::Type{MOI.Nonpositives}) where T = true
supported_constraint(::Type{VVF}, ::Type{MOI.Nonnegatives}) where T = true
supported_constraint(::Type{VVF}, ::Type{MOI.Zeros}) where T = true
# VAF - Linear
supported_constraint(::Type{VAF{T}}, ::Type{MOI.Nonpositives}) where T = true
supported_constraint(::Type{VAF{T}}, ::Type{MOI.Nonnegatives}) where T = true
supported_constraint(::Type{VAF{T}}, ::Type{MOI.Zeros}) where T = true
#VVF - SOC
supported_constraint(::Type{VVF}, ::Type{MOI.SecondOrderCone}) where T = true
#VAF - SOC 
supported_constraint(::Type{VAF{T}}, ::Type{MOI.SecondOrderCone}) where T = true
#VVF - RotatedSOC
supported_constraint(::Type{VVF}, ::Type{MOI.RotatedSecondOrderCone}) where T = true
#VAF - RotatedSOC 
supported_constraint(::Type{VAF{T}}, ::Type{MOI.RotatedSecondOrderCone}) where T = true
#VVF - SDP Triangle
supported_constraint(::Type{VVF}, ::Type{MOI.PositiveSemidefiniteConeTriangle}) where T = true
#VAF - SDP Triangle 
supported_constraint(::Type{VAF{T}}, ::Type{MOI.PositiveSemidefiniteConeTriangle}) where T = true

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