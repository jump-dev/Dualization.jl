using GLPK, CSDP, SCS

# Optimizers
linear_optimizer = DualOptimizer(GLPK.Optimizer())
conic_optimizer = DualOptimizer(CSDP.Optimizer(printlevel = 0))
power_cone_optimizer = DualOptimizer(SCS.Optimizer(verbose = false))

@testset "MOI_wrapper.jl" begin    
    linear_config = MOIT.TestConfig(atol = 1e-6, rtol = 1e-6)
    linear_cache = MOIU.UniversalFallback(Dualization.DualizableModel{Float64}())
    linear_cached = MOIU.CachingOptimizer(linear_cache, linear_optimizer)
    linear_bridged = MOIB.full_bridge_optimizer(linear_cached, Float64)

    @testset "linear test" begin
        MOIT.contlineartest(linear_bridged, linear_config, ["linear8b", # Asks for infeasibility ray
                                                            "linear8c", # Asks for infeasibility ray
                                                            "linear12", # Asks for infeasibility ray
                                                            "linear13", # Feasibility problem
                                                            "linear15"  # Feasibility when written in the canonical form
                                                            ]) 
    end

    conic_config = MOIT.TestConfig(atol = 1e-4, rtol = 1e-4)
    conic_cache = MOIU.UniversalFallback(Dualization.DualizableModel{Float64}())
    conic_cached = MOIU.CachingOptimizer(conic_cache, conic_optimizer)
    conic_bridged = MOIB.full_bridge_optimizer(conic_cached, Float64)

    @testset "coninc linear, soc, rsoc and sdp test" begin
        MOIT.contconictest(conic_bridged, conic_config, ["lin3", # Feasibility problem
                                                         "lin4", # Feasibility problem
                                                         "normone2", # Feasibility problem
                                                         "norminf2", # Feasibility problem
                                                         "soc3", # Feasibility problem
                                                         "rotatedsoc2", # Feasibility problem
                                                         "exp", # TODO
                                                         "pow", # Tested in power cone test
                                                         "rootdet", # Not yet implemented
                                                         "logdet" # Not yet implemented
                                                         ])
    end

    @testset "quadratically constrained" begin
        MOIT.contquadratictest(conic_bridged, conic_config, ["qp",
                                                             "ncqcp",
                                                             "socp"
                                                             ])
    end

    power_cone_config = MOIT.TestConfig(atol = 1e-3, rtol = 1e-3)
    power_cone_cache = MOIU.UniversalFallback(Dualization.DualizableModel{Float64}())
    power_cone_cached = MOIU.CachingOptimizer(power_cone_cache, power_cone_optimizer)
    power_cone_bridged = MOIB.full_bridge_optimizer(power_cone_cached, Float64)

    @testset "power cone test" begin
        MOIT.contconictest(power_cone_bridged, 
                           power_cone_config, ["lin", # Tested in coninc linear, soc, rsoc and sdp test
                                               "normone", # Tested in coninc linear, soc, rsoc and sdp test
                                               "norminf", # Tested in coninc linear, soc, rsoc and sdp test
                                               "soc", # Tested in coninc linear, soc, rsoc and sdp test
                                               "rsoc", # Tested in coninc linear, soc, rsoc and sdp test
                                               "geomean", # Tested in coninc linear, soc, rsoc and sdp test
                                               "sdp", # Tested in coninc linear, soc, rsoc and sdp test
                                               "rootdet", # Not yet implemented
                                               "logdet", # Not yet implemented
                                               "exp" #TODO
                                               ])
    end

    @testset "attributes" begin
        @test MOI.get(linear_optimizer, MOI.SolverName()) == "Dual model with GLPK attached"
        @test MOI.get(conic_optimizer, MOI.SolverName()) == "Dual model with CSDP attached"
    end

    @testset "support" begin
        @test !MOI.supports_constraint(linear_optimizer, SVF, MOI.Integer)
        @test MOI.supports_constraint(conic_optimizer, VVF, MOI.PositiveSemidefiniteConeTriangle)
        @test MOI.supports(linear_optimizer, MOI.ObjectiveSense())
    end

    @testset "dual_status" begin
        @test Dualization.dual_status(MOI.INFEASIBLE) == MOI.DUAL_INFEASIBLE
        @test Dualization.dual_status(MOI.DUAL_INFEASIBLE) == MOI.INFEASIBLE
        @test Dualization.dual_status(MOI.ALMOST_INFEASIBLE) == MOI.ALMOST_DUAL_INFEASIBLE
        @test Dualization.dual_status(MOI.ALMOST_DUAL_INFEASIBLE) == MOI.ALMOST_INFEASIBLE
    end

    @testset "DualOptimizer" begin
        err = ErrorException("DualOptimizer must have a solver attached")
        @test_throws err DualOptimizer()
        dual_opt_f32 = Dualization.DualOptimizer{Float32}(GLPK.Optimizer())
        Caching_OptimizerType = typeof(dual_opt_f32.dual_problem.dual_model)
        @test typeof(dual_opt_f32) == DualOptimizer{Float32, Caching_OptimizerType}
    end
end
