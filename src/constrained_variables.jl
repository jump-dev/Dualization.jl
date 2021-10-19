function add_constrained_variables(dual_problem, primal_model, variable_parameters)
    single_or_vector_variables_types = MOIU.sorted_variable_sets_by_cost(dual_problem.dual_model, primal_model)
    params = Set(variable_parameters)
    for (F, S) in single_or_vector_variables_types
        if F === MOI.VectorOfVariables
            _add_constrained_variables(dual_problem.primal_dual_map, primal_model, S, params)
        elseif F === MOI.SingleVariable
            _add_constrained_variable(dual_problem.primal_dual_map, primal_model, S, params)
        end
    end
end
const NO_CONSTRAINT = CI{Nothing,Nothing}(0)
# Function barrier for the type unstability of `F` and `S`.
function _add_constrained_variables(m::PrimalDualMap, primal_model, ::Type{S}, params) where {S<:MOI.AbstractVectorSet}
    cis = MOI.get(primal_model, MOI.ListOfConstraintIndices{MOI.VectorOfVariables,S}())
    for ci in cis
        f = MOI.get(primal_model, MOI.ConstraintFunction(), ci)
        if all(vi -> !haskey(m.constrained_var_idx, vi) && !(vi in params), f.variables)
            for (i, vi) in enumerate(f.variables)
                m.constrained_var_idx[vi] = (ci, i)
            end
            # Placeholder to indicate this constraint is part of constrained variables,
            # it will be replaced later with a dual constraints
            m.constrained_var_dual[ci] = NO_CONSTRAINT
        end
    end
end
function _add_constrained_variable(m::PrimalDualMap, primal_model, ::Type{S}, params) where {S<:MOI.AbstractScalarSet}
    cis = MOI.get(primal_model, MOI.ListOfConstraintIndices{MOI.SingleVariable,S}())
    for ci in cis
        f = MOI.get(primal_model, MOI.ConstraintFunction(), ci)
        if !haskey(m.constrained_var_idx, f.variable) && !(f.variable in params)
            set = MOI.get(primal_model, MOI.ConstraintSet(), ci)
            if !iszero(MOI.constant(set))
                continue
            end
            m.constrained_var_idx[f.variable] = (ci, 1)
            # Placeholder to indicate this constraint is part of constrained variables,
            # it will be replaced later with a dual constraints
            m.constrained_var_dual[ci] = CI{Nothing,Nothing}(0)
        end
    end
end
