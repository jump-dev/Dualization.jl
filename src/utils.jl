# Copyright (c) 2017: Guilherme Bodin, and contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

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

function get_scalar_term(
    model::MOI.ModelLike,
    ci::CI{VI,S},
) where {S<:MOI.AbstractScalarSet}
    return [-MOI.constant(get_set(model, ci))]
end

function get_scalar_term(
    model::MOI.ModelLike,
    ci::CI{F,S},
) where {F<:MOI.AbstractScalarFunction,S<:MOI.AbstractScalarSet}
    return [
        MOI.constant(get_function(model, ci)) -
        MOI.constant(get_set(model, ci)),
    ]
end

# This is used to fill the dual objective dictionary
function get_scalar_term(
    func::MOI.AbstractVectorFunction,
    ::MOI.AbstractVectorSet,
    i::Int,
)
    return MOI.constant(func)[i]
end

# This is used to fill the dual objective dictionary
function get_scalar_term(
    ::MOI.VariableIndex,
    set::MOI.AbstractScalarSet,
    i::Int,
)
    return -MOI.constant(set)
end

# This is used to fill the dual objective dictionary
function get_scalar_term(
    func::MOI.AbstractScalarFunction,
    set::MOI.AbstractScalarSet,
    i::Int,
)
    # In this case there i only one constant in the function and one in the set
    return MOI.constant(func) - MOI.constant(set)
end
