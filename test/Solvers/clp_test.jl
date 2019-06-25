using Clp
const CLPOPT = with_optimizer(Clp.Optimizer, LogLevel = 0)

@testset "Clp Linear Problems" begin
    list_of_linear_problems = [ 
        lp1_test,
        lp2_test,
        lp3_test,
        lp4_test,
        lp5_test,
        lp6_test,
        lp7_test
        #lp8_test Int64 problem, does not work
    ]
    test_strong_duality(list_of_linear_problems, CLPOPT)
end