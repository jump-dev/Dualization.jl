export dualize

"""
    dualize(model::MOI.ModelLike)

Dualize the model
"""
function dualize(primal_model::MOI.ModelLike; dual_names::DualNames = DualNames("", ""))
    return dualize(primal_model, dual_names, Float64)
end

function dualize(primal_model::MOI.ModelLike, dual_names::DualNames, T::DataType)
    # Throws an error if objective function cannot be dualized
    supported_objective(primal_model) 

    # Query all constraint types of the model
    con_types = MOI.get(primal_model, MOI.ListOfConstraints())
    supported_constraints(con_types) # Throws an error if constraint cannot be dualized
    
    # Crates an empty dual model
    dual_model = DualizableModel{T}()
    primal_dual_map = PrimalDualMap{T}()
    
    # Set the dual model objective sense
    set_dual_model_sense(dual_model, primal_model)

    # Get Primal Objective Coefficients
    primal_objective = get_primal_objective(primal_model)

    # Add variables to the dual model and their dual cone constraint.
    # Return a dictionary for dual variables with primal constraints
    dual_obj_affine_terms = add_dual_vars_in_dual_cones(dual_model, primal_model, primal_dual_map,
                                                        dual_names, con_types)
    
    # Fill Dual Objective Coefficients Struct
    dual_objective = get_dual_objective(dual_model, dual_obj_affine_terms, primal_objective)

    # Add dual objective to the model
    set_dual_objective(dual_model, dual_objective)

    # Add dual equality constraint and get the link dictionary
    add_dual_equality_constraints(dual_model, primal_model,
                                  primal_dual_map, dual_names,
                                  primal_objective, con_types)

    return DualProblem(dual_model, primal_dual_map)
end