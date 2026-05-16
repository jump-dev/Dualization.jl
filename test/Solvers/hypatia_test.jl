# Copyright (c) 2017: Guilherme Bodin, and contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

import Hypatia

@testset "VariableBridgingCost" begin
    opt = MOI.instantiate(
        dual_optimizer(Hypatia.Optimizer);
        with_bridge_type = Float64,
    )
    @test MOI.supports_add_constrained_variables(opt, MOI.Reals)
    @test MOI.get(opt, MOI.VariableBridgingCost{MOI.Reals}()) == 0
    @test MOI.supports_add_constrained_variables(opt, MOI.Nonnegatives)
    @test MOI.get(opt, MOI.VariableBridgingCost{MOI.Nonnegatives}()) == 0
    @test MOI.supports_add_constrained_variables(opt, MOI.GeometricMeanCone)
    @test MOI.get(opt, MOI.VariableBridgingCost{MOI.GeometricMeanCone}()) == 2
end

@testset "Solve problems with different coefficient_type" begin
    function mineig(::Type{T}) where {T}
        model = GenericModel{T}(
            Dualization.dual_optimizer(
                Hypatia.Optimizer{T};
                coefficient_type = T,
            ),
        )
        JuMP.set_silent(model)
        @variable(model, x[1:3, 1:3] in PSDCone())
        @constraint(model, sum(x[i, i] for i in 1:3) == 1)
        @objective(model, Min, sum(x[i, i] for i in 1:3))
        optimize!(model)
        return objective_value(model)
    end
    @test mineig(Float64) ≈ mineig(Float32)
end
