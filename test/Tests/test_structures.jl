# Copyright (c) 2017: Guilherme Bodin, and contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

@testset "structures" begin
    primal_dual_map = Dualization.PrimalDualMap{Float64}()
    @test Dualization.is_empty(primal_dual_map)

    # Constructors
    model = lp1_test()
    dp_f32 = Dualization.DualProblem{Float32}(model)
    @test typeof(dp_f32) == Dualization.DualProblem{Float32,TestModel{Float64}}

    dp_f64 = Dualization.DualProblem(model) # default is Float64
    @test typeof(dp_f64) == Dualization.DualProblem{Float64,TestModel{Float64}}
end
