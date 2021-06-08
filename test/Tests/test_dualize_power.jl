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

        @test MOI.get(dual_model, MOI.NumberOfVariables()) == 5
        list_of_cons = MOI.get(dual_model, MOI.ListOfConstraints())
        @test Set(list_of_cons) == Set(
            [
                (SAF{Float64}, MOI.EqualTo{Float64})
                (VVF, MOI.DualPowerCone{Float64})
            ],
        )
        @test MOI.get(
            dual_model,
            MOI.NumberOfConstraints{VVF,MOI.DualPowerCone{Float64}}(),
        ) == 1
        @test MOI.get(
            dual_model,
            MOI.NumberOfConstraints{SAF{Float64},MOI.EqualTo{Float64}}(),
        ) == 3
        obj_type = MOI.get(dual_model, MOI.ObjectiveFunctionType())
        @test obj_type == SAF{Float64}
        obj = MOI.get(dual_model, MOI.ObjectiveFunction{obj_type}())
        @test MOI.get(dual_model, MOI.ObjectiveSense()) == MOI.MIN_SENSE
        @test MOI.constant(obj) == 0.0
        @test MOI.coefficient.(obj.terms) == [-1.0; -2.0]

        eq_con1_fun = MOI.get(
            dual_model,
            MOI.ConstraintFunction(),
            CI{SAF{Float64},MOI.EqualTo{Float64}}(2),
        )
        eq_con1_set = MOI.get(
            dual_model,
            MOI.ConstraintSet(),
            CI{SAF{Float64},MOI.EqualTo{Float64}}(2),
        )
        @test MOI.coefficient.(eq_con1_fun.terms) == [1.0; 1.0]
        @test MOI.constant.(eq_con1_fun) == 0.0
        @test MOI.constant(eq_con1_set) == 0.0
        eq_con2_fun = MOI.get(
            dual_model,
            MOI.ConstraintFunction(),
            CI{SAF{Float64},MOI.EqualTo{Float64}}(3),
        )
        eq_con2_set = MOI.get(
            dual_model,
            MOI.ConstraintSet(),
            CI{SAF{Float64},MOI.EqualTo{Float64}}(3),
        )
        @test MOI.coefficient.(eq_con2_fun.terms) == [1.0; 1.0]
        @test MOI.constant.(eq_con2_fun) == 0.0
        @test MOI.constant(eq_con2_set) == 0.0
        eq_con3_fun = MOI.get(
            dual_model,
            MOI.ConstraintFunction(),
            CI{SAF{Float64},MOI.EqualTo{Float64}}(4),
        )
        eq_con3_set = MOI.get(
            dual_model,
            MOI.ConstraintSet(),
            CI{SAF{Float64},MOI.EqualTo{Float64}}(4),
        )
        @test MOI.coefficient.(eq_con3_fun.terms) == [1.0]
        @test MOI.constant.(eq_con3_fun) == 0.0
        @test MOI.constant(eq_con3_set) == -1.0

        dual_exp_con = MOI.get(
            dual_model,
            MOI.ConstraintFunction(),
            CI{VVF,MOI.DualPowerCone}(1),
        )
        @test dual_exp_con.variables == VI.(3:5)

        primal_con_dual_var = primal_dual_map.primal_con_dual_var
        @test primal_con_dual_var[CI{SAF{Float64},MOI.EqualTo{Float64}}(2)] ==
              [VI(1)]
        @test primal_con_dual_var[CI{SAF{Float64},MOI.EqualTo{Float64}}(3)] ==
              [VI(2)]
        @test primal_con_dual_var[CI{VVF,MOI.PowerCone{Float64}}(1)] == VI.(3:5)

        primal_var_dual_con = primal_dual_map.primal_var_dual_con
        @test primal_var_dual_con[VI(1)] ==
              CI{SAF{Float64},MOI.EqualTo{Float64}}(2)
        @test primal_var_dual_con[VI(2)] ==
              CI{SAF{Float64},MOI.EqualTo{Float64}}(3)
        @test primal_var_dual_con[VI(3)] ==
              CI{SAF{Float64},MOI.EqualTo{Float64}}(4)
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
        list_of_cons = MOI.get(dual_model, MOI.ListOfConstraints())
        @test Set(list_of_cons) == Set(
            [
                (SAF{Float64}, MOI.EqualTo{Float64})
                (VVF, MOI.DualPowerCone{Float64})
            ],
        )
        @test MOI.get(
            dual_model,
            MOI.NumberOfConstraints{VVF,MOI.DualPowerCone{Float64}}(),
        ) == 1
        @test MOI.get(
            dual_model,
            MOI.NumberOfConstraints{SAF{Float64},MOI.EqualTo{Float64}}(),
        ) == 3
        obj_type = MOI.get(dual_model, MOI.ObjectiveFunctionType())
        @test obj_type == SAF{Float64}
        obj = MOI.get(dual_model, MOI.ObjectiveFunction{obj_type}())
        @test MOI.get(dual_model, MOI.ObjectiveSense()) == MOI.MIN_SENSE
        @test MOI.constant(obj) == 0.0
        @test MOI.coefficient.(obj.terms) == [-1.0; -2.0]

        eq_con1_fun = MOI.get(
            dual_model,
            MOI.ConstraintFunction(),
            CI{SAF{Float64},MOI.EqualTo{Float64}}(2),
        )
        eq_con1_set = MOI.get(
            dual_model,
            MOI.ConstraintSet(),
            CI{SAF{Float64},MOI.EqualTo{Float64}}(2),
        )
        @test MOI.coefficient.(eq_con1_fun.terms) == [1.0; 1.0]
        @test MOI.constant.(eq_con1_fun) == 0.0
        @test MOI.constant(eq_con1_set) == 0.0
        eq_con2_fun = MOI.get(
            dual_model,
            MOI.ConstraintFunction(),
            CI{SAF{Float64},MOI.EqualTo{Float64}}(3),
        )
        eq_con2_set = MOI.get(
            dual_model,
            MOI.ConstraintSet(),
            CI{SAF{Float64},MOI.EqualTo{Float64}}(3),
        )
        @test MOI.coefficient.(eq_con2_fun.terms) == [1.0; 1.0]
        @test MOI.constant.(eq_con2_fun) == 0.0
        @test MOI.constant(eq_con2_set) == 0.0
        eq_con3_fun = MOI.get(
            dual_model,
            MOI.ConstraintFunction(),
            CI{SAF{Float64},MOI.EqualTo{Float64}}(4),
        )
        eq_con3_set = MOI.get(
            dual_model,
            MOI.ConstraintSet(),
            CI{SAF{Float64},MOI.EqualTo{Float64}}(4),
        )
        @test MOI.coefficient.(eq_con3_fun.terms) == [1.0]
        @test MOI.constant.(eq_con3_fun) == 0.0
        @test MOI.constant(eq_con3_set) == -1.0

        dual_exp_con = MOI.get(
            dual_model,
            MOI.ConstraintFunction(),
            CI{VVF,MOI.DualPowerCone}(1),
        )
        @test dual_exp_con.variables == VI.(3:5)

        primal_con_dual_var = primal_dual_map.primal_con_dual_var
        @test primal_con_dual_var[CI{SAF{Float64},MOI.EqualTo{Float64}}(2)] ==
              [VI(1)]
        @test primal_con_dual_var[CI{SAF{Float64},MOI.EqualTo{Float64}}(3)] ==
              [VI(2)]
        @test primal_con_dual_var[CI{VAF{Float64},MOI.PowerCone{Float64}}(1)] ==
              VI.(3:5)

        primal_var_dual_con = primal_dual_map.primal_var_dual_con
        @test primal_var_dual_con[VI(1)] ==
              CI{SAF{Float64},MOI.EqualTo{Float64}}(2)
        @test primal_var_dual_con[VI(2)] ==
              CI{SAF{Float64},MOI.EqualTo{Float64}}(3)
        @test primal_var_dual_con[VI(3)] ==
              CI{SAF{Float64},MOI.EqualTo{Float64}}(4)
    end
end
