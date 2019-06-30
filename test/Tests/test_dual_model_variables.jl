@testset "dual_model_variables.jl" begin

    @testset "push_to_dual_obj_aff_terms!" begin
        dual_obj_affine_terms = Dict{VI, Float64}()
        Dualization.push_to_dual_obj_aff_terms!(dual_obj_affine_terms, VI(1), 0.0)
        @test isempty(dual_obj_affine_terms)
        Dualization.push_to_dual_obj_aff_terms!(dual_obj_affine_terms, VI(1), 1.0)
        @test !isempty(dual_obj_affine_terms)
    end

end