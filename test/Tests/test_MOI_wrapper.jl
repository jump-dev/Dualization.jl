@testset "MOI_wrapper.jl" begin
    for opt in dual_linear_optimizer
        linear_config = MOIT.TestConfig(atol = 1e-6, rtol = 1e-6)
        linear_cache = MOIU.UniversalFallback(Dualization.DualizableModel{Float64}())
        linear_cached = MOIU.CachingOptimizer(linear_cache, opt)
        linear_bridged = MOIB.full_bridge_optimizer(linear_cached, Float64)

        @testset "linear test" begin
            MOIT.contlineartest(linear_bridged, linear_config,
                ["linear8b", # Asks for infeasibility ray
                "linear8c", # Asks for infeasibility ray
                "linear12", # Asks for infeasibility ray
                "linear13", # Feasibility problem
                "linear15"  # Feasibility when written in the canonical form
                ])
        end
    end

    for opt in dual_conic_optimizer
        conic_config = MOIT.TestConfig(atol = 1e-4, rtol = 1e-4)
        conic_cache = MOIU.UniversalFallback(Dualization.DualizableModel{Float64}())
        conic_cached = MOIU.CachingOptimizer(conic_cache, opt)
        conic_bridged = MOIB.full_bridge_optimizer(conic_cached, Float64)

        @testset "conic linear, soc, rsoc and sdp test" begin
            MOIT.contconictest(conic_bridged, conic_config,
                ["lin3", # Feasibility problem
                "lin4", # Feasibility problem
                "geomean3f", "geomean3v", # CSDP does not converge after https://github.com/jump-dev/Dualization.jl/pull/86
                "normone2", # Feasibility problem
                "norminf2", # Feasibility problem
                "soc3", # Feasibility problem
                "rotatedsoc2", # Feasibility problem
                "exp", # Tested in exp and power cone test
                "dualexp", # Tested in exp and power cone test
                "pow", # Tested in exp and power cone test
                "dualpow", # Tested in exp and power cone test
                "rootdet", # Dual not defined in MOI
                "logdet", # Dual not defined in MOI
                "relentr" # Dual not defined in MOI
                ])
        end

        @testset "quadratically constrained" begin
            MOIT.contquadratictest(conic_bridged, conic_config, ["qp",
                                                                "ncqcp",
                                                                "socp"
                                                                ])
        end
    end

    for opt in dual_power_cone_optimizer
        power_cone_config = MOIT.TestConfig(atol = 1e-3, rtol = 1e-3)
        power_cone_cache = MOIU.UniversalFallback(Dualization.DualizableModel{Float64}())
        power_cone_cached = MOIU.CachingOptimizer(power_cone_cache, opt)
        power_cone_bridged = MOIB.full_bridge_optimizer(power_cone_cached, Float64)

        @testset "power cone test" begin
            MOIT.contconictest(power_cone_bridged, power_cone_config,
                ["lin", # Tested in coninc linear, soc, rsoc and sdp test
                "normone", # Tested in coninc linear, soc, rsoc and sdp test
                "norminf", # Tested in coninc linear, soc, rsoc and sdp test
                "soc", # Tested in coninc linear, soc, rsoc and sdp test
                "rsoc", # Tested in coninc linear, soc, rsoc and sdp test
                "geomean", # Tested in coninc linear, soc, rsoc and sdp test
                "sdp", # Tested in coninc linear, soc, rsoc and sdp test
                "rootdet", # Dual not defined in MOI
                "logdet", # Dual not defined in MOI
                "relentr", # Dual not defined in MOI
                ])
        end
    end

    @testset "attributes" begin
        for optimizer in [dual_conic_optimizer; dual_linear_optimizer]
            before = MOI.get(optimizer, MOI.Silent())
            MOI.set(optimizer, MOI.Silent(), !before)
            @test MOI.get(optimizer, MOI.Silent()) == !before
            MOI.set(optimizer, MOI.Silent(), before)
            @test MOI.get(optimizer, MOI.Silent()) == before
        end
        for i in eachindex(dual_conic_optimizer)
            @test MOI.get(dual_conic_optimizer[i], MOI.SolverName()) ==
                "Dual model with $(MOI.get(primal_conic_optimizer[i], MOI.SolverName())) attached"
        end
        for i in eachindex(dual_linear_optimizer)
            @test MOI.get(dual_linear_optimizer[i], MOI.SolverName()) ==
                "Dual model with $(MOI.get(primal_linear_optimizer[i], MOI.SolverName())) attached"
        end
    end

    @testset "support" begin
        for opt in dual_linear_optimizer
            @test !MOI.supports_constraint(opt, SVF, MOI.Integer)
            @test MOI.supports(opt, MOI.ObjectiveSense())
        end
        for opt in dual_conic_optimizer
            @test MOI.supports_constraint(opt, VVF, MOI.PositiveSemidefiniteConeTriangle)
        end
    end

    @testset "dual_status" begin
        @test Dualization.dual_status(MOI.INFEASIBLE) == MOI.DUAL_INFEASIBLE
        @test Dualization.dual_status(MOI.DUAL_INFEASIBLE) == MOI.INFEASIBLE
        @test Dualization.dual_status(MOI.ALMOST_INFEASIBLE) == MOI.ALMOST_DUAL_INFEASIBLE
        @test Dualization.dual_status(MOI.ALMOST_DUAL_INFEASIBLE) == MOI.ALMOST_INFEASIBLE
    end

    @testset "DualOptimizer" begin
        for opt in primal_linear_optimizer
            err = ErrorException("DualOptimizer must have a solver attached")
            @test_throws err DualOptimizer()
            dual_opt_f32 = Dualization.DualOptimizer{Float32}(opt)
            Caching_OptimizerType = typeof(dual_opt_f32.dual_problem.dual_model)
            @test typeof(dual_opt_f32) == DualOptimizer{Float32, Caching_OptimizerType}
        end
    end
end
