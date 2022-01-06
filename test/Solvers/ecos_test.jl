using ECOS
const ECOS_PRIMAL_FACTORY =
    MOI.OptimizerWithAttributes(ECOS.Optimizer, MOI.Silent() => true)
const ECOS_DUAL_FACTORY = dual_optimizer(ECOS_PRIMAL_FACTORY)
const ECOS_PRIMAL_OPT = MOI.instantiate(ECOS_PRIMAL_FACTORY)
const ECOS_DUAL_OPT = MOI.instantiate(ECOS_DUAL_FACTORY)

# push!(dual_linear_optimizer, DualOptimizer(ECOS.Optimizer(verbose = 0)))

@testset "ECOS conic Problems" begin
    @testset "ECOS Conic linear problems" begin
        list_of_soc_problems =
            [conic_linear2_test, conic_linear3_test, conic_linear4_test]
        test_strong_duality(list_of_soc_problems, ECOS_PRIMAL_FACTORY)
    end
    @testset "ECOS SOC problems" begin
        list_of_soc_problems =
            [soc1_test, soc2_test, soc3_test, soc4_test, soc5_test, soc6_test]
        test_strong_duality(list_of_soc_problems, ECOS_PRIMAL_FACTORY)
    end
    @testset "ECOS RotatedSOC problems" begin
        list_of_rsoc_problems = [rsoc1_test, rsoc2_test, rsoc3_test, rsoc4_test]
        test_strong_duality(list_of_rsoc_problems, ECOS_PRIMAL_FACTORY)
    end
end
