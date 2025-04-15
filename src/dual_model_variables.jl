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
        # If `F` not one of these two, we can skip the `in` check.
        if (F === MOI.VectorOfVariables || F === MOI.VariableIndex) &&
           haskey(primal_dual_map.primal_convarcon_to_dual_con, ci)
            continue
        end
        # Add dual variable to dual cone
        # Fill a dual objective dictionary
        # Fill the primal_con_to_dual_var_vec dictionary
        ci_dual = add_dual_variable(
            dual_model,
            primal_model,
            dual_names,
            primal_dual_map.primal_con_to_dual_var_vec,
            dual_obj_affine_terms,
            ci,
        )
        push_to_primal_con_to_dual_convarcon!(
            primal_dual_map.primal_con_to_dual_convarcon,
            ci,
            ci_dual,
        )
        push_to_primal_con_to_primal_constants_vec!(
            primal_model,
            primal_dual_map.primal_con_to_primal_constants_vec,
            ci,
        )
    end
    return
end

function add_dual_vars_in_dual_cones(
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
function push_to_primal_con_to_primal_constants_vec!(
    primal_model::MOI.ModelLike,
    primal_con_to_primal_constants_vec::Dict{MOI.ConstraintIndex,Vector{T}},
    ci::MOI.ConstraintIndex{F,S},
) where {T,F<:MOI.AbstractScalarFunction,S<:MOI.AbstractScalarSet}
    push!(primal_con_to_primal_constants_vec, ci => get_scalar_term(primal_model, ci))
    return
end

function push_to_primal_con_to_primal_constants_vec!(
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

# Utils for primal_con_to_dual_convarcon dict
function push_to_primal_con_to_dual_convarcon!(
    primal_con_to_dual_convarcon::Dict{MOI.ConstraintIndex,MOI.ConstraintIndex},
    ci::MOI.ConstraintIndex,
    ci_dual::MOI.ConstraintIndex,
)
    push!(primal_con_to_dual_convarcon, ci => ci_dual)
    return
end

function push_to_primal_con_to_dual_convarcon!(
    primal_con_to_dual_convarcon::Dict{MOI.ConstraintIndex,MOI.ConstraintIndex},
    ci::MOI.ConstraintIndex,
    ci_dual::Nothing,
)
    return # Don't put in the dict a nothing value
end

# Utils for dual_obj_affine_terms dict
function push_to_dual_obj_aff_terms!(
    primal_model::MOI.ModelLike,
    dual_obj_affine_terms::Dict{MOI.VariableIndex,T},
    vi::MOI.VariableIndex,
    func::MOI.AbstractFunction,
    set::MOI.AbstractSet,
    i::Int,
) where {T}
    value = set_dot(i, set, T) * get_scalar_term(func, set, i)
    if !iszero(value) # If value is different than 0 add to the dictionary
        push!(dual_obj_affine_terms, vi => value)
    end
    return
end

function push_to_dual_obj_aff_terms!(
    ::MOI.ModelLike,
    ::Dict{MOI.VariableIndex},
    ::MOI.VariableIndex,
    ::MOI.VectorOfVariables,
    ::MOI.AbstractVectorSet,
    i::Int,
)
    return # It is zero so don't push to the dual_obj_affine_terms
end

function add_dual_variable(
    dual_model::MOI.ModelLike,
    primal_model::MOI.ModelLike,
    dual_names::DualNames,
    primal_con_to_dual_var_vec::Dict{MOI.ConstraintIndex,Vector{MOI.VariableIndex}},
    dual_obj_affine_terms::Dict{MOI.VariableIndex,T},
    ci::MOI.ConstraintIndex{F,S},
) where {T,F<:MOI.AbstractFunction,S<:MOI.AbstractSet}
    vis, con_index = add_dual_cone_constraint(dual_model, primal_model, ci)
    # Add the map of the added dual variable to the relationated constraint
    push!(primal_con_to_dual_var_vec, ci => vis)
    # Get constraint name
    ci_name = MOI.get(primal_model, MOI.ConstraintName(), ci)
    # Add each vi to the dictionary
    func = get_function(primal_model, ci)
    set = get_set(primal_model, ci)
    for (i, vi) in enumerate(vis)
        push_to_dual_obj_aff_terms!(
            primal_model,
            dual_obj_affine_terms,
            vi,
            func,
            set,
            i,
        )
        if !is_empty(dual_names)
            set_dual_variable_name(
                dual_model,
                vi,
                i,
                ci_name,
                dual_names.dual_variable_name_prefix,
            )
        end
    end
    return con_index
end

function set_dual_variable_name(
    dual_model::MOI.ModelLike,
    vi::MOI.VariableIndex,
    i::Int,
    ci_name::String,
    prefix::String,
)
    isempty(ci_name) && return
    MOI.set(dual_model, MOI.VariableName(), vi, prefix * ci_name * "_$i")
    return
end

function add_primal_parameter_vars(
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
    if ignore_objective
        # only crossed terms (parameter times primal variable) of the objective
        # are required
        added = Set{MOI.VariableIndex}()
        for vec in values(primal_objective.quad_cross_parameters)
            for term in vec
                ind = term.variable
                if ind in added
                    # do nothing
                else
                    push!(added, ind)
                    vi = MOI.add_variable(dual_model)
                    push_to_primal_parameter_to_dual_parameter!(
                        primal_dual_map.primal_parameter_to_dual_parameter,
                        ind,
                        vi,
                    )
                    # set name
                    if !is_empty(dual_names)
                        vi_name = MOI.get(primal_model, MOI.VariableName(), ind)
                        set_parameter_variable_name(
                            dual_model,
                            vi,
                            vi_name,
                            dual_names,
                        )
                    end
                end
            end
        end
    elseif length(variable_parameters) > 0
        vis = MOI.add_variables(dual_model, length(variable_parameters))
        for i in eachindex(vis)
            push_to_primal_parameter_to_dual_parameter!(
                primal_dual_map.primal_parameter_to_dual_parameter,
                variable_parameters[i],
                vis[i],
            )
            if !is_empty(dual_names)
                vi_name = MOI.get(
                    primal_model,
                    MOI.VariableName(),
                    variable_parameters[i],
                )
                set_parameter_variable_name(
                    dual_model,
                    vis[i],
                    vi_name,
                    dual_names,
                )
            end
        end
    end
    return
end

# Save mapping between primal parameter and dual parameter
function push_to_primal_parameter_to_dual_parameter!(
    primal_parameter_to_dual_parameter::Dict{MOI.VariableIndex,MOI.VariableIndex},
    vi::MOI.VariableIndex,
    vi_dual::MOI.VariableIndex,
)
    push!(primal_parameter_to_dual_parameter, vi => vi_dual)
    return
end

# Add name to parameter variable
function set_parameter_variable_name(
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

function add_quadratic_slack_vars(
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
                push_to_quad_slack!(
                    primal_dual_map.primal_var_in_quad_obj_to_dual_slack_var,
                    ind,
                    vi,
                )
                # set name
                if !is_empty(dual_names)
                    vi_name = MOI.get(primal_model, MOI.VariableName(), ind)
                    set_quad_slack_name(dual_model, vi, vi_name, dual_names)
                end
            end
        end
    end
    return
end

# Save mapping between primal variable and dual quadratic slack
function push_to_quad_slack!(
    dual_quad_slack::Dict{MOI.VariableIndex,MOI.VariableIndex},
    vi::MOI.VariableIndex,
    vi_dual::MOI.VariableIndex,
)
    push!(dual_quad_slack, vi => vi_dual)
    return
end

# set name for dual quadratic slack
function set_quad_slack_name(
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
