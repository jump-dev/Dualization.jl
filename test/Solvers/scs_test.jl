using SCS
const SCSOPT = with_optimizer(SCS.Optimizer)

@testset "SCS SOC Problems" begin
    list_of_linear_problems = [     
        soc1_test,
        soc2_test
        # soc3_test,
        # soc4_test,
        # soc5_test,
        # soc6_test
    ]
    test_strong_duality(list_of_linear_problems, SCSOPT)
end