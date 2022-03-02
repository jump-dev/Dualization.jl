using SCS
const SCS_PRIMAL_FACTORY =
    MOI.OptimizerWithAttributes(SCS.Optimizer, MOI.Silent() => true)
const SCS_DUAL_FACTORY = dual_optimizer(SCS_PRIMAL_FACTORY)
const SCS_PRIMAL_OPT = MOI.instantiate(SCS_PRIMAL_FACTORY)
const SCS_DUAL_OPT = MOI.instantiate(SCS_DUAL_FACTORY)

push!(primal_power_cone_factory, SCS_PRIMAL_FACTORY)
push!(dual_power_cone_factory, SCS_DUAL_FACTORY)
push!(dual_power_cone_optimizer, SCS_DUAL_OPT)
push!(primal_power_cone_optimizer, SCS_PRIMAL_OPT)

@testset "SCS Exponential Cone problems" begin
    list_of_exp_problems = [exp1_test, exp2_test]
    test_strong_duality(list_of_exp_problems, SCS_PRIMAL_FACTORY)
end

# # Warm up to pass tests on x86
# dual_problem = dualize(soc1_test())
# test_strong_duality(
#     soc1_test(),
#     dual_problem.dual_model,
#     SCS_PRIMAL_FACTORY,
#     1e-3,
#     1e-3,
# )

@testset "SCS SOC problems" begin
    list_of_soc_problems =
        [soc3_test, soc4_test, soc5_test, soc6_test]
    test_strong_duality(list_of_soc_problems, SCS_PRIMAL_FACTORY)
    list_of_soc_problems =
        [soc1_test, soc2_test]
    test_strong_duality(
        list_of_soc_problems, SCS_PRIMAL_FACTORY,
        atol = 1e-3, rtol = 1e-3)
end
@testset "SCS RotatedSOC problems" begin
    list_of_rsoc_problems = [rsoc1_test, rsoc2_test, rsoc3_test]
    test_strong_duality(list_of_rsoc_problems, SCS_PRIMAL_FACTORY)
    list_of_rsoc_problems = [rsoc4_test]
    test_strong_duality(
        list_of_rsoc_problems, SCS_PRIMAL_FACTORY,
        atol = 1e-3, rtol = 1e-3)
end

@testset "SCS SDP triangle problems" begin
    list_of_sdp_triang_problems = [
        sdpt1_test,
        sdpt2_test,
        sdpt3_test,
        sdpt4_test,
    ]
    test_strong_duality(list_of_sdp_triang_problems, SCS_PRIMAL_FACTORY)
end

@testset "SCS Power Cone problems" begin
    list_of_pow_problems = [
        pow1_test,
        pow2_test,
    ]
    test_strong_duality(list_of_pow_problems, SCS_PRIMAL_FACTORY)
end