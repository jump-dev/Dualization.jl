using Clp
const CLPOPT = with_optimizer(Clp.Optimizer, LogLevel = 0)

@testset "Clp Linear Problems" begin
    @testset "lp1" begin
        @test test_strong_duality(primal_model_lp1, dual_model_lp1.dual_model, CLPOPT)
    end
    @testset "lp2" begin
        @test test_strong_duality(primal_model_lp2, dual_model_lp2.dual_model, CLPOPT)
    end
    @testset "lp3" begin
        @test test_strong_duality(primal_model_lp3, dual_model_lp3.dual_model, CLPOPT)
    end
    @testset "lp4" begin
        @test test_strong_duality(primal_model_lp4, dual_model_lp4.dual_model, CLPOPT)
    end
    @testset "lp5" begin
        @test test_strong_duality(primal_model_lp5, dual_model_lp5.dual_model, CLPOPT)
    end
    @testset "lp6" begin
        @test test_strong_duality(primal_model_lp6, dual_model_lp6.dual_model, CLPOPT)
    end
    # @testset "lp7" begin
    #     @test test_strong_duality(primal_model_lp7, dual_model_lp7.dual_model, CLPOPT)
    # end
end