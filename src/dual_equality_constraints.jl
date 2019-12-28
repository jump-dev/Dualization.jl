function add_dual_equality_constraints(dual_model::MOI.ModelLike, primal_model::MOI.ModelLike,
                                       primal_dual_map::PrimalDualMap,  dual_names::DualNames,
                                       primal_objective::PrimalObjective{T},
                                       con_types::Vector{Tuple{DataType, DataType}},
                                       variable_parameters::Vector{VI}) where T

    sense_change = MOI.get(dual_model, MOI.ObjectiveSense()) == MOI.MAX_SENSE ? one(T) : -one(T)

    all_variables = MOI.get(primal_model, MOI.ListOfVariableIndices())
    restricted_variables = setdiff(all_variables, variable_parameters)

    # Loop at every constraint to get the scalar affine terms
    scalar_affine_terms = get_scalar_affine_terms(primal_model,
        primal_dual_map.primal_con_dual_var, 
        all_variables, con_types, T)

    # get RHS from objective coeficients
    scalar_terms = get_scalar_terms(primal_model,
        all_variables, primal_objective)

    # Add terms from objective:
    # Terms from quadratic part
    add_scalar_affine_terms_from_quad_obj(scalar_affine_terms, primal_model,
        primal_dual_map.primal_var_dual_quad_slack, primal_objective)
    # terms from mixing variables and parameters
    add_scalar_affine_terms_from_quad_params(scalar_affine_terms, primal_model,
        primal_dual_map.primal_parameter, primal_objective)

    for primal_vi in restricted_variables
        # Add equality constraint
        dual_ci = MOIU.normalize_and_add_constraint(dual_model,
            MOI.ScalarAffineFunction(scalar_affine_terms[primal_vi], zero(T)),
            MOI.EqualTo(sense_change * get(scalar_terms, primal_vi, zero(T))))
        #Set constraint name with the name of the associated priaml variable
        set_dual_constraint_name(dual_model, primal_model, primal_vi, dual_ci, 
                                 dual_names.dual_constraint_name_prefix)
        # Add primal variable to dual contraint to the link dictionary
        push!(primal_dual_map.primal_var_dual_con, primal_vi => dual_ci)
    end
    return scalar_affine_terms
end

function add_scalar_affine_terms_from_quad_obj(
    scalar_affine_terms::Dict{VI,Vector{MOI.ScalarAffineTerm{T}}},
    primal_model::MOI.ModelLike,
    primal_var_dual_quad_slack::Dict{VI, VI},
    primal_objective::PrimalObjective{T}) where T
    for term in primal_objective.obj.quadratic_terms
        if term.variable_index_1 == term.variable_index_2
            dual_vi = primal_var_dual_quad_slack[term.variable_index_1]
            push_to_scalar_affine_terms!(
                scalar_affine_terms[term.variable_index_1],
                -MOI.coefficient(term), dual_vi)
        else
            dual_vi_1 = primal_var_dual_quad_slack[term.variable_index_1]
            push_to_scalar_affine_terms!(
                scalar_affine_terms[term.variable_index_2],
                -MOI.coefficient(term), dual_vi_1)
            dual_vi_2 = primal_var_dual_quad_slack[term.variable_index_2]
            push_to_scalar_affine_terms!(
                scalar_affine_terms[term.variable_index_1],
                -MOI.coefficient(term), dual_vi_2)
        end
    end
end

function add_scalar_affine_terms_from_quad_params(
    scalar_affine_terms::Dict{VI,Vector{MOI.ScalarAffineTerm{T}}},
    primal_model::MOI.ModelLike,
    primal_parameter::Dict{VI, VI},
    primal_objective::PrimalObjective{T}) where T
    for (key,val) in primal_objective.quad_cross_parameters
        for term in val
            dual_vi = primal_parameter[term.variable_index]
            push_to_scalar_affine_terms!(scalar_affine_terms[key], -MOI.coefficient(term), dual_vi)
        end
    end
end

function set_dual_constraint_name(dual_model::MOI.ModelLike, primal_model::MOI.ModelLike, 
                                  primal_vi::VI, dual_ci::CI, prefix::String)
    MOI.set(dual_model, MOI.ConstraintName(), dual_ci, 
            prefix*MOI.get(primal_model, MOI.VariableName(), primal_vi))
    return 
end

function get_scalar_terms(primal_model::MOI.ModelLike,
    variables::Vector{VI},
    primal_objective::PrimalObjective{T}) where T

    scalar_terms = Dict{VI,T}()
    for term in get_affine_terms(primal_objective)
        if haskey(scalar_terms, term.variable_index)
            scalar_terms[term.variable_index] += MOI.coefficient(term)
        else
            scalar_terms[term.variable_index] = MOI.coefficient(term)
        end
    end
    return scalar_terms
end

function get_scalar_affine_terms(primal_model::MOI.ModelLike,
                                 primal_con_dual_var::Dict{CI, Vector{VI}},
                                 variables::Vector{VI},
                                 con_types::Vector{Tuple{DataType, DataType}},
                                 T::Type)
                                 
    scalar_affine_terms = Dict{VI,Vector{MOI.ScalarAffineTerm{T}}}()
    for vi in variables
        scalar_affine_terms[vi] = MOI.ScalarAffineTerm{T}[]
    end
    for (F, S) in con_types
        primal_cis = MOI.get(primal_model, MOI.ListOfConstraintIndices{F,S}()) # Constraints of type {F, S}
        for ci in primal_cis
            fill_scalar_affine_terms!(scalar_affine_terms, primal_con_dual_var, 
                                      primal_model, ci) 
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

function fill_scalar_affine_terms!(scalar_affine_terms::Dict{VI,Vector{MOI.ScalarAffineTerm{T}}},
                                   primal_con_dual_var::Dict{CI, Vector{VI}},
                                   primal_model::MOI.ModelLike, ci::CI{SAF{T}, S}, 
                                   ) where {T, S <: Union{MOI.GreaterThan{T},
                                                          MOI.LessThan{T},
                                                          MOI.EqualTo{T}}}

    moi_function = get_function(primal_model, ci)
    for term in moi_function.terms
        dual_vi = primal_con_dual_var[ci][1] # In this case we only have one vi
        push_to_scalar_affine_terms!(scalar_affine_terms[term.variable_index],
                                     MOI.coefficient(term), dual_vi)
    end
    return 
end

function fill_scalar_affine_terms!(scalar_affine_terms::Dict{VI,Vector{MOI.ScalarAffineTerm{T}}},
                                   primal_con_dual_var::Dict{CI, Vector{VI}},
                                   primal_model::MOI.ModelLike, ci::CI{SVF, S}, 
                                   ) where {T, S <: Union{MOI.GreaterThan{T},
                                                          MOI.LessThan{T},
                                                          MOI.EqualTo{T}}}

    moi_function = get_function(primal_model, ci)
    dual_vi = primal_con_dual_var[ci][1] # In this case we only have one vi
    push_to_scalar_affine_terms!(scalar_affine_terms[moi_function.variable], one(T), dual_vi)
    return 
end

function fill_scalar_affine_terms!(scalar_affine_terms::Dict{VI,Vector{MOI.ScalarAffineTerm{T}}},
                                   primal_con_dual_var::Dict{CI, Vector{VI}},
                                   primal_model::MOI.ModelLike, ci::CI{VAF{T}, S}, 
                                   ) where {T, S <: MOI.AbstractVectorSet}

    moi_function = get_function(primal_model, ci)
    set = get_set(primal_model, ci)
    for term in moi_function.terms
        dual_vi = primal_con_dual_var[ci][term.output_index]
        # term.output_index is the row of the VAF,
        # it corresponds to the dual variable associated with this constraint
        push_to_scalar_affine_terms!(scalar_affine_terms[term.scalar_term.variable_index], 
            set_dot(term.output_index, set, T)*MOI.coefficient(term), dual_vi)
    end
    return
end

function fill_scalar_affine_terms!(scalar_affine_terms::Dict{VI,Vector{MOI.ScalarAffineTerm{T}}},
                                   primal_con_dual_var::Dict{CI, Vector{VI}},
                                   primal_model::MOI.ModelLike, ci::CI{VVF, S}, 
                                   ) where {T, S <: MOI.AbstractVectorSet}

    moi_function = get_function(primal_model, ci)
    set = get_set(primal_model, ci)
    for (i, variable) in enumerate(moi_function.variables)
        dual_vi = primal_con_dual_var[ci][i]
        push_to_scalar_affine_terms!(scalar_affine_terms[variable], 
                                    set_dot(i, set, T)*one(T), dual_vi)
    end
    return  
end

function set_dot(i::Int, s::MOI.AbstractVectorSet, T::Type)
    vec = zeros(T, MOI.dimension(s))
    vec[i] = one(T)
    return MOIU.set_dot(vec, vec, s)
end
function set_dot(i::Int, s::MOI.AbstractScalarSet, T::Type)
    return one(T)
end