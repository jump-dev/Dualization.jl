using SCS
const SCS_PRIMAL_OPT = SCS.Optimizer(verbose = false)
const SCS_DUAL_OPT = DualOptimizer(SCS.Optimizer(verbose = false))
const SCS_PRIMAL_FACTORY = with_optimizer(SCS.Optimizer, verbose = false)
const SCS_DUAL_FACTORY = with_optimizer(DualOptimizer, SCS.Optimizer(verbose = false))

push!(primal_power_cone_factory, SCS_PRIMAL_FACTORY)
push!(dual_power_cone_factory, SCS_DUAL_FACTORY)
push!(dual_power_cone_optimizer, SCS_DUAL_OPT)
push!(primal_power_cone_optimizer, SCS_PRIMAL_OPT)

@testset "SCS Exponential Cone Problems" begin
    list_of_exp_problems = [
        exp1_test,
        exp2_test
    ]
    test_strong_duality(list_of_exp_problems, SCS_PRIMAL_FACTORY)
end

@testset "SCS Power Cone Problems" begin
    list_of_pow_problems = [
        pow1_test,
        pow2_test
    ]
    test_strong_duality(list_of_pow_problems, SCS_PRIMAL_FACTORY; atol = 1e-3, rtol = 1e-3)
end