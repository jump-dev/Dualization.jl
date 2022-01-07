@testset "quadratic problems" begin
    @testset "qp1_test" begin
        #=
            min x^2 + xy + y^2 + yz + z^2
        s.t.
            x + 2y + 3z >= 4 (a)
            x +  y      >= 1 (b)
            x,y \in R
        dual
            max 4a +  b - w1^2 - w1 w2 - w2^2 - w2 w3 - w3^2
        s.t.
            - a -  b + 2w1 + 1w2        = 0
            -2a -  b + 1w1 + 2w2 + 1w3  = 0
            -3a            + 1w2 + 2w3  = 0
            a >= 0
            b >= 0
        =#
        primal_model = qp1_test()
        dual_model, primal_dual_map = dual_model_and_map(primal_model)

        @test MOI.get(dual_model, MOI.NumberOfVariables()) == 2 + 3
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
        ) == 2
        @test MOI.get(
            dual_model,
            MOI.NumberOfConstraints{SAF{Float64},MOI.EqualTo{Float64}}(),
        ) == 3
        obj_type = MOI.get(dual_model, MOI.ObjectiveFunctionType())
        @test obj_type == SQF{Float64}
        obj = MOI.get(dual_model, MOI.ObjectiveFunction{obj_type}())
        @test MOI.constant(obj) == 0.0
        @test MOI.coefficient.(obj.affine_terms) == [1.0; 4.0]
        @test MOI.coefficient.(obj.quadratic_terms) ==
              [-2.0; -1.0; -2.0; -1.0; -2.0]

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
        @test MOI.coefficient.(eq_con1_fun.terms) == [1.0; 1.0; -2.0; -1.0]
        @test MOI.constant.(eq_con1_fun) == 0.0
        @test MOI.constant(eq_con1_set) == 0.0
        eq_con2_fun = MOI.get(
            dual_model,
            MOI.ConstraintFunction(),
            CI{SAF{Float64},MOI.EqualTo{Float64}}(2),
        )
        eq_con2_set = MOI.get(
            dual_model,
            MOI.ConstraintSet(),
            CI{SAF{Float64},MOI.EqualTo{Float64}}(2),
        )
        @test MOI.coefficient.(eq_con2_fun.terms) ==
              [2.0; 1.0; -1.0; -2.0; -1.0]
        @test MOI.constant.(eq_con2_fun) == 0.0
        @test MOI.constant(eq_con2_set) == 0.0
        eq_con3_fun = MOI.get(
            dual_model,
            MOI.ConstraintFunction(),
            CI{SAF{Float64},MOI.EqualTo{Float64}}(3),
        )
        eq_con3_set = MOI.get(
            dual_model,
            MOI.ConstraintSet(),
            CI{SAF{Float64},MOI.EqualTo{Float64}}(3),
        )
        @test MOI.coefficient.(eq_con3_fun.terms) == [3.0; -1.0; -2.0]
        @test MOI.constant.(eq_con3_fun) == 0.0
        @test MOI.constant(eq_con3_set) == 0.0

        primal_con_dual_var = primal_dual_map.primal_con_dual_var
        @test primal_con_dual_var[CI{SAF{Float64},MOI.GreaterThan{Float64}}(
            1,
        )] == [VI(1)]
        @test primal_con_dual_var[CI{SAF{Float64},MOI.GreaterThan{Float64}}(
            2,
        )] == [VI(2)]

        primal_var_dual_con = primal_dual_map.primal_var_dual_con
        @test primal_var_dual_con[VI(1)] ==
              CI{SAF{Float64},MOI.EqualTo{Float64}}(1)
        @test primal_var_dual_con[VI(2)] ==
              CI{SAF{Float64},MOI.EqualTo{Float64}}(2)
        @test primal_var_dual_con[VI(3)] ==
              CI{SAF{Float64},MOI.EqualTo{Float64}}(3)

        primal_var_dual_quad_slack = primal_dual_map.primal_var_dual_quad_slack
        @test primal_var_dual_quad_slack[VI(1)] == VI(2 + 1)
        @test primal_var_dual_quad_slack[VI(2)] == VI(2 + 2)
        @test primal_var_dual_quad_slack[VI(3)] == VI(2 + 3)
    end
    @testset "qp2_test" begin
        #=
            min 2 x^2 + y^2 + xy + x + y + 1
        s.t.
            x + y = 1 (a)
            x    >= 0 (b)
               y >= 0 (c)
        dual
            max a + 1 - 2 w1^2 - w2^2 - w1 w2
        s.t.
            - a - b     + 4w1 + 1w2 + 1 = 0
            - a     - c + 1w1 + 2w2 + 1 = 0
            a \in R
            b >= 0
            c >= 0
        =#
        primal_model = qp2_test()
        dual_model, primal_dual_map = dual_model_and_map(primal_model)

        @test MOI.get(dual_model, MOI.NumberOfVariables()) == 3
        list_of_cons = MOI.get(dual_model, MOI.ListOfConstraintTypesPresent())
        @test Set(list_of_cons) ==
              Set([(SAF{Float64}, MOI.GreaterThan{Float64})],)
        obj_type = MOI.get(dual_model, MOI.ObjectiveFunctionType())
        @test obj_type == SQF{Float64}
        obj = MOI.get(dual_model, MOI.ObjectiveFunction{obj_type}())
        @test MOI.constant(obj) == 1.0
        @test MOI.coefficient.(obj.affine_terms) == [1.0]
        @test Set(MOI.coefficient.(obj.quadratic_terms)) ==
              Set([-4.0; -1.0; -2.0])
    end
end
