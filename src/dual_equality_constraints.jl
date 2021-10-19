function add_dual_equality_constraints(
    dual_model::MOI.ModelLike,
    primal_model::MOI.ModelLike,
    primal_dual_map::PrimalDualMap,
    dual_names::DualNames,
    primal_objective::PrimalObjective{T},
    con_types::Vector{Tuple{DataType,DataType}},
    variable_parameters::Vector{VI},
) where {T}
    sense_change =
        MOI.get(dual_model, MOI.ObjectiveSense()) == MOI.MAX_SENSE ? one(T) :
        -one(T)
    sense_change =
        MOI.get(dual_model, MOI.ObjectiveSense()) == MOI.MAX_SENSE ? one(T) : -one(T)

    all_variables = MOI.get(primal_model, MOI.ListOfVariableIndices())
    restricted_variables = setdiff(all_variables, variable_parameters)

    # Loop at every constraint to get the scalar affine terms
    scalar_affine_terms = get_scalar_affine_terms(
        primal_model,
        primal_dual_map.primal_con_dual_var,
        all_variables,
        con_types,
        T,
    )

    # get RHS from objective coeficients
    scalar_terms = get_scalar_terms(primal_objective)

    # Add terms from objective:
    # Terms from quadratic part
    add_scalar_affine_terms_from_quad_obj(
        scalar_affine_terms,
        primal_dual_map.primal_var_dual_quad_slack,
        primal_objective,
    )
    # terms from mixing variables and parameters
    add_scalar_affine_terms_from_quad_params(
        scalar_affine_terms,
        primal_dual_map.primal_parameter,
        primal_objective,
    )

    # Constrained variables
    for ci in keys(primal_dual_map.constrained_var_dual)
        _add_constrained_variable_constraint(
            dual_model,
            primal_model,
            primal_dual_map.constrained_var_dual,
            ci,
            scalar_affine_terms,
            scalar_terms,
            sense_change,
            T,
        )
    end

    # Free variables
    for primal_vi in restricted_variables
        if primal_vi in keys(primal_dual_map.constrained_var_idx)
            continue # constrained variable
        end
        # Add equality constraint
        dual_ci = MOIU.normalize_and_add_constraint(
            dual_model,
            MOI.ScalarAffineFunction(scalar_affine_terms[primal_vi], zero(T)),
            MOI.EqualTo(sense_change * get(scalar_terms, primal_vi, zero(T))),
        )
        #Set constraint name with the name of the associated priaml variable
        if !is_empty(dual_names)
            set_dual_constraint_name(
                dual_model,
                primal_model,
                primal_vi,
                dual_ci,
                dual_names.dual_constraint_name_prefix,
            )
        end
        # Add primal variable to dual contraint to the link dictionary
        push!(primal_dual_map.primal_var_dual_con, primal_vi => dual_ci)
    end
    return scalar_affine_terms
end

# `_add_constrained_variable_constraint` is a function barrier to avoid type
# unstability.

function _add_constrained_variable_constraint(
    dual_model,
    primal_model,
    ci_map,
    ci::MOI.ConstraintIndex{MOI.VectorOfVariables,MOI.Zeros},
    scalar_affine_terms,
    scalar_terms,
    sense_change,
    ::Type,
)
    # The dual is `Reals`, adding a constraint `func`-in-`Reals` is equivalent
    # to not adding any constraint.
end
function _add_constrained_variable_constraint(
    dual_model,
    primal_model,
    ci_map,
    ci::MOI.ConstraintIndex{MOI.VectorOfVariables},
    scalar_affine_terms,
    scalar_terms,
    sense_change,
    ::Type{T},
) where {T}
    func_primal = MOI.get(primal_model, MOI.ConstraintFunction(), ci)
    func_dual = MOIU.vectorize([
        MOI.ScalarAffineFunction(
            MOIU.operate_terms(-, scalar_affine_terms[primal_vi]),
            sense_change * get(scalar_terms, primal_vi, zero(T)),
        ) for primal_vi in func_primal.variables
    ])
    set_primal = MOI.get(primal_model, MOI.ConstraintSet(), ci)
    set_dual = MOI.dual_set(set_primal)
    ci_map[ci] = MOI.add_constraint(dual_model, func_dual, set_dual)
    return
end

function _add_constrained_variable_constraint(
    dual_model,
    primal_model,
    ci_map,
    ci::MOI.ConstraintIndex{MOI.SingleVariable,<:MOI.EqualTo},
    scalar_affine_terms,
    scalar_terms,
    sense_change,
    ::Type,
)
    # Nothing to add as the set is `EqualTo`.
end
function _add_constrained_variable_constraint(
    dual_model,
    primal_model,
    ci_map,
    ci::MOI.ConstraintIndex{MOI.SingleVariable},
    scalar_affine_terms,
    scalar_terms,
    sense_change,
    ::Type{T},
) where {T}
    func_primal = MOI.get(primal_model, MOI.ConstraintFunction(), ci)
    primal_vi = func_primal.variable
    func_dual = MOI.ScalarAffineFunction(
        MOIU.operate_terms(-, scalar_affine_terms[primal_vi]),
        sense_change * get(scalar_terms, primal_vi, zero(T)),
    )
    set_primal = MOI.get(primal_model, MOI.ConstraintSet(), ci)
    set_dual = _dual_set(set_primal)
    ci_map[ci] = MOIU.normalize_and_add_constraint(dual_model, func_dual, set_dual)
    return
end

function add_scalar_affine_terms_from_quad_obj(
    scalar_affine_terms::Dict{VI,Vector{MOI.ScalarAffineTerm{T}}},
    primal_var_dual_quad_slack::Dict{VI,VI},
    primal_objective::PrimalObjective{T},
) where {T}
    for term in primal_objective.obj.quadratic_terms
        if term.variable_index_1 == term.variable_index_2
            dual_vi = primal_var_dual_quad_slack[term.variable_index_1]
            push_to_scalar_affine_terms!(
                scalar_affine_terms[term.variable_index_1],
                -MOI.coefficient(term),
                dual_vi,
            )
        else
            dual_vi_1 = primal_var_dual_quad_slack[term.variable_index_1]
            push_to_scalar_affine_terms!(
                scalar_affine_terms[term.variable_index_2],
                -MOI.coefficient(term),
                dual_vi_1,
            )
            dual_vi_2 = primal_var_dual_quad_slack[term.variable_index_2]
            push_to_scalar_affine_terms!(
                scalar_affine_terms[term.variable_index_1],
                -MOI.coefficient(term),
                dual_vi_2,
            )
        end
    end
end

function add_scalar_affine_terms_from_quad_params(
    scalar_affine_terms::Dict{VI,Vector{MOI.ScalarAffineTerm{T}}},
    primal_parameter::Dict{VI,VI},
    primal_objective::PrimalObjective{T},
) where {T}
    for (key, val) in primal_objective.quad_cross_parameters
        for term in val
            dual_vi = primal_parameter[term.variable_index]
            push_to_scalar_affine_terms!(
                scalar_affine_terms[key],
                -MOI.coefficient(term),
                dual_vi,
            )
        end
    end
end

function set_dual_constraint_name(
    dual_model::MOI.ModelLike,
    primal_model::MOI.ModelLike,
    primal_vi::VI,
    dual_ci::CI,
    prefix::String,
)
    MOI.set(
        dual_model,
        MOI.ConstraintName(),
        dual_ci,
        prefix * MOI.get(primal_model, MOI.VariableName(), primal_vi),
    )
    return
end

function get_scalar_terms(primal_objective::PrimalObjective{T}) where {T}
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

function fill_scalar_affine_terms!(
    scalar_affine_terms::Dict{VI,Vector{MOI.ScalarAffineTerm{T}}},
    primal_con_dual_var::Dict{CI,Vector{VI}},
    primal_model::MOI.ModelLike,
    ::Type{F},
    ::Type{S},
) where {T,F,S}
    for ci in MOI.get(primal_model, MOI.ListOfConstraintIndices{F,S}())
        fill_scalar_affine_terms!(
            scalar_affine_terms,
            primal_con_dual_var,
            primal_model,
            ci,
        )
    end
    return
end

function get_scalar_affine_terms(
    primal_model::MOI.ModelLike,
    primal_con_dual_var::Dict{CI,Vector{VI}},
    variables::Vector{VI},
    con_types::Vector{Tuple{DataType,DataType}},
    ::Type{T},
) where {T}
    scalar_affine_terms = Dict{VI,Vector{MOI.ScalarAffineTerm{T}}}(
        vi => MOI.ScalarAffineTerm{T}[] for vi in variables
    )
    for (F, S) in con_types
        fill_scalar_affine_terms!(
            scalar_affine_terms,
            primal_con_dual_var,
            primal_model,
            F,
            S,
        )
    end
    return scalar_affine_terms
end

function push_to_scalar_affine_terms!(
    scalar_affine_terms::Vector{MOI.ScalarAffineTerm{T}},
    affine_term::T,
    vi::VI,
) where {T}
    if !iszero(affine_term) # if term is different than 0 add to the scalar affine terms vector
        push!(scalar_affine_terms, MOI.ScalarAffineTerm(affine_term, vi))
    end
    return
end

function fill_scalar_affine_terms!(
    scalar_affine_terms::Dict{VI,Vector{MOI.ScalarAffineTerm{T}}},
    primal_con_dual_var::Dict{CI,Vector{VI}},
    primal_model::MOI.ModelLike,
    ci::CI{SAF{T},S},
) where {T,S<:Union{MOI.GreaterThan{T},MOI.LessThan{T},MOI.EqualTo{T}}}
    moi_function = get_function(primal_model, ci)
    for term in moi_function.terms
        dual_vi = primal_con_dual_var[ci][1] # In this case we only have one vi
        push_to_scalar_affine_terms!(
            scalar_affine_terms[term.variable_index],
            MOI.coefficient(term),
            dual_vi,
        )
    end
    return
end

function fill_scalar_affine_terms!(
    scalar_affine_terms::Dict{VI,Vector{MOI.ScalarAffineTerm{T}}},
    primal_con_dual_var::Dict{CI,Vector{VI}},
    primal_model::MOI.ModelLike,
    ci::CI{SVF,S},
) where {T,S<:Union{MOI.GreaterThan{T},MOI.LessThan{T},MOI.EqualTo{T}}}
    dual_var = get(primal_con_dual_var, ci, nothing)
    if dual_var === nothing
        return # No variables created as it's a constrained variable
    end
    moi_function = get_function(primal_model, ci)
    dual_vi = dual_var[1] # In this case we only have one vi
    push_to_scalar_affine_terms!(
        scalar_affine_terms[moi_function.variable],
        one(T),
        dual_vi,
    )
    return
end

function fill_scalar_affine_terms!(
    scalar_affine_terms::Dict{VI,Vector{MOI.ScalarAffineTerm{T}}},
    primal_con_dual_var::Dict{CI,Vector{VI}},
    primal_model::MOI.ModelLike,
    ci::CI{VAF{T},S},
) where {T,S<:MOI.AbstractVectorSet}
    moi_function = get_function(primal_model, ci)
    set = get_set(primal_model, ci)
    for term in moi_function.terms
        dual_vi = primal_con_dual_var[ci][term.output_index]
        # term.output_index is the row of the VAF,
        # it corresponds to the dual variable associated with this constraint
        push_to_scalar_affine_terms!(
            scalar_affine_terms[term.scalar_term.variable_index],
            set_dot(term.output_index, set, T) * MOI.coefficient(term),
            dual_vi,
        )
    end
    return
end

function fill_scalar_affine_terms!(
    scalar_affine_terms::Dict{VI,Vector{MOI.ScalarAffineTerm{T}}},
    primal_con_dual_var::Dict{CI,Vector{VI}},
    primal_model::MOI.ModelLike,
    ci::CI{VVF,S},
) where {T,S<:MOI.AbstractVectorSet}
    dual_vars = get(primal_con_dual_var, ci, nothing)
    if dual_vars === nothing
        return # No variables created as it's part of constrained variables
    end
    moi_function = get_function(primal_model, ci)
    set = get_set(primal_model, ci)
    for (i, variable) in enumerate(moi_function.variables)
        dual_vi = dual_vars[i]
        push_to_scalar_affine_terms!(
            scalar_affine_terms[variable],
            set_dot(i, set, T) * one(T),
            dual_vi,
        )
    end
    return
end

function set_dot(i::Integer, s::MOI.AbstractVectorSet, T::Type)
    vec = zeros(T, MOI.dimension(s))
    vec[i] = one(T)
    return MOIU.set_dot(vec, vec, s)
end
function set_dot(::Integer, ::MOI.AbstractScalarSet, T::Type)
    return one(T)
end
