# Copyright (c) 2017: Guilherme Bodin, and contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

function _add_dual_vars_in_dual_cones(
    dual_obj_affine_terms::Dict{MOI.VariableIndex,T},
    dual_model::MOI.ModelLike,
    primal_model::MOI.ModelLike,
    primal_dual_map::PrimalDualMap{T},
    dual_names::DualNames,
    ::Type{F},
    ::Type{S},
) where {T,F,S}
    for ci in MOI.get(primal_model, MOI.ListOfConstraintIndices{F,S}())
        # If `F` not one of these two, we can skip the `haskey` check.
        if (F === MOI.VectorOfVariables || F === MOI.VariableIndex) &&
           haskey(primal_dual_map.primal_convarcon_to_dual_con, ci)
            # primal constraints that are the main constraints of
            # constrained variables have no dual variable associated
            # bacause they associated with dual constraints
            continue
        end
        # Add dual variable to dual cone
        # Fill a dual objective dictionary
        # Fill the primal_con_to_dual_var_vec dictionary
        ci_dual = _add_dual_variable(
            dual_model,
            primal_model,
            dual_names,
            primal_dual_map.primal_con_to_dual_var_vec,
            dual_obj_affine_terms,
            ci,
        )
        if ci_dual !== nothing
            primal_dual_map.primal_con_to_dual_convarcon[ci] = ci_dual
        end
        _cache_primal_constraint_constant!(
            primal_model,
            primal_dual_map.primal_con_to_primal_constants_vec,
            ci,
        )
    end
    return
end

# barrier function
function _add_dual_vars_in_dual_cones(
    dual_model::MOI.ModelLike,
    primal_model::MOI.ModelLike,
    primal_dual_map::PrimalDualMap{T},
    dual_names::DualNames,
    con_types::Vector{Tuple{Type,Type}},
) where {T}
    dual_obj_affine_terms = Dict{MOI.VariableIndex,T}()
    for (F, S) in con_types
        _add_dual_vars_in_dual_cones(
            dual_obj_affine_terms,
            dual_model,
            primal_model,
            primal_dual_map,
            dual_names,
            F,
            S,
        )
    end
    return dual_obj_affine_terms
end

# Utils for primal_con_to_primal_constants_vec dict
function _cache_primal_constraint_constant!(
    primal_model::MOI.ModelLike,
    primal_con_to_primal_constants_vec::Dict{MOI.ConstraintIndex,Vector{T}},
    ci::MOI.ConstraintIndex{F,S},
) where {T,F<:MOI.AbstractScalarFunction,S<:MOI.AbstractScalarSet}
    primal_con_to_primal_constants_vec[ci] =
        _get_normalized_constant(primal_model, ci)
    return
end

function _cache_primal_constraint_constant!(
    primal_model::MOI.ModelLike,
    primal_con_to_primal_constants_vec::Dict{MOI.ConstraintIndex,Vector{T}},
    ci::MOI.ConstraintIndex{F,S},
) where {T,F<:MOI.AbstractVectorFunction,S<:MOI.AbstractVectorSet}
    # No constants need to be passed to the DualOptimizer in this case,
    # because the VectorSet's do not have constants inside them that
    # will need to be used in result queries as some ScalarSet's might.
    # Hence, don't need to push zero to the dict.
    return
end

function _add_dual_variable(
    dual_model::MOI.ModelLike,
    primal_model::MOI.ModelLike,
    dual_names::DualNames,
    primal_con_to_dual_var_vec::Dict{
        MOI.ConstraintIndex,
        Vector{MOI.VariableIndex},
    },
    dual_obj_affine_terms::Dict{MOI.VariableIndex,T},
    ci::MOI.ConstraintIndex{F,S},
) where {T,F<:MOI.AbstractFunction,S<:MOI.AbstractSet}
    vis, con_index = _add_dual_cone_constraint(dual_model, primal_model, ci)
    # Add the map of the added dual variable to the relationated constraint
    primal_con_to_dual_var_vec[ci] = vis
    # Get constraint name
    ci_name = MOI.get(primal_model, MOI.ConstraintName(), ci)
    # Add each vi to the dictionary
    func = MOI.get(primal_model, MOI.ConstraintFunction(), ci)
    set = MOI.get(primal_model, MOI.ConstraintSet(), ci)
    for (i, vi) in enumerate(vis)
        if !(F <: MOI.VectorOfVariables)
            value = set_dot(i, set, T) * _get_normalized_constant(func, set, i)
            if !iszero(value)
                dual_obj_affine_terms[vi] = value
            end
        end
        if !is_empty(dual_names) && !isempty(ci_name)
            pre = dual_names.dual_variable_name_prefix
            MOI.set(dual_model, MOI.VariableName(), vi, pre * ci_name * "_$i")
        end
    end
    return con_index
end

function _add_primal_parameter_vars(
    dual_model::MOI.ModelLike,
    primal_model::MOI.ModelLike,
    primal_dual_map::PrimalDualMap{T},
    dual_names::DualNames,
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
    for i in eachindex(vis)
        primal_dual_map.primal_parameter_to_dual_parameter[parameters[i]] =
            vis[i]
        if !is_empty(dual_names)
            vi_name = MOI.get(primal_model, MOI.VariableName(), parameters[i])
            _set_parameter_variable_name(
                dual_model,
                vis[i],
                vi_name,
                dual_names,
            )
        end
    end
    return
end

# Add name to parameter variable
function _set_parameter_variable_name(
    dual_model::MOI.ModelLike,
    vi::MOI.VariableIndex,
    vi_name::String,
    dual_names,
)
    prefix =
        dual_names.parameter_name_prefix == "" ? "param_" :
        dual_names.parameter_name_prefix
    MOI.set(dual_model, MOI.VariableName(), vi, prefix * vi_name)
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
                #do nothing
            else
                push!(added, ind)
                vi = MOI.add_variable(dual_model)
                primal_dual_map.primal_var_in_quad_obj_to_dual_slack_var[ind] =
                    vi
                if !is_empty(dual_names)
                    vi_name = MOI.get(primal_model, MOI.VariableName(), ind)
                    _set_quad_slack_name(dual_model, vi, vi_name, dual_names)
                end
            end
        end
    end
    return
end

# set name for dual quadratic slack
function _set_quad_slack_name(
    dual_model::MOI.ModelLike,
    vi::MOI.VariableIndex,
    vi_name::String,
    dual_names,
)
    prefix = if dual_names.quadratic_slack_name_prefix == ""
        "quadslack_"
    else
        dual_names.quadratic_slack_name_prefix
    end
    MOI.set(dual_model, MOI.VariableName(), vi, prefix * vi_name)
    return
end
