export dualize

struct PrimalDualLink
    primal_var_dual_con::Dict{VI, CI}
    dual_var_primal_con::Dict{VI, CI}
end

const PDLink = PrimalDualLink

struct DualProblem
    dual_model::MOI.ModelLike 
    pd_link::PDLink
end

"""
    dualize(model::MOI.ModelLike, ::Type{T}) where T

Dualize the model
"""
function dualize(primal_model::MOI.ModelLike)
    # Throws an error if objective function cannot be dualized
    supported_objective(primal_model) 

    # Query all constraint types of the model
    constr_types = MOI.get(primal_model, MOI.ListOfConstraints())
    supported_constraints(constr_types) # Throws an error if constraint cannot be dualized
    
    # Crates an empty dual model
    dual_model = Model{Float64}()

    # Set the dual model objective sense
    set_dual_model_sense(dual_model, primal_model)

    # Add variables to the dual model and dual cone constraint.
    # Return a dictionary for dualvariables with primal constraints
    # Return a dictionary with primal constraint coefficients
    dual_var_primal_con, constr_coeffs = add_dual_model_variables(dual_model, primal_model, constr_types)

    # Get Primal Objective Coefficients
    poc = get_POC(primal_model)

    # Add dual equality constraint and get the link dictionary
    num_primal_variables = primal_model.num_variables_created
    primal_var_dual_con = add_dual_model_equality_constraints(dual_model, constr_coeffs, dual_var_primal_con, poc, num_primal_variables)

    # Fill Dual Objective Coefficients Struct
    doc = get_DOC(dual_model, constr_coeffs, dual_var_primal_con, poc)

    # Add dual objective to the model
    set_DOC(dual_model, doc)

    return DualProblem(dual_model, PDLink(primal_var_dual_con, dual_var_primal_con))
end