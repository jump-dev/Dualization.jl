# Copyright (c) 2017: Guilherme Bodin, and contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

using Hypatia
using LinearAlgebra

@testset "Solve problems with differetn coefficient type" begin
    function mineig(::Type{T}) where {T}
        model = GenericModel{T}()
        d = 3
        @variable(model, x[1:d,1:d] in PSDCone())
        @constraint(model, tr(x) == 1)
        @objective(model, Min, real(dot(I,x)))
        set_optimizer(model, Dualization.dual_optimizer(Hypatia.Optimizer{T}; coefficient_type = T))
        JuMP.set_silent(model)
        optimize!(model)
        return objective_value(model)
    end
    
    @test mineig(Float64) ≈ mineig(Float32)
end