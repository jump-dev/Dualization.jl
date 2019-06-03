"""
    supported_constraints(constr_types::Vector{Tuple{DataType, DataType}})

Throws an error if a constraint is not supported to be dualized 
"""
function supported_constraints(constr_types::Vector{Tuple{DataType, DataType}})
    for (F, S) in constr_types
        if !supported_constraint(F, S)
            error("""
                oops! not implemented
            """)
        end
    end
    return nothing
end

# General case
supported_constraint(::Any, ::Any) = false
# List of supported constraints
supported_constraint(::Type{SAF{T}}, ::Type{MOI.GreaterThan{T}}) where T = true
supported_constraint(::Type{SAF{T}}, ::Type{MOI.LessThan{T}}) where T = true
#TODO

"""
    supported_objective(obj_func_type::DataType)

Throws an error if an objective function is not supported to be dualized 
"""
function supported_objective(obj_func_type::DataType)
    if !supported_obj(obj_func_type)
        error("""
            oops! not implemented
        """)
    end
    return nothing
end

# General case
supported_obj(::Any) = false
# List of supported objective functions
supported_obj(::Type{SVF}) = true
supported_obj(::Type{VVF}) = true
supported_obj(::Type{SAF{T}}) where T = true
#TODO