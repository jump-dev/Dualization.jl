# Copyright (c) 2017: Guilherme Bodin, and contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

# barrier function
function _add_dual_vars_in_dual_cones(
    dual_model::MOI.ModelLike,
    primal_model::MOI.ModelLike,
    primal_dual_map::PrimalDualMap{T},
    dual_names::DualNames,
    con_types::Vector{Tuple{Type,Type}},
    variable_parameters,
) where {T}
    dual_obj_affine_terms = Dict{MOI.VariableIndex,T}()
    parameters_set = Set(variable_parameters)
    for (F, S) in con_types
        _add_dual_vars_in_dual_cones(
            dual_obj_affine_terms,
            dual_model,
            primal_model,
            primal_dual_map,
            dual_names,
            F,
            S,
            parameters_set,
        )
    end
    return dual_obj_affine_terms
end

function _add_dual_vars_in_dual_cones(
    dual_obj_affine_terms::Dict{MOI.VariableIndex,T},
    dual_model::MOI.ModelLike,
    primal_model::MOI.ModelLike,
    primal_dual_map::PrimalDualMap{T},
    dual_names::DualNames,
    ::Type{F},
    ::Type{S},
    parameters_set,
) where {T,F,S}
    for ci in MOI.get(primal_model, MOI.ListOfConstraintIndices{F,S}())
        # If `F` not one of these two, we can skip the `haskey` check.
        if haskey(primal_dual_map.primal_constrained_variables, ci) ||
           # primal constraints that are the main constraints of
           # constrained variables have no dual variable associated
           # bacause they associated with dual constraints
           (
            F <: MOI.VariableIndex &&
            MOI.get(primal_model, MOI.ConstraintFunction(), ci) in
            parameters_set
        )
            # if a parameter is constrained, either because the set is
            # Parameter or because it was user defined parameter its constraint
            # will lead to a useless dual variable.
            continue
        end
        # Add dual variable to dual cone
        # Fill a dual objective dictionary
        # Fill the primal_dual_map info
        _add_dual_variable(
            dual_model,
            primal_model,
            dual_names,
            primal_dual_map,
            dual_obj_affine_terms,
            ci,
        )
    end
    return
end

function _add_dual_variable(
    dual_model::MOI.ModelLike,
    primal_model::MOI.ModelLike,
    dual_names::DualNames,
    primal_dual_map::PrimalDualMap,
    dual_obj_affine_terms::Dict{MOI.VariableIndex,T},
    ci::MOI.ConstraintIndex{F,S},
) where {T,F<:MOI.AbstractFunction,S<:MOI.AbstractSet}
    vis, con_index = _add_dual_cone_constraint(dual_model, primal_model, ci)
    # Add the map of the added dual variable to the relationated constraint
    set_constant = if F <: MOI.AbstractScalarFunction
        _get_normalized_constant(primal_model, ci)
    else
        T[]
    end
    primal_dual_map.primal_constraint_data[ci] =
        PrimalConstraintData(set_constant, vis, con_index)
    # Get constraint name
    ci_name = MOI.get(primal_model, MOI.ConstraintName(), ci)
    # Add each vi to the dictionary
    func = MOI.get(primal_model, MOI.ConstraintFunction(), ci)
    set = MOI.get(primal_model, MOI.ConstraintSet(), ci)
    is_unique_var = length(vis) == 1
    for (i, vi) in enumerate(vis)
        if !(F <: MOI.VectorOfVariables)
            value = set_dot(i, set, T) * _get_normalized_constant(func, set, i)
            if !iszero(value)
                dual_obj_affine_terms[vi] = value
            end
        end
        if !is_empty(dual_names) && !isempty(ci_name)
            pre = dual_names.dual_variable_name_prefix
            pos = is_unique_var ? "" : "_$i"
            MOI.set(dual_model, MOI.VariableName(), vi, pre * ci_name * pos)
        end
    end
    return
end

function _add_primal_parameter_vars(
    dual_model::MOI.ModelLike,
    primal_model::MOI.ModelLike,
    primal_dual_map::PrimalDualMap{T},
    dual_names::DualNames,
    moi_parameter_sets::Dict{MOI.VariableIndex,MOI.Parameter{T}},
    variable_parameters::Vector{MOI.VariableIndex},
    primal_objective,
    ignore_objective::Bool,
) where {T}
    # if objective is ignored we only need parameters that appear in the
    # quadratic objective
    parameters = if ignore_objective
        # only crossed terms (parameter times primal variable) of the objective
        # are required
        to_add = Set{MOI.VariableIndex}()
        for vec in values(primal_objective.quad_cross_parameters)
            for term in vec
                push!(to_add, term.variable)
            end
        end
        collect(to_add)
    else
        variable_parameters
    end
    vis = MOI.add_variables(dual_model, length(parameters))

    moi_parameters = keys(moi_parameter_sets)
    for i in eachindex(vis)
        pvi = parameters[i]
        dvi = vis[i]

        if pvi in moi_parameters
            MOI.add_constraint(dual_model, dvi, moi_parameter_sets[pvi])
        end
        primal_dual_map.primal_parameter_to_dual_parameter[pvi] = dvi
        if !is_empty(dual_names)
            pvi_name = MOI.get(primal_model, MOI.VariableName(), pvi)
            prefix =
                dual_names.parameter_name_prefix == "" ? "param_" :
                dual_names.parameter_name_prefix
            MOI.set(dual_model, MOI.VariableName(), dvi, prefix * pvi_name)
        end
    end
    return
end

function _add_quadratic_slack_vars(
    dual_model::MOI.ModelLike,
    primal_model::MOI.ModelLike,
    primal_dual_map::PrimalDualMap{T},
    dual_names::DualNames,
    primal_objective,
) where {T}
    # only main quadratic terms (primal variable times primal variable)
    # of the objective are required
    added = Set{MOI.VariableIndex}()
    for term in primal_objective.obj.quadratic_terms
        for ind in [term.variable_1, term.variable_2]
            if ind in added
                continue
            end
            push!(added, ind)
            vi = MOI.add_variable(dual_model)
            primal_dual_map.primal_var_in_quad_obj_to_dual_slack_var[ind] = vi
            if !is_empty(dual_names)
                name = MOI.get(primal_model, MOI.VariableName(), ind)
                prefix =
                    dual_names.quadratic_slack_name_prefix == "" ?
                    "quadslack_" : dual_names.quadratic_slack_name_prefix
                MOI.set(dual_model, MOI.VariableName(), vi, prefix * name)
            end
        end
    end
    return
end
