# Copyright (c) 2017: Guilherme Bodin, and contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

@testset "soc problems" begin
    @testset "soc1_test" begin
        #=
        primal
           max 0x + 1y + 1z
        s.t.
           x == 1          :w_4
           x >= ||(y,z)||  :w_1, w_2, w_3
        dual
           min -w_4
        s.t.
           w_2 == -1
           w_3 == -1
           w_1 + w_4 == 0
           w_1 >= ||(w_2, w_3)||
        =#
        primal_model = soc1_test()
        dual_model, primal_dual_map = dual_model_and_map(primal_model)

        @test MOI.get(dual_model, MOI.NumberOfVariables()) == 1
        list_of_cons = MOI.get(dual_model, MOI.ListOfConstraintTypesPresent())
        @test Set(list_of_cons) ==
              Set([(MOI.VectorAffineFunction{Float64}, MOI.SecondOrderCone)],)
        @test MOI.get(
            dual_model,
            MOI.NumberOfConstraints{
                MOI.VectorAffineFunction{Float64},
                MOI.SecondOrderCone,
            }(),
        ) == 1
        obj_type = MOI.get(dual_model, MOI.ObjectiveFunctionType())
        @test obj_type == MOI.ScalarAffineFunction{Float64}
        obj = MOI.get(dual_model, MOI.ObjectiveFunction{obj_type}())
        @test MOI.constant(obj) == 0.0
        @test MOI.coefficient.(obj.terms) == [-1.0]
    end

    @testset "soc2_test" begin
        #=
        primal
           max 0x + 1y + 1z
        s.t.
           x == 1          :w_4
           x >= ||(y,z)||  :w_1, w_2, w_3
        dual
           min -w_4
        s.t.
           w_2 == -1
           w_3 == -1
           w_1 + w_4 == 0
           w_1 >= ||(w_2, w_3)||
        =#
        primal_model = soc2_test()
        dual_model, primal_dual_map = dual_model_and_map(primal_model)

        @test MOI.get(dual_model, MOI.NumberOfVariables()) == 4
        list_of_cons = MOI.get(dual_model, MOI.ListOfConstraintTypesPresent())
        @test Set(list_of_cons) == Set(
            [
                (MOI.ScalarAffineFunction{Float64}, MOI.EqualTo{Float64})
                (MOI.VectorOfVariables, MOI.SecondOrderCone)
            ],
        )
        @test MOI.get(
            dual_model,
            MOI.NumberOfConstraints{MOI.VectorOfVariables,MOI.SecondOrderCone}(),
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
        @test MOI.constant(obj) == 0.0
        @test MOI.coefficient.(obj.terms) == [-1.0]

        eq_con1, eq_con2, eq_con3 = MOI.get(
            dual_model,
            MOI.ListOfConstraintIndices{
                MOI.ScalarAffineFunction{Float64},
                MOI.EqualTo{Float64},
            }(),
        )

        eq_con1_fun = MOI.get(dual_model, MOI.ConstraintFunction(), eq_con1)
        eq_con1_set = MOI.get(dual_model, MOI.ConstraintSet(), eq_con1)
        @test MOI.coefficient.(eq_con1_fun.terms) == [1.0; 1.0]
        @test MOI.constant.(eq_con1_fun) == 0.0
        @test MOI.constant(eq_con1_set) == 0.0
        eq_con2_fun = MOI.get(dual_model, MOI.ConstraintFunction(), eq_con2)
        eq_con2_set = MOI.get(dual_model, MOI.ConstraintSet(), eq_con2)
        @test MOI.coefficient.(eq_con2_fun.terms) == [1.0]
        @test MOI.constant.(eq_con2_fun) == 0.0
        @test MOI.constant(eq_con2_set) == -1.0
        eq_con3_fun = MOI.get(dual_model, MOI.ConstraintFunction(), eq_con3)
        eq_con3_set = MOI.get(dual_model, MOI.ConstraintSet(), eq_con3)
        @test MOI.coefficient.(eq_con3_fun.terms) == [1.0]
        @test MOI.constant.(eq_con3_fun) == 0.0
        @test MOI.constant(eq_con3_set) == -1.0

        soc_con = MOI.get(
            dual_model,
            MOI.ConstraintFunction(),
            MOI.ConstraintIndex{MOI.VectorOfVariables,MOI.SecondOrderCone}(1),
        )
        @test soc_con.variables == MOI.VariableIndex.(2:4)

        primal_con_dual_var = primal_dual_map.primal_con_dual_var
        @test primal_con_dual_var[MOI.ConstraintIndex{
            MOI.VectorAffineFunction{Float64},
            MOI.Zeros,
        }(
            1,
        )] == [MOI.VariableIndex(1)]
        primal_soc_con = first(
            MOI.get(
                primal_model,
                MOI.ListOfConstraintIndices{
                    MOI.VectorAffineFunction{Float64},
                    MOI.SecondOrderCone,
                }(),
            ),
        )
        @test primal_con_dual_var[primal_soc_con] ==
              [MOI.VariableIndex(2); MOI.VariableIndex(3); MOI.VariableIndex(4)]

        primal_var_dual_con = primal_dual_map.primal_var_dual_con
        @test primal_var_dual_con[MOI.VariableIndex(1)] == eq_con1
        @test primal_var_dual_con[MOI.VariableIndex(2)] == eq_con2
        @test primal_var_dual_con[MOI.VariableIndex(3)] == eq_con3
    end
end
