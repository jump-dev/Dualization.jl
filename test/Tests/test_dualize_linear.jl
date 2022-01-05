@testset "linear problems" begin
    @testset "lp1_test" begin
        #=
        primal
            min -4x_2 - 1
        s.t.
            x_1 >= 3         :y_2
            x_1 + 2x_2 <= 3  :y_3

        dual
            max 3y_2 + 3y_3 - 1
        s.t.
            y_2 >= 0
            y_3 <= 0
            y_2 + y_3 == 0    :x_1
            2y_3 == -4        :x_2
        =#
        primal_model = lp1_test()
        dual_model, primal_dual_map = dual_model_and_map(primal_model)

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
        ) == 2
        obj_type = MOI.get(dual_model, MOI.ObjectiveFunctionType())
        @test obj_type == SAF{Float64}
        obj = MOI.get(dual_model, MOI.ObjectiveFunction{obj_type}())
        @test MOI.constant(obj) == -1.0
        @test MOI.coefficient.(obj.terms) == [3.0; 3.0]
    end

    @testset "lp7_test" begin
        #=
        primal
            min -4x1 -3x2 -1
        s.t.
            2x1 + x2 - 3 <= 0  :y_3
            x1 + 2x2 - 3 <= 0  :y_4
            x1 >= 1            :y_1
            x2 >= 0            :y_2

        dual
            max 3y_4 + 3y_3 + y_1 - 1
        s.a.
            y_1 + 2y_3 + y_4 = -4 :x_1
            y_2 + y_3 + 2y_4 = -3 :x_2
            y_1 >= 0
            y_2 >= 0
            y_3 <= 0
            y_4 <= 0
        =#
        primal_model = lp7_test()
        dual_model, primal_dual_map = dual_model_and_map(primal_model)

        @test MOI.get(dual_model, MOI.NumberOfVariables()) == 3
        list_of_cons = MOI.get(dual_model, MOI.ListOfConstraintTypesPresent())
        @test Set(list_of_cons) == Set(
            [
                (VI, MOI.GreaterThan{Float64})
                (SAF{Float64}, MOI.EqualTo{Float64})
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
            MOI.NumberOfConstraints{SAF{Float64},MOI.EqualTo{Float64}}(),
        ) == 1
        obj_type = MOI.get(dual_model, MOI.ObjectiveFunctionType())
        @test obj_type == SAF{Float64}
        obj = MOI.get(dual_model, MOI.ObjectiveFunction{obj_type}())
        @test MOI.constant(obj) == -1.0
        @test MOI.coefficient.(obj.terms) ==
              (Sys.WORD_SIZE == 32 ? [1.0, 3.0, 3.0] : [3.0; 1.0; 3.0])
    end

    @testset "lp10_test" begin
        #=
        primal
            min x1
        s.t.
            2x1 + x2  == 3 :y_3
            x1 + 2x2  == 3 :y_4
            x1 >= 1        :y_1
            x2 == 0        :y_2

        dual
            max y_1 + 3y_3 + 3y_4
        s.t
            y_2 + y_3 + y_4 == 1.0 :x_1
            y_1 + y_3 + y_4 == 0.0 :x_2
            y_2 >= 0
        =#
        primal_model = lp10_test()
        dual_model, primal_dual_map = dual_model_and_map(primal_model)

        @test MOI.get(dual_model, MOI.NumberOfVariables()) == 3
        list_of_cons = MOI.get(dual_model, MOI.ListOfConstraintTypesPresent())
        @test Set(list_of_cons) == Set(
            [
                (VI, MOI.GreaterThan{Float64})
                (SAF{Float64}, MOI.EqualTo{Float64})
            ],
        )
        @test MOI.get(
            dual_model,
            MOI.NumberOfConstraints{VI,MOI.GreaterThan{Float64}}(),
        ) == 1
        @test MOI.get(
            dual_model,
            MOI.NumberOfConstraints{SAF{Float64},MOI.EqualTo{Float64}}(),
        ) == 1
        obj_type = MOI.get(dual_model, MOI.ObjectiveFunctionType())
        @test obj_type == SAF{Float64}
        obj = MOI.get(dual_model, MOI.ObjectiveFunction{obj_type}())
        @test MOI.constant(obj) == 0.0
        @test Set(MOI.coefficient.(obj.terms)) == Set([1.0; 3.0; 3.0])
    end

    @testset "lp12_test" begin
        #=
        primal
            min 4x_3 + 5
        s.t.
            x_1 + 2x_2 + x_3 <= 20 :y_3
            x_1 <= 1               :y_1
            x_2 <= 3               :y_2

        dual
            max 3y_2 + y_1 + 20y_3 + 5
        s.t.
            y_1 + y_3 == 0
            y_2 + 2y_3 == 0
            y_3 == 4.0
            y_1 <= 0
            y_2 <= 0
            y_3 <= 0
        =#
        primal_model = lp12_test()
        dual_model, primal_dual_map = dual_model_and_map(primal_model)

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
        ) == 3
        obj_type = MOI.get(dual_model, MOI.ObjectiveFunctionType())
        @test obj_type == SAF{Float64}
        obj = MOI.get(dual_model, MOI.ObjectiveFunction{obj_type}())
        @test MOI.constant(obj) == 5.0
        @test Set(MOI.coefficient.(obj.terms)) == Set([1.0; 3.0; 20.0])
    end

    @testset "lp13_test" begin
        #=
        primal
           min -4x1 -3x2 -1
        s.t.
           2x1 + x2 - 3 <= 0  :y_3
           x1 + 2x2 - 3 <= 0  :y_4
           x1 >= 0            :y_1
           x2 >= 0            :y_2

        dual
           max 3y_4 + 3y_3 - 1
        s.a.
           y_1 + 2y_3 + y_4 = -4 :x_1
           y_2 + y_3 + 2y_4 = -3 :x_2
           y_1 >= 0
           y_2 >= 0
           y_3 <= 0
           y_4 <= 0
        =#
        primal_model = lp13_test()
        dual_model, primal_dual_map = dual_model_and_map(primal_model)

        @test MOI.get(dual_model, MOI.NumberOfVariables()) == 2
        list_of_cons = MOI.get(dual_model, MOI.ListOfConstraintTypesPresent())
        @test Set(list_of_cons) == Set([
            (VAF{Float64}, MOI.Nonnegatives)
            (VVF, MOI.Nonpositives)
        ])
        @test MOI.get(
            dual_model,
            MOI.NumberOfConstraints{VVF,MOI.Nonpositives}(),
        ) == 1
        @test MOI.get(
            dual_model,
            MOI.NumberOfConstraints{VVF,MOI.Nonnegatives}(),
        ) == 0
        @test MOI.get(
            dual_model,
            MOI.NumberOfConstraints{SAF{Float64},MOI.EqualTo{Float64}}(),
        ) == 0
        obj_type = MOI.get(dual_model, MOI.ObjectiveFunctionType())
        @test obj_type == SAF{Float64}
        obj = MOI.get(dual_model, MOI.ObjectiveFunction{obj_type}())
        @test MOI.constant(obj) == -1.0
        @test MOI.coefficient.(obj.terms) == [3.0; 3.0]
    end
end
