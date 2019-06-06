export dualize

"""
    dualize(model::MOI.ModelLike, ::Type{T}) where T

Dualize the model
"""
function dualize(model::MOI.ModelLike)
    # Query all constraint types of the model
    constr_types = MOI.get(model, MOI.ListOfConstraints())
    supported_constraints(constr_types) # Throws an error if constraint cannot be dualized
    
    # Query the objective function type of the model
    obj_func_type = MOI.get(model, MOI.ObjectiveFunctionType())
    supported_objective(obj_func_type) # Throws an error if objective function cannot be dualized
    
    # Crates an empty dual model
    dual_model = Model{Float64}()

    # Set the dual model objective sense
    set_dualmodel_sense(dual_model, model)

    # Add variables to the dual model and dual cone constraint.
    # Return a dictionary for dualvariables with primal constraints
    dict_dualvar_primalcon = add_dual_model_variables(dual_model, model, constr_types)

    # Get constraints terms and constraints
    dict_constr_coeffs = get_constraints_coefficients(model, constr_types)

    # Get Primal Objective Coefficients
    poc = get_POC(model)

    # Add dual equality constraint
    add_dualmodel_equality_constraints(dual_model, model, dict_constr_coeffs, dict_dualvar_primalcon, poc)

    # Fill Dual Objective Coefficients Struct
    doc = get_DOC(dual_model, dict_constr_coeffs, dict_dualvar_primalcon, poc)

    # Add dual objective to the model
    set_DOC(dual_model, doc)

    return dual_model
end

"""
    set_dualmodel_sense!(dual_model::MOI.ModelLike, model::MOI.ModelLike)

Set the dual model objective sense
"""
function set_dualmodel_sense(dual_model::MOI.ModelLike, model::MOI.ModelLike)
    # Get model sense
    sense = MOI.get(model, MOI.ObjectiveSense())

    if sense == MOI.FEASIBILITY_SENSE
        error(sense, " is not supported") # Feasibility should be supported?
    end
    # Set dual model sense
    dual_sense = (sense == MOI.MIN_SENSE) ? MOI.MAX_SENSE : MOI.MIN_SENSE
    MOI.set(dual_model, MOI.ObjectiveSense(), dual_sense)
    return nothing
end

"""
    get_constraints_coefficients(model::MOI.ModelLike)

Get the terms of the a0 vector and the constant b as per 
http://www.juliaopt.org/MathOptInterface.jl/stable/apimanual/#Advanced-1
"""
function get_constraints_coefficients(model::MOI.ModelLike, constr_types::Vector{Tuple{DataType, DataType}})
    # Empty dictionary to store Ai and bi for each cone
    dict_coeffs = Dict{Any, Tuple{Vector{Float64}, Float64}}()

    for (F, S) in constr_types
        num_cons_f_s = MOI.get(model, MOI.NumberOfConstraints{F, S}()) # Number of constraints {F, S}
        # Fill Ai and bi
        for con_id = 1:num_cons_f_s
            fill_constraint_terms(dict_coeffs, model, F, S, con_id)
        end
    end

    return dict_coeffs
end

"""
        add_dualmodel_equality_constraints(dualmodel::MOI.ModelLike, model::MOI.ModelLike, dict_constr_coeffs::Dict, 
                                            dict_dualvar_primalcon::Dict, a0::Array{T, 1}) where T

Add the dual model equality constraints
"""
function add_dualmodel_equality_constraints(dualmodel::MOI.ModelLike, model::MOI.ModelLike, dict_constr_coeffs::Dict, 
                                            dict_dualvar_primalcon::Dict, poc::POC{T}) where T
    
    sense = MOI.get(dualmodel, MOI.ObjectiveSense()) # Get dual model sense

    for var = 1:model.num_variables_created #Number of variables
        safs = Array{MOI.ScalarAffineTerm{T}}(undef, model.nextconstraintid) 
        for constr = 1:model.nextconstraintid # Number of constraints of the model
            vi = VI(constr)
            term = dict_constr_coeffs[dict_dualvar_primalcon[vi]][1][var] # Accessing Ai^T
            safs[constr] = MOI.ScalarAffineTerm(term, vi)
        end
        # Add constraint, the sense of a0 depends on the dualmodel ObjectiveSense
        # If max sense scalar term is -a0 and if min sense sacalar term is a0
        scalar_term = (sense == MOI.MAX_SENSE ? -1 : 1) * poc.affine_terms[var]
        # Add equality constraint
        MOI.add_constraint(dualmodel, MOI.ScalarAffineFunction(safs, scalar_term), MOI.EqualTo(0.0))
    end
    return nothing
end