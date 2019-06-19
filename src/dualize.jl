export dualize

struct PrimalDualMap
    primal_var_dual_con::Dict{VI, CI}
    dual_var_primal_con::Dict{VI, CI}
end

struct DualProblem
    dual_model::MOI.ModelLike 
    primal_dual_map::PrimalDualMap
end

"""
    dualize(model::MOI.ModelLike, ::Type{T}) where T

Dualize the model
"""
function dualize(primal_model::MOI.ModelLike)
    # Throws an error if objective function cannot be dualized
    supported_objective(primal_model) 

    # Query all constraint types of the model
    con_types = MOI.get(primal_model, MOI.ListOfConstraints())
    supported_constraints(con_types) # Throws an error if constraint cannot be dualized
    
    # Crates an empty dual model
    dual_model = Model{Float64}()

    # Set the dual model objective sense
    set_dual_model_sense(dual_model, primal_model)

    # Add variables to the dual model and their dual cone constraint.
    # Return a dictionary for dual variables with primal constraints
    dual_var_primal_con = add_dual_model_vars_in_dual_cones(dual_model, primal_model, con_types)

    # Return a dictionary with primal constraint coefficients
    con_coeffs = add_dual_model_variables(dual_model, primal_model, con_types)

    # Get Primal Objective Coefficients
    primal_objective = get_primal_objective(primal_model)

    # Add dual equality constraint and get the link dictionary
    primal_var_dual_con = add_dual_model_equality_constraints(dual_model, con_coeffs, dual_var_primal_con, 
                                                              primal_objective, primal_model.num_variables_created)

    # Fill Dual Objective Coefficients Struct
    dual_obj_coeffs = get_dual_objective(dual_model, con_coeffs, dual_var_primal_con, primal_objective)

    # Add dual objective to the model
    set_dual_objective(dual_model, dual_obj_coeffs)

    return DualProblem(dual_model, PrimalDualMap(primal_var_dual_con, dual_var_primal_con))
end