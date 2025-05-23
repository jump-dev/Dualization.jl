# Copyright (c) 2017: Guilherme Bodin, and contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

"""
    _set_dual_model_sense(dual_model::MOI.ModelLike, model::MOI.ModelLike)

Set the dual model objective sense.
"""
function _set_dual_model_sense(
    dual_model::MOI.ModelLike,
    primal_model::MOI.ModelLike,
    assume_min_if_feasibility::Bool,
)::Nothing
    # Get model sense
    primal_sense = MOI.get(primal_model, MOI.ObjectiveSense())
    # Set dual model sense
    dual_sense = if primal_sense == MOI.MIN_SENSE
        MOI.MAX_SENSE
    elseif primal_sense == MOI.MAX_SENSE
        MOI.MIN_SENSE
    elseif primal_sense == MOI.FEASIBILITY_SENSE && assume_min_if_feasibility
        # We assume fesibility sense is a Min 0
        # so the dual would be Max ...
        MOI.MAX_SENSE
    else
        error(
            "Expected objective sense to be either MIN_SENSE or MAX_SENSE, " *
            "got FEASIBILITY_SENSE. It is not possible to decide how to " *
            "dualize. Set the sense to either MIN_SENSE or MAX_SENSE to " *
            "proceed. Alternatively, set the keyword argument " *
            "`assume_min_if_feasibility` to true to assume the dual model " *
            "is a minimization problem without setting the sense.",
        )
    end
    MOI.set(dual_model, MOI.ObjectiveSense(), dual_sense)
    return
end

function _scalar_quadratic_function(
    func::MOI.ScalarQuadraticFunction{T},
    ::Type{T},
) where {T}
    return MOI.Utilities.canonical(func)
end

function _scalar_quadratic_function(
    func::MOI.ScalarAffineFunction{T},
    ::Type{T},
) where {T}
    return _scalar_quadratic_function(
        MOI.ScalarQuadraticFunction{T}(
            MOI.ScalarQuadraticTerm{T}[],
            func.terms,
            func.constant,
        ),
        T,
    )
end

function _scalar_quadratic_function(func::MOI.VariableIndex, T::Type)
    return _scalar_quadratic_function(
        MOI.ScalarAffineFunction{T}([MOI.ScalarAffineTerm(1.0, func)], 0),
        T,
    )
end

"""
    _PrimalObjective{T}

Primal objective is defined as a `MOI.ScalarAffineFunction`
"""
mutable struct _PrimalObjective{T}
    obj::MOI.ScalarQuadraticFunction{T}
    quad_cross_parameters::Dict{
        MOI.VariableIndex,
        Vector{MOI.ScalarAffineTerm{T}},
    }
    obj_parametric::Union{MOI.ScalarQuadraticFunction{T},Nothing}

    function _PrimalObjective{T}(obj) where {T}
        canonical_obj = _scalar_quadratic_function(obj, T)
        quad_cross_parameters =
            Dict{MOI.VariableIndex,Vector{MOI.ScalarAffineTerm{T}}}()
        return new(canonical_obj, quad_cross_parameters, nothing)
    end
end

"""
    _DualObjective{T}

Dual objective is defined as a `MOI.ScalarAffineFunction`.
"""
mutable struct _DualObjective{T}
    obj::MOI.ScalarQuadraticFunction{T}
end

# allow removing variables from objective function
function _get_primal_objective(
    primal_model::MOI.ModelLike,
    variable_parameters::Vector{MOI.VariableIndex},
    T::Type,
)
    F = MOI.get(primal_model, MOI.ObjectiveFunctionType())
    p_obj =
        _PrimalObjective{T}(MOI.get(primal_model, MOI.ObjectiveFunction{F}()))
    if length(variable_parameters) > 0
        vars_func, quad_cross_params, params_func =
            _split_variables(p_obj.obj, variable_parameters)
        p_obj.obj = vars_func
        p_obj.quad_cross_parameters = quad_cross_params
        p_obj.obj_parametric = params_func
    end
    return p_obj
end

function _split_variables(
    func::MOI.ScalarQuadraticFunction{T},
    variable_parameters::Vector{MOI.VariableIndex},
) where {T}

    # linear part
    lin_params = MOI.ScalarAffineTerm{T}[]
    lin_vars = MOI.ScalarAffineTerm{T}[]
    for term in func.affine_terms
        if term.variable in variable_parameters
            push!(lin_params, term)
        else
            push!(lin_vars, term)
        end
    end

    # Quadratic part
    quad_params = MOI.ScalarQuadraticTerm{T}[]
    quad_vars = MOI.ScalarQuadraticTerm{T}[]
    quad_cross_params =
        Dict{MOI.VariableIndex,Vector{MOI.ScalarAffineTerm{T}}}()
    for term in func.quadratic_terms
        is_param_1 = term.variable_1 in variable_parameters
        is_param_2 = term.variable_2 in variable_parameters
        if is_param_1 && is_param_2
            push!(quad_params, term)
        elseif is_param_1
            _push_affine_term(quad_cross_params, term, false)
        elseif is_param_2
            _push_affine_term(quad_cross_params, term, true)
        else
            push!(quad_vars, term)
        end
    end

    variables_func =
        MOI.ScalarQuadraticFunction{T}(quad_vars, lin_vars, func.constant)
    parameters_func =
        MOI.ScalarQuadraticFunction{T}(quad_params, lin_params, zero(T))

    return variables_func, quad_cross_params, parameters_func
end

function _push_affine_term(
    dic,
    term::MOI.ScalarQuadraticTerm{T},
    var_is_first::Bool,
) where {T}
    variable = var_is_first ? term.variable_1 : term.variable_2
    parameter = var_is_first ? term.variable_2 : term.variable_1
    if haskey(dic, variable)
        push!(
            dic[variable],
            MOI.ScalarAffineTerm{T}(term.coefficient, parameter),
        )
    else
        dic[variable] = [MOI.ScalarAffineTerm{T}(term.coefficient, parameter)]
    end
end

"""
    _set_dual_objective(
        dual_model::MOI.ModelLike,
        dual_objective::_DualObjective{T},
    )::Nothing where {T}

Add the objective function to the dual model.
"""
function _set_dual_objective(
    dual_model::MOI.ModelLike,
    dual_objective::_DualObjective{T},
)::Nothing where {T}
    # Set dual model objective function
    raw_obj = dual_objective.obj
    if MOI.Utilities.number_of_quadratic_terms(T, raw_obj) > 0
        MOI.set(
            dual_model,
            MOI.ObjectiveFunction{MOI.ScalarQuadraticFunction{T}}(),
            raw_obj,
        )
    else
        MOI.set(
            dual_model,
            MOI.ObjectiveFunction{MOI.ScalarAffineFunction{T}}(),
            MOI.ScalarAffineFunction{T}(raw_obj.affine_terms, raw_obj.constant),
        )
    end
    return
end

"""
    _get_dual_objective(
        dual_model::MOI.ModelLike,
        dual_obj_affine_terms::Dict,
        primal_objective::_PrimalObjective{T},
    )::_DualObjective{T} where {T}

build the dual model objective function from the primal model.
"""
function _get_dual_objective(
    dual_problem,
    dual_obj_affine_terms::Dict,
    primal_objective::_PrimalObjective{T},
    scalar_affine_terms,
    variable_parameters,
)::_DualObjective{T} where {T}
    dual_model = dual_problem.dual_model
    map = dual_problem.primal_dual_map
    sense_change = ifelse(
        MOI.get(dual_model, MOI.ObjectiveSense()) == MOI.MAX_SENSE,
        -one(T),
        one(T),
    )

    # standard linear part
    lin_terms = MOI.ScalarAffineTerm{T}[]
    sizehint!(lin_terms, length(dual_obj_affine_terms))
    for var in keys(dual_obj_affine_terms) # Number of constraints of the primal model
        coef = dual_obj_affine_terms[var]
        push!(lin_terms, MOI.ScalarAffineTerm{T}(
            # Add positive terms bi if dual model sense is max
            sense_change * coef,
            # Variable index associated with term bi
            var,
        ))
    end

    # standard quadratic part
    quad_terms = MOI.ScalarQuadraticTerm{T}[]
    sizehint!(quad_terms, length(primal_objective.obj.quadratic_terms))
    for term in primal_objective.obj.quadratic_terms
        push!(
            quad_terms,
            MOI.ScalarQuadraticTerm{T}(
                -MOI.coefficient(term),
                map.primal_var_in_quad_obj_to_dual_slack_var[term.variable_1],
                map.primal_var_in_quad_obj_to_dual_slack_var[term.variable_2],
            ),
        )
    end

    # parametric part
    # if some variables were marked to be parameters then their final
    # processing occurs here.
    if nothing !== primal_objective.obj_parametric

        # linear: coef * parameter
        # are treated as constants in the objective, so they go
        # to the dual objective in the exact same way they come from primal obj.
        for term in primal_objective.obj_parametric.affine_terms
            push!(
                lin_terms,
                MOI.ScalarAffineTerm{T}(
                    MOI.coefficient(term),
                    map.primal_parameter_to_dual_parameter[term.variable],
                ),
            )
        end

        # quadratic: coef * parameter * parameter
        # are treated as constants in the objective, so they go
        # to the dual objective in the exact same way they come from primal obj.
        for term in primal_objective.obj_parametric.quadratic_terms
            push!(
                quad_terms,
                MOI.ScalarQuadraticTerm{T}(
                    MOI.coefficient(term),
                    map.primal_parameter_to_dual_parameter[term.variable_1],
                    map.primal_parameter_to_dual_parameter[term.variable_2],
                ),
            )
        end

        # crossed terms: parameters * variables
        # these come from parameters that belong to constraints functions
        # that were collectted while building constraints.
        # Since they are parameters they are treated as "constrants in rhs"
        # and, thus, the go to the obj of the dual.
        # TODO? set_dot
        for vi in variable_parameters
            param = map.primal_parameter_to_dual_parameter[vi]
            for term in scalar_affine_terms[vi]
                push!(
                    quad_terms,
                    MOI.ScalarQuadraticTerm{T}(
                        sense_change * MOI.coefficient(term),
                        param,
                        term.variable,
                    ),
                )
            end
        end
    end

    saf_dual_objective = MOI.ScalarQuadraticFunction{T}(
        quad_terms,
        lin_terms,
        MOI.constant(primal_objective.obj),
    )
    return _DualObjective{T}(saf_dual_objective)
end
