# Copyright (c) 2017: Guilherme Bodin, and contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

@testset "pow problems" begin
    @testset "pow1_test" begin
        #=
        primal
            max z
        s.t.
            x^0.9 * y^(0.1) >= |z| (i.e (x, y, z) are in the 3d power cone with a=0.9) :w_3, w_4, w_5
            x == 2 :w_2
            y == 1 :w_2
        dual
            min -w_2 - 2w_1
        s.t.
            w_1 + w_3 == 0
            w_2 + w_4 == 0
            w_5 == -1
            (w_3, w_4, w_5) ∈ DualPowerCone
        =#
        primal_model = pow1_test()
        dual_model, primal_dual_map = dual_model_and_map(primal_model)

        @test MOI.get(dual_model, MOI.NumberOfVariables()) == 2
        list_of_cons = MOI.get(dual_model, MOI.ListOfConstraintTypesPresent())
        @test Set(list_of_cons) == Set([(
            MOI.VectorAffineFunction{Float64},
            MOI.DualPowerCone{Float64},
        )],)
        @test MOI.get(
            dual_model,
            MOI.NumberOfConstraints{
                MOI.VectorAffineFunction{Float64},
                MOI.DualPowerCone{Float64},
            }(),
        ) == 1
        obj_type = MOI.get(dual_model, MOI.ObjectiveFunctionType())
        @test obj_type == MOI.ScalarAffineFunction{Float64}
        obj = MOI.get(dual_model, MOI.ObjectiveFunction{obj_type}())
        @test MOI.get(dual_model, MOI.ObjectiveSense()) == MOI.MIN_SENSE
        @test MOI.constant(obj) == 0.0
        @test Set(MOI.coefficient.(obj.terms)) == Set([-1.0; -2.0])
    end

    @testset "pow2_test" begin
        #=
        primal
            max z
        s.t.
            x^0.9 * y^(0.1) >= |z| (i.e (x, y, z) are in the 3d power cone with a=0.9) :w_3, w_4, w_5
            x == 2 :w_2
            y == 1 :w_2
        dual
            min -w_2 - 2w_1
        s.t.
            w_1 + w_3 == 0
            w_2 + w_4 == 0
            w_5 == -1
            (w_3, w_4, w_5) ∈ DualPowerCone
        =#
        primal_model = pow2_test()
        dual_model, primal_dual_map = dual_model_and_map(primal_model)

        @test MOI.get(dual_model, MOI.NumberOfVariables()) == 5
        list_of_cons = MOI.get(dual_model, MOI.ListOfConstraintTypesPresent())
        @test Set(list_of_cons) == Set(
            [
                (MOI.ScalarAffineFunction{Float64}, MOI.EqualTo{Float64})
                (MOI.VectorOfVariables, MOI.DualPowerCone{Float64})
            ],
        )
        @test MOI.get(
            dual_model,
            MOI.NumberOfConstraints{
                MOI.VectorOfVariables,
                MOI.DualPowerCone{Float64},
            }(),
        ) == 1
        @test MOI.get(
            dual_model,
            MOI.NumberOfConstraints{
                MOI.ScalarAffineFunction{Float64},
                MOI.EqualTo{Float64},
            }(),
        ) == 3
        obj_type = MOI.get(dual_model, MOI.ObjectiveFunctionType())
        @test obj_type == MOI.ScalarAffineFunction{Float64}
        obj = MOI.get(dual_model, MOI.ObjectiveFunction{obj_type}())
        @test MOI.get(dual_model, MOI.ObjectiveSense()) == MOI.MIN_SENSE
        @test MOI.constant(obj) == 0.0
        @test MOI.coefficient.(obj.terms) == [-1.0; -2.0]

        eq_con1, eq_con2, eq_con3 = MOI.get(
            dual_model,
            MOI.ListOfConstraintIndices{
                MOI.ScalarAffineFunction{Float64},
                MOI.EqualTo{Float64},
            }(),
        )
        pow_con = MOI.get(
            dual_model,
            MOI.ListOfConstraintIndices{
                MOI.VectorOfVariables,
                MOI.DualPowerCone{Float64},
            }(),
        )

        eq_con1_fun = MOI.get(dual_model, MOI.ConstraintFunction(), eq_con1)
        eq_con1_set = MOI.get(dual_model, MOI.ConstraintSet(), eq_con1)
        @test MOI.coefficient.(eq_con1_fun.terms) == [1.0; 1.0]
        @test MOI.constant.(eq_con1_fun) == 0.0
        @test MOI.constant(eq_con1_set) == 0.0
        eq_con2_fun = MOI.get(dual_model, MOI.ConstraintFunction(), eq_con2)
        eq_con2_set = MOI.get(dual_model, MOI.ConstraintSet(), eq_con2)
        @test MOI.coefficient.(eq_con2_fun.terms) == [1.0; 1.0]
        @test MOI.constant.(eq_con2_fun) == 0.0
        @test MOI.constant(eq_con2_set) == 0.0
        eq_con3_fun = MOI.get(dual_model, MOI.ConstraintFunction(), eq_con3)
        eq_con3_set = MOI.get(dual_model, MOI.ConstraintSet(), eq_con3)
        @test MOI.coefficient.(eq_con3_fun.terms) == [1.0]
        @test MOI.constant.(eq_con3_fun) == 0.0
        @test MOI.constant(eq_con3_set) == -1.0

        dual_pow_con = MOI.get(dual_model, MOI.ConstraintFunction(), pow_con)

        primal_con_to_dual_var_vec = primal_dual_map.primal_con_to_dual_var_vec
        @test primal_con_to_dual_var_vec[eq_con1] == [MOI.VariableIndex(1)]
        @test primal_con_to_dual_var_vec[eq_con2] == [MOI.VariableIndex(2)]

        primal_var_to_dual_con = primal_dual_map.primal_var_to_dual_con
        @test primal_var_to_dual_con[MOI.VariableIndex(1)] == eq_con1
        @test primal_var_to_dual_con[MOI.VariableIndex(2)] == eq_con2
        @test primal_var_to_dual_con[MOI.VariableIndex(3)] == eq_con3
    end
end
