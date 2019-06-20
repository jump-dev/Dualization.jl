# # Equality constraints
# """
#         add_dualmodel_equality_constraints(dual_model::MOI.ModelLike, dict_constr_coeffs::Dict, 
#                                             dict_dualvar_primalcon::Dict, a0::Array{T, 1}) where T

# Add the dual model equality constraints
# """
# function add_dual_equality_constraints(dual_model::MOI.ModelLike, con_coeffs::Dict, 
#                                              dual_var_primal_con::Dict, primal_objective::PrimalObjective{T}, 
#                                              num_primal_var::Int) where T
    
#     dual_sense = MOI.get(dual_model, MOI.ObjectiveSense()) # Get dual model sense
#     primal_var_dual_con = Dict{VI, CI}() # Empty primal variables dual constraints Dict

#     scalar_term_index = 1::Int
#     for var = 1:num_primal_var
#         scalar_affine_terms = Vector{MOI.ScalarAffineTerm{T}}(undef, dual_model.num_variables_created) 
#         for con = 1:dual_model.num_variables_created # Number of constraints of the primal model (equalt number of variables of the dual)
#             vi = VI(con)
#             affine_term = con_coeffs[dual_var_primal_con[vi]][1][var] # Accessing Ai^T
#             scalar_affine_terms[con] = MOI.ScalarAffineTerm(affine_term, vi)
#         end
#         # Add constraint, the sense of a0 depends on the dual_model ObjectiveSense
#         # If max sense scalar term is -a0 and if min sense sacalar term is a0
#         if var == primal_objective.saf.terms[scalar_term_index].variable_index.value
#             scalar_term_value = primal_objective.saf.terms[scalar_term_index].coefficient
#             scalar_term_index += 1
#         else # In this case this variable is not on the objective function
#             scalar_term_value = zero(T)
#         end
#         scalar_term = (dual_sense == MOI.MAX_SENSE ? -1 : 1) * scalar_term_value
#         # Add primal variable to dual contraint to the link dictionary
#         push!(primal_var_dual_con, VI(var) => CI{SAF{T}, MOI.EqualTo}(dual_model.nextconstraintid))
#         # Add equality constraint
#         MOI.add_constraint(dual_model, MOI.ScalarAffineFunction(scalar_affine_terms, scalar_term), MOI.EqualTo(0.0))
#     end
#     return primal_var_dual_con
# end

function add_dual_vars_in_dual_cones(dual_model::MOI.ModelLike, primal_model::MOI.ModelLike, 
                                     con_types::Vector{Tuple{DataType, DataType}})
    dual_var_primal_con = Dict{VI, CI}()
    dual_obj_affine_terms = Dict{VI, Float64}()
    for (F, S) in con_types
        num_con_f_s = MOI.get(primal_model, MOI.NumberOfConstraints{F, S}()) # Number of constraints {F, S}
        for con_id = 1:num_con_f_s
            add_dual_variable(dual_model, primal_model, dual_var_primal_con, dual_obj_affine_terms, con_id, F, S)
        end
    end
    return dual_var_primal_con, dual_obj_affine_terms
end

# Utils for these functions
function push_to_dual_obj_aff_terms!(dual_obj_affine_terms::Dict{VI, T}, vi::VI, value::T) where T
    if iszero(value)
        return # don't push to the dict
    end
    return push!(dual_obj_affine_terms, vi => value)
end

function _add_dual_variable(dual_model::MOI.ModelLike, primal_model::MOI.ModelLike,
                            dual_var_primal_con:: Dict{VI, CI}, dual_obj_affine_terms::Dict{VI, T},
                            con_id::Int, 
                            F::Union{Type{SAF{T}}, Type{SVF}}, 
                            S::Union{Type{MOI.GreaterThan{T}},
                                     Type{MOI.LessThan{T}},
                                     Type{MOI.EqualTo{T}}}) where T
    
    ci = get_ci(primal_model, F, S, con_id)
    vi = MOI.add_variable(dual_model)
    push!(dual_var_primal_con, vi => ci) # Add the map of the added dual variable to the relationated constraint
    push_to_dual_obj_aff_terms!(dual_obj_affine_terms, vi, get_scalar_term(primal_model, con_id, F, S))
    return vi
end

function _add_dual_variable(dual_model::MOI.ModelLike, primal_model::MOI.ModelLike,
                            dual_var_primal_con:: Dict{VI, CI}, dual_obj_affine_terms::Dict{VI, T},
                            con_id::Int, 
                            F::Type{VAF{T}}, 
                            S::Union{Type{MOI.Nonpositives},
                                     Type{MOI.Nonnegatives},
                                     Type{MOI.Zeros}}) where T
    
    row_dimension = get_ci_row_dimension(primal_model, F, S, con_id) 
    ci = get_ci(primal_model, F, S, con_id)
    vis = MOI.add_variables(dual_model, row_dimension) # Add as many variables as the number of rows of the VAF
    # Add each vi to the dictionary
    i::Int = 1
    for vi in vis
        push!(dual_var_primal_con, vi => ci) # Add the map of the added dual variable to the relationated constraint
        push_to_dual_obj_aff_terms!(dual_obj_affine_terms, vi, get_scalar_term(primal_model, con_id, F, S)[i])
        i += 1
    end
    return vis
end


# SAFs
function add_dual_variable(dual_model::MOI.ModelLike, primal_model::MOI.ModelLike,
                           dual_var_primal_con:: Dict{VI, CI}, dual_obj_affine_terms::Dict{VI, T},
                           con_id::Int, F::Type{SAF{T}}, S::Type{MOI.GreaterThan{T}}) where T
                                 
    vi = _add_dual_variable(dual_model, primal_model, dual_var_primal_con, 
                            dual_obj_affine_terms, con_id, F, S)
    return MOI.add_constraint(dual_model, SVF(vi), MOI.GreaterThan(0.0)) # Add variable to the dual cone of the constraint
end

function add_dual_variable(dual_model::MOI.ModelLike, primal_model::MOI.ModelLike,
                           dual_var_primal_con:: Dict{VI, CI}, dual_obj_affine_terms::Dict{VI, T},
                           con_id::Int, F::Type{SAF{T}}, S::Type{MOI.LessThan{T}}) where T
                                 
    vi = _add_dual_variable(dual_model, primal_model, dual_var_primal_con, 
                            dual_obj_affine_terms, con_id, F, S)
    return MOI.add_constraint(dual_model, SVF(vi), MOI.LessThan(0.0)) # Add variable to the dual cone of the constraint
end

function add_dual_variable(dual_model::MOI.ModelLike, primal_model::MOI.ModelLike,
                           dual_var_primal_con:: Dict{VI, CI}, dual_obj_affine_terms::Dict{VI, T},
                           con_id::Int, F::Type{SAF{T}}, S::Type{MOI.EqualTo{T}}) where T
                            
    vi = _add_dual_variable(dual_model, primal_model, dual_var_primal_con, 
                            dual_obj_affine_terms, con_id, F, S)
    return # No constraint is added
end



#SVF
function add_dual_variable(dual_model::MOI.ModelLike, primal_model::MOI.ModelLike,
                           dual_var_primal_con:: Dict{VI, CI}, dual_obj_affine_terms::Dict{VI, T},
                           con_id::Int, F::Type{SVF}, S::Type{MOI.GreaterThan{T}}) where T

    vi = _add_dual_variable(dual_model, primal_model, dual_var_primal_con, 
                            dual_obj_affine_terms, con_id, F, S)
    return MOI.add_constraint(dual_model, SVF(vi), MOI.GreaterThan(0.0)) # Add variable to the dual cone of the constraint
end

function add_dual_variable(dual_model::MOI.ModelLike, primal_model::MOI.ModelLike,
                           dual_var_primal_con:: Dict{VI, CI}, dual_obj_affine_terms::Dict{VI, T}, 
                           con_id::Int, F::Type{SVF}, S::Type{MOI.LessThan{T}}) where T

    vi = _add_dual_variable(dual_model, primal_model, dual_var_primal_con, 
                            dual_obj_affine_terms, con_id, F, S)
    return MOI.add_constraint(dual_model, SVF(vi), MOI.LessThan(0.0)) # Add variable to the dual cone of the constraint
end

function add_dual_variable(dual_model::MOI.ModelLike, primal_model::MOI.ModelLike,
                           dual_var_primal_con:: Dict{VI, CI}, dual_obj_affine_terms::Dict{VI, T},
                           con_id::Int, F::Type{SVF}, S::Type{MOI.EqualTo{T}}) where T

    vi = _add_dual_variable(dual_model, primal_model, dual_var_primal_con, 
                            dual_obj_affine_terms, con_id, F, S)
    return # No constraint is added
end



#VAF
function add_dual_variable(dual_model::MOI.ModelLike, primal_model::MOI.ModelLike,
                           dual_var_primal_con:: Dict{VI, CI}, dual_obj_affine_terms::Dict{VI, T},
                           con_id::Int, F::Type{VAF{T}}, S::Type{MOI.Nonpositives}) where T

    vis = _add_dual_variable(dual_model, primal_model, dual_var_primal_con, 
                             dual_obj_affine_terms, con_id, F, S)
    return MOI.add_constraint(dual_model, VVF(vis), MOI.Nonpositives(length(vis))) # Add variable to the dual cone of the constraint
end

function add_dual_variable(dual_model::MOI.ModelLike, primal_model::MOI.ModelLike,
                           dual_var_primal_con:: Dict{VI, CI}, dual_obj_affine_terms::Dict{VI, T},
                           con_id::Int, F::Type{VAF{T}}, S::Type{MOI.Nonnegatives}) where T

    vis = _add_dual_variable(dual_model, primal_model, dual_var_primal_con, 
                             dual_obj_affine_terms, con_id, F, S)
    return MOI.add_constraint(dual_model, VVF(vis), MOI.Nonnegatives(length(vis))) # Add variable to the dual cone of the constraint
end

function add_dual_variable(dual_model::MOI.ModelLike, primal_model::MOI.ModelLike,
                           dual_var_primal_con:: Dict{VI, CI}, dual_obj_affine_terms::Dict{VI, T},
                           con_id::Int, F::Type{VAF{T}}, S::Type{MOI.Zeros}) where T

    vis = _add_dual_variable(dual_model, primal_model, dual_var_primal_con, 
                             dual_obj_affine_terms, con_id, F, S)
    return # Dual cone is reals
end