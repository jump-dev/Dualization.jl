using GLPK, SCS, CSDP

# For testing bug found on issue # 52
function solve_vaf_sdp(factory::JuMP.OptimizerFactory)
    model = Model(factory)
    @variable(model, x)
    @constraint(model, [4x x; x 4x] - ones(2, 2) in PSDCone())
    @objective(model, Min, x)
    optimize!(model)
    return JuMP.objective_value(model) # 0.6
end

@testset "JuMP dualize" begin
    @testset "direct_mode" begin
        JuMP_model = JuMP.direct_model(MOIU.MockOptimizer(MOIU.Model{Float64}()))
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
    @testset "set_dot on different sets" begin
        primal_scs = solve_vaf_sdp(with_optimizer(SCS.Optimizer, verbose = 0))
        dual_scs = solve_vaf_sdp(with_optimizer(DualOptimizer, SCS.Optimizer(verbose = 0)))
        primal_csdp = solve_vaf_sdp(with_optimizer(CSDP.Optimizer, printlevel = 0))
        dual_csdp = solve_vaf_sdp(with_optimizer(DualOptimizer, CSDP.Optimizer(printlevel = 0)))
        @test isapprox(primal_scs, dual_scs; atol = 1e-3)
        @test isapprox(primal_csdp, dual_csdp; atol = 1e-6)
    end
end