using ECOS
const ECOS_PRIMAL_OPT = ECOS.Optimizer(verbose = 0)
const ECOS_DUAL_OPT = DualOptimizer(ECOS.Optimizer(verbose = 0))
const ECOS_PRIMAL_FACTORY = with_optimizer(ECOS.Optimizer, verbose = 0)
const ECOS_DUAL_FACTORY = with_optimizer(DualOptimizer, ECOS.Optimizer(verbose = 0))

# push!(dual_linear_optimizer, DualOptimizer(ECOS.Optimizer(verbose = 0)))

@testset "ECOS conic Problems" begin
    @testset "ECOS Conic linear problems" begin
        list_of_soc_problems = [
            conic_linear1_test,
            conic_linear2_test,
            conic_linear3_test,
            conic_linear4_test
        ]
        test_strong_duality(list_of_soc_problems, ECOS_PRIMAL_FACTORY)
    end
    @testset "ECOS SOC problems" begin
        list_of_soc_problems = [
            soc1_test,
            soc2_test,
            soc3_test,
            soc4_test,
            soc5_test,
            soc6_test
        ]
        test_strong_duality(list_of_soc_problems, ECOS_PRIMAL_FACTORY)
    end
    @testset "ECOS RotatedSOC problems" begin
        list_of_rsoc_problems = [
            rsoc1_test,
            rsoc2_test,
            rsoc3_test,
            rsoc4_test
        ]
        test_strong_duality(list_of_rsoc_problems, ECOS_PRIMAL_FACTORY)
    end
end