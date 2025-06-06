# Copyright (c) 2017: Guilherme Bodin, and contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

"""
    dualize(args...; kwargs...)

The `dualize` function works in three different ways. The user can provide:

  * A `MathOptInterface.ModelLike`

    The function will return a `DualProblem` struct that has the dualized model
    and `PrimalDualMap{Float64}` for users to identify the links between primal
    and dual model. The `PrimalDualMap{Float64}` maps variables and constraints
    from the original primal model into the respective objects of the dual
    model.

  * A `MathOptInterface.ModelLike` and a `DualProblem{T}`

  * A `JuMP.Model`

    The function will return a JuMP model with the dual representation of the
    problem.

  * A `JuMP.Model` and an optimizer constructor

    The function will return a JuMP model with the dual representation of the
    problem with the optimizer constructor attached.

On each of these methods, the user can provide the following keyword arguments:

  * `dual_names`: of type `DualNames` struct. It allows users to set more
    intuitive names for the dual variables and dual constraints created.

  * `variable_parameters`: A vector of MOI.VariableIndex containing the
    variables that should not be considered model variables during dualization.
    These variables will behave like constants during dualization. This is
    especially useful for the case of bi-level modelling, where the second level
    depends on some decisions from the upper level.

  * `ignore_objective`: a boolean indicating if the objective function should be
    added to the dual model. This is also useful for bi-level modelling, where
    the second level model is represented as a KKT in the upper level model.

  * `assume_min_if_feasibility`: a boolean indicating if the objective function
    is of type `MOI.FEASIBILITY_SENSE` then the objective is treated as
    `MOI.MIN_SENSE`. Therefore, the dual will have a `MOI.MAX_SENSE` objective.
    This is set to false by default, to warn users about the outcome.
"""
function dualize end

function dualize(
    primal_model::MOI.ModelLike,
    dual_problem::DualProblem = DualProblem{Float64}();
    dual_names::DualNames = EMPTY_DUAL_NAMES,
    variable_parameters::Vector{MOI.VariableIndex} = MOI.VariableIndex[],
    ignore_objective::Bool = false,
    consider_constrained_variables::Bool = true,
    assume_min_if_feasibility::Bool = false,
)
    return dualize(
        primal_model,
        dual_problem,
        dual_names,
        variable_parameters,
        ignore_objective,
        consider_constrained_variables,
        assume_min_if_feasibility,
    )
end

function dualize(
    primal_model::MOI.ModelLike,
    dual_problem::DualProblem{T},
    dual_names::DualNames,
    _variable_parameters::Vector{MOI.VariableIndex},
    ignore_objective::Bool,
    consider_constrained_variables::Bool,
    assume_min_if_feasibility::Bool = false,
) where {T}
    # Throws an error if objective function cannot be dualized
    supported_objective(primal_model)

    # Query all constraint types of the model
    con_types = MOI.get(primal_model, MOI.ListOfConstraintTypesPresent())
    supported_constraints(con_types) # Errors if constraint cant be dualized

    # merge user listed parameters and MOI.VariableIndex-in-MOI.Parameter{T}
    moi_parameters =
        _get_parameter_variables(dual_problem.primal_dual_map, primal_model)
    all_parameters = Set{MOI.VariableIndex}(_variable_parameters)
    for p in moi_parameters
        push!(all_parameters, p)
    end
    variable_parameters = collect(all_parameters)

    # Set the dual model objective sense
    _set_dual_model_sense(
        dual_problem.dual_model,
        primal_model,
        assume_min_if_feasibility,
    )

    # Get primal objective in quadratic form
    # terms already split considering parameters
    primal_objective =
        _get_primal_objective(primal_model, variable_parameters, T)

    # Cache information of which primal variables are `constrained_variables`
    # filling the a map: primal_variable_data, from original primal vars to:
    # 1) constrained variable constraint (if constrained) and 2) index (if
    # vector and constrained) and 3) dual constraint (if dual set not `Reals`),
    # 4) dual function (if dual set is `Reals`).
    # Items 3 and 4 are initialized with `nothing` at this point.
    # If the Set constant of a MOI.VariableIndex-in-Set constraint is non-zero,
    # the respective primal variable will not be a constrained variable (with
    # respect to that constraint).
    # Constrained variables are registered in `primal_constrained_variables`.
    # Since MOI.VariableIndex-in-MOI.Parameter{T} are in the variable_parameters
    # list, they are not considered constrained variables, they are parameters.
    if consider_constrained_variables
        _select_constrained_variables(
            dual_problem,
            primal_model,
            variable_parameters,
        )
    end

    # Add variables to the dual model and their dual cone constraint.
    # Return a dictionary from dual variables to primal constraints
    # constants (obj coef of dual var)
    # Loops through all constraints that are not the constraint of a
    # constrained variable (defined by `add_constrained_variables`).
    # * creates the dual variable associated with the primal constraint
    # * fills `dual_obj_affine_terms`, since we are already looping through
    #   all constraints that might have constants.
    # * fills `primal_con_to_dual_var_vec` mapping the primal constraint and the dual
    #   variable
    # * fills `primal_con_to_dual_convarcon` to map the primal constraint to a
    #   constraint in the dual variable (if there is such constraint the dual
    #   dual variable is said to be constrained). If the primal constraint's set
    #   is EqualTo or Zeros, no constraint is added in the dual variable (the
    #   dual variable is said to be free).
    # * fills `primal_con_to_primal_constants_vec` mapping primal constraints to their
    #   respective constants, which might be inside the set.
    #   this map is used in `MOI.get(::DualOptimizer,::MOI.ConstraintPrimal,ci)`
    #   that requires extra information in the case that the scalar set
    #   constrains a constant (EqualtTo, GreaterThan, LessThan)
    dual_obj_affine_terms = _add_dual_vars_in_dual_cones(
        dual_problem.dual_model,
        primal_model,
        dual_problem.primal_dual_map,
        dual_names,
        con_types,
        variable_parameters,
    )

    # Creates variables in the dual problem that represent parameters in the
    # primal model.
    # Fills `primal_parameter_to_dual_parameter` mapping parameters in the primal to parameters
    # in the dual model.
    _add_primal_parameter_vars(
        dual_problem.dual_model,
        primal_model,
        dual_problem.primal_dual_map,
        dual_names,
        variable_parameters,
        primal_objective,
        ignore_objective,
    )

    # Add dual slack variables that are associated to the primal quadratic terms
    # All primal variables that appear in the objective products will have an
    # associated dual slack variable that is created here.
    # also, `primal_var_in_quad_obj_to_dual_slack_var` is filled, mapping primal variables
    # (that appear in quadritc objective terms) to dual "slack" variables.
    _add_quadratic_slack_vars(
        dual_problem.dual_model,
        primal_model,
        dual_problem.primal_dual_map,
        dual_names,
        primal_objective,
    )

    # Add dual constraints
    # that will be equality if associated to "free variables"
    # but will be constrained in the dual set of the associated primal
    # constrained variable if such variable is not "free"
    # Also, fills the link dictionary.
    # returns `scalar_affine_terms`
    # because the terms associated to variables that are parameters will be used
    # in `_get_dual_objective`
    scalar_affine_terms = _add_dual_equality_constraints(
        dual_problem.dual_model,
        primal_model,
        dual_problem.primal_dual_map,
        dual_names,
        primal_objective,
        con_types,
        variable_parameters,
    )

    if ignore_objective
        # do not add objective
    else
        # Fill Dual Objective Coefficients Struct
        dual_objective = _get_dual_objective(
            dual_problem,
            dual_obj_affine_terms,
            primal_objective,
            scalar_affine_terms,
            variable_parameters,
        )
        # Add dual objective to the model
        _set_dual_objective(dual_problem.dual_model, dual_objective)
    end
    return dual_problem
end
