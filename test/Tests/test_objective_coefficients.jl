# Copyright (c) 2017: Guilherme Bodin, and contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

@testset "objective_coefficients.jl" begin
    @testset "_set_dual_model_sense" begin
        # ERROR: FEASIBILITY_SENSE is not supported
        # @test_throws ErrorException Dualization._set_dual_model_sense(lp11_test(), lp11_test())
        # obj = MOI.ScalarAffineFunction([MOI.ScalarAffineTerm(0.0, MOI.VariableIndex(1))], 0.0)
        # @test_throws ErrorException Dualization._PrimalObjective{Float64}(obj)

        model = lp1_test()
        @test MOI.get(model, MOI.ObjectiveSense()) == MOI.MIN_SENSE
        Dualization._set_dual_model_sense(model, model)
        @test MOI.get(model, MOI.ObjectiveSense()) == MOI.MAX_SENSE

        model = lp4_test()
        @test MOI.get(model, MOI.ObjectiveSense()) == MOI.MAX_SENSE
        Dualization._set_dual_model_sense(model, model)
        @test MOI.get(model, MOI.ObjectiveSense()) == MOI.MIN_SENSE
    end
end
