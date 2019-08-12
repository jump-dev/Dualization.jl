export dualize

# MOI dualize
function dualize(primal_model::MOI.ModelLike; dual_names::DualNames = DualNames("", ""))
    # Creates an empty dual problem
    dual_problem = DualProblem{Float64}()
    return dualize(primal_model, dual_problem, dual_names)
end

function dualize(primal_model::MOI.ModelLike, dual_problem::DualProblem{T}; 
                 dual_names::DualNames = DualNames("", "")) where T
    # Dualize with the optimizer already attached
    return dualize(primal_model, dual_problem, dual_names)
end

function dualize(primal_model::MOI.ModelLike, dual_problem::DualProblem{T}, dual_names::DualNames) where T
    # Throws an error if objective function cannot be dualized
    supported_objective(primal_model) 

    # Query all constraint types of the model
    con_types = MOI.get(primal_model, MOI.ListOfConstraints())
    supported_constraints(con_types) # Throws an error if constraint cannot be dualized
    
    # Set the dual model objective sense
    set_dual_model_sense(dual_problem.dual_model, primal_model)

    # Get Primal Objective Coefficients
    primal_objective = get_primal_objective(primal_model)

    # Add variables to the dual model and their dual cone constraint.
    # Return a dictionary for dual variables with primal constraints
    dual_obj_affine_terms = add_dual_vars_in_dual_cones(dual_problem.dual_model, primal_model, 
                                                        dual_problem.primal_dual_map,
                                                        dual_names, con_types)
    
    # Fill Dual Objective Coefficients Struct
    dual_objective = get_dual_objective(dual_problem.dual_model, 
                                        dual_obj_affine_terms, primal_objective)

    # Add dual objective to the model
    set_dual_objective(dual_problem.dual_model, dual_objective)

    # Add dual equality constraint and get the link dictionary
    add_dual_equality_constraints(dual_problem.dual_model, primal_model,
                                  dual_problem.primal_dual_map, dual_names,
                                  primal_objective, con_types)

    return dual_problem
end

# JuMP dualize
function dualize(model::JuMP.Model; dual_names::DualNames = DualNames("", ""))
    # Create an empty JuMP model
    JuMP_model = JuMP.Model()

    if JuMP.mode(model) != JuMP.AUTOMATIC # Only works in AUTOMATIC mode
        error("Dualization does not support solvers in $(model.moi_backend.mode) mode")
    end
    # Dualize and attach to the model
    dualize(backend(model), DualProblem(backend(JuMP_model)); dual_names = dual_names)
    
    return JuMP_model
end

function dualize(model::JuMP.Model, factory::OptimizerFactory; dual_names::DualNames = DualNames("", ""))
    # Dualize the JuMP model
    dual_JuMP_model = dualize(model; dual_names = dual_names)
    # Set the optimizer
    JuMP.set_optimizer(dual_JuMP_model, factory)
    return dual_JuMP_model
end

# dualize docs
"""
    dualize(args...; kwargs...)

The `dualize` function works in three different ways. The user can provide:

* A `MathOptInterface.ModelLike`

The function will return a `DualProblem` struct that has the dualized model
and `PrimalDualMap{Float64}` for users to identify the links between primal and dual model.

* A `MathOptInterface.ModelLike` and a `DualProblem{T}`

* A `JuMP.Model`

The function will return a JuMP model with the dual representation of the problem.

* A `JuMP.Model` and an optimizer factory

The function will return a JuMP model with the dual representation of the problem with 
the `OptimizerFactory` attached. The `OptimizerFactory` is the solver and its key arguments
that users provide in JuMP models, i.e. `with_optimizer(GLPK.Optimizer)`.

On each of these methods, the user can provide the keyword argument `dual_names`.
`dual_names` must be a `DualNames` struct. It allows users to set more intuitive names 
for the dual variables and dual constraints created.
"""
function dualize end
