function add_dual_cone_constraint(dual_model::MOI.ModelLike, primal_model::MOI.ModelLike, vi::Vector{VI},
                                  ci::CI{F, S}) where {F <: MOI.AbstractScalarFunction, S <: MOI.AbstractScalarSet}
    # In this case vi should have only one entry
    return MOI.add_constraint(dual_model, SVF(vi[1]), MOI.dual_set(get_set(primal_model, ci)))
end

function add_dual_cone_constraint(dual_model::MOI.ModelLike, primal_model::MOI.ModelLike, vi::Vector{VI},
                                  ci::CI{F, MOI.EqualTo{T}}) where {T, F <: MOI.AbstractScalarFunction}
    return 
end

function add_dual_cone_constraint(dual_model::MOI.ModelLike, primal_model::MOI.ModelLike, vis::Vector{VI},
                                  ci::CI{F, S}) where {F <: MOI.AbstractVectorFunction, S <: MOI.AbstractVectorSet}
    return MOI.add_constraint(dual_model, VVF(vis), MOI.dual_set(get_set(primal_model, ci)))
end

function add_dual_cone_constraint(dual_model::MOI.ModelLike, primal_model::MOI.ModelLike, vis::Vector{VI},
                                  ci::CI{F, MOI.Zeros}) where {F <: MOI.AbstractVectorFunction}
    return 
end