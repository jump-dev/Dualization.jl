"""
    supported_constraints(con_types::Vector{Tuple{DataType, DataType}})

Returns `true` if `Function-in-Set` is supported for Dualization and throws an error if it is not.
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
supported_constraint(::Type{SVF}, ::Type{<:MOI.GreaterThan}) = true
supported_constraint(::Type{SVF}, ::Type{<:MOI.LessThan}) = true
supported_constraint(::Type{SVF}, ::Type{<:MOI.EqualTo}) = true
# SAF - Linear
supported_constraint(::Type{SAF{T}}, ::Type{MOI.GreaterThan{T}}) where T = true
supported_constraint(::Type{SAF{T}}, ::Type{MOI.LessThan{T}}) where T = true
supported_constraint(::Type{SAF{T}}, ::Type{MOI.EqualTo{T}}) where T = true
# VVF - Linear
supported_constraint(::Type{VVF}, ::Type{MOI.Nonpositives}) = true
supported_constraint(::Type{VVF}, ::Type{MOI.Nonnegatives}) = true
supported_constraint(::Type{VVF}, ::Type{MOI.Zeros}) = true
# VAF - Linear
supported_constraint(::Type{<:VAF}, ::Type{MOI.Nonpositives}) = true
supported_constraint(::Type{<:VAF}, ::Type{MOI.Nonnegatives}) = true
supported_constraint(::Type{<:VAF}, ::Type{MOI.Zeros}) = true
# SOC
supported_constraint(::Type{VVF}, ::Type{MOI.SecondOrderCone}) = true
supported_constraint(::Type{<:VAF}, ::Type{MOI.SecondOrderCone}) = true
# RotatedSOC
supported_constraint(::Type{VVF}, ::Type{MOI.RotatedSecondOrderCone}) = true
supported_constraint(::Type{<:VAF}, ::Type{MOI.RotatedSecondOrderCone}) = true
# SDP Triangle
supported_constraint(::Type{VVF}, ::Type{MOI.PositiveSemidefiniteConeTriangle}) = true
supported_constraint(::Type{<:VAF}, ::Type{MOI.PositiveSemidefiniteConeTriangle}) = true
# ExponentialCone
supported_constraint(::Type{VVF}, ::Type{MOI.ExponentialCone}) = true
supported_constraint(::Type{<:VAF}, ::Type{MOI.ExponentialCone}) = true
# DualExponentialCone
supported_constraint(::Type{VVF}, ::Type{MOI.DualExponentialCone}) = true
supported_constraint(::Type{<:VAF}, ::Type{MOI.DualExponentialCone}) = true
# PowerCone
supported_constraint(::Type{VVF}, ::Type{<:MOI.PowerCone}) = true
supported_constraint(::Type{VAF{T}}, ::Type{MOI.PowerCone{T}}) where T = true
# DualPowerCone
supported_constraint(::Type{VVF}, ::Type{<:MOI.DualPowerCone}) = true
supported_constraint(::Type{VAF{T}}, ::Type{MOI.DualPowerCone{T}}) where T = true

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
supported_obj(::Any) = false
# List of supported objective functions
supported_obj(::Type{SVF}) = true
supported_obj(::Type{<:SAF}) = true
