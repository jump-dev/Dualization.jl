# Copyright (c) 2017: Guilherme Bodin, and contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

@testset "MOI_wrapper.jl" begin
    for opt in dual_linear_optimizer
        linear_config = MOI.Test.Config(atol = 1e-6, rtol = 1e-6)
        linear_cache =
            MOI.Utilities.UniversalFallback(MOI.Utilities.Model{Float64}())
        MOI.empty!(opt)
        linear_cached = MOI.Utilities.CachingOptimizer(linear_cache, opt)
        linear_bridged =
            MOI.Bridges.full_bridge_optimizer(linear_cached, Float64)

        @testset "linear test" begin
            MOI.Test.runtests(
                linear_bridged,
                linear_config,
                include = ["test_linear_"],
                exclude = [
                    r"^test_linear_FEASIBILITY_SENSE$",
                    r"^test_linear_INFEASIBLE_2$",
                    r"^test_linear_Interval_inactive$",
                    r"^test_linear_add_constraints$",
                    r"^test_linear_inactive_bounds$",
                    r"^test_linear_integration_2$",
                    r"^test_linear_integration_Interval$",
                    r"^test_linear_integration_delete_variables$",
                    r"^test_linear_complex_Zeros$",
                    r"^test_linear_complex_Zeros_duplicate$",
                ],
            )
        end
    end

    for opt in dual_conic_optimizer
        conic_config = MOI.Test.Config(atol = 1e-4, rtol = 1e-4)
        conic_cache =
            MOI.Utilities.UniversalFallback(MOI.Utilities.Model{Float64}())
        conic_cached = MOI.Utilities.CachingOptimizer(conic_cache, opt)
        conic_bridged = MOI.Bridges.full_bridge_optimizer(conic_cached, Float64)

        @testset "conic linear, soc, rsoc and sdp test" begin
            MOI.Test.runtests(
                conic_bridged,
                conic_config,
                include = ["test_conic_"],
                exclude = [
                    # uses FEASIBILITY_SENSE
                    r"test_conic_NormInfinityCone_INFEASIBLE$",
                    r"test_conic_NormOneCone_INFEASIBLE$",
                    r"test_conic_PositiveSemidefiniteConeSquare_3$",
                    r"test_conic_PositiveSemidefiniteConeTriangle_3$",
                    r"test_conic_SecondOrderCone_INFEASIBLE$",
                    r"test_conic_SecondOrderCone_negative_post_bound_2$",
                    r"test_conic_SecondOrderCone_negative_post_bound_3$",
                    r"test_conic_SecondOrderCone_no_initial_bound$",
                    r"test_conic_RotatedSecondOrderCone_out_of_order$",
                    r"test_conic_linear_INFEASIBLE",
                    r"test_conic_empty_matrix$",
                    r"test_conic_HermitianPositiveSemidefiniteConeTriangle_2$",
                ],
            )
        end

        @testset "quadratically constrained" begin
            MOI.Test.runtests(
                conic_bridged,
                conic_config,
                include = ["test_quadratic_"],
            )
        end
    end

    @testset "attributes" begin
        for optimizer in [dual_conic_optimizer; dual_linear_optimizer]
            @test MOI.supports(optimizer, MOI.Silent())
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
                MOI.VectorOfVariables,
                MOI.PositiveSemidefiniteConeTriangle,
            )
        end
    end

    @testset "_dual_status" begin
        @test Dualization._dual_status(MOI.INFEASIBLE) == MOI.DUAL_INFEASIBLE
        @test Dualization._dual_status(MOI.DUAL_INFEASIBLE) == MOI.INFEASIBLE
        @test Dualization._dual_status(MOI.ALMOST_INFEASIBLE) ==
              MOI.ALMOST_DUAL_INFEASIBLE
        @test Dualization._dual_status(MOI.ALMOST_DUAL_INFEASIBLE) ==
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

    @testset "dual_optimizer_kwargs" begin
        constructor = Dualization.dual_optimizer(
            HiGHS.Optimizer;
            assume_min_if_feasibility = true,
        )
        model = MOI.instantiate(constructor)
        @test model.assume_min_if_feasibility
        model = Dualization.DualOptimizer(
            HiGHS.Optimizer();
            assume_min_if_feasibility = true,
        )
        @test model.assume_min_if_feasibility
        model = Dualization.DualOptimizer{Float64}(
            HiGHS.Optimizer();
            assume_min_if_feasibility = true,
        )
        @test model.assume_min_if_feasibility
    end

    @testset "Copy twice" begin
        T = Float64
        model = MOI.Utilities.UniversalFallback(MOI.Utilities.Model{T}())
        x = MOI.add_variable(model)
        c = MOI.add_constraint(model, T(2) * x, MOI.GreaterThan(T(0)))
        MOI.set(model, MOI.ObjectiveSense(), MOI.MIN_SENSE)
        MOI.set(model, MOI.VariablePrimalStart(), x, T(1))
        MOI.set(model, MOI.ConstraintPrimalStart(), c, T(3))
        MOI.set(model, MOI.ConstraintDualStart(), c, T(4))
        dual_model = MOI.Utilities.UniversalFallback(MOI.Utilities.Model{T}())
        dual_problem = Dualization.DualProblem{T}(dual_model)
        OptimizerType = typeof(dual_problem.dual_model)
        dual = DualOptimizer{T,OptimizerType}(dual_problem)
        MOI.copy_to(dual, model)
        # Test that it is emptied
        MOI.copy_to(dual, model)
        @test MOI.get(dual_model, MOI.NumberOfVariables()) == 1
    end
end
