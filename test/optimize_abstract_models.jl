# Copyright (c) 2017: Guilherme Bodin, and contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

"""
Attach an MOI.ModelLike to an optimizer,
solve it and retrieve the termination status and objective value
"""
function solve_abstract_model(model::MOI.ModelLike, optimizer_constructor)
    JuMP_model = JuMP.Model()
    MOI.copy_to(JuMP.backend(JuMP_model), model)
    set_optimizer(JuMP_model, optimizer_constructor)
    optimize!(JuMP_model)
    termination_status = JuMP.termination_status(JuMP_model)
    obj_val = try
        JuMP.objective_value(JuMP_model)
    catch
        NaN
    end
    return termination_status, obj_val
end

"""
Test if strong duality holds for a problem
"""
function test_strong_duality(
    primal_model::MOI.ModelLike,
    dual_model::MOI.ModelLike,
    optimizer_constructor,
    atol::Float64,
    rtol::Float64,
)
    primal_term_status, primal_obj_val =
        solve_abstract_model(primal_model, optimizer_constructor)
    dual_term_status, dual_obj_val =
        solve_abstract_model(dual_model, optimizer_constructor)

    if primal_term_status == dual_term_status == MOI.OPTIMAL
        return isapprox(primal_obj_val, dual_obj_val; atol = atol, rtol = rtol)
    elseif (primal_term_status == MOI.INFEASIBLE) &&
           (dual_term_status == MOI.DUAL_INFEASIBLE)
        return true
    elseif (primal_term_status == MOI.DUAL_INFEASIBLE) &&
           (dual_term_status == MOI.INFEASIBLE)
        return true
    elseif (primal_term_status == MOI.DUAL_INFEASIBLE) &&
           (dual_term_status == MOI.INFEASIBLE_OR_UNBOUNDED)
        return true
    elseif (primal_term_status == MOI.INFEASIBLE_OR_UNBOUNDED) &&
           (dual_term_status == MOI.DUAL_INFEASIBLE)
        return true
    end
    @show primal_term_status, primal_obj_val
    @show dual_term_status, dual_obj_val
    return false # In case strong duality doesn't hold
end

function test_strong_duality(
    primal_problems::Vector,
    optimizer_constructor;
    atol = 1e-6,
    rtol = 1e-4,
)
    for primal_problem in primal_problems
        dual_problem = dualize(primal_problem())
        @testset "$primal_problem" begin
            @test test_strong_duality(
                primal_problem(),
                dual_problem.dual_model,
                optimizer_constructor,
                atol,
                rtol,
            )
        end
    end
end
