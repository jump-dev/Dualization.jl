using COSMO
const COSMOOPT = with_optimizer(COSMO.Optimizer, verbose = false)

@testset "COSMO Exponential Cone Problems" begin
    list_of_exp_problems = [     
        exp1_test,
        exp2_test
    ]
    test_strong_duality(list_of_exp_problems, COSMOOPT)
end

@testset "COSMO Power Cone Problems" begin
    list_of_pow_problems = [     
        pow1_test,
        pow2_test
    ]
    test_strong_duality(list_of_pow_problems, COSMOOPT; atol = 1e-3, rtol = 1e-3)
end