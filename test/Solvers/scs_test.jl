using SCS
const SCSOPT = with_optimizer(SCS.Optimizer, verbose = false)

#TODO
# @testset "SCS Exponential Cone Problems" begin
#     list_of_exp_problems = [     
#         exp1_test,
#         exp2_test
#     ]
#     test_strong_duality(list_of_exp_problems, SCSOPT)
# end

@testset "SCS Power Cone Problems" begin
    list_of_pow_problems = [     
        pow1_test,
        pow2_test
    ]
    test_strong_duality(list_of_pow_problems, SCSOPT; atol = 1e-3, rtol = 1e-3)
end