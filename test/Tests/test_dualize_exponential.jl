# Copyright (c) 2017: Guilherme Bodin, and contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

@testset "exp problems" begin
    @testset "exp1_test" begin
        #=
        primal
            min x + y + z
        s.t.
            y e^(x/y) <= z, y > 0 (i.e (x, y, z) are in the exponential primal cone) :w3, w_4, w_5
            x == 1 :w_1
            y == 2 :w_2
        dual
            max 2w_2 + w_1
        s.t.
            w_1 + w_3 == 1
            w_2 + w_4 == 1
            w_5 == 1
            (w_3, w_4, w_5) ∈ DualExponentialCone
        =#
        primal_model = exp1_test()
        dual_model, primal_dual_map = dual_model_and_map(primal_model)

        @test MOI.get(dual_model, MOI.NumberOfVariables()) == 2
        list_of_cons = MOI.get(dual_model, MOI.ListOfConstraintTypesPresent())
        @test Set(list_of_cons) == Set([(
            MOI.VectorAffineFunction{Float64},
            MOI.DualExponentialCone,
        )],)
        @test MOI.get(
            dual_model,
            MOI.NumberOfConstraints{
                MOI.VectorAffineFunction{Float64},
                MOI.DualExponentialCone,
            }(),
        ) == 1
        obj_type = MOI.get(dual_model, MOI.ObjectiveFunctionType())
        @test obj_type == MOI.ScalarAffineFunction{Float64}
        obj = MOI.get(dual_model, MOI.ObjectiveFunction{obj_type}())
        @test MOI.get(dual_model, MOI.ObjectiveSense()) == MOI.MAX_SENSE
        @test MOI.constant(obj) == 0.0
        @test Set(MOI.coefficient.(obj.terms)) == Set([2.0; 1.0])
    end

    @testset "exp2_test" begin
        #=
        primal
            min x + y + z
        s.t.
            y e^(x/y) <= z, y > 0 (i.e (x, y, z) are in the exponential primal cone) :w3, w_4, w_5
            x == 1 :w_1
            y == 2 :w_2
        dual
            max 2w_2 + w_1
        s.t.
            w_1 + w_3 == 1
            w_2 + w_4 == 1
            w_5 == 1
            (w_3, w_4, w_5) ∈ DualExponentialCone
        =#
        primal_model = exp2_test()
        dual_model, primal_dual_map = dual_model_and_map(primal_model)

        @test MOI.get(dual_model, MOI.NumberOfVariables()) == 5
        list_of_cons = MOI.get(dual_model, MOI.ListOfConstraintTypesPresent())
        @test Set(list_of_cons) == Set(
            [
                (MOI.ScalarAffineFunction{Float64}, MOI.EqualTo{Float64})
                (MOI.VectorOfVariables, MOI.DualExponentialCone)
            ],
        )
        @test MOI.get(
            dual_model,
            MOI.NumberOfConstraints{
                MOI.VectorOfVariables,
                MOI.DualExponentialCone,
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
        @test MOI.get(dual_model, MOI.ObjectiveSense()) == MOI.MAX_SENSE
        @test MOI.constant(obj) == 0.0
        @test MOI.coefficient.(obj.terms) == [2.0; 1.0]

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
        @test MOI.constant(eq_con1_set) == 1.0
        eq_con2_fun = MOI.get(dual_model, MOI.ConstraintFunction(), eq_con2)
        eq_con2_set = MOI.get(dual_model, MOI.ConstraintSet(), eq_con2)
        @test MOI.coefficient.(eq_con2_fun.terms) == [1.0; 1.0]
        @test MOI.constant.(eq_con2_fun) == 0.0
        @test MOI.constant(eq_con2_set) == 1.0
        eq_con3_fun = MOI.get(dual_model, MOI.ConstraintFunction(), eq_con3)
        eq_con3_set = MOI.get(dual_model, MOI.ConstraintSet(), eq_con3)
        @test MOI.coefficient.(eq_con3_fun.terms) == [1.0]
        @test MOI.constant.(eq_con3_fun) == 0.0
        @test MOI.constant(eq_con3_set) == 1.0

        dual_exp_con = MOI.get(
            dual_model,
            MOI.ConstraintFunction(),
            MOI.ConstraintIndex{MOI.VectorOfVariables,MOI.DualExponentialCone}(
                1,
            ),
        )
        @test dual_exp_con.variables == MOI.VariableIndex.(3:5)

        primal_constraint_data = primal_dual_map.primal_constraint_data
        @test primal_constraint_data[eq_con1].dual_variables ==
              [MOI.VariableIndex(1)]
        @test primal_constraint_data[eq_con2].dual_variables ==
              [MOI.VariableIndex(2)]
        @test primal_constraint_data[MOI.ConstraintIndex{
            MOI.VectorAffineFunction{Float64},
            MOI.ExponentialCone,
        }(
            1,
        )].dual_variables == MOI.VariableIndex.(3:5)

        primal_variable_data = primal_dual_map.primal_variable_data
        @test primal_variable_data[MOI.VariableIndex(1)].dual_constraint ==
              eq_con1
        @test primal_variable_data[MOI.VariableIndex(2)].dual_constraint ==
              eq_con2
        @test primal_variable_data[MOI.VariableIndex(3)].dual_constraint ==
              eq_con3
    end
end
