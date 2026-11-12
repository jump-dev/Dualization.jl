# Copyright (c) 2017: Guilherme Bodin, and contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

using Dualization
using JuMP
using Test

import HiGHS
import SCS

@testset "modify" begin
    highs_factory = dual_optimizer(
        MOI.OptimizerWithAttributes(HiGHS.Optimizer, MOI.Silent() => true),
    )
    scs_factory = dual_optimizer(
        MOI.OptimizerWithAttributes(SCS.Optimizer, MOI.Silent() => true),
    )

    @testset "free variable: $sense with $solver" for sense in [
            MOI.MIN_SENSE,
            MOI.MAX_SENSE,
        ],
        (solver, factory) in [("HiGHS", highs_factory), ("SCS", scs_factory)]

        model = Model(factory)
        @variable(model, x)
        @constraint(model, 1.0 * x >= 1.0)
        @constraint(model, 1.0 * x <= 3.0)
        @objective(model, sense, 2.0 * x)
        optimize!(model)
        expected_x = sense == MOI.MIN_SENSE ? 1.0 : 3.0
        @test is_solved_and_feasible(model)
        @test value(x) ≈ expected_x atol = 1e-3
        @test objective_value(model) ≈ 2.0 * expected_x atol = 1e-3
        for coefficient in [4.0, -4.0]
            set_objective_coefficient(model, x, coefficient)
            optimize!(model)
            expected_x =
                (sense == MOI.MIN_SENSE) == (coefficient > 0) ? 1.0 : 3.0
            @test is_solved_and_feasible(model)
            @test value(x) ≈ expected_x atol = 1e-3
            @test objective_value(model) ≈ coefficient * expected_x atol = 1e-3
        end
    end

    model = Model(highs_factory)
    @variable(model, x[1:2] >= 0)
    @constraint(model, 2x[1] + x[2] <= 4)
    @constraint(model, x[1] + 2x[2] <= 4)
    @objective(model, Max, 4x[1] + 3x[2])
    optimize!(model)
    @test objective_value(model) ≈ 28 / 3
    set_objective_coefficient(model, x[1], 5.0)
    optimize!(model)
    @test objective_value(model) ≈ 10.6666666666

    model = Model(highs_factory)
    @variable(model, x[1:2] >= 0)
    @constraint(model, 2x[1] + x[2] <= 4)
    @constraint(model, x[1] + 2x[2] <= 4)
    @objective(model, Min, -4x[1] + -3x[2])
    optimize!(model)
    @test objective_value(model) ≈ -28 / 3
    set_objective_coefficient(model, x[1], -5.0)
    optimize!(model)
    @test objective_value(model) ≈ -10.6666666666

    model = Model(scs_factory)
    @variable(model, x[1:2] >= 0)
    @constraint(model, 2x[1] + x[2] <= 4)
    @constraint(model, x[1] + 2x[2] <= 4)
    @objective(model, Max, 4x[1] + 3x[2])
    optimize!(model)
    @test objective_value(model) ≈ 28 / 3 atol = 1e-3
    set_objective_coefficient(model, x[1], 5.0)
    optimize!(model)
    @test objective_value(model) ≈ 10.6666666666 atol = 1e-3

    model = Model(scs_factory)
    @variable(model, x[1:2] >= 0)
    @constraint(model, 2x[1] + x[2] <= 4)
    @constraint(model, x[1] + 2x[2] <= 4)
    @objective(model, Min, -4x[1] + -3x[2])
    optimize!(model)
    @test objective_value(model) ≈ -28 / 3 atol = 1e-3
    set_objective_coefficient(model, x[1], -5.0)
    optimize!(model)
    @test objective_value(model) ≈ -10.6666666666 atol = 1e-3

    model = Model(scs_factory)
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
