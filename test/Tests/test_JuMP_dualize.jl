using GLPK
@testset "JuMP dualize" begin
    @testset "direct_mode" begin
        JuMP_model = JuMP.direct_model(GLPK.Optimizer())
        err = ErrorException("Dualization does not support solvers in DIRECT mode")
        @test_throws ErrorException dualize(JuMP_model)
    end
    @testset "dualize JuMP models" begin
        # Only testing with a small LP
        JuMP_model = JuMP.Model()
        MOI.copy_to(JuMP.backend(JuMP_model), lp1_test())
        dual_JuMP_model = dualize(JuMP_model)
        @test backend(dual_JuMP_model).state == MOIU.NO_OPTIMIZER
        dual_JuMP_model = dualize(JuMP_model, with_optimizer(GLPK.Optimizer))
        @test backend(dual_JuMP_model).state == MOIU.EMPTY_OPTIMIZER
        @test MOI.get(backend(dual_JuMP_model), MOI.SolverName()) == "GLPK"
    end
end