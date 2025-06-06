# Copyright (c) 2017: Guilherme Bodin, and contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

function _add_dual_equality_constraints(
    dual_model::MOI.ModelLike,
    primal_model::MOI.ModelLike,
    primal_dual_map::PrimalDualMap{T},
    dual_names::DualNames,
    primal_objective::_PrimalObjective{T},
    con_types::Vector{Tuple{Type,Type}},
    variable_parameters::Vector{MOI.VariableIndex},
) where {T}
    sense_change = ifelse(
        MOI.get(primal_model, MOI.ObjectiveSense()) == MOI.MIN_SENSE,
        one(T),
        -one(T),
    )

    all_variables = MOI.get(primal_model, MOI.ListOfVariableIndices())
    non_parameter_variables = setdiff(all_variables, variable_parameters)

    # Loop at every constraint to collect the scalar affine terms in the
    # `scalar_affine_terms` list (a dics mapping variable index to 
    # a scalar affine function).
    # TODO: flip these signs a priorie instead of require post processing later
    scalar_affine_terms = _get_scalar_affine_terms(
        primal_model,
        primal_dual_map.primal_constraint_data,
        all_variables,
        con_types,
        T,
    )

    # get constants (rhs) of dual constraints from primal objective coefficients
    scalar_terms = _get_dual_constraint_constants(primal_objective)

    # Collect affine terms of dual constraints that come from the quadratic
    # part of the primal objective function, and add them into
    # `scalar_affine_terms`.
    # These terms are added with flipped signs (because the sign will be flipped again).
    # TODO: unflip these signs
    _add_scalar_affine_terms_from_quad_obj(
        scalar_affine_terms,
        primal_dual_map.primal_var_in_quad_obj_to_dual_slack_var,
        primal_objective,
        sense_change,
    )

    # terms from mixing variables and parameters
    # These terms are added with flipped signs (because the sign will be flipped again).
    # TODO: unflip these signs
    _add_scalar_affine_terms_from_quad_params(
        scalar_affine_terms,
        primal_dual_map.primal_parameter_to_dual_parameter,
        primal_objective,
        sense_change,
    )

    # Constrained variables
    for ci in keys(primal_dual_map.primal_constrained_variables)
        # Add constraints associated with constrained variables
        # These are constraints that will not be regular equality constraints
        # they will be  function-in-set, where set is the dual set of the
        # primal constrained variable.
        # If the dual set is Reals, the constraint is not added, butthe function
        # is cached inthe primal dual map.
        # TODO: flip these signs a priori instead of requiring post-processing later
        _add_constrained_variable_constraint(
            dual_model,
            primal_model,
            primal_dual_map,
            ci,
            scalar_affine_terms,
            scalar_terms,
            sense_change,
            dual_names,
        )
    end

    # Free variables
    for primal_vi in non_parameter_variables
        data = get(primal_dual_map.primal_variable_data, primal_vi, nothing)
        if data !== nothing &&
           data.primal_constrained_variable_constraint !== nothing
            continue # constrained variable
        end
        # Add equality constraint
        # these are constraints associated to primal variables that are not
        # treated as constrained variables, that is "free variables" (x \in R)
        # therefore their associated dual constraints are equalities.
        dual_ci = MOI.Utilities.normalize_and_add_constraint(
            dual_model,
            MOI.ScalarAffineFunction(
                # TODO: flip these two signs bellow to match _add_constrained_variable_constraint
                # MOI.Utilities.operate_terms(-, scalar_affine_terms[primal_vi]),
                # sense_change * get(scalar_terms, primal_vi, zero(T))),
                MOI.Utilities.operate_terms(+, scalar_affine_terms[primal_vi]),
                -sense_change * get(scalar_terms, primal_vi, zero(T)),
            ),
            MOI.EqualTo(zero(T)),
        )
        # Set constraint name with the name of the associated priaml variable
        if !is_empty(dual_names)
            _set_dual_constraint_name(
                dual_model,
                primal_model,
                primal_vi,
                dual_ci,
                dual_names.dual_constraint_name_prefix,
            )
        end
        # Add primal variable to dual contraint to the link dictionary
        primal_dual_map.primal_variable_data[primal_vi] =
            PrimalVariableData{T}(nothing, -1, dual_ci, nothing)
    end
    return scalar_affine_terms
end

# `_add_constrained_variable_constraint` is a function barrier to avoid type
# unstability.

function _add_constrained_variable_constraint(
    dual_model,
    primal_model,
    primal_dual_map::PrimalDualMap{T},
    ci::MOI.ConstraintIndex{MOI.VectorOfVariables,MOI.Zeros},
    scalar_affine_terms,
    scalar_terms,
    sense_change,
) where {T}
    # The dual is `Reals`, adding a constraint `func`-in-`Reals` is equivalent
    # to not adding any constraint.
    vis = primal_dual_map.primal_constrained_variables[ci]
    for (i, vi) in enumerate(vis)
        dual_function = MOI.ScalarAffineFunction(
            MOI.Utilities.operate_terms(-, scalar_affine_terms[vi]),
            sense_change * get(scalar_terms, vi, zero(T)),
        )
        primal_dual_map.primal_variable_data[vi] =
            PrimalVariableData{T}(ci, i, nothing, dual_function)
    end
    return
end

function _add_constrained_variable_constraint(
    dual_model,
    primal_model,
    primal_dual_map::PrimalDualMap{T},
    ci::MOI.ConstraintIndex{MOI.VectorOfVariables},
    scalar_affine_terms,
    scalar_terms,
    sense_change,
    dual_names::DualNames,
) where {T}
    vis = primal_dual_map.primal_constrained_variables[ci]
    set_primal = MOI.get(primal_model, MOI.ConstraintSet(), ci)
    set_dual = MOI.dual_set(set_primal)
    func_dual = MOI.Utilities.vectorize([
        MOI.ScalarAffineFunction(
            MOI.Utilities.operate_term.(
                *,
                -inv(set_dot(i, set_primal, T)),
                scalar_affine_terms[primal_vi],
            ),
            sense_change *
            inv(set_dot(i, set_primal, T)) *
            get(scalar_terms, primal_vi, zero(T)),
        ) for (i, primal_vi) in enumerate(vis)
    ])
    dual_ci = MOI.add_constraint(dual_model, func_dual, set_dual)
    for (i, vi) in enumerate(vis)
        primal_dual_map.primal_variable_data[vi] =
            PrimalVariableData{T}(ci, i, dual_ci, nothing)
    end
    if !is_empty(dual_names)
        @warn(
            "dual names for constrained vector of variables not supported yet."
        )
    end
    return
end

function _add_constrained_variable_constraint(
    dual_model,
    primal_model,
    primal_dual_map::PrimalDualMap{T},
    ci::MOI.ConstraintIndex{MOI.VariableIndex,MOI.EqualTo{T}},
    scalar_affine_terms,
    scalar_terms,
    sense_change,
    dual_names::DualNames,
) where {T}
    vi = primal_dual_map.primal_constrained_variables[ci][]
    # Nothing to add as the set is `EqualTo`.
    dual_function = MOI.ScalarAffineFunction(
        MOI.Utilities.operate_terms(-, scalar_affine_terms[vi]),
        sense_change * get(scalar_terms, vi, zero(T)),
    )
    primal_dual_map.primal_variable_data[vi] =
        PrimalVariableData{T}(ci, 0, nothing, dual_function)
    return
end

function _add_constrained_variable_constraint(
    dual_model,
    primal_model,
    primal_dual_map::PrimalDualMap{T},
    ci::MOI.ConstraintIndex{MOI.VariableIndex},
    scalar_affine_terms,
    scalar_terms,
    sense_change,
    dual_names::DualNames,
) where {T}
    vi = primal_dual_map.primal_constrained_variables[ci][]
    func_dual = MOI.ScalarAffineFunction(
        MOI.Utilities.operate_terms(-, scalar_affine_terms[vi]),
        sense_change * get(scalar_terms, vi, zero(T)),
    )
    set_primal = MOI.get(primal_model, MOI.ConstraintSet(), ci)
    set_dual = _dual_set(set_primal)
    dual_ci = MOI.Utilities.normalize_and_add_constraint(
        dual_model,
        func_dual,
        set_dual,
    )
    primal_dual_map.primal_variable_data[vi] =
        PrimalVariableData{T}(ci, 0, dual_ci, nothing)
    if !is_empty(dual_names)
        _set_dual_constraint_name(
            dual_model,
            primal_model,
            vi,
            dual_ci,
            dual_names.dual_constraint_name_prefix,
        )
    end
    return
end

function _add_scalar_affine_terms_from_quad_obj(
    scalar_affine_terms::Dict{
        MOI.VariableIndex,
        Vector{MOI.ScalarAffineTerm{T}},
    },
    primal_var_in_quad_obj_to_dual_slack_var::Dict{
        MOI.VariableIndex,
        MOI.VariableIndex,
    },
    primal_objective::_PrimalObjective{T},
    sense_change::T,
) where {T}
    for term in primal_objective.obj.quadratic_terms
        if term.variable_1 == term.variable_2
            dual_vi = primal_var_in_quad_obj_to_dual_slack_var[term.variable_1]
            _push_to_scalar_affine_terms!(
                scalar_affine_terms[term.variable_1],
                -sense_change * MOI.coefficient(term),
                dual_vi,
            )
        else
            dual_vi_1 =
                primal_var_in_quad_obj_to_dual_slack_var[term.variable_1]
            _push_to_scalar_affine_terms!(
                scalar_affine_terms[term.variable_2],
                -sense_change * MOI.coefficient(term),
                dual_vi_1,
            )
            dual_vi_2 =
                primal_var_in_quad_obj_to_dual_slack_var[term.variable_2]
            _push_to_scalar_affine_terms!(
                scalar_affine_terms[term.variable_1],
                -sense_change * MOI.coefficient(term),
                dual_vi_2,
            )
        end
    end
    return
end

function _add_scalar_affine_terms_from_quad_params(
    scalar_affine_terms::Dict{
        MOI.VariableIndex,
        Vector{MOI.ScalarAffineTerm{T}},
    },
    primal_parameter_to_dual_parameter::Dict{
        MOI.VariableIndex,
        MOI.VariableIndex,
    },
    primal_objective::_PrimalObjective{T},
    sense_change::T,
) where {T}
    for (key, val) in primal_objective.quad_cross_parameters
        for term in val
            dual_vi = primal_parameter_to_dual_parameter[term.variable]
            _push_to_scalar_affine_terms!(
                scalar_affine_terms[key],
                -sense_change * MOI.coefficient(term),
                dual_vi,
            )
        end
    end
end

function _set_dual_constraint_name(
    dual_model::MOI.ModelLike,
    primal_model::MOI.ModelLike,
    primal_vi::MOI.VariableIndex,
    dual_ci::MOI.ConstraintIndex,
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

function _get_dual_constraint_constants(
    primal_objective::_PrimalObjective{T},
) where {T}
    scalar_terms = Dict{MOI.VariableIndex,T}()
    for term in primal_objective.obj.affine_terms
        if haskey(scalar_terms, term.variable)
            scalar_terms[term.variable] += MOI.coefficient(term)
        else
            scalar_terms[term.variable] = MOI.coefficient(term)
        end
    end
    return scalar_terms
end

# function barrier
function _fill_scalar_affine_terms!(
    scalar_affine_terms::Dict{
        MOI.VariableIndex,
        Vector{MOI.ScalarAffineTerm{T}},
    },
    primal_constraint_data,
    primal_model::MOI.ModelLike,
    ::Type{F},
    ::Type{S},
) where {T,F,S}
    for ci in MOI.get(primal_model, MOI.ListOfConstraintIndices{F,S}())
        _fill_scalar_affine_terms!(
            scalar_affine_terms,
            primal_constraint_data,
            primal_model,
            ci,
        )
    end
    return
end

function _get_scalar_affine_terms(
    primal_model::MOI.ModelLike,
    primal_constraint_data,
    variables::Vector{MOI.VariableIndex},
    con_types::Vector{Tuple{Type,Type}},
    ::Type{T},
) where {T}
    scalar_affine_terms =
        Dict{MOI.VariableIndex,Vector{MOI.ScalarAffineTerm{T}}}(
            vi => MOI.ScalarAffineTerm{T}[] for vi in variables
        )
    for (F, S) in con_types
        _fill_scalar_affine_terms!(
            scalar_affine_terms,
            primal_constraint_data,
            primal_model,
            F,
            S,
        )
    end
    return scalar_affine_terms
end

function _push_to_scalar_affine_terms!(
    scalar_affine_terms::Vector{MOI.ScalarAffineTerm{T}},
    affine_term::T,
    vi::MOI.VariableIndex,
) where {T}
    if !iszero(affine_term) # if term is different than 0 add to the scalar affine terms vector
        push!(scalar_affine_terms, MOI.ScalarAffineTerm(affine_term, vi))
    end
    return
end

function _fill_scalar_affine_terms!(
    scalar_affine_terms::Dict{
        MOI.VariableIndex,
        Vector{MOI.ScalarAffineTerm{T}},
    },
    primal_constraint_data,
    primal_model::MOI.ModelLike,
    ci::MOI.ConstraintIndex{MOI.ScalarAffineFunction{T},S},
) where {T,S<:Union{MOI.GreaterThan{T},MOI.LessThan{T},MOI.EqualTo{T}}}
    moi_function = MOI.get(primal_model, MOI.ConstraintFunction(), ci)
    for term in moi_function.terms
        dual_vi = primal_constraint_data[ci].dual_variables[1] # In this case we only have one vi
        _push_to_scalar_affine_terms!(
            scalar_affine_terms[term.variable],
            MOI.coefficient(term),
            dual_vi,
        )
    end
    return
end

function _fill_scalar_affine_terms!(
    ::Dict{MOI.VariableIndex,Vector{MOI.ScalarAffineTerm{T}}},
    primal_constraint_data,
    ::MOI.ModelLike,
    ::MOI.ConstraintIndex{MOI.VariableIndex,MOI.Parameter{T}},
) where {T}
    return
end

function _fill_scalar_affine_terms!(
    scalar_affine_terms::Dict{
        MOI.VariableIndex,
        Vector{MOI.ScalarAffineTerm{T}},
    },
    primal_constraint_data,
    primal_model::MOI.ModelLike,
    ci::MOI.ConstraintIndex{MOI.VariableIndex,S},
) where {T,S<:Union{MOI.GreaterThan{T},MOI.LessThan{T},MOI.EqualTo{T}}}
    data = get(primal_constraint_data, ci, nothing)
    if data === nothing
        # No variables created as the primal constraint is the constraint
        # of a constrained variable. Hence, its duality information goes to
        # the dual constraint associated to that primal variable.
        return
    end
    moi_function = MOI.get(primal_model, MOI.ConstraintFunction(), ci)
    dual_vi = data.dual_variables[1] # In this case we only have one vi
    _push_to_scalar_affine_terms!(
        scalar_affine_terms[moi_function],
        one(T),
        dual_vi,
    )
    return
end

function _fill_scalar_affine_terms!(
    scalar_affine_terms::Dict{
        MOI.VariableIndex,
        Vector{MOI.ScalarAffineTerm{T}},
    },
    primal_constraint_data,
    primal_model::MOI.ModelLike,
    ci::MOI.ConstraintIndex{MOI.VectorAffineFunction{T},S},
) where {T,S<:MOI.AbstractVectorSet}
    moi_function = MOI.get(primal_model, MOI.ConstraintFunction(), ci)
    set = MOI.get(primal_model, MOI.ConstraintSet(), ci)
    for term in moi_function.terms
        dual_vi = primal_constraint_data[ci].dual_variables[term.output_index]
        # term.output_index is the row of the MOI.VectorAffineFunction,
        # it corresponds to the dual variable associated with this constraint
        _push_to_scalar_affine_terms!(
            scalar_affine_terms[term.scalar_term.variable],
            set_dot(term.output_index, set, T) * MOI.coefficient(term),
            dual_vi,
        )
    end
    return
end

function _fill_scalar_affine_terms!(
    scalar_affine_terms::Dict{
        MOI.VariableIndex,
        Vector{MOI.ScalarAffineTerm{T}},
    },
    primal_constraint_data,
    primal_model::MOI.ModelLike,
    ci::MOI.ConstraintIndex{MOI.VectorOfVariables,S},
) where {T,S<:MOI.AbstractVectorSet}
    data = get(primal_constraint_data, ci, nothing)
    if data === nothing
        # No variables created as the primal constraint is the constraint
        # of a constrained variable. Hence, its duality information goes to
        # the dual constraint associated to that primal variable.
        return
    end
    moi_function = MOI.get(primal_model, MOI.ConstraintFunction(), ci)
    set = MOI.get(primal_model, MOI.ConstraintSet(), ci)
    for (i, variable) in enumerate(moi_function.variables)
        dual_vi = data.dual_variables[i]
        _push_to_scalar_affine_terms!(
            scalar_affine_terms[variable],
            set_dot(i, set, T) * one(T),
            dual_vi,
        )
    end
    return
end

struct _CanonicalVector{T} <: AbstractVector{T}
    index::Int
    n::Int
end

Base.eltype(::Type{_CanonicalVector{T}}) where {T} = T

Base.length(v::_CanonicalVector) = v.n

Base.size(v::_CanonicalVector) = (v.n,)

function Base.getindex(v::_CanonicalVector{T}, i::Integer) where {T}
    return convert(T, i == v.index)
end

# This is much faster than the default implementation that goes
# through all entries even if only one is nonzero.
function LinearAlgebra.dot(
    x::_CanonicalVector{T},
    y::_CanonicalVector{T},
) where {T}
    return convert(T, x.index == y.index)
end

function MOI.Utilities.triangle_dot(
    x::_CanonicalVector{T},
    y::_CanonicalVector{T},
    dim::Int,
    offset::Int,
) where {T}
    if x.index != y.index || x.index <= offset
        return zero(T)
    elseif MOI.Utilities.is_diagonal_vectorized_index(x.index - offset)
        return one(T)
    else
        return 2one(T)
    end
end

function set_dot(i::Integer, s::MOI.AbstractVectorSet, T::Type)
    vec = _CanonicalVector{T}(i, MOI.dimension(s))
    return MOI.Utilities.set_dot(vec, vec, s)
end

function set_dot(::Integer, ::MOI.AbstractScalarSet, T::Type)
    return one(T)
end
