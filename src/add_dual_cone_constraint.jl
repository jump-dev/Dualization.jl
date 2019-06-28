function add_dual_cone_constraint(dual_model::MOI.ModelLike, primal_model::MOI.ModelLike, vis::Vector{VI},
                                  ci::CI{F, S}) where {F <: MOI.AbstractFunction, S <: MOI.AbstractSet}
    if length(vis) == 1
        _add_dual_cone_constraint(dual_model, primal_model, vis[1], ci)
    else
        _add_dual_cone_constraint(dual_model, primal_model, vis, ci)
    end
end

function _add_dual_cone_constraint(dual_model::MOI.ModelLike, primal_model::MOI.ModelLike, vi::VI,
                                  ci::CI{F, S}) where {F <: MOI.AbstractScalarFunction, S <: MOI.AbstractScalarSet}
    return MOI.add_constraint(dual_model, SVF(vi), dual_set(get_set(primal_model, ci)))
end

function _add_dual_cone_constraint(dual_model::MOI.ModelLike, primal_model::MOI.ModelLike, vi::VI,
                                  ci::CI{F, S}) where {F <: MOI.AbstractScalarFunction, S <: MOI.EqualTo}
    return 
end

function _add_dual_cone_constraint(dual_model::MOI.ModelLike, primal_model::MOI.ModelLike, vis::Vector{VI},
                                  ci::CI{F, S}) where {F <: MOI.AbstractVectorFunction, S <: MOI.AbstractVectorSet}
    return MOI.add_constraint(dual_model, VVF(vis), dual_set(get_set(primal_model, ci)))
end

function _add_dual_cone_constraint(dual_model::MOI.ModelLike, primal_model::MOI.ModelLike, vis::Vector{VI},
                                  ci::CI{F, S}) where {F <: MOI.AbstractVectorFunction, S <: MOI.Zeros}
    return 
end