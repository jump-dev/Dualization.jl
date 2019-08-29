@testset "conic linear problems" begin
    @testset "conic_linear1_test" begin
    #=
    primal
        min -3x - 2y - 4z
    s.t.    
        x +  y +  z == 3 :w_4
        y +  z == 2      :w_5
        x>=0 y>=0 z>=0   :w_1, w_2, w_3

    dual
        max 3w_4 + 2w_5
    s.t.
        w_1, w_2, w_3 \in Nonnegatives
        w_1 + w_4 == -3.0
        w_2 + w_4 + w_5 == -2.0
        w_3 + w_4 + w_5 == -4.0
    =#
        primal_model = conic_linear1_test()
        dual_model, primal_dual_map = dual_model_and_map(primal_model)

        @test MOI.get(dual_model, MOI.NumberOfVariables()) == 5
        list_of_cons =  MOI.get(dual_model, MOI.ListOfConstraints())
        @test Set(list_of_cons) == Set([
            (SAF{Float64}, MOI.EqualTo{Float64})
            (VVF, MOI.Nonnegatives)
        ])
        @test MOI.get(dual_model, MOI.NumberOfConstraints{SAF{Float64}, MOI.EqualTo{Float64}}()) == 3
        @test MOI.get(dual_model, MOI.NumberOfConstraints{VVF, MOI.Nonnegatives}()) == 1
        obj_type = MOI.get(dual_model, MOI.ObjectiveFunctionType())
        @test obj_type == SAF{Float64}
        @test MOI.get(dual_model, MOI.ObjectiveSense()) == MOI.MAX_SENSE
        obj = MOI.get(dual_model, MOI.ObjectiveFunction{obj_type}())
        @test MOI.constant(obj) == 0.0
        @test MOI.coefficient.(obj.terms) == [3.0; 2.0]
        
        eq_con1_fun = MOI.get(dual_model, MOI.ConstraintFunction(), CI{SAF{Float64}, MOI.EqualTo{Float64}}(2))
        eq_con1_set = MOI.get(dual_model, MOI.ConstraintSet(), CI{SAF{Float64}, MOI.EqualTo{Float64}}(2))
        @test MOI.coefficient.(eq_con1_fun.terms) == [1.0; 1.0]
        @test MOI.constant.(eq_con1_fun) == 0.0
        @test MOI.constant(eq_con1_set) == -3.0
        eq_con2_fun = MOI.get(dual_model, MOI.ConstraintFunction(), CI{SAF{Float64}, MOI.EqualTo{Float64}}(3))
        eq_con2_set = MOI.get(dual_model, MOI.ConstraintSet(), CI{SAF{Float64}, MOI.EqualTo{Float64}}(3))
        @test MOI.coefficient.(eq_con2_fun.terms) == [1.0; 1.0; 1.0]
        @test MOI.constant.(eq_con2_fun) == 0.0
        @test MOI.constant(eq_con2_set) == -2.0
        eq_con3_fun = MOI.get(dual_model, MOI.ConstraintFunction(), CI{SAF{Float64}, MOI.EqualTo{Float64}}(4))
        eq_con3_set = MOI.get(dual_model, MOI.ConstraintSet(), CI{SAF{Float64}, MOI.EqualTo{Float64}}(4))
        @test MOI.coefficient.(eq_con3_fun.terms) == [1.0; 1.0; 1.0]
        @test MOI.constant.(eq_con3_fun) == 0.0
        @test MOI.constant(eq_con3_set) == -4.0

        primal_con_dual_var = primal_dual_map.primal_con_dual_var
        @test primal_con_dual_var[CI{VAF{Float64}, MOI.Zeros}(2)] == VI.(4:5)
        @test primal_con_dual_var[CI{VVF, MOI.Nonnegatives}(1)] == VI.(1:3)

        primal_var_dual_con = primal_dual_map.primal_var_dual_con
        @test primal_var_dual_con[VI(1)] == CI{SAF{Float64}, MOI.EqualTo{Float64}}(2)
        @test primal_var_dual_con[VI(2)] == CI{SAF{Float64}, MOI.EqualTo{Float64}}(3)
        @test primal_var_dual_con[VI(3)] == CI{SAF{Float64}, MOI.EqualTo{Float64}}(4)
    end

    @testset "conic_linear3_test" begin
    #=
    primal 
        min  3x + 2y - 4z + 0s
    s.t.  
        x           -  s == -4    :w_4
            y            == -3    :w_5
        x      +  z      == 12    :w_6
        y <= 0 :w_3
        z >= 0 :w_2
        s zero :w_1

    dual
        max -4w_4 - 3w_5 + 12w_6
    s.t
        w_4 + w_6 == 3
        w_3 + w_5 == 2
        w_2 + w_6 == -4
        w_1 - w_4 == 0
        w_2 >= 0
        w_3 <= 0
        w_1 in Reals
    =#
        primal_model = conic_linear3_test()
        dual_model, primal_dual_map = dual_model_and_map(primal_model)
        
        @test MOI.get(dual_model, MOI.NumberOfVariables()) == 6
        list_of_cons =  MOI.get(dual_model, MOI.ListOfConstraints())
        @test Set(list_of_cons) == Set([
            (SAF{Float64}, MOI.EqualTo{Float64})
            (VVF, MOI.Nonnegatives)
            (VVF, MOI.Nonpositives)
        ])
        @test MOI.get(dual_model, MOI.NumberOfConstraints{SAF{Float64}, MOI.EqualTo{Float64}}()) == 4
        @test MOI.get(dual_model, MOI.NumberOfConstraints{VVF, MOI.Nonnegatives}()) == 1
        @test MOI.get(dual_model, MOI.NumberOfConstraints{VVF, MOI.Nonpositives}()) == 1
        obj_type = MOI.get(dual_model, MOI.ObjectiveFunctionType())
        @test obj_type == SAF{Float64}
        @test MOI.get(dual_model, MOI.ObjectiveSense()) == MOI.MAX_SENSE
        obj = MOI.get(dual_model, MOI.ObjectiveFunction{obj_type}())
        @test MOI.constant(obj) == 0.0
        @test MOI.coefficient.(obj.terms) == [-4.0; -3.0; 12.0]
        
        eq_con1_fun = MOI.get(dual_model, MOI.ConstraintFunction(), CI{SAF{Float64}, MOI.EqualTo{Float64}}(3))
        eq_con1_set = MOI.get(dual_model, MOI.ConstraintSet(), CI{SAF{Float64}, MOI.EqualTo{Float64}}(3))
        @test MOI.coefficient.(eq_con1_fun.terms) == [1.0; 1.0]
        @test MOI.constant.(eq_con1_fun) == 0.0
        @test MOI.constant(eq_con1_set) == 3.0
        eq_con2_fun = MOI.get(dual_model, MOI.ConstraintFunction(), CI{SAF{Float64}, MOI.EqualTo{Float64}}(4))
        eq_con2_set = MOI.get(dual_model, MOI.ConstraintSet(), CI{SAF{Float64}, MOI.EqualTo{Float64}}(4))
        @test MOI.coefficient.(eq_con2_fun.terms) == [1.0; 1.0]
        @test MOI.constant.(eq_con2_fun) == 0.0
        @test MOI.constant(eq_con2_set) == 2.0
        eq_con3_fun = MOI.get(dual_model, MOI.ConstraintFunction(), CI{SAF{Float64}, MOI.EqualTo{Float64}}(5))
        eq_con3_set = MOI.get(dual_model, MOI.ConstraintSet(), CI{SAF{Float64}, MOI.EqualTo{Float64}}(5))
        @test MOI.coefficient.(eq_con3_fun.terms) == [1.0; 1.0]
        @test MOI.constant.(eq_con3_fun) == 0.0
        @test MOI.constant(eq_con3_set) == -4.0
        eq_con6_fun = MOI.get(dual_model, MOI.ConstraintFunction(), CI{SAF{Float64}, MOI.EqualTo{Float64}}(6))
        eq_con6_set = MOI.get(dual_model, MOI.ConstraintSet(), CI{SAF{Float64}, MOI.EqualTo{Float64}}(6))
        @test MOI.coefficient.(eq_con6_fun.terms) == [1.0; -1.0]
        @test MOI.constant.(eq_con6_fun) == 0.0
        @test MOI.constant(eq_con6_set) == 0.0

        primal_con_dual_var = primal_dual_map.primal_con_dual_var
        @test primal_con_dual_var[CI{VVF, MOI.Zeros}(4)] == [VI(1)]
        @test primal_con_dual_var[CI{VVF, MOI.Nonnegatives}(3)] == [VI(2)]
        @test primal_con_dual_var[CI{VVF, MOI.Nonpositives}(2)] == [VI(3)]
        @test primal_con_dual_var[CI{VAF{Float64}, MOI.Zeros}(1)] == VI.(4:6)


        primal_var_dual_con = primal_dual_map.primal_var_dual_con
        @test primal_var_dual_con[VI(1)] == CI{SAF{Float64}, MOI.EqualTo{Float64}}(3)
        @test primal_var_dual_con[VI(2)] == CI{SAF{Float64}, MOI.EqualTo{Float64}}(4)
        @test primal_var_dual_con[VI(3)] == CI{SAF{Float64}, MOI.EqualTo{Float64}}(5)
        @test primal_var_dual_con[VI(4)] == CI{SAF{Float64}, MOI.EqualTo{Float64}}(6)
    end
end