"""
Attach an AbstractModel{T} to an optimizer, 
solve it and retrieve the termination status and objective value
"""
function solve_abstract_model(model::MOIU.AbstractModel{T}, optimizer) where T
    JuMP_model = JuMP.Model()
    MOI.copy_to(JuMP.backend(JuMP_model), model)
    set_optimizer(JuMP_model, with_optimizer(optimizer))
    optimize!(JuMP_model)
    termination_status = JuMP.termination_status(JuMP_model)
    obj_val = JuMP.objective_value(JuMP_model)
    return termination_status, obj_val
end

"""
Test if strong duality holds for a primal dual pair
"""
function test_strong_duality(primal_model::MOIU.AbstractModel{T}, 
                             dual_model::MOIU.AbstractModel{T}, optimizer) where T

    primal_term_status, primal_obj_val = solve_abstract_model(primal_model, optimizer)
    dual_term_status, dual_obj_val = solve_abstract_model(dual_model, optimizer)

    if primal_term_status == dual_term_status == MOI.OPTIMAL
        return primal_obj_val == dual_obj_val
    elseif (primal_term_status == MOI.INFEASIBLE) && (dual_term_status == MOI.DUAL_INFEASIBLE)
        return true
    elseif (primal_term_status == MOI.DUAL_INFEASIBLE) && (dual_term_status == MOI.INFEASIBLE)
        return true
    elseif (primal_term_status == MOI.INFEASIBLE_OR_UNBOUNDED) && (dual_term_status == MOI.INFEASIBLE_OR_UNBOUNDED)
        @warn("Both infeasible or unbounded, review this case")
        return true
    end
    return false # In case strong duality doesn't hold
end