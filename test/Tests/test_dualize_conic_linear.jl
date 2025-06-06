# Copyright (c) 2017: Guilherme Bodin, and contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

@testset "conic linear problems" begin
    @testset "conic_linear1_test" begin
        #=
        primal
            min -3x - 2y - 4z
        s.t.
            x +  y +  z == 3 :w_1
            y +  z == 2      :w_2
            x>=0 y>=0 z>=0
        dual
            max 3w_1 + 2w_2
        s.t.
            [-w_1 - 3.0,
             -w_1 - w_2 - 2.0,
             -w_1 - w_2 - 4.0] in Nonnegatives
        =#
        primal_model = conic_linear1_test()
        dual_model, primal_dual_map = dual_model_and_map(primal_model)

        @test MOI.get(dual_model, MOI.NumberOfVariables()) == 2
        list_of_cons = MOI.get(dual_model, MOI.ListOfConstraintTypesPresent())
        @test list_of_cons ==
              [(MOI.VectorAffineFunction{Float64}, MOI.Nonnegatives)]
        @test MOI.get(
            dual_model,
            MOI.NumberOfConstraints{
                MOI.VectorAffineFunction{Float64},
                MOI.Nonnegatives,
            }(),
        ) == 1
        obj_type = MOI.get(dual_model, MOI.ObjectiveFunctionType())
        @test obj_type == MOI.ScalarAffineFunction{Float64}
        @test MOI.get(dual_model, MOI.ObjectiveSense()) == MOI.MAX_SENSE
        obj = MOI.get(dual_model, MOI.ObjectiveFunction{obj_type}())
        @test MOI.constant(obj) == 0.0
        @test Set(MOI.coefficient.(obj.terms)) == Set([3.0; 2.0])

        ci = first(
            MOI.get(
                dual_model,
                MOI.ListOfConstraintIndices{
                    MOI.VectorAffineFunction{Float64},
                    MOI.Nonnegatives,
                }(),
            ),
        )
        eq_con1_fun = MOI.get(dual_model, MOI.ConstraintFunction(), ci)
        @test MOI.coefficient.(eq_con1_fun.terms) == -ones(5)
        @test MOI.constant(eq_con1_fun) == [-3.0, -2.0, -4.0]
        @test MOI.get(dual_model, MOI.ConstraintSet(), ci) ==
              MOI.Nonnegatives(3)

        primal_constraint_data = primal_dual_map.primal_constraint_data
        ci_zero = first(
            MOI.get(
                primal_model,
                MOI.ListOfConstraintIndices{
                    MOI.VectorAffineFunction{Float64},
                    MOI.Zeros,
                }(),
            ),
        )
        @test primal_constraint_data[ci_zero].dual_variables ==
              MOI.VariableIndex.(1:2)
        ci_nneg = first(
            MOI.get(
                primal_model,
                MOI.ListOfConstraintIndices{
                    MOI.VectorOfVariables,
                    MOI.Nonnegatives,
                }(),
            ),
        )
        @test !haskey(primal_dual_map.primal_constraint_data, ci_nneg)
        vis = primal_dual_map.primal_constrained_variables[ci_nneg]
        for vi in vis
            @test primal_dual_map.primal_variable_data[vi].dual_constraint == ci
        end

        for i in 1:3
            vi = MOI.VariableIndex(i)
            data = primal_dual_map.primal_variable_data[vi]
            @test data.primal_constrained_variable_constraint == ci_nneg
            @test data.primal_constrained_variable_index == i
            @test data.dual_constraint == ci
            @test data.dual_function === nothing
        end
    end

    @testset "conic_linear3_test" begin
        #=
        primal
            min  3x + 2y - 4z + 0s
        s.t.
            x           -  s == -4    :w_1
                y            == -3    :w_2
            x      +  z      == 12    :w_3
            y <= 0
            z >= 0
            s zero
        dual
            max -4w_4 - 3w_5 + 12w_6
        s.t
            w_1 + w_3 == 3
            [-w_2 + 2] in Nonpositives
            [-w_3 - 4] in Nonnegatives
        =#
        primal_model = conic_linear3_test()
        dual_model, primal_dual_map = dual_model_and_map(primal_model)

        @test MOI.get(dual_model, MOI.NumberOfVariables()) == 3
        list_of_cons = MOI.get(dual_model, MOI.ListOfConstraintTypesPresent())
        @test Set(list_of_cons) == Set(
            [
                (MOI.VectorAffineFunction{Float64}, MOI.Reals)
                (MOI.VectorAffineFunction{Float64}, MOI.Nonpositives)
                (MOI.VectorAffineFunction{Float64}, MOI.Nonnegatives)
                (MOI.ScalarAffineFunction{Float64}, MOI.EqualTo{Float64})
            ],
        )
        @test MOI.get(
            dual_model,
            MOI.NumberOfConstraints{
                MOI.ScalarAffineFunction{Float64},
                MOI.EqualTo{Float64},
            }(),
        ) == 1
        @test MOI.get(
            dual_model,
            MOI.NumberOfConstraints{
                MOI.VectorAffineFunction{Float64},
                MOI.Nonnegatives,
            }(),
        ) == 1
        @test MOI.get(
            dual_model,
            MOI.NumberOfConstraints{
                MOI.VectorAffineFunction{Float64},
                MOI.Nonpositives,
            }(),
        ) == 1
        obj_type = MOI.get(dual_model, MOI.ObjectiveFunctionType())
        @test obj_type == MOI.ScalarAffineFunction{Float64}
        @test MOI.get(dual_model, MOI.ObjectiveSense()) == MOI.MAX_SENSE
        obj = MOI.get(dual_model, MOI.ObjectiveFunction{obj_type}())
        @test MOI.constant(obj) == 0.0
        @test Set(MOI.coefficient.(obj.terms)) == Set([-4.0; 12.0; -3.0])

        ci_eq = first(
            MOI.get(
                dual_model,
                MOI.ListOfConstraintIndices{
                    MOI.ScalarAffineFunction{Float64},
                    MOI.EqualTo{Float64},
                }(),
            ),
        )
        eq_con1_fun = MOI.get(dual_model, MOI.ConstraintFunction(), ci_eq)
        eq_con1_set = MOI.get(dual_model, MOI.ConstraintSet(), ci_eq)
        @test MOI.coefficient.(eq_con1_fun.terms) == [1.0; 1.0]
        @test MOI.constant.(eq_con1_fun) == 0.0
        @test MOI.constant(eq_con1_set) == 3.0
        ci_np = first(
            MOI.get(
                dual_model,
                MOI.ListOfConstraintIndices{
                    MOI.VectorAffineFunction{Float64},
                    MOI.Nonpositives,
                }(),
            ),
        )
        eq_con2_fun = MOI.get(dual_model, MOI.ConstraintFunction(), ci_np)
        @test MOI.get(dual_model, MOI.ConstraintSet(), ci_np) ==
              MOI.Nonpositives(1)
        @test MOI.coefficient.(eq_con2_fun.terms) == -[1.0]
        @test MOI.constant(eq_con2_fun) == [2.0]
        ci_nn = first(
            MOI.get(
                dual_model,
                MOI.ListOfConstraintIndices{
                    MOI.VectorAffineFunction{Float64},
                    MOI.Nonnegatives,
                }(),
            ),
        )
        eq_con3_fun = MOI.get(dual_model, MOI.ConstraintFunction(), ci_nn)
        @test MOI.get(dual_model, MOI.ConstraintSet(), ci_nn) ==
              MOI.Nonnegatives(1)
        @test MOI.coefficient.(eq_con3_fun.terms) == -[1.0]
        @test MOI.constant(eq_con3_fun) == [-4.0]

        ci_zero = first(
            MOI.get(
                primal_model,
                MOI.ListOfConstraintIndices{MOI.VectorOfVariables,MOI.Zeros}(),
            ),
        )
        @test !haskey(primal_dual_map.primal_constraint_data, ci_zero)
        ci_nneg = first(
            MOI.get(
                primal_model,
                MOI.ListOfConstraintIndices{
                    MOI.VectorOfVariables,
                    MOI.Nonnegatives,
                }(),
            ),
        )
        @test !haskey(primal_dual_map.primal_constraint_data, ci_nneg)
        vis = primal_dual_map.primal_constrained_variables[ci_nneg]
        for vi in vis
            @test primal_dual_map.primal_variable_data[vi].dual_constraint ==
                  ci_nn
        end
        ci_npos = first(
            MOI.get(
                primal_model,
                MOI.ListOfConstraintIndices{
                    MOI.VectorOfVariables,
                    MOI.Nonpositives,
                }(),
            ),
        )
        @test !haskey(primal_dual_map.primal_constraint_data, ci_npos)
        vis = primal_dual_map.primal_constrained_variables[ci_npos]
        for vi in vis
            @test primal_dual_map.primal_variable_data[vi].dual_constraint ==
                  ci_np
        end
        ci_aff_zero = first(
            MOI.get(
                primal_model,
                MOI.ListOfConstraintIndices{
                    MOI.VectorAffineFunction{Float64},
                    MOI.Zeros,
                }(),
            ),
        )
        @test primal_dual_map.primal_constraint_data[ci_aff_zero].dual_variables ==
              MOI.VariableIndex.(1:3)

        data = primal_dual_map.primal_variable_data[MOI.VariableIndex(1)]
        @test data.dual_constraint == ci_eq
        for i in 2:4
            data = primal_dual_map.primal_variable_data[MOI.VariableIndex(i)]
            @test data.dual_constraint !== nothing
        end
        # @test primal_dual_map.primal_convar_to_primal_convarcon_and_index[MOI.VariableIndex(
        #     2,
        # )] == (ci_npos, 1)
        # @test primal_dual_map.primal_convar_to_primal_convarcon_and_index[MOI.VariableIndex(
        #     3,
        # )] == (ci_nneg, 1)
        # @test primal_dual_map.primal_convar_to_primal_convarcon_and_index[MOI.VariableIndex(
        #     4,
        # )] == (ci_zero, 1)
        data = primal_dual_map.primal_variable_data[MOI.VariableIndex(2)]
        @test data.primal_constrained_variable_constraint == ci_npos
        @test data.primal_constrained_variable_index == 1
        data = primal_dual_map.primal_variable_data[MOI.VariableIndex(3)]
        @test data.primal_constrained_variable_constraint == ci_nneg
        @test data.primal_constrained_variable_index == 1
        data = primal_dual_map.primal_variable_data[MOI.VariableIndex(4)]
        @test data.primal_constrained_variable_constraint == ci_zero
        @test data.primal_constrained_variable_index == 1
    end
end
