# Copyright (c) 2017: Guilherme Bodin, and contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

@testset "modify" begin
    model = Model(HiGHS_DUAL_FACTORY)
    @variable(model, x[1:2] >= 0)
    @constraint(model, 2x[1] + x[2] <= 4)
    @constraint(model, x[1] + 2x[2] <= 4)
    @objective(model, Max, 4x[1] + 3x[2])
    optimize!(model)
    @test objective_value(model) ≈ 28 / 3
    set_objective_coefficient(model, x[1], 5.0)
    optimize!(model)
    @test objective_value(model) ≈ 10.6666666666

    model = Model(HiGHS_DUAL_FACTORY)
    @variable(model, x[1:2] >= 0)
    @constraint(model, 2x[1] + x[2] <= 4)
    @constraint(model, x[1] + 2x[2] <= 4)
    @objective(model, Min, -4x[1] + -3x[2])
    optimize!(model)
    @test objective_value(model) ≈ -28 / 3
    set_objective_coefficient(model, x[1], -5.0)
    optimize!(model)
    @test objective_value(model) ≈ -10.6666666666

    model = Model(SCS_DUAL_FACTORY)
    @variable(model, x[1:2] >= 0)
    @constraint(model, 2x[1] + x[2] <= 4)
    @constraint(model, x[1] + 2x[2] <= 4)
    @objective(model, Max, 4x[1] + 3x[2])
    optimize!(model)
    @test objective_value(model) ≈ 28 / 3 atol = 1e-3
    set_objective_coefficient(model, x[1], 5.0)
    optimize!(model)
    @test objective_value(model) ≈ 10.6666666666 atol = 1e-3

    model = Model(SCS_DUAL_FACTORY)
    @variable(model, x[1:2] >= 0)
    @constraint(model, 2x[1] + x[2] <= 4)
    @constraint(model, x[1] + 2x[2] <= 4)
    @objective(model, Min, -4x[1] + -3x[2])
    optimize!(model)
    @test objective_value(model) ≈ -28 / 3 atol = 1e-3
    set_objective_coefficient(model, x[1], -5.0)
    optimize!(model)
    @test objective_value(model) ≈ -10.6666666666 atol = 1e-3

    model = Model(SCS_DUAL_FACTORY)
    @variable(model, x)
    @variable(model, y)
    @variable(model, z)
    @constraint(model, x + 2y + 3z >= 4)
    @constraint(model, x + y >= 1)
    @objective(model, Min, x^2 + x * y + y^2 + y * z + z^2)
    optimize!(model)
    @test objective_value(model) ≈ 1.8571 atol = 1e-3
    # Now the objective is @objective(model, Min, x^2 + x*y + y^2 + y*z + z^2 - 5x)
    set_objective_coefficient(model, x, -5.0)
    optimize!(model)
    @test objective_value(model) ≈ -9.15 atol = 1e-3
end
