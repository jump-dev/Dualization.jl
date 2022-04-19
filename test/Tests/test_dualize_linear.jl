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

    @testset "lp7_test compact" begin
        #=
        primal
            min -4x1 -3x2 -1
        s.t.
            2x1 + x2 - 3 <= 0  :y_3
            x1 + 2x2 - 3 <= 0  :y_4
            x1 >= 1            :y_1 (behaves like affine since rhs!=0)
            x2 >= 0            :y_2 (does not appear in compact)
        standard dual
            max 3y_4 + 3y_3 + y_1 - 1
        s.a.
            y_1 + 2y_3 + y_4 = -4 :x_1
            y_2 + y_3 + 2y_4 = -3 :x_2
            y_1 >= 0
            y_2 >= 0
            y_3 <= 0
            y_4 <= 0
        compact dual
            max 3y_4 + 3y_3 + y_1 - 1
        s.a.
            y_1 + 2y_3 + y_4 = -4 :x_1
            - y_3 - 2y_4 >= 3 :x_2
            y_1 >= 0
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
        @test MOI.get(
            dual_model,
            MOI.NumberOfConstraints{SAF{Float64},MOI.GreaterThan{Float64}}(),
        ) == 1
        obj_type = MOI.get(dual_model, MOI.ObjectiveFunctionType())
        @test obj_type == SAF{Float64}
        obj = MOI.get(dual_model, MOI.ObjectiveFunction{obj_type}())
        @test MOI.constant(obj) == -1.0
        @test Set(MOI.coefficient.(obj.terms)) == Set([3.0; 1.0; 3.0])

        ci = MOI.get(
            dual_model,
            MOI.ListOfConstraintIndices{SAF{Float64},MOI.EqualTo{Float64}}(),
        )[]
        f = MOI.get(dual_model, MOI.ConstraintFunction(), ci)
        @test Set(MOI.coefficient.(f.terms)) == Set([1.0; 2.0; 1.0])
        @test MOI.constant(f) == 0.0
        @test MOI.get(dual_model, MOI.ConstraintSet(), ci) == MOI.EqualTo(-4.0)
        ci = MOI.get(
            dual_model,
            MOI.ListOfConstraintIndices{SAF{Float64},MOI.GreaterThan{Float64}}(),
        )[]
        f = MOI.get(dual_model, MOI.ConstraintFunction(), ci)
        @test Set(MOI.coefficient.(f.terms)) == Set([-1.0; -2.0])
        @test MOI.constant(f) == 0.0
        @test MOI.get(dual_model, MOI.ConstraintSet(), ci) ==
              MOI.GreaterThan(3.0)
    end

    @testset "lp7_test standard" begin
        #=
        primal
            min -4x1 -3x2 -1
        s.t.
            2x1 + x2 - 3 <= 0  :y_3 (nopos1)
            x1 + 2x2 - 3 <= 0  :y_4 (nopos1)
            x1 >= 1            :y_1 (behaves like affine since rhs!=0)
            x2 >= 0            :y_2 (does not appear in compact)
        standard dual
            max 3y_4 + 3y_3 + y_1 - 1
        s.a.
            y_1 + 2y_3 + y_4 = -4 :x_1
            y_2 + y_3 + 2y_4 = -3 :x_2
            y_1 >= 0
            y_2 >= 0
            y_3 <= 0 (nopos1)
            y_4 <= 0 (nopos1)
        compact dual
            max 3y_4 + 3y_3 + y_1 - 1
        s.a.
            y_1 + 2y_3 + y_4 = -4 :x_1
            - y_3 - 2y_4 >= 3 :x_2
            y_1 >= 0
            y_3 <= 0
            y_4 <= 0
        =#
        primal_model = lp7_test()
        dual = dualize(primal_model, consider_constrained_variables = false)
        dual_model, primal_dual_map = dual.dual_model, dual.primal_dual_map
        @test MOI.get(dual_model, MOI.NumberOfVariables()) == 4
        list_of_cons = MOI.get(dual_model, MOI.ListOfConstraintTypesPresent())
        @test Set(list_of_cons) == Set(
            [
                (SAF{Float64}, MOI.EqualTo{Float64})
                (VI, MOI.GreaterThan{Float64})
                (VVF, MOI.Nonpositives)
            ],
        )
        @test MOI.get(
            dual_model,
            MOI.NumberOfConstraints{VVF,MOI.Nonpositives}(),
        ) == 1
        @test MOI.get(
            dual_model,
            MOI.NumberOfConstraints{VI,MOI.GreaterThan{Float64}}(),
        ) == 2
        @test MOI.get(
            dual_model,
            MOI.NumberOfConstraints{SAF{Float64},MOI.EqualTo{Float64}}(),
        ) == 2
        obj_type = MOI.get(dual_model, MOI.ObjectiveFunctionType())
        @test obj_type == SAF{Float64}
        obj = MOI.get(dual_model, MOI.ObjectiveFunction{obj_type}())
        @test MOI.constant(obj) == -1.0
        @test Set(MOI.coefficient.(obj.terms)) == Set([3.0; 1.0; 3.0])

        cis = MOI.get(
            dual_model,
            MOI.ListOfConstraintIndices{VI,MOI.GreaterThan{Float64}}(),
        )
        for ci in cis
            @test MOI.get(dual_model, MOI.ConstraintSet(), ci) ==
                  MOI.GreaterThan(0.0)
        end

        cis = MOI.get(
            dual_model,
            MOI.ListOfConstraintIndices{SAF{Float64},MOI.EqualTo{Float64}}(),
        )
        @test Set(MOI.get.(dual_model, MOI.ConstraintSet(), cis)) ==
              Set([MOI.EqualTo(-4.0), MOI.EqualTo(-3.0)])
    end

    @testset "lp14_test_min" begin
        #=
            min -1 +2x1 -3x2 +4x3
        s.t.
            +5x1  -6x2  +7x3 <= 8   (y1)
            -9x1 +10x2 -11x3 >= -12 (y2)
            13x1 -14x2 +15x3 == 16  (y3)
            x1 >= 0 (y4)
            x2 <= 0 (y5)
            x3 free (y6)
        standard dual
            ...
        compact dual
            max 8y1 -12y2 +16y3 - 1
        s.a.
            -5y1  +9y2 -13y3 +2 >= 0 (x1)
            +6y1 -10y2 +14y3 -3 <= 0 (x2)
            -7y1 +11y2 -15y3 +4 == 0 (x3)
            y1 <= 0
            y2 >= 0
            y3 free
        =#
        primal_model = lp14_test(MOI.MIN_SENSE)
        dual_model, primal_dual_map = dual_model_and_map(primal_model)

        @test MOI.get(dual_model, MOI.NumberOfVariables()) == 3
        list_of_cons = MOI.get(dual_model, MOI.ListOfConstraintTypesPresent())
        @test Set(list_of_cons) == Set(
            [
                (VI, MOI.GreaterThan{Float64})
                (VI, MOI.LessThan{Float64})
                (SAF{Float64}, MOI.EqualTo{Float64})
                (SAF{Float64}, MOI.GreaterThan{Float64})
                (SAF{Float64}, MOI.LessThan{Float64})
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
        @test MOI.get(
            dual_model,
            MOI.NumberOfConstraints{SAF{Float64},MOI.GreaterThan{Float64}}(),
        ) == 1
        @test MOI.get(
            dual_model,
            MOI.NumberOfConstraints{SAF{Float64},MOI.LessThan{Float64}}(),
        ) == 1

        obj_type = MOI.get(dual_model, MOI.ObjectiveFunctionType())
        @test obj_type == SAF{Float64}
        obj = MOI.get(dual_model, MOI.ObjectiveFunction{obj_type}())
        @test MOI.constant(obj) == -1.0
        @test Set(MOI.coefficient.(obj.terms)) == Set([8.0, -12.0, 16])

        ci = MOI.get(
            dual_model,
            MOI.ListOfConstraintIndices{SAF{Float64},MOI.GreaterThan{Float64}}(),
        )[]
        f = MOI.get(dual_model, MOI.ConstraintFunction(), ci)
        @test Set(MOI.coefficient.(f.terms)) == Set([-5.0; 9.0; -13.0])
        @test MOI.constant(f) == 0.0
        @test MOI.get(dual_model, MOI.ConstraintSet(), ci) ==
              MOI.GreaterThan(-2.0)

        ci = MOI.get(
            dual_model,
            MOI.ListOfConstraintIndices{SAF{Float64},MOI.LessThan{Float64}}(),
        )[]
        f = MOI.get(dual_model, MOI.ConstraintFunction(), ci)
        @test Set(MOI.coefficient.(f.terms)) == Set([6.0; -10.0; +14.0])
        @test MOI.constant(f) == 0.0
        @test MOI.get(dual_model, MOI.ConstraintSet(), ci) == MOI.LessThan(3.0)

        # TODO flip these
        # ci = MOI.get(dual_model, MOI.ListOfConstraintIndices{SAF{Float64},MOI.EqualTo{Float64}}())[]
        # f = MOI.get(dual_model, MOI.ConstraintFunction(), ci)
        # @test Set(MOI.coefficient.(f.terms)) == Set([-7.0; +11.0; -15.0])
        # @test MOI.constant(f) == 0.0
        # @test MOI.get(dual_model, MOI.ConstraintSet(), ci) == MOI.EqualTo(-4.0)

    end
    @testset "lp14_test_max compact" begin
        #=
            max -1 +2x1 -3x2 +4x3
        s.t.
            +5x1  -6x2  +7x3 <= 8   (y1)
            -9x1 +10x2 -11x3 >= -12 (y2)
            13x1 -14x2 +15x3 == 16  (y3)
            x1 >= 0 (y4)
            x2 <= 0 (y5)
            x3 free (y6)
        standard dual
            min -8y1 +12y2 -16y3 - 1
        s.a.
            -5y1  +9y2 -13y3 -y4 -2 == 0 (x1)
            +6y1 -10y2 +14y3 -y5 +3 == 0 (x2)
            -7y1 +11y2 -15y3 -y6 -4 == 0 (x3)
            y1 <= 0
            y2 >= 0
            y3 free
            y4 >= 0
            y5 <= 0
            y6 == 0
        compact dual
            min -8y1 +12y2 -16y3 - 1
        s.a.
            -5y1  +9y2 -13y3 -2 >= 0 (x1)
            +6y1 -10y2 +14y3 +3 <= 0 (x2)
            -7y1 +11y2 -15y3 -4 == 0 (x3)
            y1 <= 0
            y2 >= 0
            y3 free
        =#
        primal_model = lp14_test(MOI.MAX_SENSE)
        dual_model, primal_dual_map = dual_model_and_map(primal_model)

        @test MOI.get(dual_model, MOI.NumberOfVariables()) == 3
        list_of_cons = MOI.get(dual_model, MOI.ListOfConstraintTypesPresent())
        @test Set(list_of_cons) == Set(
            [
                (VI, MOI.GreaterThan{Float64})
                (VI, MOI.LessThan{Float64})
                (SAF{Float64}, MOI.EqualTo{Float64})
                (SAF{Float64}, MOI.GreaterThan{Float64})
                (SAF{Float64}, MOI.LessThan{Float64})
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
        @test MOI.get(
            dual_model,
            MOI.NumberOfConstraints{SAF{Float64},MOI.GreaterThan{Float64}}(),
        ) == 1
        @test MOI.get(
            dual_model,
            MOI.NumberOfConstraints{SAF{Float64},MOI.LessThan{Float64}}(),
        ) == 1

        obj_type = MOI.get(dual_model, MOI.ObjectiveFunctionType())
        @test obj_type == SAF{Float64}
        obj = MOI.get(dual_model, MOI.ObjectiveFunction{obj_type}())
        @test MOI.constant(obj) == -1.0
        @test Set(MOI.coefficient.(obj.terms)) == Set([-8.0, 12.0, -16])

        ci = MOI.get(
            dual_model,
            MOI.ListOfConstraintIndices{SAF{Float64},MOI.GreaterThan{Float64}}(),
        )[]
        f = MOI.get(dual_model, MOI.ConstraintFunction(), ci)
        @test Set(MOI.coefficient.(f.terms)) == Set([-5.0; 9.0; -13.0])
        @test MOI.constant(f) == 0.0
        @test MOI.get(dual_model, MOI.ConstraintSet(), ci) ==
              MOI.GreaterThan(2.0)

        ci = MOI.get(
            dual_model,
            MOI.ListOfConstraintIndices{SAF{Float64},MOI.LessThan{Float64}}(),
        )[]
        f = MOI.get(dual_model, MOI.ConstraintFunction(), ci)
        @test Set(MOI.coefficient.(f.terms)) == Set([6.0; -10.0; +14.0])
        @test MOI.constant(f) == 0.0
        @test MOI.get(dual_model, MOI.ConstraintSet(), ci) == MOI.LessThan(-3.0)

        # TODO flip these
        # ci = MOI.get(dual_model, MOI.ListOfConstraintIndices{SAF{Float64},MOI.EqualTo{Float64}}())[]
        # f = MOI.get(dual_model, MOI.ConstraintFunction(), ci)
        # @test Set(MOI.coefficient.(f.terms)) == Set([-7.0; +11.0; -15.0])
        # @test MOI.constant(f) == 0.0
        # @test MOI.get(dual_model, MOI.ConstraintSet(), ci) == MOI.EqualTo(4.0)

    end
    @testset "lp14_test_min standard" begin
        #=
            min -1 +2x1 -3x2 +4x3
        s.t.
            +5x1  -6x2  +7x3 <= 8   (y1)
            -9x1 +10x2 -11x3 >= -12 (y2)
            13x1 -14x2 +15x3 == 16  (y3)
            x1 >= 0 (y4)
            x2 <= 0 (y5)
            x3 free
        standard dual
            min 8y1 -12y2 +16y3 - 1
        s.a.
            -5y1  +9y2 -13y3 -y4 +2 == 0 (x1)
            +6y1 -10y2 +14y3 -y5 -3 == 0 (x2)
            -7y1 +11y2 -15y3     +4 == 0 (x3)
            y1 <= 0
            y2 >= 0
            y3 free
            y4 >= 0
            y5 <= 0
        compact dual
            max 8y1 -12y2 +16y3 - 1
        s.a.
            -5y1  +9y2 -13y3 +2 >= 0 (x1)
            +6y1 -10y2 +14y3 -3 <= 0 (x2)
            -7y1 +11y2 -15y3 +4 == 0 (x3)
            y1 <= 0
            y2 >= 0
            y3 free
        =#
        primal_model = lp14_test(MOI.MIN_SENSE)
        dual = dualize(primal_model, consider_constrained_variables = false)
        dual_model, primal_dual_map = dual.dual_model, dual.primal_dual_map

        @test MOI.get(dual_model, MOI.NumberOfVariables()) == 5
        list_of_cons = MOI.get(dual_model, MOI.ListOfConstraintTypesPresent())
        @test Set(list_of_cons) == Set(
            [
                (SAF{Float64}, MOI.EqualTo{Float64})
                (VI, MOI.GreaterThan{Float64})
                (VI, MOI.LessThan{Float64})
            ],
        )
        @test MOI.get(
            dual_model,
            MOI.NumberOfConstraints{SAF{Float64},MOI.EqualTo{Float64}}(),
        ) == 3
        @test MOI.get(
            dual_model,
            MOI.NumberOfConstraints{VI,MOI.GreaterThan{Float64}}(),
        ) == 2
        @test MOI.get(
            dual_model,
            MOI.NumberOfConstraints{VI,MOI.LessThan{Float64}}(),
        ) == 2

        obj_type = MOI.get(dual_model, MOI.ObjectiveFunctionType())
        @test obj_type == SAF{Float64}
        obj = MOI.get(dual_model, MOI.ObjectiveFunction{obj_type}())
        @test MOI.constant(obj) == -1.0
        @test Set(MOI.coefficient.(obj.terms)) == Set([8.0, -12.0, 16])

        cis = MOI.get(
            dual_model,
            MOI.ListOfConstraintIndices{VI,MOI.GreaterThan{Float64}}(),
        )
        for ci in cis
            @test MOI.get(dual_model, MOI.ConstraintSet(), ci) ==
                  MOI.GreaterThan(0.0)
        end
        cis = MOI.get(
            dual_model,
            MOI.ListOfConstraintIndices{VI,MOI.LessThan{Float64}}(),
        )
        for ci in cis
            @test MOI.get(dual_model, MOI.ConstraintSet(), ci) ==
                  MOI.LessThan(0.0)
        end

        cis = MOI.get(
            dual_model,
            MOI.ListOfConstraintIndices{SAF{Float64},MOI.EqualTo{Float64}}(),
        )
        # TODO: review signs here
        @test Set(MOI.get.(dual_model, MOI.ConstraintSet(), cis)) ==
              Set([MOI.EqualTo(2.0), MOI.EqualTo(-3.0), MOI.EqualTo(4.0)])
        for ci in cis
            set = MOI.get(dual_model, MOI.ConstraintSet(), ci)
            f = MOI.get(dual_model, MOI.ConstraintFunction(), ci)
            if set == MOI.EqualTo(2.0)
                @test Set(MOI.coefficient.(f.terms)) ==
                      Set(-[-5.0; 9.0; -13.0; -1])
                @test MOI.constant(f) == 0.0
            elseif set == MOI.EqualTo(-3.0)
                @test Set(MOI.coefficient.(f.terms)) ==
                      Set(-[6.0; -10.0; +14.0; -1])
                @test MOI.constant(f) == 0.0
            elseif set == MOI.EqualTo(4.0)
                @test Set(MOI.coefficient.(f.terms)) ==
                      Set(-[-7.0; +11.0; -15.0])
                @test MOI.constant(f) == 0.0
            else
                error("wrong ci")
            end
        end
    end
    @testset "lp14_test_max standard" begin
        #=
            max -1 +2x1 -3x2 +4x3
        s.t.
            +5x1  -6x2  +7x3 <= 8   (y1)
            -9x1 +10x2 -11x3 >= -12 (y2)
            13x1 -14x2 +15x3 == 16  (y3)
            x1 >= 0 (y4)
            x2 <= 0 (y5)
            x3 free
        standard dual
            min -8y1 +12y2 -16y3 - 1
        s.a.
            -5y1  +9y2 -13y3 -y4 -2 == 0 (x1)
            +6y1 -10y2 +14y3 -y5 +3 == 0 (x2)
            -7y1 +11y2 -15y3     -4 == 0 (x3)
            y1 <= 0
            y2 >= 0
            y3 free
            y4 >= 0
            y5 <= 0
        compact dual
            min -8y1 +12y2 -16y3 - 1
        s.a.
            -5y1  +9y2 -13y3 -2 >= 0 (x1)
            +6y1 -10y2 +14y3 +3 <= 0 (x2)
            -7y1 +11y2 -15y3 -4 == 0 (x3)
            y1 <= 0
            y2 >= 0
            y3 free
        =#
        primal_model = lp14_test(MOI.MAX_SENSE)
        dual = dualize(primal_model, consider_constrained_variables = false)
        dual_model, primal_dual_map = dual.dual_model, dual.primal_dual_map

        @test MOI.get(dual_model, MOI.NumberOfVariables()) == 5
        list_of_cons = MOI.get(dual_model, MOI.ListOfConstraintTypesPresent())
        @test Set(list_of_cons) == Set(
            [
                (SAF{Float64}, MOI.EqualTo{Float64})
                (VI, MOI.GreaterThan{Float64})
                (VI, MOI.LessThan{Float64})
            ],
        )
        @test MOI.get(
            dual_model,
            MOI.NumberOfConstraints{SAF{Float64},MOI.EqualTo{Float64}}(),
        ) == 3
        @test MOI.get(
            dual_model,
            MOI.NumberOfConstraints{VI,MOI.GreaterThan{Float64}}(),
        ) == 2
        @test MOI.get(
            dual_model,
            MOI.NumberOfConstraints{VI,MOI.LessThan{Float64}}(),
        ) == 2

        obj_type = MOI.get(dual_model, MOI.ObjectiveFunctionType())
        @test obj_type == SAF{Float64}
        obj = MOI.get(dual_model, MOI.ObjectiveFunction{obj_type}())
        @test MOI.constant(obj) == -1.0
        @test Set(MOI.coefficient.(obj.terms)) == Set([-8.0, 12.0, -16])

        cis = MOI.get(
            dual_model,
            MOI.ListOfConstraintIndices{VI,MOI.GreaterThan{Float64}}(),
        )
        for ci in cis
            @test MOI.get(dual_model, MOI.ConstraintSet(), ci) ==
                  MOI.GreaterThan(0.0)
        end
        cis = MOI.get(
            dual_model,
            MOI.ListOfConstraintIndices{VI,MOI.LessThan{Float64}}(),
        )
        for ci in cis
            @test MOI.get(dual_model, MOI.ConstraintSet(), ci) ==
                  MOI.LessThan(0.0)
        end

        cis = MOI.get(
            dual_model,
            MOI.ListOfConstraintIndices{SAF{Float64},MOI.EqualTo{Float64}}(),
        )
        # TODO: review signs here
        @test Set(MOI.get.(dual_model, MOI.ConstraintSet(), cis)) ==
              Set([MOI.EqualTo(-2.0), MOI.EqualTo(3.0), MOI.EqualTo(-4.0)])
        for ci in cis
            set = MOI.get(dual_model, MOI.ConstraintSet(), ci)
            f = MOI.get(dual_model, MOI.ConstraintFunction(), ci)
            if set == MOI.EqualTo(-2.0)
                @test Set(MOI.coefficient.(f.terms)) ==
                      Set(-[-5.0; 9.0; -13.0; -1])
                @test MOI.constant(f) == 0.0
            elseif set == MOI.EqualTo(3.0)
                @test Set(MOI.coefficient.(f.terms)) ==
                      Set(-[6.0; -10.0; +14.0; -1])
                @test MOI.constant(f) == 0.0
            elseif set == MOI.EqualTo(-4.0)
                @test Set(MOI.coefficient.(f.terms)) ==
                      Set(-[-7.0; +11.0; -15.0])
                @test MOI.constant(f) == 0.0
            else
                error("wrong ci")
            end
        end
    end
end
