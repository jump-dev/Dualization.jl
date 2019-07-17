@testset "soc problems" begin
    @testset "soc1_test" begin
    #=
   primal
       max 0x + 1y + 1z
   s.t.
       x == 1          :w_4
       x >= ||(y,z)||  :w_1, w_2, w_3

   dual
       min -w_4
   s.t.
       w_2 == -1
       w_3 == -1
       w_1 + w_4 == 0
       w_1 >= ||(w_2, w_3)||
    =#
       primal_model = soc1_test()
       dual_model, primal_dual_map = dual_model_and_map(primal_model)

       @test MOI.get(dual_model, MOI.NumberOfVariables()) == 4
       list_of_cons =  MOI.get(dual_model, MOI.ListOfConstraints())
       @test Set(list_of_cons) == Set([
           (SAF{Float64}, MOI.EqualTo{Float64})              
           (VVF, MOI.SecondOrderCone)
       ])
       @test MOI.get(dual_model, MOI.NumberOfConstraints{VVF, MOI.SecondOrderCone}()) == 1   
       @test MOI.get(dual_model, MOI.NumberOfConstraints{SAF{Float64}, MOI.EqualTo{Float64}}()) == 3
       obj_type = MOI.get(dual_model, MOI.ObjectiveFunctionType())
       @test obj_type == SAF{Float64}
       obj = MOI.get(dual_model, MOI.ObjectiveFunction{obj_type}())
       @test MOI._constant(obj) == 0.0
       @test MOI.coefficient.(obj.terms) == [-1.0]
       
       eq_con1_fun = MOI.get(dual_model, MOI.ConstraintFunction(), CI{SAF{Float64}, MOI.EqualTo{Float64}}(2))
       eq_con1_set = MOI.get(dual_model, MOI.ConstraintSet(), CI{SAF{Float64}, MOI.EqualTo{Float64}}(2))
       @test MOI.coefficient.(eq_con1_fun.terms) == [1.0; 1.0]
       @test MOI._constant.(eq_con1_fun) == 0.0
       @test MOIU.getconstant(eq_con1_set) == 0.0
       eq_con2_fun = MOI.get(dual_model, MOI.ConstraintFunction(), CI{SAF{Float64}, MOI.EqualTo{Float64}}(3))
       eq_con2_set = MOI.get(dual_model, MOI.ConstraintSet(), CI{SAF{Float64}, MOI.EqualTo{Float64}}(3))
       @test MOI.coefficient.(eq_con2_fun.terms) == [1.0]
       @test MOI._constant.(eq_con2_fun) == 0.0
       @test MOIU.getconstant(eq_con2_set) == -1.0
       eq_con3_fun = MOI.get(dual_model, MOI.ConstraintFunction(), CI{SAF{Float64}, MOI.EqualTo{Float64}}(4))
       eq_con3_set = MOI.get(dual_model, MOI.ConstraintSet(), CI{SAF{Float64}, MOI.EqualTo{Float64}}(4))
       @test MOI.coefficient.(eq_con3_fun.terms) == [1.0]
       @test MOI._constant.(eq_con3_fun) == 0.0
       @test MOIU.getconstant(eq_con3_set) == -1.0

       soc_con = MOI.get(dual_model, MOI.ConstraintFunction(), CI{VVF, MOI.SecondOrderCone}(1))
       @test soc_con.variables == VI.(1:3)

       primal_con_dual_var = primal_dual_map.primal_con_dual_var
       @test primal_con_dual_var[CI{VAF{Float64}, MOI.Zeros}(1)] == [VI(4)]
       @test primal_con_dual_var[CI{VVF, MOI.SecondOrderCone}(2)] == [VI(1); VI(2); VI(3)]

       primal_var_dual_con = primal_dual_map.primal_var_dual_con
       @test primal_var_dual_con[VI(1)] == CI{SAF{Float64}, MOI.EqualTo{Float64}}(2)
       @test primal_var_dual_con[VI(2)] == CI{SAF{Float64}, MOI.EqualTo{Float64}}(3)
       @test primal_var_dual_con[VI(3)] == CI{SAF{Float64}, MOI.EqualTo{Float64}}(4)
   end

   @testset "soc2_test" begin
    #=
   primal
       max 0x + 1y + 1z
   s.t.
       x == 1          :w_4
       x >= ||(y,z)||  :w_1, w_2, w_3
   
   dual
       min -w_4
   s.t.
       w_2 == -1
       w_3 == -1
       w_1 + w_4 == 0
       w_1 >= ||(w_2, w_3)||
   =#
       primal_model = soc2_test()
       dual_model, primal_dual_map = dual_model_and_map(primal_model)

       @test MOI.get(dual_model, MOI.NumberOfVariables()) == 4
       list_of_cons =  MOI.get(dual_model, MOI.ListOfConstraints())
       @test Set(list_of_cons) == Set([
           (SAF{Float64}, MOI.EqualTo{Float64})              
           (VVF, MOI.SecondOrderCone)
       ])
       @test MOI.get(dual_model, MOI.NumberOfConstraints{VVF, MOI.SecondOrderCone}()) == 1   
       @test MOI.get(dual_model, MOI.NumberOfConstraints{SAF{Float64}, MOI.EqualTo{Float64}}()) == 3
       obj_type = MOI.get(dual_model, MOI.ObjectiveFunctionType())
       @test obj_type == SAF{Float64}
       obj = MOI.get(dual_model, MOI.ObjectiveFunction{obj_type}())
       @test MOI._constant(obj) == 0.0
       @test MOI.coefficient.(obj.terms) == [-1.0]
       
       eq_con1_fun = MOI.get(dual_model, MOI.ConstraintFunction(), CI{SAF{Float64}, MOI.EqualTo{Float64}}(2))
       eq_con1_set = MOI.get(dual_model, MOI.ConstraintSet(), CI{SAF{Float64}, MOI.EqualTo{Float64}}(2))
       @test MOI.coefficient.(eq_con1_fun.terms) == [1.0; 1.0]
       @test MOI._constant.(eq_con1_fun) == 0.0
       @test MOIU.getconstant(eq_con1_set) == 0.0
       eq_con2_fun = MOI.get(dual_model, MOI.ConstraintFunction(), CI{SAF{Float64}, MOI.EqualTo{Float64}}(3))
       eq_con2_set = MOI.get(dual_model, MOI.ConstraintSet(), CI{SAF{Float64}, MOI.EqualTo{Float64}}(3))
       @test MOI.coefficient.(eq_con2_fun.terms) == [1.0]
       @test MOI._constant.(eq_con2_fun) == 0.0
       @test MOIU.getconstant(eq_con2_set) == -1.0
       eq_con3_fun = MOI.get(dual_model, MOI.ConstraintFunction(), CI{SAF{Float64}, MOI.EqualTo{Float64}}(4))
       eq_con3_set = MOI.get(dual_model, MOI.ConstraintSet(), CI{SAF{Float64}, MOI.EqualTo{Float64}}(4))
       @test MOI.coefficient.(eq_con3_fun.terms) == [1.0]
       @test MOI._constant.(eq_con3_fun) == 0.0
       @test MOIU.getconstant(eq_con3_set) == -1.0

       soc_con = MOI.get(dual_model, MOI.ConstraintFunction(), CI{VVF, MOI.SecondOrderCone}(1))
       @test soc_con.variables == VI.(2:4)

       primal_con_dual_var = primal_dual_map.primal_con_dual_var
       @test primal_con_dual_var[CI{VAF{Float64}, MOI.Zeros}(1)] == [VI(1)]
       @test primal_con_dual_var[CI{VAF{Float64}, MOI.SecondOrderCone}(2)] == [VI(2); VI(3); VI(4)]

       primal_var_dual_con = primal_dual_map.primal_var_dual_con
       @test primal_var_dual_con[VI(1)] == CI{SAF{Float64}, MOI.EqualTo{Float64}}(2)
       @test primal_var_dual_con[VI(2)] == CI{SAF{Float64}, MOI.EqualTo{Float64}}(3)
       @test primal_var_dual_con[VI(3)] == CI{SAF{Float64}, MOI.EqualTo{Float64}}(4)
   end
end