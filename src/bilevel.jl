
struct Complements#{M1 <: MOI.ModelLike, M2 <: MOI.ModelLike, F, S}
    # primal::M1
    func#::F
    set#::S
    # dual::M2
    variable#::VI
end

function get_complements(primal_model, dual_model, primal_dual_map)
    map = primal_dual_map.primal_con_dual_var
    out = Complements[]
    for i in map
        func = MOI.get(primal_model, MOI.ConstraintFunction(), i[1])
        set = MOI.get(primal_model, MOI.ConstraintSet(), i[1])
        con = Complements(func, set, i[2])
        push!(out, con)
    end
    return out
end

function build_bilivel(upper::MOI.ModelLike, lower::MOI.ModelLike,
                       link::Dict{VI,VI}, upper_variables)
    
    # Start with an empty problem
    mode = MOIU.AUTOMATIC
    m = MOIU.CachingOptimizer(MOIU.Model{Float64}(), mode)

    # add the first level
    copy_names = false
    upper_idxmap = MOIU.default_copy_to(m, upper, copy_names)

    # append the second level primal
    lower_idxmap = MOIU.IndexMap()

    for i in keys(upper_idxmap.varmap)
        lower_idxmap[link[i]] = upper_idxmap[i]
    end

    append_to(m, lower, lower_idxmap, copy_names)

    # dualize the second level
    dual_problem = dualize(lower, variable_parameters = upper_variables, ignore_objective = true)
    lower_dual = dual_problem.dual_model
    lower_primal_dual_map = dual_problem.primal_dual_map

    # appende the second level dual
    lower_dual_idxmap = MOIU.IndexMap()

    append_to(m, lower_dual, lower_dual_idxmap, copy_names)

    # complete KKT
    # 1 - primal dual equality (quadratic equality constraint)
    # 1a - no slacks
    # 1b - use slack
    # 2 - complementarity
    # 2a - actual complementarity constraints
    # 2b - SOS1 (slack * duals)
    # 2c - Big-M formulation (Fortuny-Amat and McCarl, 1981)
    # 3 - NLP (y = argmin_y problem)

end

function append_to(dest::MOI.ModelLike, src::MOI.ModelLike, idxmap, copy_names::Bool)
    # MOI.empty!(dest)

    # idxmap = MOIU.IndexMap()

    vis_src = MOI.get(src, MOI.ListOfVariableIndices())
    constraint_types = MOI.get(src, MOI.ListOfConstraints())
    single_variable_types = [S for (F, S) in constraint_types
                             if F == MOI.SingleVariable]
    vector_of_variables_types = [S for (F, S) in constraint_types
                                 if F == MOI.VectorOfVariables]

    # The `NLPBlock` assumes that the order of variables does not change (#849)
    if MOI.NLPBlock() in MOI.get(src, MOI.ListOfModelAttributesSet())
        error("not nlp for now")
        vector_of_variables_not_added = [
            MOI.get(src, MOI.ListOfConstraintIndices{MOI.VectorOfVariables, S}())
            for S in vector_of_variables_types
        ]
        single_variable_not_added = [
            MOI.get(src, MOI.ListOfConstraintIndices{MOI.SingleVariable, S}())
            for S in single_variable_types
        ]
    else
        vector_of_variables_not_added = [
            MOIU.copy_vector_of_variables(dest, src, idxmap, S)
            for S in vector_of_variables_types
        ]
        single_variable_not_added = [
            MOIU.copy_single_variable(dest, src, idxmap, S)
            for S in single_variable_types
        ]
    end

    MOIU.copy_free_variables(dest, idxmap, vis_src, MOI.add_variables)

    # Copy variable attributes
    # pass_attributes(dest, src, copy_names, idxmap, vis_src)

    # Copy model attributes
    # pass_attributes(dest, src, copy_names, idxmap)

    # Copy constraints
    MOIU.pass_constraints(dest, src, copy_names, idxmap,
                     single_variable_types, single_variable_not_added,
                     vector_of_variables_types, vector_of_variables_not_added)

    return idxmap
end