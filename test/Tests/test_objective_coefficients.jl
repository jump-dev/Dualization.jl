@testset "objective_coefficients.jl" begin

    @testset "set_dual_model_sense" begin
        # ERROR: FEASIBILITY_SENSE is not supported
        @test_throws ErrorException Dualization.set_dual_model_sense(lp11_test(), lp11_test())
        obj = MOI.ScalarAffineFunction([MOI.ScalarAffineTerm(0.0, VI(1))], 0.0)
        @test_throws ErrorException Dualization.PrimalObjective{Float64}(obj)

        model = lp1_test()
        @test MOI.get(model, MOI.ObjectiveSense()) == MOI.MIN_SENSE
        Dualization.set_dual_model_sense(model, model)
        @test MOI.get(model, MOI.ObjectiveSense()) == MOI.MAX_SENSE

        model = lp4_test()
        @test MOI.get(model, MOI.ObjectiveSense()) == MOI.MAX_SENSE
        Dualization.set_dual_model_sense(model, model)
        @test MOI.get(model, MOI.ObjectiveSense()) == MOI.MIN_SENSE
    end

    @testset "get_primal_objective" begin
        model = lp1_test()
        primal_objective = Dualization.get_primal_objective(model)
        
        @test primal_objective.saf.terms[1] == MOI.ScalarAffineTerm{Float64}(-4.0, MOI.VariableIndex(2))
        @test MOI._constant(Dualization.get_saf(primal_objective)) == -1.0

        model = lp10_test()
        
        @test model.objective == MOI.SingleVariable(MOI.VariableIndex(1))
        primal_objective = Dualization.get_primal_objective(model)
        @test Dualization.get_primal_objective(model).saf.terms[1] == MOI.ScalarAffineTerm{Float64}(1.0, MOI.VariableIndex(1))
        @test MOI._constant(Dualization.get_saf(primal_objective)) == 0.0
    end

end