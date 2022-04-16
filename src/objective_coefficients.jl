"""
    set_dual_model_sense!(dual_model::MOI.ModelLike, model::MOI.ModelLike)

Set the dual model objective sense.
"""
function set_dual_model_sense(
    dual_model::MOI.ModelLike,
    primal_model::MOI.ModelLike,
)::Nothing where {T}
    # Get model sense
    primal_sense = MOI.get(primal_model, MOI.ObjectiveSense())
    if primal_sense == MOI.FEASIBILITY_SENSE
        error(primal_sense, " is not supported")
    end
    # Set dual model sense
    dual_sense = (primal_sense == MOI.MIN_SENSE) ? MOI.MAX_SENSE : MOI.MIN_SENSE
    MOI.set(dual_model, MOI.ObjectiveSense(), dual_sense)
    return
end

function _scalar_quadratic_function(
    func::MOI.ScalarQuadraticFunction{T},
    ::Type{T},
) where {T}
    return MOIU.canonical(func)
end
function _scalar_quadratic_function(
    func::MOI.ScalarAffineFunction{T},
    ::Type{T},
) where {T}
    return _scalar_quadratic_function(
        SQF{T}(MOI.ScalarQuadraticTerm{T}[], func.terms, func.constant),
        T,
    )
end
function _scalar_quadratic_function(func::MOI.VariableIndex, T::Type)
    return _scalar_quadratic_function(
        SAF{T}([MOI.ScalarAffineTerm(1.0, func)], 0),
        T,
    )
end

# Primals
"""
    PrimalObjective{T}

Primal objective is defined as a `MOI.ScalarAffineFunction`
"""
mutable struct PrimalObjective{T}
    obj::SQF{T}
    quad_cross_parameters::Dict{VI,Vector{MOI.ScalarAffineTerm{T}}}
    obj_parametric::Union{SQF{T},Nothing}

    function PrimalObjective{T}(obj) where {T}
        canonical_obj = _scalar_quadratic_function(obj, T)
        quad_cross_parameters = Dict{VI,Vector{MOI.ScalarAffineTerm{T}}}()
        return new(canonical_obj, quad_cross_parameters, nothing)
    end
end

# Duals
"""
    DualObjective{T}

Dual objective is defined as a `MOI.ScalarAffineFunction`.
"""
mutable struct DualObjective{T}
    obj::SQF{T}
end

const Objective{T} = Union{PrimalObjective{T},DualObjective{T}}

function get_raw_obj(objective::Objective{T}) where {T}
    return objective.obj
end
function get_affine_terms(objective::Objective{T}) where {T}
    return objective.obj.affine_terms
end

function get_primal_objective(primal_model::MOI.ModelLike, T::Type = Float64)
    F = MOI.get(primal_model, MOI.ObjectiveFunctionType())
    return _get_primal_objective(
        MOI.get(primal_model, MOI.ObjectiveFunction{F}()),
        T,
    )
end

function _get_primal_objective(obj_fun, T::Type)
    return PrimalObjective{T}(obj_fun)
end

# allow removing variables from objective function
function get_primal_objective(
    primal_model::MOI.ModelLike,
    variable_parameters::Vector{VI},
    T::Type,
)
    p_obj = get_primal_objective(primal_model, T)
    if length(variable_parameters) > 0
        vars_func, quad_cross_params, params_func =
            split_variables(p_obj.obj, variable_parameters)
        p_obj.obj = vars_func
        p_obj.quad_cross_parameters = quad_cross_params
        p_obj.obj_parametric = params_func
    end
    return p_obj
end

function split_variables(
    func::MOI.ScalarQuadraticFunction{T},
    variable_parameters::Vector{VI},
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
    quad_cross_params = Dict{VI,Vector{MOI.ScalarAffineTerm{T}}}()
    for term in func.quadratic_terms
        is_param_1 = term.variable_1 in variable_parameters
        is_param_2 = term.variable_2 in variable_parameters
        if is_param_1 && is_param_2
            push!(quad_params, term)
        elseif is_param_1
            push_affine_term(quad_cross_params, term, false)
        elseif is_param_2
            push_affine_term(quad_cross_params, term, true)
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

function push_affine_term(
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
    set_dual_objective(dual_model::MOI.ModelLike, dual_objective::DualObjective{T})::Nothing where T

Add the objective function to the dual model.
"""
function set_dual_objective(
    dual_model::MOI.ModelLike,
    dual_objective::DualObjective{T},
)::Nothing where {T}
    # Set dual model objective function
    raw_obj = get_raw_obj(dual_objective)
    if MOIU.number_of_quadratic_terms(T, raw_obj) > 0
        MOI.set(dual_model, MOI.ObjectiveFunction{SQF{T}}(), raw_obj)
    else
        MOI.set(
            dual_model,
            MOI.ObjectiveFunction{SAF{T}}(),
            SAF{T}(raw_obj.affine_terms, raw_obj.constant),
        )
    end
    return
end

"""
    get_dual_objective(dual_model::MOI.ModelLike, dual_obj_affine_terms::Dict,
                       primal_objective::PrimalObjective{T})::DualObjective{T} where T

build the dual model objective function from the primal model.
"""
function get_dual_objective(
    dual_problem,
    dual_obj_affine_terms::Dict,
    primal_objective::PrimalObjective{T},
    con_types,
    scalar_affine_terms,
    variable_parameters,
)::DualObjective{T} where {T}
    dual_model = dual_problem.dual_model
    map = dual_problem.primal_dual_map
    sense_change =
        MOI.get(dual_model, MOI.ObjectiveSense()) == MOI.MAX_SENSE ? -one(T) :
        one(T)

    # standard linear part
    num_objective_terms = length(dual_obj_affine_terms)
    lin_terms = MOI.ScalarAffineTerm{T}[]
    sizehint!(lin_terms, num_objective_terms)
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
                map.primal_var_dual_quad_slack[term.variable_1],
                map.primal_var_dual_quad_slack[term.variable_2],
            ),
        )
    end

    # parametric part

    if nothing !== primal_objective.obj_parametric

        # linear
        for term in primal_objective.obj_parametric.affine_terms
            push!(
                lin_terms,
                MOI.ScalarAffineTerm{T}(
                    MOI.coefficient(term),
                    map.primal_parameter[term.variable],
                ),
            )
        end

        # quadratic
        for term in primal_objective.obj_parametric.quadratic_terms
            push!(
                quad_terms,
                MOI.ScalarQuadraticTerm{T}(
                    MOI.coefficient(term),
                    map.primal_parameter[term.variable_1],
                    map.primal_parameter[term.variable_2],
                ),
            )
        end

        # crossed
        # TODO? set_dot
        for vi in variable_parameters
            param = map.primal_parameter[vi]
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
        MOI.constant(get_raw_obj(primal_objective)),
    )
    return DualObjective{T}(saf_dual_objective)
end
