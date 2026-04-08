# Dualization handles scalar constraints like `f(x) >= lb` in a way that's equivalent
# to applying a `MOI.Bridges.Constraint.VectorizeBridge`. That is, it is equivalent to
# transforming it into `[f(x) - lb] in MOI.Nonnegatives(1)`.
# For packages that define custom attributes, to avoid having them to deal with both
# defining how it should go through the vectorize bridge and for a scalar constraint
# in a dualization layer, we just use the vectorize bridge implementation here:
# This also help us get the mechanism that detect if it is a ray or not.
# It's getting quite hacky, maybe we should just drop support for scalar constraint
# in Dualization and rely on a bridge layer.

struct _AfterVectorize{T,OT,F,S} <: MOI.ModelLike
    inner::DualOptimizer{T,OT}
    inner_ci::MOI.ConstraintIndex{F,S}
end

# Vectorize bridge uses this to check if it is a ray or not
function MOI.get(av::_AfterVectorize, attr::MOI.AbstractModelAttribute)
    return MOI.get(av.inner, attr)
end

function _vectorize_bridge(
    ::Type{MOI.Bridges.Constraint.VectorizeBridge{T,F,S,G}},
    constant,
) where {T,F,S,G}
    dummy_ci = MOI.ConstraintIndex{F,S}(1)
    return MOI.Bridges.Constraint.VectorizeBridge{T,F,S,G}(dummy_ci, constant)
end

function _wrap(optimizer::DualOptimizer, ci::MOI.ConstraintIndex)
    return _AfterVectorize(optimizer, ci), ci
end

function _wrap(optimizer::DualOptimizer{T}, ci::MOI.ConstraintIndex{F,S}) where {T,F<:MOI.AbstractScalarFunction,S<:MOI.Utilities.ScalarLinearSet}
    model = _AfterVectorize(optimizer, ci)
    primal_dual_map = optimizer.dual_problem.primal_dual_map
    data = get(primal_dual_map.primal_constraint_data, ci, nothing)
    if !isnothing(data)
        constant = data.primal_set_constants[]
        BT = MOI.Bridges.Constraint.concrete_bridge_type(
            MOI.Bridges.Constraint.VectorizeBridge{T},
            F,
            S,
        )
        ci = _vectorize_bridge(BT, -constant)
    end
    return model, ci
end

function MOI.set(
    optimizer::DualOptimizer,
    attr::MOI.AbstractConstraintAttribute,
    ci::MOI.ConstraintIndex,
    value,
)
    model, new_ci = _wrap(optimizer, ci)
    return MOI.set(model, attr, new_ci, value)
end

function MOI.get(
    optimizer::DualOptimizer,
    attr::MOI.AbstractConstraintAttribute,
    ci::MOI.ConstraintIndex,
)
    model, new_ci = _wrap(optimizer, ci)
    return MOI.get(model, attr, new_ci)
end
