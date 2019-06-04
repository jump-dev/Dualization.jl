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
    dict_dualvar_primalcon = add_dualmodel_variables(dualmodel, model, constr_types)

    # Get objective terms and constant
    a0, b0 = get_objective_coefficients(model)

    # Get constraints terms and constraints
    dict_constr_coeffs = get_constraints_coefficients(model, constr_types)

    # Add dual equality constraint
    add_dualmodel_equality_constraints(dualmodel, model, dict_constr_coeffs, dict_dualvar_primalcon, a0)

    # Add dual objective function
    add_dualmodel_objective(dualmodel, model, dict_constr_coeffs, dict_dualvar_primalcon, b0)

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
    dict_dualvar_primalcon = Dict{VI, CI}()
    i = 1
    for (F, S) in constr_types
        num_cons_f_s = MOI.get(model, MOI.NumberOfConstraints{F, S}()) # Number of constraints {F, S}
        for con_id = 1:num_cons_f_s
            vi = VI(i)
            ci = get_ci(model, F, S, con_id)
            push!(dict_dualvar_primalcon, vi => ci) # Add dual variable to the dict
            add_dualcone_constraint(dualmodel, vi, F, S) # Add dual variable in dual cone constraint y \in C^*
            i += 1
        end
    end
    return dict_dualvar_primalcon
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

"""
        add_dualmodel_equality_constraints(dualmodel::MOI.ModelLike, model::MOI.ModelLike, dict_constr_coeffs::Dict, 
                                            dict_dualvar_primalcon::Dict, a0::Array{T, 1}) where T

Add the dual model equality constraints
"""
function add_dualmodel_equality_constraints(dualmodel::MOI.ModelLike, model::MOI.ModelLike, dict_constr_coeffs::Dict, 
                                            dict_dualvar_primalcon::Dict, a0::Array{T, 1}) where T
    
    sense = MOI.get(dualmodel, MOI.ObjectiveSense()) # Get dual model sense

    for var = 1:model.num_variables_created #Number of variables
        safs = Array{MOI.ScalarAffineTerm{T}}(undef, model.nextconstraintid) 
        for constr = 1:model.nextconstraintid # Number of constraints of the model
            vi = VI(constr)
            term = dict_constr_coeffs[dict_dualvar_primalcon[vi]][1][var] # Accessing Ai^T
            safs[constr] = MOI.ScalarAffineTerm(term, vi)
        end
        # Add constraint, the sense of a0 depends on the dualmodel ObjectiveSense
        if sense == MOI.MAX_SENSE 
            MOI.add_constraint(dualmodel, MOI.ScalarAffineFunction(safs, a0[var]), MOI.EqualTo(0.0))
        else
            MOI.add_constraint(dualmodel, MOI.ScalarAffineFunction(safs, -a0[var]), MOI.EqualTo(0.0))
        end
    end
    return nothing
end

"""
    add_dualmodel_objective(dualmodel::MOI.ModelLike, model::MOI.ModelLike, dict_constr_coeffs::Dict, 
                            dict_dualvar_primalcon::Dict, b0::T) where T

Add the objective function to the dual model
"""
function add_dualmodel_objective(dualmodel::MOI.ModelLike, model::MOI.ModelLike, dict_constr_coeffs::Dict, 
                                 dict_dualvar_primalcon::Dict, b0::T) where T

    sense = MOI.get(dualmodel, MOI.ObjectiveSense()) # Get dual model sense

    term_vec = Array{T}(undef, model.nextconstraintid)
    vi_vec   = Array{VI}(undef, dualmodel.num_variables_created)
    for constr = 1:model.nextconstraintid # Number of constraints of the model
        vi = VI(constr)
        term = dict_constr_coeffs[dict_dualvar_primalcon[vi]][2] # Accessing Ai^T
        if sense == MOI.MAX_SENSE 
            term_vec[constr] = term
        else
            term_vec[constr] = -term
        end
        vi_vec[constr] = vi
    end

    # Find all non zero terms of terms_vec
    non_zero_terms = findall(x -> x != 0, term_vec)
    # Set dual model objective function
    MOI.set(dualmodel, MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(),  
            MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.(term_vec[non_zero_terms], vi_vec[non_zero_terms]), b0)
            )
    return nothing
end