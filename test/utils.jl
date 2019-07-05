function dual_model_and_map(primal_model::MOI.ModelLike)
    dual = Dualization.dualize(primal_model)
    return dual.dual_model, dual.primal_dual_map
end