# Copyright (c) 2017: Guilherme Bodin, and contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

"""
    _add_dual_cone_constraint(primal_model, dual_model, ci)

Add variables to the dual models. These variables are associated with primal
constraints. If the primal constraint is of type
function-in-`MOI.Zeros` or function-in-`MOI.EqualTo(zero(T))`, then the dual
variable are unconstrained. Otherwise, the dual variables are created as
constrained variables in the dual model.

The function returns a tuple: the first element is a vector dual variables,
and the second element is the constraint index of the dual constraint. If the
dual variable in not a constrained variable, the second element is `nothing`.
"""
function _add_dual_cone_constraint(
    dual_model::MOI.ModelLike,
    primal_model::MOI.ModelLike,
    ci::MOI.ConstraintIndex{F,S},
) where {F<:MOI.AbstractScalarFunction,S<:MOI.AbstractScalarSet}
    vi, con_index = MOI.add_constrained_variable(
        dual_model,
        _dual_set(MOI.get(primal_model, MOI.ConstraintSet(), ci)),
    )
    return [vi], con_index
end

function _add_dual_cone_constraint(
    dual_model::MOI.ModelLike,
    ::MOI.ModelLike,
    ci::MOI.ConstraintIndex{F,MOI.EqualTo{T}},
) where {T,F<:MOI.AbstractScalarFunction}
    vi = MOI.add_variable(dual_model)
    return [vi], nothing
end

function _add_dual_cone_constraint(
    dual_model::MOI.ModelLike,
    primal_model::MOI.ModelLike,
    ci::MOI.ConstraintIndex{F,S},
) where {F<:MOI.AbstractVectorFunction,S<:MOI.AbstractVectorSet}
    return MOI.add_constrained_variables(
        dual_model,
        _dual_set(MOI.get(primal_model, MOI.ConstraintSet(), ci)),
    )
end

function _add_dual_cone_constraint(
    dual_model::MOI.ModelLike,
    primal_model::MOI.ModelLike,
    ci::MOI.ConstraintIndex{F,MOI.Zeros},
) where {F<:MOI.AbstractVectorFunction}
    # Add as many variables as the dimension of the constraint
    dim = MOI.output_dimension(
        MOI.get(primal_model, MOI.ConstraintFunction(), ci),
    )
    vis = MOI.add_variables(dual_model, dim)
    return vis, nothing
end
