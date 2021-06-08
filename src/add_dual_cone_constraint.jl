function add_dual_cone_constraint(
    dual_model::MOI.ModelLike,
    primal_model::MOI.ModelLike,
    ci::CI{F,S},
) where {F<:MOI.AbstractScalarFunction,S<:MOI.AbstractScalarSet}
    vi, con_index = MOI.add_constrained_variable(
        dual_model,
        _dual_set(get_set(primal_model, ci)),
    )
    return [vi], con_index
end

function add_dual_cone_constraint(
    dual_model::MOI.ModelLike,
    primal_model::MOI.ModelLike,
    ci::CI{F,MOI.EqualTo{T}},
) where {T,F<:MOI.AbstractScalarFunction}
    vi = MOI.add_variable(dual_model)
    return [vi], nothing
end

function add_dual_cone_constraint(
    dual_model::MOI.ModelLike,
    primal_model::MOI.ModelLike,
    ci::CI{F,S},
) where {F<:MOI.AbstractVectorFunction,S<:MOI.AbstractVectorSet}
    return MOI.add_constrained_variables(
        dual_model,
        _dual_set(get_set(primal_model, ci)),
    )
end

function add_dual_cone_constraint(
    dual_model::MOI.ModelLike,
    primal_model::MOI.ModelLike,
    ci::CI{F,MOI.Zeros},
) where {F<:MOI.AbstractVectorFunction}
    # Add as many variables as the dimension of the constraint
    vis = MOI.add_variables(dual_model, get_ci_row_dimension(primal_model, ci))
    return vis, nothing
end
