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
                         ci::CI{F, S}, T::DataType) where {F <: MOI.AbstractScalarFunction, 
                                                           S <: MOI.AbstractScalarSet}
    
    if F <: SVF
        return [- MOIU.getconstant(get_set(model, ci))]
    else
        return MOIU.constant(get_function(model, ci)) .- MOIU.getconstant(get_set(model, ci))
    end
end

function get_scalar_term(model::MOI.ModelLike, 
                         ci::CI{F, S}, T::DataType) where {F <: MOI.AbstractVectorFunction, 
                                                           S <: MOI.AbstractVectorSet}
    if F <: VVF
        return zeros(T, get_ci_row_dimension(model, ci))
    else
        return MOIU.constant(get_function(model, ci))
    end
end

function get_scalar_term(model::MOI.ModelLike, 
                         ci::CI{F, S}, T::DataType) where {F <: MOI.AbstractVectorFunction, 
                                                           S <: MOI.SecondOrderCone}
    
    return zeros(T, get_ci_row_dimension(model, ci))
end
