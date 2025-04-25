# Copyright (c) 2017: Guilherme Bodin, and contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

function _select_constrained_variables(
    dual_problem,
    primal_model,
    variable_parameters,
)
    single_or_vector_variables_types =
        MOI.Utilities.sorted_variable_sets_by_cost(
            dual_problem.dual_model,
            primal_model,
        )
    params = Set(variable_parameters)
    selected_variables = Set{MOI.VariableIndex}()
    for S in single_or_vector_variables_types
        _select_constrained_variables(
            dual_problem.primal_dual_map,
            primal_model,
            S,
            params,
            selected_variables,
        )
    end
    return
end

# Function barrier for the type instability of `F` and `S`.
function _select_constrained_variables(
    m::PrimalDualMap{T},
    primal_model,
    ::Type{S},
    params,
    selected_variables,
) where {T,S<:MOI.AbstractVectorSet}
    cis = MOI.get(
        primal_model,
        MOI.ListOfConstraintIndices{MOI.VectorOfVariables,S}(),
    )
    for ci in cis
        f = MOI.get(primal_model, MOI.ConstraintFunction(), ci)
        # try to add variables as constrained variables
        if all(
            # no element of the VectorOfVariables is a constrained variable
            # and not a parameter
            vi -> !(vi in selected_variables) && !(vi in params),
            f.variables,
        )
            m.primal_constrained_variables[ci] = f.variables
            for vi in f.variables
                push!(selected_variables, vi)
            end
        end
    end
    return
end

function _select_constrained_variables(
    m::PrimalDualMap{T},
    primal_model,
    ::Type{S},
    params,
    selected_variables,
) where {T,S<:MOI.AbstractScalarSet}
    cis = MOI.get(
        primal_model,
        MOI.ListOfConstraintIndices{MOI.VariableIndex,S}(),
    )
    for ci in cis
        vi = MOI.get(primal_model, MOI.ConstraintFunction(), ci)
        # no element of the VectorOfVariables is a constrained variable
        # and not a parameter
        if !(vi in selected_variables) && !(vi in params)
            set = MOI.get(primal_model, MOI.ConstraintSet(), ci)
            if !iszero(MOI.constant(set))
                continue
            end
            m.primal_constrained_variables[ci] = [vi]
            push!(selected_variables, vi)
        end
    end
    return
end
