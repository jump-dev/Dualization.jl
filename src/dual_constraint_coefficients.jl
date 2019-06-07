# Equality constraints
"""
        add_dualmodel_equality_constraints(dualmodel::MOI.ModelLike, dict_constr_coeffs::Dict, 
                                            dict_dualvar_primalcon::Dict, a0::Array{T, 1}) where T

Add the dual model equality constraints
"""
function add_dual_model_equality_constraints(dual_model::MOI.ModelLike, constr_coeffs::Dict, 
                                             dual_var_primal_con::Dict, poc::POC{T}, num_primalvariables::Int) where T
    
    dual_sense = MOI.get(dual_model, MOI.ObjectiveSense()) # Get dual model sense
    dict_primalvar_dualcon = Dict{VI, CI}() # Empty primal variables dual constraints Dict

    scalar_term_index = 1
    for var = 1:num_primalvariables
        safs = Array{MOI.ScalarAffineTerm{T}}(undef, dual_model.num_variables_created) 
        for constr = 1:dual_model.num_variables_created # Number of constraints of the primal model (equalt number of variables of the dual)
            vi = VI(constr)
            affine_term = constr_coeffs[dual_var_primal_con[vi]][1][var] # Accessing Ai^T
            safs[constr] = MOI.ScalarAffineTerm(affine_term, vi)
        end
        # Add constraint, the sense of a0 depends on the dualmodel ObjectiveSense
        # If max sense scalar term is -a0 and if min sense sacalar term is a0
        if var == poc.vi_vec[scalar_term_index].value
            scalar_term_value = poc.affine_terms[scalar_term_index]
            scalar_term_index += 1
        else # In this case this variable is not on the objective function
            scalar_term_value = zero(T)
        end
        scalar_term = (dual_sense == MOI.MAX_SENSE ? -1 : 1) * scalar_term_value
        # Add primal variable to dual contraint to the link dictionary
        push!(dict_primalvar_dualcon, VI(var) => CI{SAF{T}, MOI.EqualTo}(dual_model.nextconstraintid))
        # Add equality constraint
        MOI.add_constraint(dual_model, MOI.ScalarAffineFunction(safs, scalar_term), MOI.EqualTo(0.0))
    end
    return dict_primalvar_dualcon
end


# Dual cone constraints
"""
Add dual model with variables and dual cone constraints. 
Creates dual variables => primal constraints dict
"""
function add_dual_model_variables(dual_model::MOI.ModelLike, model::MOI.ModelLike, constr_types::Vector{Tuple{DataType, DataType}})
    # Adds the dual variables to the dual model, assumining the number of constraints of the model
    # is model.nextconstraintid
    MOI.add_variables(dual_model, model.nextconstraintid) 
    dict_dualvar_primalcon = Dict{VI, CI}()
    dict_coeffs = Dict{CI, Tuple{Vector{Float64}, Float64}}()
    i = 1
    for (F, S) in constr_types
        num_cons_f_s = MOI.get(model, MOI.NumberOfConstraints{F, S}()) # Number of constraints {F, S}
        for con_id = 1:num_cons_f_s
            vi = VI(i)
            ci = get_ci(model, F, S, con_id)
            fill_constraint_coefficients(dict_coeffs, model, F, S, con_id)
            fill_dual_var_primal_con(dict_dualvar_primalcon, vi, ci)
            add_dualcone_constraint(dual_model, vi, F, S) # Add dual variable in dual cone constraint y \in C^*
            i += 1
        end
    end
    return dict_dualvar_primalcon, dict_coeffs
end

function fill_dual_var_primal_con(dict_dual_var_primal_con::Dict, vi::VI, ci::CI)
    push!(dict_dual_var_primal_con, vi => ci) # Add dual variable to the dict
end

function add_dualcone_constraint(dualmodel::MOI.ModelLike, vi::VI,
                                  ::Type{SAF{T}}, ::Type{MOI.GreaterThan{T}}) where T
    return MOI.add_constraint(dualmodel, SVF(vi), MOI.GreaterThan(0.0))
end

function add_dualcone_constraint(dualmodel::MOI.ModelLike, vi::VI,
                                  ::Type{SAF{T}}, ::Type{MOI.LessThan{T}}) where T
    return MOI.add_constraint(dualmodel, SVF(vi), MOI.LessThan(0.0))
end

function add_dualcone_constraint(dualmodel::MOI.ModelLike, vi::VI,
                                  ::Type{SAF{T}}, ::Type{MOI.EqualTo{T}}) where T
    return nothing # No constraint
end

function add_dualcone_constraint(dualmodel::MOI.ModelLike, vi::VI,
                                 ::Type{SVF}, ::Type{MOI.GreaterThan{T}}) where T
    return MOI.add_constraint(dualmodel, SVF(vi), MOI.GreaterThan(0.0))
end

function add_dualcone_constraint(dualmodel::MOI.ModelLike, vi::VI,
                                 ::Type{SVF}, ::Type{MOI.LessThan{T}}) where T
    return MOI.add_constraint(dualmodel, SVF(vi), MOI.LessThan(0.0))
end

function add_dualcone_constraint(dualmodel::MOI.ModelLike, vi::VI,
                                 ::Type{SVF}, ::Type{MOI.EqualTo{T}}) where T
    return nothing # No constraint
end