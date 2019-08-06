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
    # Attach the model backend
    if model.moi_backend.optimizer === nothing # No solver attached
        # dualize and attach to the model
        dual_problem = dualize(model.moi_backend; dual_names = dual_names)
        MOI.copy_to(JuMP.backend(JuMP_model), dual_problem.dual_model)
    elseif model.moi_backend.mode == MOIU.AUTOMATIC # Solver in automatic mode attached
        # Create an empty copy of the optimizer
        dual_problem = dualize(model.moi_backend; dual_names = dual_names)
        MOI.copy_to(JuMP.backend(JuMP_model), dual_problem.dual_model)
    else # Solver in some other mode attached
        error("Dualization does not support solvers in $(model.moi_backend.mode) mode")
    end
    return JuMP_model
end

function dualize(model::JuMP.Model, factory::OptimizerFactory; dual_names::DualNames = DualNames("", ""))
    # Dualize the JuMP model
    JuMP_model = dualize(model; dual_names = dual_names)
    # Attach an optimizer
    JuMP.set_optimizer(JuMP_model, factory)
    return JuMP_model
end

# dualize docs
"""
dualize(model)

model can be a `MOI.ModelLike` or a `JuMP.Model`
"""
function dualize end