# Copyright (c) 2017: Guilherme Bodin, and contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

@testset "names" begin
    model = lp1_test()
    MOI.set(model, MOI.VariableName(), MOI.VariableIndex(1), "x1")
    MOI.set(model, MOI.VariableName(), MOI.VariableIndex(2), "x2")
    @test model.var_to_name[MOI.VariableIndex(1)] == "x1"
    @test model.var_to_name[MOI.VariableIndex(2)] == "x2"
    MOI.set(
        model,
        MOI.ConstraintName(),
        MOI.ConstraintIndex{
            MOI.ScalarAffineFunction{Float64},
            MOI.LessThan{Float64},
        }(
            1,
        ),
        "lessthan",
    )
    @test model.con_to_name[MOI.ConstraintIndex{
        MOI.ScalarAffineFunction{Float64},
        MOI.LessThan{Float64},
    }(
        1,
    )] == "lessthan"

    # Dualize without names
    dual_problem = dualize(model)
    dual_model = dual_problem.dual_model
    primal_dual_map = dual_problem.primal_dual_map
    # Query variable names
    vi_1 = primal_dual_map.primal_con_to_dual_var_vec[MOI.ConstraintIndex{
        MOI.VariableIndex,
        MOI.GreaterThan{Float64},
    }(
        1,
    )][1]
    vi_2 = primal_dual_map.primal_con_to_dual_var_vec[MOI.ConstraintIndex{
        MOI.ScalarAffineFunction{Float64},
        MOI.LessThan{Float64},
    }(
        1,
    )][1]
    @test MOI.get(dual_model, MOI.VariableName(), vi_1) == ""
    @test MOI.get(dual_model, MOI.VariableName(), vi_2) == ""
    # Query constraint names
    ci_1 = primal_dual_map.primal_var_to_dual_con[MOI.VariableIndex(1)]
    ci_2 = primal_dual_map.primal_var_to_dual_con[MOI.VariableIndex(2)]
    @test MOI.get(dual_model, MOI.ConstraintName(), ci_1) == ""
    @test MOI.get(dual_model, MOI.ConstraintName(), ci_2) == ""

    dual_problem = dualize(
        model;
        dual_names = Dualization.DualNames("dualvar_", "dualcon_"),
    )
    dual_model = dual_problem.dual_model
    primal_dual_map = dual_problem.primal_dual_map
    # Query variable names
    vi_1 = primal_dual_map.primal_con_to_dual_var_vec[MOI.ConstraintIndex{
        MOI.VariableIndex,
        MOI.GreaterThan{Float64},
    }(
        1,
    )][1]
    vi_2 = primal_dual_map.primal_con_to_dual_var_vec[MOI.ConstraintIndex{
        MOI.ScalarAffineFunction{Float64},
        MOI.LessThan{Float64},
    }(
        1,
    )][1]
    @test MOI.get(dual_model, MOI.VariableName(), vi_2) == "dualvar_lessthan_1"
    # Query constraint names
    ci_1 = primal_dual_map.primal_var_to_dual_con[MOI.VariableIndex(1)]
    ci_2 = primal_dual_map.primal_var_to_dual_con[MOI.VariableIndex(2)]
    @test MOI.get(dual_model, MOI.ConstraintName(), ci_1) == "dualcon_x1"
    @test MOI.get(dual_model, MOI.ConstraintName(), ci_2) == "dualcon_x2"
end
