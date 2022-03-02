using HiGHS
const HiGHS_PRIMAL_FACTORY =
    MOI.OptimizerWithAttributes(HiGHS.Optimizer, MOI.Silent() => true)
const HiGHS_DUAL_FACTORY = dual_optimizer(HiGHS_PRIMAL_FACTORY)
const HiGHS_PRIMAL_OPT = MOI.instantiate(HiGHS_PRIMAL_FACTORY)
const HiGHS_DUAL_OPT = MOI.instantiate(HiGHS_DUAL_FACTORY)

push!(primal_linear_factory, HiGHS_PRIMAL_FACTORY)
push!(dual_linear_factory, HiGHS_DUAL_FACTORY)
push!(dual_linear_optimizer, HiGHS_DUAL_OPT)
push!(primal_linear_optimizer, HiGHS_PRIMAL_OPT)

@testset "HiGHS Linear Problems" begin
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
        lp13_test,
    ]
    test_strong_duality(list_of_linear_problems, HiGHS_PRIMAL_FACTORY)
end

@testset "HiGHS Quadratic Problems" begin
    list_of_quad_problems = [
        qp1_test,
        qp2_test,
    ]
    test_strong_duality(list_of_quad_problems, HiGHS_PRIMAL_FACTORY)
end
