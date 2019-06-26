function add_dual_vars_in_dual_cones(dual_model::MOI.ModelLike, primal_model::MOI.ModelLike, 
                                     con_types::Vector{Tuple{DataType, DataType}}, T::DataType)
    primal_con_dual_var = Dict{CI, Vector{VI}}()
    dual_obj_affine_terms = Dict{VI, T}()
    for (F, S) in con_types
        num_con_f_s = MOI.get(primal_model, MOI.NumberOfConstraints{F, S}()) # Number of constraints {F, S}
        for con_id = 1:num_con_f_s
            # Add dual variable to dual cone
            # Fill a dual objective dictionary
            # Fill the primal_con_dual_var dictionary
            add_dual_variable(dual_model, primal_model, primal_con_dual_var, dual_obj_affine_terms, con_id, F, S)
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
                            con_id::Int, 
                            F::Union{Type{SAF{T}}, Type{SVF}}, 
                            S::Union{Type{MOI.GreaterThan{T}},
                                     Type{MOI.LessThan{T}},
                                     Type{MOI.EqualTo{T}}}) where T
    
    ci = get_ci(primal_model, F, S, con_id)
    vi = MOI.add_variable(dual_model)
    push!(primal_con_dual_var, ci => [vi]) # Add the map of the added dual variable to the relationated constraint
    push_to_dual_obj_aff_terms!(dual_obj_affine_terms, vi, get_scalar_term(primal_model, con_id, F, S))
    return vi
end

function _add_dual_variable(dual_model::MOI.ModelLike, primal_model::MOI.ModelLike,
                            primal_con_dual_var::Dict{CI, Vector{VI}}, dual_obj_affine_terms::Dict{VI, T},
                            con_id::Int, 
                            F::Type{VAF{T}}, 
                            S::Union{Type{MOI.Nonpositives},
                                     Type{MOI.Nonnegatives},
                                     Type{MOI.Zeros}}) where T
    
    row_dimension = get_ci_row_dimension(primal_model, F, S, con_id) 
    ci = get_ci(primal_model, F, S, con_id)
    vis = MOI.add_variables(dual_model, row_dimension) # Add as many variables as the number of rows of the VAF
    push!(primal_con_dual_var, ci => vis) # Add the map of the added dual variable to the relationated constraint
    # Add each vi to the dictionary
    i::Int = 1
    for vi in vis
        push_to_dual_obj_aff_terms!(dual_obj_affine_terms, vi, get_scalar_term(primal_model, con_id, F, S)[i])
        i += 1
    end
    return vis
end


# SAFs
function add_dual_variable(dual_model::MOI.ModelLike, primal_model::MOI.ModelLike,
                           primal_con_dual_var::Dict{CI, Vector{VI}}, dual_obj_affine_terms::Dict{VI, T},
                           con_id::Int, F::Type{SAF{T}}, S::Type{MOI.GreaterThan{T}}) where T
                                 
    vi = _add_dual_variable(dual_model, primal_model, primal_con_dual_var, 
                            dual_obj_affine_terms, con_id, F, S)
    return MOI.add_constraint(dual_model, SVF(vi), MOI.GreaterThan(zero(T))) # Add variable to the dual cone of the constraint
end

function add_dual_variable(dual_model::MOI.ModelLike, primal_model::MOI.ModelLike,
                           primal_con_dual_var::Dict{CI, Vector{VI}}, dual_obj_affine_terms::Dict{VI, T},
                           con_id::Int, F::Type{SAF{T}}, S::Type{MOI.LessThan{T}}) where T
                                 
    vi = _add_dual_variable(dual_model, primal_model, primal_con_dual_var, 
                            dual_obj_affine_terms, con_id, F, S)
    return MOI.add_constraint(dual_model, SVF(vi), MOI.LessThan(zero(T))) # Add variable to the dual cone of the constraint
end

function add_dual_variable(dual_model::MOI.ModelLike, primal_model::MOI.ModelLike,
                           primal_con_dual_var::Dict{CI, Vector{VI}}, dual_obj_affine_terms::Dict{VI, T},
                           con_id::Int, F::Type{SAF{T}}, S::Type{MOI.EqualTo{T}}) where T
                            
    vi = _add_dual_variable(dual_model, primal_model, primal_con_dual_var, 
                            dual_obj_affine_terms, con_id, F, S)
    return # No constraint is added
end



#SVF
function add_dual_variable(dual_model::MOI.ModelLike, primal_model::MOI.ModelLike,
                           primal_con_dual_var::Dict{CI, Vector{VI}}, dual_obj_affine_terms::Dict{VI, T},
                           con_id::Int, F::Type{SVF}, S::Type{MOI.GreaterThan{T}}) where T

    vi = _add_dual_variable(dual_model, primal_model, primal_con_dual_var, 
                            dual_obj_affine_terms, con_id, F, S)
    return MOI.add_constraint(dual_model, SVF(vi), MOI.GreaterThan(zero(T))) # Add variable to the dual cone of the constraint
end

function add_dual_variable(dual_model::MOI.ModelLike, primal_model::MOI.ModelLike,
                           primal_con_dual_var::Dict{CI, Vector{VI}}, dual_obj_affine_terms::Dict{VI, T}, 
                           con_id::Int, F::Type{SVF}, S::Type{MOI.LessThan{T}}) where T

    vi = _add_dual_variable(dual_model, primal_model, primal_con_dual_var, 
                            dual_obj_affine_terms, con_id, F, S)
    return MOI.add_constraint(dual_model, SVF(vi), MOI.LessThan(zero(T))) # Add variable to the dual cone of the constraint
end

function add_dual_variable(dual_model::MOI.ModelLike, primal_model::MOI.ModelLike,
                           primal_con_dual_var::Dict{CI, Vector{VI}}, dual_obj_affine_terms::Dict{VI, T},
                           con_id::Int, F::Type{SVF}, S::Type{MOI.EqualTo{T}}) where T

    vi = _add_dual_variable(dual_model, primal_model, primal_con_dual_var, 
                            dual_obj_affine_terms, con_id, F, S)
    return # No constraint is added
end



#VAF
function add_dual_variable(dual_model::MOI.ModelLike, primal_model::MOI.ModelLike,
                           primal_con_dual_var::Dict{CI, Vector{VI}}, dual_obj_affine_terms::Dict{VI, T},
                           con_id::Int, F::Type{VAF{T}}, S::Type{MOI.Nonpositives}) where T

    vis = _add_dual_variable(dual_model, primal_model, primal_con_dual_var, 
                             dual_obj_affine_terms, con_id, F, S)
    return MOI.add_constraint(dual_model, VVF(vis), MOI.Nonpositives(length(vis))) # Add variable to the dual cone of the constraint
end

function add_dual_variable(dual_model::MOI.ModelLike, primal_model::MOI.ModelLike,
                           primal_con_dual_var::Dict{CI, Vector{VI}}, dual_obj_affine_terms::Dict{VI, T},
                           con_id::Int, F::Type{VAF{T}}, S::Type{MOI.Nonnegatives}) where T

    vis = _add_dual_variable(dual_model, primal_model, primal_con_dual_var, 
                             dual_obj_affine_terms, con_id, F, S)
    return MOI.add_constraint(dual_model, VVF(vis), MOI.Nonnegatives(length(vis))) # Add variable to the dual cone of the constraint
end

function add_dual_variable(dual_model::MOI.ModelLike, primal_model::MOI.ModelLike,
                           primal_con_dual_var::Dict{CI, Vector{VI}}, dual_obj_affine_terms::Dict{VI, T},
                           con_id::Int, F::Type{VAF{T}}, S::Type{MOI.Zeros}) where T

    vis = _add_dual_variable(dual_model, primal_model, primal_con_dual_var, 
                             dual_obj_affine_terms, con_id, F, S)
    return # Dual cone is reals
end