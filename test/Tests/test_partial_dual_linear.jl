# Copyright (c) 2017: Guilherme Bodin, and contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

@testset "linear problems - partial dualization" begin
    @testset "lp1_test - ignore x_2" begin
        #=
        primal
            min -4x_2 - 1
        s.t.
            x_1 >= 3         :y_2
            x_1 + 2x_2 <= 3  :y_3
        ignore x_2 during dualization
        dual
            obj ignored
        s.t.
            y_2 >= 0
            y_3 <= 0
            y_2 + y_3 == 0    :x_1
        =#
        primal_model = lp1_test()
        dual = Dualization.dualize(
            primal_model,
            variable_parameters = MOI.VariableIndex[MOI.VariableIndex(2)],
            ignore_objective = true,
        )
        dual_model = dual.dual_model
        primal_dual_map = dual.primal_dual_map

        @test MOI.get(dual_model, MOI.NumberOfVariables()) == 2
        list_of_cons = MOI.get(dual_model, MOI.ListOfConstraintTypesPresent())
        @test Set(list_of_cons) == Set(
            [
                (MOI.VariableIndex, MOI.GreaterThan{Float64})
                (MOI.VariableIndex, MOI.LessThan{Float64})
                (MOI.ScalarAffineFunction{Float64}, MOI.EqualTo{Float64})
            ],
        )
        @test MOI.get(
            dual_model,
            MOI.NumberOfConstraints{
                MOI.VariableIndex,
                MOI.GreaterThan{Float64},
            }(),
        ) == 1
        @test MOI.get(
            dual_model,
            MOI.NumberOfConstraints{MOI.VariableIndex,MOI.LessThan{Float64}}(),
        ) == 1
        @test MOI.get(
            dual_model,
            MOI.NumberOfConstraints{
                MOI.ScalarAffineFunction{Float64},
                MOI.EqualTo{Float64},
            }(),
        ) == 1
        # @show obj_type = MOI.get(dual_model, MOI.ObjectiveFunctionType())

        eq_con1_fun = MOI.get(
            dual_model,
            MOI.ConstraintFunction(),
            MOI.ConstraintIndex{
                MOI.ScalarAffineFunction{Float64},
                MOI.EqualTo{Float64},
            }(
                1,
            ),
        )
        eq_con1_set = MOI.get(
            dual_model,
            MOI.ConstraintSet(),
            MOI.ConstraintIndex{
                MOI.ScalarAffineFunction{Float64},
                MOI.EqualTo{Float64},
            }(
                1,
            ),
        )
        @test MOI.coefficient.(eq_con1_fun.terms) == [1.0; 1.0]
        @test MOI.constant.(eq_con1_fun) == 0.0
        @test MOI.constant(eq_con1_set) == 0.0

        primal_constraint_data = primal_dual_map.primal_constraint_data
        @test primal_constraint_data[MOI.ConstraintIndex{
            MOI.ScalarAffineFunction{Float64},
            MOI.LessThan{Float64},
        }(
            1,
        )].dual_variables == [MOI.VariableIndex(1)]

        primal_variable_data = primal_dual_map.primal_variable_data
        @test primal_variable_data[MOI.VariableIndex(1)].dual_constraint ==
              MOI.ConstraintIndex{
            MOI.ScalarAffineFunction{Float64},
            MOI.EqualTo{Float64},
        }(
            1,
        )
    end

    @testset "lp1_test - parameter name" begin
        #=
        primal
            min -4x_2 - 1
        s.t.
            x_1 >= 3         :y_2
            x_1 + 2x_2 <= 3  :y_3
        ignore x_2 during dualization
        dual

        s.t.
            y_2 >= 0
            y_3 <= 0
            y_2 + y_3 == 0    :x_1
        =#
        primal_model = lp1_test()
        MOI.add_constraint(
            primal_model,
            MOI.VariableIndex(2),
            MOI.Parameter{Float64}(0.0),
        )
        dual = Dualization.dualize(
            primal_model,
            dual_names = Dualization.DualNames("", "", "parameter_", ""),
        )
        dual_model = dual.dual_model
        primal_dual_map = dual.primal_dual_map
        primal_parameter_to_dual_parameter =
            primal_dual_map.primal_parameter_to_dual_parameter
        @test MOI.get(
            dual_model,
            MOI.VariableName(),
            primal_parameter_to_dual_parameter[MOI.VariableIndex(2)],
        ) ==
              "parameter_" *
              MOI.get(primal_model, MOI.VariableName(), MOI.VariableIndex(2))
    end

    @testset "lp7_test - x_1 ignored" begin
        #=
        primal
            min -4x1 -3x2 -1
        s.t.
            2x1 + x2 - 3 <= 0  :y_2
            x1 + 2x2 - 3 <= 0  :y_3
            x1 >= 1            :no dual here
            x2 >= 0
            ignore x_1 during dualization
        dual
            obj ignored
        s.t.
            -y_2 - 2y_3 >= 3 :x_2
            y_2 <= 0
            y_3 <= 0
        =#
        primal_model = lp7_test()
        dual = Dualization.dualize(
            primal_model,
            variable_parameters = MOI.VariableIndex[MOI.VariableIndex(1)],
            ignore_objective = true,
        )
        dual_model = dual.dual_model
        primal_dual_map = dual.primal_dual_map

        @test MOI.get(dual_model, MOI.NumberOfVariables()) == 2
        list_of_cons = MOI.get(dual_model, MOI.ListOfConstraintTypesPresent())
        @test Set(list_of_cons) == Set(
            [
                (MOI.ScalarAffineFunction{Float64}, MOI.GreaterThan{Float64})
                (MOI.VectorOfVariables, MOI.Nonpositives)
            ],
        )
        @test MOI.get(
            dual_model,
            MOI.NumberOfConstraints{
                MOI.VariableIndex,
                MOI.GreaterThan{Float64},
            }(),
        ) == 0
        @test MOI.get(
            dual_model,
            MOI.NumberOfConstraints{MOI.VectorOfVariables,MOI.Nonpositives}(),
        ) == 1
        @test MOI.get(
            dual_model,
            MOI.NumberOfConstraints{
                MOI.ScalarAffineFunction{Float64},
                MOI.GreaterThan{Float64},
            }(),
        ) == 1
        # @show obj_type = MOI.get(dual_model, MOI.ObjectiveFunctionType())
        eq, = MOI.get(
            dual_model,
            MOI.ListOfConstraintIndices{
                MOI.ScalarAffineFunction{Float64},
                MOI.GreaterThan{Float64},
            }(),
        )

        eq_con2_fun = MOI.get(dual_model, MOI.ConstraintFunction(), eq)
        eq_con2_set = MOI.get(dual_model, MOI.ConstraintSet(), eq)
        @test MOI.coefficient.(eq_con2_fun.terms) == [-1.0; -2.0]
        @test MOI.constant.(eq_con2_fun) == 0.0
        @test MOI.constant(eq_con2_set) == 3.0

        primal_constraint_data = primal_dual_map.primal_constraint_data
        vaf_npos, = MOI.get(
            primal_model,
            MOI.ListOfConstraintIndices{
                MOI.VectorAffineFunction{Float64},
                MOI.Nonpositives,
            }(),
        )
        @test primal_constraint_data[vaf_npos].dual_variables ==
              [MOI.VariableIndex(1); MOI.VariableIndex(2)]
        vgt1, vgt2 = MOI.get(
            primal_model,
            MOI.ListOfConstraintIndices{
                MOI.VariableIndex,
                MOI.GreaterThan{Float64},
            }(),
        )
        @test !haskey(primal_constraint_data, vgt1) # as this was not dualized

        for (vi, data) in primal_dual_map.primal_variable_data
            vi = MOI.VariableIndex(2)
            @test data.primal_constrained_variable_constraint == vgt2
            @test data.primal_constrained_variable_index == 0
            @test data.dual_constraint !== nothing
            @test data.dual_function === nothing
        end
    end

    @testset "lp12_test - x_1 and x_3 ignored" begin
        #=
        primal
            min 4x_3 + 5
        s.t.
            x_1 + 2x_2 + x_3 <= 20 :y_3
            x_1 <= 1               : # no dual here: y_1
            x_2 <= 3               :y_2
        ignoring x_1 and x_3
        dual
            obj ignored
        s.t.
            #  y_1 + y_3 == 0  :x_1
            y_2 + 2y_3 == 0 :x_2
            #  y_3 == 4.0      :x_3
            # y_1 <= 0
            y_2 <= 0
            y_3 <= 0
        =#
        primal_model = lp12_test()
        dual = Dualization.dualize(
            primal_model,
            variable_parameters = MOI.VariableIndex[
                MOI.VariableIndex(1),
                MOI.VariableIndex(3),
            ],
            ignore_objective = true,
        )
        dual_model = dual.dual_model
        primal_dual_map = dual.primal_dual_map

        @test MOI.get(dual_model, MOI.NumberOfVariables()) == 2
        list_of_cons = MOI.get(dual_model, MOI.ListOfConstraintTypesPresent())
        @test Set(list_of_cons) == Set(
            [
                (MOI.VariableIndex, MOI.LessThan{Float64})
                (MOI.ScalarAffineFunction{Float64}, MOI.EqualTo{Float64})
            ],
        )
        @test MOI.get(
            dual_model,
            MOI.NumberOfConstraints{MOI.VariableIndex,MOI.LessThan{Float64}}(),
        ) == 2
        @test MOI.get(
            dual_model,
            MOI.NumberOfConstraints{
                MOI.ScalarAffineFunction{Float64},
                MOI.EqualTo{Float64},
            }(),
        ) == 1

        eq_con2_fun = MOI.get(
            dual_model,
            MOI.ConstraintFunction(),
            MOI.ConstraintIndex{
                MOI.ScalarAffineFunction{Float64},
                MOI.EqualTo{Float64},
            }(
                1,
            ),
        )
        eq_con2_set = MOI.get(
            dual_model,
            MOI.ConstraintSet(),
            MOI.ConstraintIndex{
                MOI.ScalarAffineFunction{Float64},
                MOI.EqualTo{Float64},
            }(
                1,
            ),
        )
        @test MOI.coefficient.(eq_con2_fun.terms) == [2.0; 1.0]
        @test MOI.constant.(eq_con2_fun) == 0.0
        @test MOI.constant(eq_con2_set) == 0.0

        primal_constraint_data = primal_dual_map.primal_constraint_data
        @test primal_constraint_data[MOI.ConstraintIndex{
            MOI.VariableIndex,
            MOI.LessThan{Float64},
        }(
            2,
        )].dual_variables == [MOI.VariableIndex(2)]
        @test !haskey(
            primal_constraint_data,
            MOI.ConstraintIndex{MOI.VariableIndex,MOI.LessThan{Float64}}(1),
        )
        @test primal_constraint_data[MOI.ConstraintIndex{
            MOI.ScalarAffineFunction{Float64},
            MOI.LessThan{Float64},
        }(
            1,
        )].dual_variables == [MOI.VariableIndex(1)]

        primal_variable_data = primal_dual_map.primal_variable_data
        @test primal_variable_data[MOI.VariableIndex(2)].dual_constraint ==
              MOI.ConstraintIndex{
            MOI.ScalarAffineFunction{Float64},
            MOI.EqualTo{Float64},
        }(
            1,
        )
    end

    @testset "lp12_test - x_1 ignored x_3 moi_param" begin
        #=
        primal
            min 4x_3 + 5
        s.t.
            x_1 + 2x_2 + x_3 <= 20 :y_3
            x_1 <= 1               : # no dual here: y_1
            x_2 <= 3               :y_2
        ignoring x_1 and x_3
        dual
            obj ignored
        s.t.
            #  y_1 + y_3 == 0  :x_1
            y_2 + 2y_3 == 0 :x_2
            #  y_3 == 4.0      :x_3
            # y_1 <= 0
            y_2 <= 0
            y_3 <= 0
        =#
        primal_model = lp12_test()
        MOI.add_constraint(
            primal_model,
            MOI.VariableIndex(3),
            MOI.Parameter{Float64}(0.0),
        )
        dual = Dualization.dualize(
            primal_model,
            variable_parameters = MOI.VariableIndex[MOI.VariableIndex(1),
            # MOI.VariableIndex(3), # as a param
            ],
            ignore_objective = true,
        )
        dual_model = dual.dual_model
        primal_dual_map = dual.primal_dual_map

        @test MOI.get(dual_model, MOI.NumberOfVariables()) == 2
        list_of_cons = MOI.get(dual_model, MOI.ListOfConstraintTypesPresent())
        @test Set(list_of_cons) == Set(
            [
                (MOI.VariableIndex, MOI.LessThan{Float64})
                (MOI.ScalarAffineFunction{Float64}, MOI.EqualTo{Float64})
            ],
        )
        @test MOI.get(
            dual_model,
            MOI.NumberOfConstraints{MOI.VariableIndex,MOI.LessThan{Float64}}(),
        ) == 2
        @test MOI.get(
            dual_model,
            MOI.NumberOfConstraints{
                MOI.ScalarAffineFunction{Float64},
                MOI.EqualTo{Float64},
            }(),
        ) == 1

        eq_con2_fun = MOI.get(
            dual_model,
            MOI.ConstraintFunction(),
            MOI.ConstraintIndex{
                MOI.ScalarAffineFunction{Float64},
                MOI.EqualTo{Float64},
            }(
                1,
            ),
        )
        eq_con2_set = MOI.get(
            dual_model,
            MOI.ConstraintSet(),
            MOI.ConstraintIndex{
                MOI.ScalarAffineFunction{Float64},
                MOI.EqualTo{Float64},
            }(
                1,
            ),
        )
        @test MOI.coefficient.(eq_con2_fun.terms) == [2.0; 1.0]
        @test MOI.constant.(eq_con2_fun) == 0.0
        @test MOI.constant(eq_con2_set) == 0.0

        primal_constraint_data = primal_dual_map.primal_constraint_data
        @test primal_constraint_data[MOI.ConstraintIndex{
            MOI.VariableIndex,
            MOI.LessThan{Float64},
        }(
            2,
        )].dual_variables == [MOI.VariableIndex(2)]
        @test !haskey(
            primal_constraint_data,
            MOI.ConstraintIndex{MOI.VariableIndex,MOI.LessThan{Float64}}(1),
        )
        @test primal_constraint_data[MOI.ConstraintIndex{
            MOI.ScalarAffineFunction{Float64},
            MOI.LessThan{Float64},
        }(
            1,
        )].dual_variables == [MOI.VariableIndex(1)]

        primal_variable_data = primal_dual_map.primal_variable_data
        @test primal_variable_data[MOI.VariableIndex(2)].dual_constraint ==
              MOI.ConstraintIndex{
            MOI.ScalarAffineFunction{Float64},
            MOI.EqualTo{Float64},
        }(
            1,
        )
    end
end
