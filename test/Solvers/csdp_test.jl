using CSDP
const CSDP_PRIMAL_OPT = CSDP.Optimizer(printlevel = 0)
const CSDP_DUAL_OPT = DualOptimizer(CSDP.Optimizer(printlevel = 0))
const CSDP_PRIMAL_FACTORY = with_optimizer(CSDP.Optimizer, printlevel = 0)
const CSDP_DUAL_FACTORY = with_optimizer(DualOptimizer, CSDP.Optimizer(printlevel = 0))

push!(primal_conic_factory, CSDP_PRIMAL_FACTORY)
push!(dual_conic_factory, CSDP_DUAL_FACTORY)
push!(dual_conic_optimizer, CSDP_DUAL_OPT)
push!(primal_conic_optimizer, CSDP_PRIMAL_OPT)

@testset "CSDP SDP triangle Problems" begin
    list_of_sdp_triang_problems = [
        # sdpt1_test, # CSDP is returning SLOW_PROGRESS
        # sdpt2_test, # CSDP is returning SLOW_PROGRESS
        sdpt3_test,
        sdpt4_test
    ]
    test_strong_duality(list_of_sdp_triang_problems, CSDP_PRIMAL_FACTORY)
end