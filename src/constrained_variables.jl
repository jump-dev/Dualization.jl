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
    for S in single_or_vector_variables_types
        _select_constrained_variables(
            dual_problem.primal_dual_map,
            primal_model,
            S,
            params,
        )
    end
    return
end

const NO_CONSTRAINT = MOI.ConstraintIndex{Nothing,Nothing}(0)

# Function barrier for the type instability of `F` and `S`.
function _select_constrained_variables(
    m::PrimalDualMap,
    primal_model,
    ::Type{S},
    params,
) where {S<:MOI.AbstractVectorSet}
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
            vi ->
                !haskey(m.primal_convar_to_primal_convarcon_and_index, vi) &&
                !(vi in params),
            f.variables,
        )
            for (i, vi) in enumerate(f.variables)
                m.primal_convar_to_primal_convarcon_and_index[vi] = (ci, i)
            end
            # Placeholder to indicate this constraint is part of constrained variables,
            # it will be replaced later with a dual constraints
            m.primal_convarcon_to_dual_con[ci] = NO_CONSTRAINT
        end
    end
    return
end

function _select_constrained_variables(
    m::PrimalDualMap,
    primal_model,
    ::Type{S},
    params,
) where {S<:MOI.AbstractScalarSet}
    cis = MOI.get(
        primal_model,
        MOI.ListOfConstraintIndices{MOI.VariableIndex,S}(),
    )
    for ci in cis
        f = MOI.get(primal_model, MOI.ConstraintFunction(), ci)
        # no element of the VectorOfVariables is a constrained variable
        # and not a parameter
        if !haskey(m.primal_convar_to_primal_convarcon_and_index, f) &&
           !(f in params)
            set = MOI.get(primal_model, MOI.ConstraintSet(), ci)
            if !iszero(MOI.constant(set))
                continue
            end
            m.primal_convar_to_primal_convarcon_and_index[f] = (ci, 1)
            # Placeholder to indicate this constraint is part of constrained variables,
            # it will be replaced later with a dual constraints
            m.primal_convarcon_to_dual_con[ci] = NO_CONSTRAINT
        end
    end
    return
end
