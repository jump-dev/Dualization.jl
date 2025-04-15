@testset "linear problems" begin
    @testset "feasibility_1_test" begin
        #=
        primal
            min 0
        s.t.
            x_1 >= 3         :y_2
            x_1 + 2x_2 <= 3  :y_3
        dual
            max 3y_2 + 3y_3
        s.t.
            y_2 >= 0
            y_3 <= 0
            y_2 + y_3 == 0    :x_1
            2y_3 == 0        :x_2
        =#
        primal_model = feasibility_1_test()
        dual_model, primal_dual_map = dual_model_and_map(primal_model)

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
        ) == 2
        obj_type = MOI.get(dual_model, MOI.ObjectiveFunctionType())
        @test obj_type == MOI.ScalarAffineFunction{Float64}
        obj = MOI.get(dual_model, MOI.ObjectiveFunction{obj_type}())
        @test MOI.constant(obj) == 0.0
        @test MOI.coefficient.(obj.terms) == [3.0; 3.0]
    end
end