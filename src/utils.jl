# Some useful wrappers
function get_function(model::MOI.ModelLike, ci::CI)
    return MOI.get(model, MOI.ConstraintFunction(), ci)
end

function get_set(model::MOI.ModelLike, ci::CI)
    return MOI.get(model, MOI.ConstraintSet(), ci)
end

function get_ci_row_dimension(model::MOI.ModelLike, ci::CI)
    return MOI.output_dimension(get_function(model, ci))
end

function get_scalar_term(model::MOI.ModelLike, 
                         ci::CI{SVF, S}) where {S <: MOI.AbstractScalarSet}
    
    return [- MOI.constant(get_set(model, ci))]
end

function get_scalar_term(model::MOI.ModelLike, 
                         ci::CI{F, S}) where {F <: MOI.AbstractScalarFunction, 
                                              S <: MOI.AbstractScalarSet}

    return [MOI.constant(get_function(model, ci)) - MOI.constant(get_set(model, ci))]
end

# This is used to fill the dual objective dictionary
function get_scalar_term(model::MOI.ModelLike, i::Int,
                         ci::CI{F, S}) where {F <: MOI.AbstractVectorFunction, 
                                              S <: MOI.AbstractVectorSet}
    return MOI.constant(get_function(model, ci))[i]
end

# This is used to fill the dual objective dictionary
function get_scalar_term(model::MOI.ModelLike, i::Int,
                         ci::CI{SVF, S}) where {S <: MOI.AbstractScalarSet}
    
    return - MOI.constant(get_set(model, ci))
end

# This is used to fill the dual objective dictionary
function get_scalar_term(model::MOI.ModelLike, i::Int,
                         ci::CI{F, S}) where {F <: MOI.AbstractScalarFunction, 
                                              S <: MOI.AbstractScalarSet}

    # In this case there i only one constant in the function and one in the set
    return MOI.constant(get_function(model, ci))[1] - MOI.constant(get_set(model, ci))
end