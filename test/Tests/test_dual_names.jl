@testset "names" begin
    model = lp1_test()
    MOI.set(model, MOI.VariableName(), VI(1), "x1")
    MOI.set(model, MOI.VariableName(), VI(2), "x2")
    @test model.var_to_name[VI(1)] == "x1"
    @test model.var_to_name[VI(2)] == "x2"
    MOI.set(model, MOI.ConstraintName(), CI{SAF{Float64}, MOI.LessThan{Float64}}(1), "lessthan")
    MOI.set(model, MOI.ConstraintName(), CI{SVF, MOI.GreaterThan{Float64}}(1), "greaterthan1")
    @test model.con_to_name[CI{SAF{Float64}, MOI.LessThan{Float64}}(1)] == "lessthan"
    @test model.con_to_name[CI{SVF, MOI.GreaterThan{Float64}}(1)] == "greaterthan1"
    # Dualize
    dual_problem = dualize(model)
    dual_model = dual_problem.dual_model
    primal_dual_map = dual_problem.primal_dual_map
    # Query variable names
    vi_1 = primal_dual_map.primal_con_dual_var[CI{SVF, MOI.GreaterThan{Float64}}(1)][1]
    vi_2 = primal_dual_map.primal_con_dual_var[CI{SAF{Float64}, MOI.LessThan{Float64}}(1)][1]
    @test MOI.get(dual_model, MOI.VariableName(), vi_1) == "greaterthan1_1"
    @test MOI.get(dual_model, MOI.VariableName(), vi_2) == "lessthan_1"
    # Query constraint names
    ci_1 = primal_dual_map.primal_var_dual_con[VI(1)]
    ci_2 = primal_dual_map.primal_var_dual_con[VI(2)]
    @test MOI.get(dual_model, MOI.ConstraintName(), ci_1) == "x1"
    @test MOI.get(dual_model, MOI.ConstraintName(), ci_2) == "x2"

    dual_problem = dualize(model; dual_names = Dualization.DualNames("dualvar_", "dualcon_"))
    dual_model = dual_problem.dual_model
    primal_dual_map = dual_problem.primal_dual_map
    # Query variable names
    vi_1 = primal_dual_map.primal_con_dual_var[CI{SVF, MOI.GreaterThan{Float64}}(1)][1]
    vi_2 = primal_dual_map.primal_con_dual_var[CI{SAF{Float64}, MOI.LessThan{Float64}}(1)][1]
    @test MOI.get(dual_model, MOI.VariableName(), vi_1) == "dualvar_greaterthan1_1"
    @test MOI.get(dual_model, MOI.VariableName(), vi_2) == "dualvar_lessthan_1"
    # Query constraint names
    ci_1 = primal_dual_map.primal_var_dual_con[VI(1)]
    ci_2 = primal_dual_map.primal_var_dual_con[VI(2)]
    @test MOI.get(dual_model, MOI.ConstraintName(), ci_1) == "dualcon_x1"
    @test MOI.get(dual_model, MOI.ConstraintName(), ci_2) == "dualcon_x2"
end