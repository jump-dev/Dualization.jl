function add_dual_equality_constraints(dual_model::MOI.ModelLike,
                                       dual_var_primal_con::Dict, 
                                       primal_objective::PrimalObjective{T},
                                       num_primal_variables::Int) where T
    
    dual_sense = MOI.get(dual_model, MOI.ObjectiveSense()) # Get dual model sense
    primal_var_dual_con = Dict{VI, CI}() # Empty primal variables dual constraints Dict

    scalar_term_index = 1::Int
    for var = 1:num_primal_variables
        primal_vi = VI(var)
        # Get scalar affine terms
        scalar_affine_terms = get_scalar_affine_terms()
        # Add constraint, the sense of a0 depends on the dual_model ObjectiveSense
        # If max sense scalar term is -a0 and if min sense sacalar term is a0
        if var == primal_objective.saf.terms[scalar_term_index].variable_index.value
            scalar_term_value = primal_objective.saf.terms[scalar_term_index].coefficient
            scalar_term_index += 1
        else # In this case this variable is not on the objective function
            scalar_term_value = zero(T)
        end
        scalar_term = (dual_sense == MOI.MAX_SENSE ? -1 : 1) * scalar_term_value
        # Add primal variable to dual contraint to the link dictionary
        push!(primal_var_dual_con, primal_vi => CI{SAF{T}, MOI.EqualTo}(dual_model.nextconstraintid))
        # Add equality constraint
        MOI.add_constraint(dual_model, MOI.ScalarAffineFunction(scalar_affine_terms, scalar_term), MOI.EqualTo(0.0))
    end
    return primal_var_dual_con
end

function get_scalar_affine_terms(dual_model::MOI.ModelLike, primal_model::MOI.ModelLike,
                                 dual_var_primal_con::Dict, primal_vi::VI, T::DataType)
    scalar_affine_terms = Vector{MOI.ScalarAffineTerm{T}}(undef, 0) 
    for con = 1:dual_model.num_variables_created # Number of constraints of the primal model (equalt number of variables of the dual)
        dual_vi = VI(con)
        # Query the Ai[var] term in the con constraint every constraint
        primal_ci = dual_var_primal_con[dual_vi]
        scalar_affine_term = query_scalar_affine_term(primal_model, primal_ci, primal_vi)
        push_to_scalar_affine_terms!(scalar_affine_terms, scalar_affine_term, dual_vi)
    end
    return scalar_affine_terms
end

#Scalars
function push_to_scalar_affine_terms!(scalar_affine_terms::Vector{MOI.ScalarAffineTerm{T}},
                                      affine_term::T, vi::VI) where T
    return iszero(affine_term) ? nothing : push!(scalar_affine_terms, MOI.ScalarAffineTerm(affine_term, vi))
end

function query_scalar_affine_term()

end

#Vector
function push_to_scalar_affine_terms!(scalar_affine_terms::Vector{MOI.ScalarAffineTerm{T}},
                                      affine_terms::Vector{T}, vis::Vector{VI}) where T
    for i in eachindex(affine_terms)
        push_to_scalar_affine_terms!(scalar_affine_terms, affine_terms[i], vis[i])
    end
end

function query_scalar_affine_term()

end