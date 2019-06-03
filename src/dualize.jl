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
    dualmodel = Model{Float64}()

    # Set the dual model objective sense
    set_dualmodel_sense(dualmodel, model)

    # Add variables to the dual model and dual cone constraint.
    # Return a dictionary for dualvariables with primal constraints
    dualvar_primalcon_dict = add_dualmodel_variables(dualmodel, model, constr_types)

    # Get objective terms and constant
    a0, b0 = get_objective_coefficients(model)

    # Get constraints terms and constraints
    a0, b0 = get_constraints_coefficients(model)

    # Add dual equality constraint
    

    # Add dual objective function

    return dualmodel
end

"""
Add dual model with variables and dual cone constraints. 
Creates dual variables => primal constraints dict
"""
function add_dualmodel_variables(dualmodel::MOI.ModelLike, model::MOI.ModelLike, constr_types::Vector{Tuple{DataType, DataType}})
    # Adds the dual variables to the dual model, assumining the number of constraints of the model
    # is model.nextconstraintid
    MOI.add_variables(dualmodel, model.nextconstraintid) 
    dualvar_primalcon_dict = Dict{VI, CI}()
    i = 1
    for (F, S) in constr_types
        num_cons_f_s = MOI.get(model, MOI.NumberOfConstraints{F, S}()) #number of constraints {F, S}
        for con_id in 1:num_cons_f_s
            vi = VI(i)
            push!(dualvar_primalcon_dict, vi => CI{F, S}(con_id)) # Add dual variable to the dict
            add_dualcone_cosntraint(dualmodel, vi, F, S) # Add dual variable in dual cone constraint y \in C^*
            i += 1
        end
    end
    return dualvar_primalcon_dict
end


"""
    set_dualmodel_sense!(dualmodel::MOI.ModelLike, model::MOI.ModelLike)

Set the dual model objective sense
"""
function set_dualmodel_sense(dualmodel::MOI.ModelLike, model::MOI.ModelLike)
    # Get model sense
    sense = MOI.get(model, MOI.ObjectiveSense())

    # Set dual model sense
    if sense == MOI.MIN_SENSE
        MOI.set(dualmodel, MOI.ObjectiveSense(), MOI.MAX_SENSE)
    elseif sense == MOI.MAX_SENSE
        MOI.set(dualmodel, MOI.ObjectiveSense(), MOI.MIN_SENSE)
    else
        error(sense, " is not supported") # Feasibility should be supported?
    end
    return nothing
end

"""
    get_constraints_coefficients(model::MOI.ModelLike)

Get the terms of the a0 vector and the constant b as per 
http://www.juliaopt.org/MathOptInterface.jl/stable/apimanual/#Advanced-1
"""
function get_constraints_coefficients(model::MOI.ModelLike, constr_types::Vector{Tuple{DataType, DataType}})
    # Empty dictionary to store Ai and bi for each cone
    dict_coeffs = Dict{Tuple{DataType, DataType}, Tuple{Array{Float64, 2}, Vector{Float64}}}()

    for (F, S) in constr_types
        num_cons_f_s = MOI.get(model, MOI.NumberOfConstraints{F, S}()) # Number of constraints {F, S}
        Ai = zeros(Float64, model.num_variables_created, num_cons_f_s) # Empty Ai
        bi = zeros(Float64, num_cons_f_s) # Empty bi
        # Fill Ai and bi
        for con_id = 1:num_cons_f_s
            set_constraint_terms(Ai, bi, model, F, S, con_id)
        end
        push!(dict_coeffs, (F, S) => (Ai, bi))
    end

    return dict_coeffs
end

"""
    get_objective_coefficients(model::MOI.ModelLike)

Get the terms of the a0 vector and the constant b as per 
http://www.juliaopt.org/MathOptInterface.jl/stable/apimanual/#Advanced-1
"""
function get_objective_coefficients(model::MOI.ModelLike)
    # Empty vector a0 with the number of variables
    a0 = zeros(Float64, model.num_variables_created)

    # Fill a0 for each term in the objective function
    for term in model.objective.terms
        a0[term.variable_index.value] = term.coefficient
    end

    b0 = model.objective.constant # Constant term of the objective function
    return a0, b0
end