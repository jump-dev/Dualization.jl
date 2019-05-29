"""
    dualize(model::MOI.ModelLike, ::Type{T}) where T

Dualize the model
"""
function dualize(model::MOI.ModelLike, ::Type{T}) where T
    # Query all constraint types of the model
    constr_types = MOI.get(model, MOI.ListOfConstraints())
    supported_constraints(constr_types) # Throws an error if constraint cannot be dualized
    
    # Query the objective function type of the model
    obj_func_type = MOI.get(model, MOI.ObjectiveFunctionType())
    supported_objective(obj_func_type) # Throws an error if objective function cannot be dualized
    
    # Crates an empty dual model and a dictionary for dualvariables with primal constraints
    dualmodel, dualvar_primalcon_dict = create_dualmodel_variables(model, constr_types)

    # Fill the dual constraints structure
    for (F, S) in constr_types
        println(F, ", ", S)
        # Query constraints of type (F,S)
        constrs_F_S = MOI.get(model, MOI.ListOfConstraintIndices{F, S}())
        # Add the dualized constraint to the model
        for constr in constrs_F_S
            add_dual(dualmodel, constr) 
        end
    end

    # Fill the dual model with the dual objective

    return dualmodel
end

"""
Build empty dual model with variables and creates dual variables => primal constraints dict
"""
function create_dualmodel_variables(model::MOI.ModelLike, constr_types::Vector{Tuple{DataType, DataType}})
    #Declares a dual model
    dualmodel = Model{Float64}()

    # Adds the dual variables to the dual model, assumining the number of constraints of the model
    # is model.nextconstraintid
    MOI.add_variables(dualmodel, model.nextconstraintid) 
    dualvar_primalcon_dict = Dict{VI, CI}()
    i = 1
    for (F, S) in constr_types
        num_cons_f_s = MOI.get(model, MOI.NumberOfConstraints{F, S}()) #number of constraints {F, S}
        for con_id in 1:num_cons_f_s
            push!(dualvar_primalcon_dict, VI(i) => CI{F,S}(con_id))
            i += 1
        end
    end
    return dualmodel, dualvar_primalcon_dict
end