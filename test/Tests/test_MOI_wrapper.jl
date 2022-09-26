# Copyright (c) 2017: Guilherme Bodin, and contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

@testset "MOI_wrapper.jl" begin
    for opt in dual_linear_optimizer
        linear_config = MOIT.Config(atol = 1e-6, rtol = 1e-6)
        linear_cache =
            MOIU.UniversalFallback(Dualization.DualizableModel{Float64}())
        MOI.empty!(opt)
        linear_cached = MOIU.CachingOptimizer(linear_cache, opt)
        linear_bridged = MOIB.full_bridge_optimizer(linear_cached, Float64)

        @testset "linear test" begin
            MOIT.runtests(
                linear_bridged,
                linear_config,
                include = ["test_linear_"],
                exclude = [
                    "test_linear_FEASIBILITY_SENSE",
                    "test_linear_INFEASIBLE_2",
                    "test_linear_Interval_inactive",
                    "test_linear_add_constraints",
                    "test_linear_inactive_bounds",
                    "test_linear_integration_2",
                    "test_linear_integration_Interval",
                    "test_linear_integration_delete_variables",
                ],
            )
        end
    end

    for opt in dual_conic_optimizer
        opt = dual_conic_optimizer[1]
        conic_config = MOIT.Config(atol = 1e-4, rtol = 1e-4)
        conic_cache =
            MOIU.UniversalFallback(Dualization.DualizableModel{Float64}())
        conic_cached = MOIU.CachingOptimizer(conic_cache, opt)
        conic_bridged = MOIB.full_bridge_optimizer(conic_cached, Float64)

        @testset "conic linear, soc, rsoc and sdp test" begin
            MOIT.runtests(
                conic_bridged,
                conic_config,
                include = ["test_conic_"],
                exclude = [
                    "test_conic_NormInfinityCone_INFEASIBLE",
                    "test_conic_NormOneCone_INFEASIBLE",
                    "test_conic_PositiveSemidefiniteConeSquare_3",
                    "test_conic_PositiveSemidefiniteConeTriangle_3",
                    "test_conic_SecondOrderCone_INFEASIBLE",
                    "test_conic_SecondOrderCone_negative_post_bound_2",
                    "test_conic_SecondOrderCone_negative_post_bound_3",
                    "test_conic_SecondOrderCone_no_initial_bound",
                    "test_conic_RotatedSecondOrderCone_out_of_order",
                    "test_conic_linear_INFEASIBLE",
                    "test_conic_empty_matrix", # uses FEASIBILITY_SENSE
                ],
            )
        end

        @testset "quadratically constrained" begin
            MOIT.runtests(
                conic_bridged,
                conic_config,
                include = ["test_quadratic_"],
            )
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
            @test !MOI.supports_constraint(opt, MOI.VariableIndex, MOI.Integer)
            @test MOI.supports(opt, MOI.ObjectiveSense())
        end
        for opt in dual_conic_optimizer
            @test MOI.supports_constraint(
                opt,
                VVF,
                MOI.PositiveSemidefiniteConeTriangle,
            )
        end
    end

    @testset "dual_status" begin
        @test Dualization.dual_status(MOI.INFEASIBLE) == MOI.DUAL_INFEASIBLE
        @test Dualization.dual_status(MOI.DUAL_INFEASIBLE) == MOI.INFEASIBLE
        @test Dualization.dual_status(MOI.ALMOST_INFEASIBLE) ==
              MOI.ALMOST_DUAL_INFEASIBLE
        @test Dualization.dual_status(MOI.ALMOST_DUAL_INFEASIBLE) ==
              MOI.ALMOST_INFEASIBLE
    end

    @testset "DualOptimizer" begin
        for opt in primal_linear_optimizer
            err = ErrorException("DualOptimizer must have a solver attached")
            @test_throws err DualOptimizer()
            dual_opt_f32 = Dualization.DualOptimizer{Float32}(opt)
            Caching_OptimizerType = typeof(dual_opt_f32.dual_problem.dual_model)
            @test typeof(dual_opt_f32) ==
                  DualOptimizer{Float32,Caching_OptimizerType}
        end
    end
end
