export dualize

# MOI dualize
function dualize(
    primal_model::MOI.ModelLike;
    dual_names::DualNames = EMPTY_DUAL_NAMES,
    variable_parameters::Vector{VI} = VI[],
    ignore_objective::Bool = false,
)
    # Creates an empty dual problem
    dual_problem = DualProblem{Float64}()
    return dualize(
        primal_model,
        dual_problem,
        dual_names,
        variable_parameters,
        ignore_objective,
    )
end

function dualize(
    primal_model::MOI.ModelLike,
    dual_problem::DualProblem{T};
    dual_names::DualNames = EMPTY_DUAL_NAMES,
    variable_parameters::Vector{VI} = VI[],
    ignore_objective::Bool = false,
) where {T}
    # Dualize with the optimizer already attached
    return dualize(
        primal_model,
        dual_problem,
        dual_names,
        variable_parameters,
        ignore_objective,
    )
end

function dualize(
    primal_model::MOI.ModelLike,
    dual_problem::DualProblem{T},
    dual_names::DualNames,
    variable_parameters::Vector{VI},
    ignore_objective::Bool,
) where {T}
    # Throws an error if objective function cannot be dualized
    supported_objective(primal_model)

    # Query all constraint types of the model
    con_types = MOI.get(primal_model, MOI.ListOfConstraintTypesPresent())
    supported_constraints(con_types) # Errors if constraint cant be dualized

    # Set the dual model objective sense
    set_dual_model_sense(dual_problem.dual_model, primal_model)

    # Get primal objective in quadratic form
    # terms already split considering parameters
    primal_objective =
        get_primal_objective(primal_model, variable_parameters, T)

    # cache information of which variables as `constrained_variables`
    # creating a map: constrained_var_idx, from original vars to original
    # constrains and their internal index (if vector constrains), 1 otherwise.
    # and initializes the map: constrained_var_dual, from original ci
    # to the dual constraint (latter is initilized as empty at this point).
    add_constrained_variables(dual_problem, primal_model, variable_parameters)

    # Add variables to the dual model and their dual cone constraint.
    # Return a dictionary from dual variables to primal constraints
    # constants (obj coef of dual var)
    dual_obj_affine_terms = add_dual_vars_in_dual_cones(
        dual_problem.dual_model,
        primal_model,
        dual_problem.primal_dual_map,
        dual_names,
        con_types,
    )

    add_primal_parameter_vars(
        dual_problem.dual_model,
        primal_model,
        dual_problem.primal_dual_map,
        dual_names,
        variable_parameters,
        primal_objective,
        ignore_objective,
    )

    add_quadratic_slack_vars(
        dual_problem.dual_model,
        primal_model,
        dual_problem.primal_dual_map,
        dual_names,
        primal_objective,
    )

    # Add dual equality constraint and get the link dictionary
    scalar_affine_terms = add_dual_equality_constraints(
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
        dual_objective = get_dual_objective(
            dual_problem,
            dual_obj_affine_terms,
            primal_objective,
            con_types,
            scalar_affine_terms,
            variable_parameters,
        )
        # Add dual objective to the model
        set_dual_objective(dual_problem.dual_model, dual_objective)
    end
    return dual_problem
end

# JuMP dualize
function dualize(model::JuMP.Model; dual_names::DualNames = EMPTY_DUAL_NAMES)
    # Create an empty JuMP model
    JuMP_model = JuMP.Model()

    if JuMP.mode(model) != JuMP.AUTOMATIC # Only works in AUTOMATIC mode
        error(
            "Dualization does not support solvers in $(model.moi_backend.mode) mode",
        )
    end
    # Dualize and attach to the model
    dualize(
        backend(model),
        DualProblem(backend(JuMP_model));
        dual_names = dual_names,
    )
    fill_obj_dict_with_variables!(JuMP_model)
    fill_obj_dict_with_constraints!(JuMP_model)
    return JuMP_model
end

function dualize(
    model::JuMP.Model,
    optimizer_constructor;
    dual_names::DualNames = EMPTY_DUAL_NAMES,
)
    # Dualize the JuMP model
    dual_JuMP_model = dualize(model; dual_names = dual_names)
    # Set the optimizer
    JuMP.set_optimizer(dual_JuMP_model, optimizer_constructor)
    return dual_JuMP_model
end

# dualize docs
"""
    dualize(args...; kwargs...)

The `dualize` function works in three different ways. The user can provide:

* A `MathOptInterface.ModelLike`

The function will return a `DualProblem` struct that has the dualized model
and `PrimalDualMap{Float64}` for users to identify the links between primal
and dual model. The `PrimalDualMap{Float64}` maps variables and constraints
from the original primal model into the respective objects of the dual model.

* A `MathOptInterface.ModelLike` and a `DualProblem{T}`

* A `JuMP.Model`

The function will return a JuMP model with the dual representation of the problem.

* A `JuMP.Model` and an optimizer constructor

The function will return a JuMP model with the dual representation of the problem with
the optimizer constructor attached.

On each of these methods, the user can provide the following keyword arguments:

* `dual_names`: of type `DualNames` struct. It allows users to set more intuitive names
for the dual variables and dual constraints created.

* `variable_parameters`: A vector of MOI.VariableIndex containing the variables that
should not be considered model variables during dualization. These variables will behave
like constants during dualization. This is specially useful for the case of bi-level
modelling, where the second level depends on some decisions from the upper level.

* `ignore_objective`: a boolean indicating if the objective function should be
added to the dual model. This is also useful for bi-level modelling, where the second
level model is represented as a KKT in the upper level model.

"""
function dualize end

function fill_obj_dict_with_variables!(model::JuMP.Model)
    all_indices = MOI.get(
        model,
        JuMP.MOI.ListOfVariableIndices(),
    )::Vector{MOI.VariableIndex}
    for vi in all_indices
        model.obj_dict[Symbol(
            MOI.get(backend(model), MOI.VariableName(), vi),
        )] = VariableRef(model, vi)
    end
    return model
end

function fill_obj_dict_with_constraints!(model::JuMP.Model)
    con_types = MOI.get(model, JuMP.MOI.ListOfConstraintTypesPresent())
    for (F, S) in con_types
        fill_obj_dict_with_constraints!(model, F, S)
    end
    return model
end

function fill_obj_dict_with_constraints!(model::JuMP.Model, F::Type, S::Type)
    for ci in MOI.get(backend(model), MOI.ListOfConstraintIndices{F,S}())
        name = MOI.get(backend(model), MOI.ConstraintName(), ci)
        if F <: MOI.AbstractScalarFunction
            model.obj_dict[Symbol(name)] =
                ConstraintRef(model, ci, JuMP.ScalarShape())
        elseif S <: MOI.AbstractVectorFunction
            model.obj_dict[Symbol(name)] =
                ConstraintRef(model, ci, JuMP.VectorShape())
        else
            continue
        end
    end
end
