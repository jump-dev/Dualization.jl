# Equality constraints
"""
        add_dualmodel_equality_constraints(dual_model::MOI.ModelLike, dict_constr_coeffs::Dict, 
                                            dict_dualvar_primalcon::Dict, a0::Array{T, 1}) where T

Add the dual model equality constraints
"""
function add_dual_model_equality_constraints(dual_model::MOI.ModelLike, con_coeffs::Dict, 
                                             dual_var_primal_con::Dict, primal_obj_coeffs::PrimalObjective{T}, 
                                             num_primal_var::Int) where T
    
    dual_sense = MOI.get(dual_model, MOI.ObjectiveSense()) # Get dual model sense
    primal_var_dual_con = Dict{VI, CI}() # Empty primal variables dual constraints Dict

    scalar_term_index = 1::Int
    for var = 1:num_primal_var
        scalar_affine_terms = Vector{MOI.ScalarAffineTerm{T}}(undef, dual_model.num_variables_created) 
        for con = 1:dual_model.num_variables_created # Number of constraints of the primal model (equalt number of variables of the dual)
            vi = VI(con)
            affine_term = con_coeffs[dual_var_primal_con[vi]][1][var] # Accessing Ai^T
            scalar_affine_terms[con] = MOI.ScalarAffineTerm(affine_term, vi)
        end
        # Add constraint, the sense of a0 depends on the dual_model ObjectiveSense
        # If max sense scalar term is -a0 and if min sense sacalar term is a0
        if var == primal_obj_coeffs.vi_vec[scalar_term_index].value
            scalar_term_value = primal_obj_coeffs.affine_terms[scalar_term_index]
            scalar_term_index += 1
        else # In this case this variable is not on the objective function
            scalar_term_value = zero(T)
        end
        scalar_term = (dual_sense == MOI.MAX_SENSE ? -1 : 1) * scalar_term_value
        # Add primal variable to dual contraint to the link dictionary
        push!(primal_var_dual_con, VI(var) => CI{SAF{T}, MOI.EqualTo}(dual_model.nextconstraintid))
        # Add equality constraint
        MOI.add_constraint(dual_model, MOI.ScalarAffineFunction(scalar_affine_terms, scalar_term), MOI.EqualTo(0.0))
    end
    return primal_var_dual_con
end


# Dual cone constraints
"""
Add dual model with variables and dual cone constraints. 
Creates dual variables => primal constraints dict
"""
function add_dual_model_variables(dual_model::MOI.ModelLike, model::MOI.ModelLike, con_types::Vector{Tuple{DataType, DataType}})
    # Adds the dual variables to the dual model, assumining the number of constraints of the model
    # is model.nextconstraintid
    MOI.add_variables(dual_model, model.nextconstraintid) 
    dual_var_primal_con = Dict{VI, CI}()
    con_coeffs = Dict{CI, Tuple{Vector{Float64}, Float64}}()
    i = 1::Int
    for (F, S) in con_types
        num_con_f_s = MOI.get(model, MOI.NumberOfConstraints{F, S}()) # Number of constraints {F, S}
        for con_id = 1:num_con_f_s
            vi = VI(i)
            ci = get_ci(model, F, S, con_id)
            fill_constraint_coefficients(con_coeffs, model, F, S, con_id)
            push!(dual_var_primal_con, vi => ci) # Fill the dual variables primal constraints dictionary
            add_dualcone_constraint(dual_model, vi, F, S) # Add dual variable in dual cone constraint y \in C^*
            i += 1
        end
    end
    return dual_var_primal_con, con_coeffs
end

function add_dualcone_constraint(dual_model::MOI.ModelLike, vi::VI,
                                  ::Type{SAF{T}}, ::Type{MOI.GreaterThan{T}}) where T
    return MOI.add_constraint(dual_model, SVF(vi), MOI.GreaterThan(0.0))
end

function add_dualcone_constraint(dual_model::MOI.ModelLike, vi::VI,
                                  ::Type{SAF{T}}, ::Type{MOI.LessThan{T}}) where T
    return MOI.add_constraint(dual_model, SVF(vi), MOI.LessThan(0.0))
end

function add_dualcone_constraint(dual_model::MOI.ModelLike, vi::VI,
                                  ::Type{SAF{T}}, ::Type{MOI.EqualTo{T}}) where T
    return nothing # No constraint
end

function add_dualcone_constraint(dual_model::MOI.ModelLike, vi::VI,
                                 ::Type{SVF}, ::Type{MOI.GreaterThan{T}}) where T
    return MOI.add_constraint(dual_model, SVF(vi), MOI.GreaterThan(0.0))
end

function add_dualcone_constraint(dual_model::MOI.ModelLike, vi::VI,
                                 ::Type{SVF}, ::Type{MOI.LessThan{T}}) where T
    return MOI.add_constraint(dual_model, SVF(vi), MOI.LessThan(0.0))
end

function add_dualcone_constraint(dual_model::MOI.ModelLike, vi::VI,
                                 ::Type{SVF}, ::Type{MOI.EqualTo{T}}) where T
    return nothing # No constraint
end