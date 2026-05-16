# Copyright (c) 2017: Guilherme Bodin, and contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

import Hypatia

@testset "VariableBridgingCost / ConstraintBridgingCost" begin
    opt = MOI.instantiate(dual_optimizer(Hypatia.Optimizer))
    # Specialized `VariableBridgingCost{MOI.Reals}`
    @test MOI.supports_add_constrained_variables(opt, MOI.Reals)
    @test MOI.get(opt, MOI.VariableBridgingCost{MOI.Reals}()) == 1
    # Specialized `VariableBridgingCost{S<:AbstractVectorSet}`, supported branch
    @test MOI.supports_add_constrained_variables(opt, MOI.Nonnegatives)
    @test MOI.get(opt, MOI.VariableBridgingCost{MOI.Nonnegatives}()) == 0
    # Same dispatch, supported with nonzero cost
    @test MOI.get(opt, MOI.VariableBridgingCost{MOI.Zeros}()) == 1
    # Same dispatch, `_dual_set_type` returns `nothing`
    @test !MOI.supports_add_constrained_variables(opt, MOI.SOS1{Float64})
    @test MOI.get(opt, MOI.VariableBridgingCost{MOI.SOS1{Float64}}()) == Inf
    # Specialized scalar `ConstraintBridgingCost`, supported branch
    @test MOI.get(
        opt,
        MOI.ConstraintBridgingCost{
            MOI.ScalarAffineFunction{Float64},
            MOI.GreaterThan{Float64},
        }(),
    ) == 1
    # Specialized vector `ConstraintBridgingCost`, `_dual_set_type` returns `nothing`
    @test !MOI.supports_constraint(opt, MOI.VectorOfVariables, MOI.SOS1{Float64})
    @test MOI.get(
        opt,
        MOI.ConstraintBridgingCost{MOI.VectorOfVariables,MOI.SOS1{Float64}}(),
    ) == Inf
    # Generic fallback (no specialized method matches)
    @test MOI.get(opt, MOI.VariableBridgingCost{MOI.GreaterThan{Float64}}()) == 0
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
