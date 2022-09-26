# Copyright (c) 2017: Guilherme Bodin, and contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

# Tests of this file not covered in other tests
@testset "dual_model_variables.jl" begin
    @testset "push_to_dual_obj_aff_terms!" begin
        primal_model = soc1_test()
        dual_obj_affine_terms = Dict{VI,Float64}()
        list = MOI.get(
            primal_model,
            MOI.ListOfConstraintIndices{VVF,MOI.SecondOrderCone}(),
        )
        ci = first(list)
        func = MOI.get(primal_model, MOI.ConstraintFunction(), ci)
        set = MOI.get(primal_model, MOI.ConstraintSet(), ci)
        Dualization.push_to_dual_obj_aff_terms!(
            primal_model,
            dual_obj_affine_terms,
            VI(1),
            func,
            set,
            1,
        )
        @test isempty(dual_obj_affine_terms)
    end

    @testset "set_dual_variable_name" begin
        primal_model = soc1_test()
        vi = VI(1)
        Dualization.set_dual_variable_name(primal_model, vi, 1, "con", "")
        @test MOI.get(primal_model, MOI.VariableName(), vi) == "con_1"
        Dualization.set_dual_variable_name(primal_model, vi, 2, "con", "")
        @test MOI.get(primal_model, MOI.VariableName(), vi) == "con_2"
        Dualization.set_dual_variable_name(primal_model, vi, 2, "con", "oi")
        @test MOI.get(primal_model, MOI.VariableName(), vi) == "oicon_2"
    end
end
