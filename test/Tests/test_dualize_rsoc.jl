# Copyright (c) 2017: Guilherme Bodin, and contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

@testset "rsoc problems" begin
    @testset "rsoc1_test" begin
        #=
        primal
            min 0a + 0b - 1x - 1y
        s.t.
            a    == 1/2 :w_2
            b    == 1   :w_1
            2a*b >= x^2+y^2  :w_3, w_4, w_5, w_6
        dual
            max w_2 + (1/2)w_1
        s.t.
            w_5 == -1
            w_6 == -1
            w_1 + w_3 == 0
            w_2 + w_4 == 0
            (w_3, w_4, w_5, w_6) \in RotatedSecondOrderCone
        =#
        primal_model = rsoc1_test()
        dual_model, primal_dual_map = dual_model_and_map(primal_model)

        @test MOI.get(dual_model, MOI.NumberOfVariables()) == 2
        list_of_cons = MOI.get(dual_model, MOI.ListOfConstraintTypesPresent())
        @test Set(list_of_cons) == Set([(
            MOI.VectorAffineFunction{Float64},
            MOI.RotatedSecondOrderCone,
        )],)
        @test MOI.get(
            dual_model,
            MOI.NumberOfConstraints{
                MOI.VectorAffineFunction{Float64},
                MOI.RotatedSecondOrderCone,
            }(),
        ) == 1
        obj_type = MOI.get(dual_model, MOI.ObjectiveFunctionType())
        @test obj_type == MOI.ScalarAffineFunction{Float64}
        obj = MOI.get(dual_model, MOI.ObjectiveFunction{obj_type}())
        @test MOI.get(dual_model, MOI.ObjectiveSense()) == MOI.MAX_SENSE
        @test MOI.constant(obj) == 0.0
        @test Set(MOI.coefficient.(obj.terms)) == Set([1.0; 0.5])
    end

    @testset "rsoc2_test" begin
        #=
        primal
            min 0a + 0b - 1x - 1y
        s.t.
            a    == 1/2
            b    == 1
            2a*b >= x^2+y^2
        dual
            max w_2 + (1/2)w_1
        s.t.
            w_5 == -1
            w_6 == -1
            w_1 + w_3 == 0
            w_2 + w_4 == 0
            (w_3, w_4, w_5, w_6) \in RotatedSecondOrderCone
        =#
        primal_model = rsoc2_test()
        dual_model, primal_dual_map = dual_model_and_map(primal_model)

        @test MOI.get(dual_model, MOI.NumberOfVariables()) == 4
        list_of_cons = MOI.get(dual_model, MOI.ListOfConstraintTypesPresent())
        @test Set(list_of_cons) == Set(
            [
                (MOI.ScalarAffineFunction{Float64}, MOI.EqualTo{Float64})
                (MOI.VectorOfVariables, MOI.RotatedSecondOrderCone)
            ],
        )
        @test MOI.get(
            dual_model,
            MOI.NumberOfConstraints{
                MOI.VectorOfVariables,
                MOI.RotatedSecondOrderCone,
            }(),
        ) == 1
        @test MOI.get(
            dual_model,
            MOI.NumberOfConstraints{
                MOI.ScalarAffineFunction{Float64},
                MOI.EqualTo{Float64},
            }(),
        ) == 2
        obj_type = MOI.get(dual_model, MOI.ObjectiveFunctionType())
        @test obj_type == MOI.ScalarAffineFunction{Float64}
        obj = MOI.get(dual_model, MOI.ObjectiveFunction{obj_type}())
        @test MOI.get(dual_model, MOI.ObjectiveSense()) == MOI.MAX_SENSE
        @test MOI.constant(obj) == 0.0
        @test MOI.coefficient.(obj.terms) == [-1.0; -0.5]

        eq_con1, eq_con2 = MOI.get(
            dual_model,
            MOI.ListOfConstraintIndices{
                MOI.ScalarAffineFunction{Float64},
                MOI.EqualTo{Float64},
            }(),
        )

        eq_con1_fun = MOI.get(dual_model, MOI.ConstraintFunction(), eq_con1)
        eq_con1_set = MOI.get(dual_model, MOI.ConstraintSet(), eq_con1)
        @test MOI.coefficient.(eq_con1_fun.terms) == [1.0]
        @test MOI.constant.(eq_con1_fun) == 0.0
        @test MOI.constant(eq_con1_set) == -1.0
        eq_con2_fun = MOI.get(dual_model, MOI.ConstraintFunction(), eq_con2)
        eq_con2_set = MOI.get(dual_model, MOI.ConstraintSet(), eq_con2)
        @test MOI.coefficient.(eq_con2_fun.terms) == [1.0]
        @test MOI.constant.(eq_con2_fun) == 0.0
        @test MOI.constant(eq_con2_set) == -1.0

        rsoc_con = MOI.get(
            dual_model,
            MOI.ConstraintFunction(),
            MOI.ConstraintIndex{
                MOI.VectorOfVariables,
                MOI.RotatedSecondOrderCone,
            }(
                1,
            ),
        )
        @test rsoc_con.variables == MOI.VariableIndex.(1:4)

        primal_constraint_data = primal_dual_map.primal_constraint_data
        @test primal_constraint_data[MOI.ConstraintIndex{
            MOI.VectorAffineFunction{Float64},
            MOI.RotatedSecondOrderCone,
        }(
            1,
        )].dual_variables == MOI.VariableIndex.(1:4)

        primal_variable_data = primal_dual_map.primal_variable_data
        @test primal_variable_data[MOI.VariableIndex(1)].dual_constraint ==
              eq_con1
        @test primal_variable_data[MOI.VariableIndex(2)].dual_constraint ==
              eq_con2
    end
end
