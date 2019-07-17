@testset "sdp problems" begin
    @testset "sdpt1_test" begin
    #=
    primal
        min Tr(X)
    s.t.
        X[2,1] = 1 : y_1
        X in PSD : y_2, y_3, y_4
   
   dual
        max y_1
    s.t.
        y_2 == 1
        y_1 + 2y_3 == 0
        y_4 == 1
        [y_2   y_3  
         y_3   y_4] in PSD
   =#
       primal_model = sdpt1_test()
       dual_model, primal_dual_map = dual_model_and_map(primal_model)

       @test MOI.get(dual_model, MOI.NumberOfVariables()) == 4
       list_of_cons =  MOI.get(dual_model, MOI.ListOfConstraints())
       @test Set(list_of_cons) == Set([
           (SAF{Float64}, MOI.EqualTo{Float64})              
           (VVF, MOI.PositiveSemidefiniteConeTriangle)
       ])
       @test MOI.get(dual_model, MOI.NumberOfConstraints{VVF, MOI.PositiveSemidefiniteConeTriangle}()) == 1   
       @test MOI.get(dual_model, MOI.NumberOfConstraints{SAF{Float64}, MOI.EqualTo{Float64}}()) == 3
       obj_type = MOI.get(dual_model, MOI.ObjectiveFunctionType())
       @test obj_type == SAF{Float64}
       obj = MOI.get(dual_model, MOI.ObjectiveFunction{obj_type}())
       @test MOI.get(dual_model, MOI.ObjectiveSense()) == MOI.MAX_SENSE
       @test MOI._constant(obj) == 0.0
       @test MOI.coefficient.(obj.terms) == [1.0]
       
       eq_con1_fun = MOI.get(dual_model, MOI.ConstraintFunction(), CI{SAF{Float64}, MOI.EqualTo{Float64}}(2))
       eq_con1_set = MOI.get(dual_model, MOI.ConstraintSet(), CI{SAF{Float64}, MOI.EqualTo{Float64}}(2))
       @test MOI.coefficient.(eq_con1_fun.terms) == [1.0]
       @test MOI._constant.(eq_con1_fun) == 0.0
       @test MOIU.getconstant(eq_con1_set) == 1.0
       eq_con2_fun = MOI.get(dual_model, MOI.ConstraintFunction(), CI{SAF{Float64}, MOI.EqualTo{Float64}}(3))
       eq_con2_set = MOI.get(dual_model, MOI.ConstraintSet(), CI{SAF{Float64}, MOI.EqualTo{Float64}}(3))
       @test MOI.coefficient.(eq_con2_fun.terms) == [1.0; 2.0]
       @test MOI._constant.(eq_con2_fun) == 0.0
       @test MOIU.getconstant(eq_con2_set) == 0.0
       eq_con3_fun = MOI.get(dual_model, MOI.ConstraintFunction(), CI{SAF{Float64}, MOI.EqualTo{Float64}}(4))
       eq_con3_set = MOI.get(dual_model, MOI.ConstraintSet(), CI{SAF{Float64}, MOI.EqualTo{Float64}}(4))
       @test MOI.coefficient.(eq_con3_fun.terms) == [1.0]
       @test MOI._constant.(eq_con3_fun) == 0.0
       @test MOIU.getconstant(eq_con3_set) == 1.0

       sdp_con = MOI.get(dual_model, MOI.ConstraintFunction(), CI{VVF, MOI.PositiveSemidefiniteConeTriangle}(1))
       @test sdp_con.variables == VI.(2:4)

       primal_con_dual_var = primal_dual_map.primal_con_dual_var
       @test primal_con_dual_var[CI{SAF{Float64}, MOI.EqualTo{Float64}}(2)] == [VI(1)]
       @test primal_con_dual_var[CI{VVF, MOI.PositiveSemidefiniteConeTriangle}(1)] == VI.(2:4)

       primal_var_dual_con = primal_dual_map.primal_var_dual_con
       @test primal_var_dual_con[VI(1)] == CI{SAF{Float64}, MOI.EqualTo{Float64}}(2)
       @test primal_var_dual_con[VI(2)] == CI{SAF{Float64}, MOI.EqualTo{Float64}}(3)
       @test primal_var_dual_con[VI(3)] == CI{SAF{Float64}, MOI.EqualTo{Float64}}(4)
   end

   @testset "sdpt2_test" begin
    #=
    primal
        min Tr(X)
    s.t.
        X[2,1] = 1 : y_1
        X in PSD : y_2, y_3, y_4
   
   dual
        max y_1
    s.t.
        y_2 == 1
        y_1 + 2y_3 == 0
        y_4 == 1
        [y_2   y_3  
         y_3   y_4] in PSD
   =#
       primal_model = sdpt2_test()
       dual_model, primal_dual_map = dual_model_and_map(primal_model)

       @test MOI.get(dual_model, MOI.NumberOfVariables()) == 4
       list_of_cons =  MOI.get(dual_model, MOI.ListOfConstraints())
       @test Set(list_of_cons) == Set([
           (SAF{Float64}, MOI.EqualTo{Float64})              
           (VVF, MOI.PositiveSemidefiniteConeTriangle)
       ])
       @test MOI.get(dual_model, MOI.NumberOfConstraints{VVF, MOI.PositiveSemidefiniteConeTriangle}()) == 1   
       @test MOI.get(dual_model, MOI.NumberOfConstraints{SAF{Float64}, MOI.EqualTo{Float64}}()) == 3
       obj_type = MOI.get(dual_model, MOI.ObjectiveFunctionType())
       @test obj_type == SAF{Float64}
       obj = MOI.get(dual_model, MOI.ObjectiveFunction{obj_type}())
       @test MOI.get(dual_model, MOI.ObjectiveSense()) == MOI.MAX_SENSE
       @test MOI._constant(obj) == 0.0
       @test MOI.coefficient.(obj.terms) == [1.0]
       
       eq_con1_fun = MOI.get(dual_model, MOI.ConstraintFunction(), CI{SAF{Float64}, MOI.EqualTo{Float64}}(2))
       eq_con1_set = MOI.get(dual_model, MOI.ConstraintSet(), CI{SAF{Float64}, MOI.EqualTo{Float64}}(2))
       @test MOI.coefficient.(eq_con1_fun.terms) == [1.0]
       @test MOI._constant.(eq_con1_fun) == 0.0
       @test MOIU.getconstant(eq_con1_set) == 1.0
       eq_con2_fun = MOI.get(dual_model, MOI.ConstraintFunction(), CI{SAF{Float64}, MOI.EqualTo{Float64}}(3))
       eq_con2_set = MOI.get(dual_model, MOI.ConstraintSet(), CI{SAF{Float64}, MOI.EqualTo{Float64}}(3))
       @test MOI.coefficient.(eq_con2_fun.terms) == [1.0; 2.0]
       @test MOI._constant.(eq_con2_fun) == 0.0
       @test MOIU.getconstant(eq_con2_set) == 0.0
       eq_con3_fun = MOI.get(dual_model, MOI.ConstraintFunction(), CI{SAF{Float64}, MOI.EqualTo{Float64}}(4))
       eq_con3_set = MOI.get(dual_model, MOI.ConstraintSet(), CI{SAF{Float64}, MOI.EqualTo{Float64}}(4))
       @test MOI.coefficient.(eq_con3_fun.terms) == [1.0]
       @test MOI._constant.(eq_con3_fun) == 0.0
       @test MOIU.getconstant(eq_con3_set) == 1.0

       sdp_con = MOI.get(dual_model, MOI.ConstraintFunction(), CI{VVF, MOI.PositiveSemidefiniteConeTriangle}(1))
       @test sdp_con.variables == VI.(2:4)

       primal_con_dual_var = primal_dual_map.primal_con_dual_var
       @test primal_con_dual_var[CI{SAF{Float64}, MOI.EqualTo{Float64}}(2)] == [VI(1)]
       @test primal_con_dual_var[CI{VAF{Float64}, MOI.PositiveSemidefiniteConeTriangle}(1)] == VI.(2:4)

       primal_var_dual_con = primal_dual_map.primal_var_dual_con
       @test primal_var_dual_con[VI(1)] == CI{SAF{Float64}, MOI.EqualTo{Float64}}(2)
       @test primal_var_dual_con[VI(2)] == CI{SAF{Float64}, MOI.EqualTo{Float64}}(3)
       @test primal_var_dual_con[VI(3)] == CI{SAF{Float64}, MOI.EqualTo{Float64}}(4)
    end
end