@testset "objective_coefficients.jl" begin
    # ERROR: FEASIBILITY_SENSE is not supported
    @test_throws ErrorException Dualization.set_dual_model_sense(lp11_test(), lp11_test())

    # test if SVF, and SAF become a SAF
end