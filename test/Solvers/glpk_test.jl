using GLPK
const GLPKOPT = with_optimizer(GLPK.Optimizer)

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
    test_strong_duality(list_of_linear_problems, GLPKOPT)
end