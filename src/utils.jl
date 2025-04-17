# Copyright (c) 2017: Guilherme Bodin, and contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

# Some useful wrappers

function _get_normalized_constant(
    model::MOI.ModelLike,
    ci::MOI.ConstraintIndex{MOI.VariableIndex,S},
) where {S<:MOI.AbstractScalarSet}
    return [-MOI.constant(MOI.get(model, MOI.ConstraintSet(), ci))]
end

function _get_normalized_constant(
    model::MOI.ModelLike,
    ci::MOI.ConstraintIndex{F,S},
) where {F<:MOI.AbstractScalarFunction,S<:MOI.AbstractScalarSet}
    return [
        MOI.constant(MOI.get(model, MOI.ConstraintFunction(), ci)) -
        MOI.constant(MOI.get(model, MOI.ConstraintSet(), ci)),
    ]
end

# This is used to fill the dual objective dictionary
function _get_normalized_constant(
    func::MOI.AbstractVectorFunction,
    ::MOI.AbstractVectorSet,
    i::Int,
)
    return MOI.constant(func)[i]
end

# This is used to fill the dual objective dictionary
function _get_normalized_constant(
    ::MOI.VariableIndex,
    set::MOI.AbstractScalarSet,
    i::Int,
)
    return -MOI.constant(set)
end

# This is used to fill the dual objective dictionary
function _get_normalized_constant(
    func::MOI.AbstractScalarFunction,
    set::MOI.AbstractScalarSet,
    i::Int,
)
    # In this case there i only one constant in the function and one in the set
    return MOI.constant(func) - MOI.constant(set)
end
