using GLPK
const GLPK_PRIMAL_OPT = GLPK.Optimizer()
const GLPK_DUAL_OPT = DualOptimizer(GLPK.Optimizer())
const GLPK_PRIMAL_FACTORY = with_optimizer(GLPK.Optimizer)
const GLPK_DUAL_FACTORY = with_optimizer(DualOptimizer, GLPK.Optimizer())

push!(primal_linear_factory, GLPK_PRIMAL_FACTORY)
push!(dual_linear_factory, GLPK_DUAL_FACTORY)
push!(dual_linear_optimizer, GLPK_DUAL_OPT)
push!(primal_linear_optimizer, GLPK_PRIMAL_OPT)

@testset "GLPK Linear Problems" begin
    list_of_linear_problems = [
        lp1_test,
        lp2_test,
        lp3_test,
        lp4_test,
        lp5_test,
        lp6_test,
        lp7_test,
        # lp8_test, Int64 problem, does not work
        # lp9_test, Interval is not implemented
        lp10_test,
        # lp11_test, Feasibility not supported
        lp12_test,
        lp13_test
    ]
    test_strong_duality(list_of_linear_problems, GLPK_PRIMAL_FACTORY)
end