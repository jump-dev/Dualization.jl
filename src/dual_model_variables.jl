function add_dual_vars_in_dual_cones(dual_model::MOI.ModelLike, primal_model::MOI.ModelLike,
                                     primal_dual_map::PrimalDualMap{T}, dual_names::DualNames,
                                     con_types::Vector{Tuple{DataType, DataType}}) where T
    dual_obj_affine_terms = Dict{VI, T}()
    for (F, S) in con_types
        for ci in MOI.get(primal_model, MOI.ListOfConstraintIndices{F,S}()) # Constraints of type {F, S}
            # Add dual variable to dual cone
            # Fill a dual objective dictionary
            # Fill the primal_con_dual_var dictionary
            ci_dual = add_dual_variable(dual_model, primal_model, dual_names,
                                        primal_dual_map.primal_con_dual_var, dual_obj_affine_terms, ci)
            push_to_primal_con_dual_con!(primal_dual_map.primal_con_dual_con, ci, ci_dual)
            push_to_primal_con_constants!(primal_model, primal_dual_map.primal_con_constants, ci)
        end
    end
    return dual_obj_affine_terms
end

# Utils for primal_con_constants dict 
function push_to_primal_con_constants!(primal_model::MOI.ModelLike, primal_con_constants::Dict{CI, Vector{T}}, 
                                      ci::CI{F, S}) where {T, F <: MOI.AbstractScalarFunction, S <: MOI.AbstractScalarSet}
    push!(primal_con_constants, ci => get_scalar_term(primal_model, ci))
    return 
end

function push_to_primal_con_constants!(primal_model::MOI.ModelLike, primal_con_constants::Dict{CI, Vector{T}}, 
                                       ci::CI{F, S}) where {T, F <: MOI.AbstractVectorFunction, S <: MOI.AbstractVectorSet}
    return # No constants need to be passed to the DualOptimizer in this case, don't need to push zero to the dict
end

# Utils for primal_con_dual_con dict
function push_to_primal_con_dual_con!(primal_con_dual_con::Dict{CI, CI}, ci::CI, ci_dual::CI)
    push!(primal_con_dual_con, ci => ci_dual)
    return 
end

function push_to_primal_con_dual_con!(primal_con_dual_con::Dict{CI, CI}, ci::CI, ci_dual::Nothing)
    return # Don't put in the dict a nothing value
end

# Utils for dual_obj_affine_terms dict
function push_to_dual_obj_aff_terms!(primal_model::MOI.ModelLike, dual_obj_affine_terms::Dict{VI, T}, vi::VI,
                                     ci::CI{F, S}, i::Int) where {T, F <: MOI.AbstractFunction, S <: MOI.AbstractSet}
    value = get_scalar_term(primal_model, i, ci)
    if !iszero(value) # If value is different than 0 add to the dictionary
        push!(dual_obj_affine_terms, vi => value)
    end
    return 
end

function push_to_dual_obj_aff_terms!(primal_model::MOI.ModelLike, dual_obj_affine_terms::Dict{VI, T}, vi::VI,
                                     ci::CI{VVF, S}, i::Int) where {T, S <: MOI.AbstractSet}
    return # It is zero so don't push to the dual_obj_affine_terms
end

function _add_dual_variable(dual_model::MOI.ModelLike, primal_model::MOI.ModelLike, dual_names::DualNames,
                            primal_con_dual_var::Dict{CI, Vector{VI}}, dual_obj_affine_terms::Dict{VI, T},
                            ci::CI{F, S}) where {T, F <: MOI.AbstractFunction, 
                                                    S <: MOI.AbstractSet}

    # Change to add_constrained_varibales in MOI 0.9.0
    # because of https://github.com/guilhermebodin/Dualization.jl/issues/9
    vis = MOI.add_variables(dual_model, get_ci_row_dimension(primal_model, ci)) # Add as many variables as the dimension of the constraint
    push!(primal_con_dual_var, ci => vis) # Add the map of the added dual variable to the relationated constraint
    # Get constraint name
    ci_name = MOI.get(primal_model, MOI.ConstraintName(), ci)
    # Add each vi to the dictionary
    for (i, vi) in enumerate(vis)
        push_to_dual_obj_aff_terms!(primal_model, dual_obj_affine_terms, vi, ci, i)
        set_dual_variable_name(dual_model, vi, i, ci_name, 
                               dual_names.dual_variable_name_prefix)
    end
    return vis
end

function add_dual_variable(dual_model::MOI.ModelLike, primal_model::MOI.ModelLike, dual_names::DualNames,
                           primal_con_dual_var::Dict{CI, Vector{VI}}, dual_obj_affine_terms::Dict{VI, T},
                           ci::CI{F, S}) where {T, F <: MOI.AbstractFunction, 
                                                   S <: MOI.AbstractSet}
                                 
    vis = _add_dual_variable(dual_model, primal_model, dual_names,
                             primal_con_dual_var, dual_obj_affine_terms, ci)
    return add_dual_cone_constraint(dual_model, primal_model, vis, ci)
end

function set_dual_variable_name(dual_model::MOI.ModelLike, vi::VI, i::Int, ci_name::String, prefix::String)
    MOI.set(dual_model, MOI.VariableName(), vi, prefix*ci_name*"_$i")
    return 
end
