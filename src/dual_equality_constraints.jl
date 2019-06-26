function add_dual_equality_constraints(dual_model::AbstractModel{T}, primal_model::AbstractModel{T},
                                       primal_con_dual_var::Dict, primal_objective::PrimalObjective{T},
                                       con_types::Vector{Tuple{DataType, DataType}}) where T
    
    dual_sense = MOI.get(dual_model, MOI.ObjectiveSense()) # Get dual model sense
    primal_var_dual_con = Dict{VI, CI}() # Empty primal variables dual constraints Dict

    scalar_term_index = 1::Int
    for var = 1:primal_model.num_variables_created
        primal_vi = VI(var)
        # Loop at every constraint to get the scalar affine terms
        scalar_affine_terms = get_scalar_affine_terms(primal_model, primal_con_dual_var, 
                                                      primal_vi, con_types)
        # Add constraint, the sense of a0 depends on the dual_model ObjectiveSense
        # If max sense scalar term is -a0 and if min sense sacalar term is a0
        if var == primal_objective.saf.terms[scalar_term_index].variable_index.value
            scalar_term_value = primal_objective.saf.terms[scalar_term_index].coefficient
            scalar_term_index += 1
        else # In this case this variable is not on the objective function
            scalar_term_value = zero(T)
        end
        scalar_term = (dual_sense == MOI.MAX_SENSE ? 1 : -1) * scalar_term_value
        # Add primal variable to dual contraint to the link dictionary
        push!(primal_var_dual_con, primal_vi => CI{SAF{T}, MOI.EqualTo}(dual_model.nextconstraintid))
        # Add equality constraint
        MOIU.add_scalar_constraint(dual_model, MOI.ScalarAffineFunction(scalar_affine_terms, zero(T)), MOI.EqualTo(scalar_term))
    end
    return primal_var_dual_con
end

function get_scalar_affine_terms(primal_model::AbstractModel{T},
                                 primal_con_dual_var::Dict{CI, Vector{VI}}, primal_vi::VI,
                                 con_types::Vector{Tuple{DataType, DataType}}) where T
    scalar_affine_terms = Vector{MOI.ScalarAffineTerm{T}}(undef, 0) 
    for (F, S) in con_types
        num_con_f_s = MOI.get(primal_model, MOI.NumberOfConstraints{F, S}()) # Number of constraints {F, S}
        for con_id = 1:num_con_f_s
            fill_scalar_affine_terms!(scalar_affine_terms, primal_con_dual_var, 
                                      primal_model, con_id, primal_vi, F, S) 
        end
    end
    return scalar_affine_terms
end

function push_to_scalar_affine_terms!(scalar_affine_terms::Vector{MOI.ScalarAffineTerm{T}},
                                      affine_term::T, vi::VI) where T

    if !iszero(affine_term) # if term is different than 0 add to the scalar affine terms vector
        push!(scalar_affine_terms, MOI.ScalarAffineTerm(affine_term, vi))
    end
    return 
end

function push_to_scalar_affine_terms!(scalar_affine_terms::Vector{MOI.ScalarAffineTerm{T}},
                                      affine_terms::Vector{T}, vis::Vector{VI}) where T
    for i in eachindex(affine_terms)
        push_to_scalar_affine_terms!(scalar_affine_terms, affine_terms[i], vis[i])
    end
end

function fill_scalar_affine_terms!(scalar_affine_terms::Vector{MOI.ScalarAffineTerm{T}},
                                   primal_con_dual_var::Dict{CI, Vector{VI}},
                                   primal_model::AbstractModel{T}, con_id::Int, primal_vi::VI, 
                                   F::Type{SAF{T}}, 
                                   S::Union{Type{MOI.GreaterThan{T}},
                                            Type{MOI.LessThan{T}},
                                            Type{MOI.EqualTo{T}}}) where T

    moi_function = get_function(primal_model, F, S, con_id)
    for term in moi_function.terms
        if term.variable_index == primal_vi
            ci = get_ci(primal_model, F, S, con_id)
            dual_vi = primal_con_dual_var[ci][1] # In this case we only have one vi
            push_to_scalar_affine_terms!(scalar_affine_terms, term.coefficient, dual_vi)
        end
    end
    return 
end

function fill_scalar_affine_terms!(scalar_affine_terms::Vector{MOI.ScalarAffineTerm{T}},
                                   primal_con_dual_var::Dict{CI, Vector{VI}},
                                   primal_model::AbstractModel{T}, con_id::Int, primal_vi::VI, 
                                   F::Type{SVF}, 
                                   S::Union{Type{MOI.GreaterThan{T}},
                                            Type{MOI.LessThan{T}},
                                            Type{MOI.EqualTo{T}}}) where T

    moi_function = get_function(primal_model, F, S, con_id)
    if moi_function.variable == primal_vi
        ci = get_ci(primal_model, F, S, con_id)
        dual_vi = primal_con_dual_var[ci][1] # In this case we only have one vi
        push_to_scalar_affine_terms!(scalar_affine_terms, one(T), dual_vi)
    end
    return 
end

function fill_scalar_affine_terms!(scalar_affine_terms::Vector{MOI.ScalarAffineTerm{T}},
                                   primal_con_dual_var::Dict{CI, Vector{VI}},
                                   primal_model::AbstractModel{T}, con_id::Int, primal_vi::VI, 
                                   F::Type{VAF{T}}, 
                                   S::Union{Type{MOI.Nonpositives},
                                            Type{MOI.Nonnegatives},
                                            Type{MOI.Zeros}}) where T

    moi_function = get_function(primal_model, F, S, con_id)
    for term in moi_function.terms
        if term.scalar_term.variable_index == primal_vi
            ci = get_ci(primal_model, F, S, con_id)
            dual_vi = primal_con_dual_var[ci][term.output_index] # term.output_index is the row of the VAF,
                                                                 # it corresponds to the dual variable associated with
                                                                 # this constraint
            push_to_scalar_affine_terms!(scalar_affine_terms, term.scalar_term.coefficient, dual_vi)
        end
    end
    return 
end