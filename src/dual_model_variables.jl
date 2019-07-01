function add_dual_vars_in_dual_cones(dual_model::MOI.ModelLike, primal_model::MOI.ModelLike, 
                                     con_types::Vector{Tuple{DataType, DataType}}, T::DataType)
    primal_con_dual_var = Dict{CI, Vector{VI}}()
    dual_obj_affine_terms = Dict{VI, T}()
    for (F, S) in con_types
        (F, S) = con_types[2]
        primal_cis = MOI.get(primal_model, MOI.ListOfConstraintIndices{F,S}()) # Constraints of type {F, S}
        for ci in primal_cis
            # Add dual variable to dual cone
            # Fill a dual objective dictionary
            # Fill the primal_con_dual_var dictionary
            add_dual_variable(dual_model, primal_model, primal_con_dual_var, dual_obj_affine_terms, ci)
        end
    end
    return primal_con_dual_var, dual_obj_affine_terms
end

# Utils for add_dual_variable functions
function push_to_dual_obj_aff_terms!(dual_obj_affine_terms::Dict{VI, T}, vi::VI, value::T) where T
    if !iszero(value) # If value is different than 0 add to the dictionary
        push!(dual_obj_affine_terms, vi => value)
    end
    return 
end

function _add_dual_variable(dual_model::MOI.ModelLike, primal_model::MOI.ModelLike,
                            primal_con_dual_var::Dict{CI, Vector{VI}}, dual_obj_affine_terms::Dict{VI, T},
                            ci::CI{F, S}) where {T, F <: MOI.AbstractFunction, 
                                                    S <: MOI.AbstractSet}

    row_dimension = get_ci_row_dimension(primal_model, ci) 
    vis = MOI.add_variables(dual_model, row_dimension) # Add as many variables as the dimension of the constraint
    push!(primal_con_dual_var, ci => vis) # Add the map of the added dual variable to the relationated constraint
    # Add each vi to the dictionary
    i::Int = 1
    for vi in vis
        push_to_dual_obj_aff_terms!(dual_obj_affine_terms, vi, get_scalar_term(primal_model, ci, T)[i])
        i += 1
    end
    return vis
end


function add_dual_variable(dual_model::MOI.ModelLike, primal_model::MOI.ModelLike,
                           primal_con_dual_var::Dict{CI, Vector{VI}}, dual_obj_affine_terms::Dict{VI, T},
                           ci::CI{F, S}) where {T, F <: MOI.AbstractFunction, 
                                                   S <: MOI.AbstractSet}
                                 
    vis = _add_dual_variable(dual_model, primal_model, primal_con_dual_var, 
                             dual_obj_affine_terms, ci)
    return add_dual_cone_constraint(dual_model, primal_model, vis, ci)
end