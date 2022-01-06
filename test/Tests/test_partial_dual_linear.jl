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
            variable_parameters = VI[VI(2)],
            ignore_objective = true,
        )
        dual_model = dual.dual_model
        primal_dual_map = dual.primal_dual_map

        @test MOI.get(dual_model, MOI.NumberOfVariables()) == 2
        list_of_cons = MOI.get(dual_model, MOI.ListOfConstraintTypesPresent())
        @test Set(list_of_cons) == Set(
            [
                (VI, MOI.GreaterThan{Float64})
                (VI, MOI.LessThan{Float64})
                (SAF{Float64}, MOI.EqualTo{Float64})
            ],
        )
        @test MOI.get(
            dual_model,
            MOI.NumberOfConstraints{VI,MOI.GreaterThan{Float64}}(),
        ) == 1
        @test MOI.get(
            dual_model,
            MOI.NumberOfConstraints{VI,MOI.LessThan{Float64}}(),
        ) == 1
        @test MOI.get(
            dual_model,
            MOI.NumberOfConstraints{SAF{Float64},MOI.EqualTo{Float64}}(),
        ) == 1
        # @show obj_type = MOI.get(dual_model, MOI.ObjectiveFunctionType())

        eq_con1_fun = MOI.get(
            dual_model,
            MOI.ConstraintFunction(),
            CI{SAF{Float64},MOI.EqualTo{Float64}}(1),
        )
        eq_con1_set = MOI.get(
            dual_model,
            MOI.ConstraintSet(),
            CI{SAF{Float64},MOI.EqualTo{Float64}}(1),
        )
        @test MOI.coefficient.(eq_con1_fun.terms) == [1.0; 1.0]
        @test MOI.constant.(eq_con1_fun) == 0.0
        @test MOI.constant(eq_con1_set) == 0.0

        primal_con_dual_var = primal_dual_map.primal_con_dual_var
        @test primal_con_dual_var[CI{SAF{Float64},MOI.LessThan{Float64}}(1)] ==
              [VI(1)]

        primal_var_dual_con = primal_dual_map.primal_var_dual_con
        @test primal_var_dual_con[VI(1)] ==
              CI{SAF{Float64},MOI.EqualTo{Float64}}(1)
    end

    @testset "lp7_test - x_1 ignored" begin
        #=
        primal
            min -4x1 -3x2 -1
        s.t.
            2x1 + x2 - 3 <= 0  :y_2
            x1 + 2x2 - 3 <= 0  :y_3
            x1 >= 1            :y_1
            x2 >= 0
            ignore x_1 during dualization
        dual
            obj ignored
        s.t.
            -y_2 - 2y_3 >= 3 :x_2
            y_1 >= 0
            y_2 <= 0
            y_3 <= 0
        =#
        primal_model = lp7_test()
        dual = Dualization.dualize(
            primal_model,
            variable_parameters = VI[VI(1)],
            ignore_objective = true,
        )
        dual_model = dual.dual_model
        primal_dual_map = dual.primal_dual_map

        @test MOI.get(dual_model, MOI.NumberOfVariables()) == 3
        list_of_cons = MOI.get(dual_model, MOI.ListOfConstraintTypesPresent())
        @test Set(list_of_cons) == Set(
            [
                (VI, MOI.GreaterThan{Float64})
                (SAF{Float64}, MOI.GreaterThan{Float64})
                (VVF, MOI.Nonpositives)
            ],
        )
        @test MOI.get(
            dual_model,
            MOI.NumberOfConstraints{VI,MOI.GreaterThan{Float64}}(),
        ) == 1
        @test MOI.get(
            dual_model,
            MOI.NumberOfConstraints{VVF,MOI.Nonpositives}(),
        ) == 1
        @test MOI.get(
            dual_model,
            MOI.NumberOfConstraints{SAF{Float64},MOI.GreaterThan{Float64}}(),
        ) == 1
        # @show obj_type = MOI.get(dual_model, MOI.ObjectiveFunctionType())
        eq, = MOI.get(
            dual_model,
            MOI.ListOfConstraintIndices{SAF{Float64},MOI.GreaterThan{Float64}}(),
        )

        eq_con2_fun = MOI.get(dual_model, MOI.ConstraintFunction(), eq)
        eq_con2_set = MOI.get(dual_model, MOI.ConstraintSet(), eq)
        @test MOI.coefficient.(eq_con2_fun.terms) == [-1.0; -2.0]
        @test MOI.constant.(eq_con2_fun) == 0.0
        @test MOI.constant(eq_con2_set) == 3.0

        primal_con_dual_var = primal_dual_map.primal_con_dual_var
        vaf_npos, = MOI.get(
            primal_model,
            MOI.ListOfConstraintIndices{VAF{Float64},MOI.Nonpositives}(),
        )
        @test primal_con_dual_var[vaf_npos] == [VI(1); VI(2)]
        vgt, = MOI.get(
            primal_model,
            MOI.ListOfConstraintIndices{VI,MOI.GreaterThan{Float64}}(),
        )
        @test primal_con_dual_var[vgt] == [VI(3)]

        primal_var_dual_con = primal_dual_map.primal_var_dual_con
        @test isempty(primal_var_dual_con)
    end

    @testset "lp12_test - x_1 and x_3 ignored" begin
        #=
        primal
            min 4x_3 + 5
        s.t.
            x_1 + 2x_2 + x_3 <= 20 :y_3
            x_1 <= 1               :y_1
            x_2 <= 3               :y_2
        ignoring x_1 and x_3
        dual
            obj ignored
        s.t.
            #  y_1 + y_3 == 0  :x_1
            y_2 + 2y_3 == 0 :x_2
            #  y_3 == 4.0      :x_3
            y_1 <= 0
            y_2 <= 0
            y_3 <= 0
        =#
        primal_model = lp12_test()
        dual = Dualization.dualize(
            primal_model,
            variable_parameters = VI[VI(1), VI(3)],
            ignore_objective = true,
        )
        dual_model = dual.dual_model
        primal_dual_map = dual.primal_dual_map

        @test MOI.get(dual_model, MOI.NumberOfVariables()) == 3
        list_of_cons = MOI.get(dual_model, MOI.ListOfConstraintTypesPresent())
        @test Set(list_of_cons) == Set(
            [
                (VI, MOI.LessThan{Float64})
                (SAF{Float64}, MOI.EqualTo{Float64})
            ],
        )
        @test MOI.get(
            dual_model,
            MOI.NumberOfConstraints{VI,MOI.LessThan{Float64}}(),
        ) == 3
        @test MOI.get(
            dual_model,
            MOI.NumberOfConstraints{SAF{Float64},MOI.EqualTo{Float64}}(),
        ) == 1

        eq_con2_fun = MOI.get(
            dual_model,
            MOI.ConstraintFunction(),
            CI{SAF{Float64},MOI.EqualTo{Float64}}(1),
        )
        eq_con2_set = MOI.get(
            dual_model,
            MOI.ConstraintSet(),
            CI{SAF{Float64},MOI.EqualTo{Float64}}(1),
        )
        @test MOI.coefficient.(eq_con2_fun.terms) == [2.0; 1.0]
        @test MOI.constant.(eq_con2_fun) == 0.0
        @test MOI.constant(eq_con2_set) == 0.0

        primal_con_dual_var = primal_dual_map.primal_con_dual_var
        @test primal_con_dual_var[CI{VI,MOI.LessThan{Float64}}(2)] == [VI(3)]
        @test primal_con_dual_var[CI{VI,MOI.LessThan{Float64}}(1)] == [VI(2)]
        @test primal_con_dual_var[CI{SAF{Float64},MOI.LessThan{Float64}}(1)] ==
              [VI(1)]

        primal_var_dual_con = primal_dual_map.primal_var_dual_con
        @test primal_var_dual_con[VI(2)] ==
              CI{SAF{Float64},MOI.EqualTo{Float64}}(1)
    end
end
