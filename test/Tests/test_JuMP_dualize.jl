# Copyright (c) 2017: Guilherme Bodin, and contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

# For testing bug found on issue # 52
function solve_vaf_sdp(optimizer_constructor)
    model = Model(optimizer_constructor)
    @variable(model, x)
    @constraint(model, [4x x; x 4x] - ones(2, 2) in PSDCone())
    @objective(model, Min, x)
    optimize!(model)
    return JuMP.objective_value(model) # 0.6
end

@testset "JuMP dualize" begin
    @testset "direct_mode" begin
        JuMP_model = JuMP.direct_model(
            MOI.Utilities.MockOptimizer(MOI.Utilities.Model{Float64}()),
        )
        err = ErrorException(
            "Dualization does not support solvers in DIRECT mode",
        )
        @test_throws ErrorException dualize(JuMP_model)
    end
    @testset "dualize JuMP models" begin
        # Only testing with a small LP
        for i in eachindex(primal_linear_factory)
            JuMP_model = JuMP.Model()
            MOI.copy_to(JuMP.backend(JuMP_model), lp1_test())
            dual_JuMP_model = dualize(JuMP_model)
            @test backend(dual_JuMP_model).state == MOI.Utilities.NO_OPTIMIZER
            dual_JuMP_model = dualize(JuMP_model, primal_linear_factory[i])
            @test backend(dual_JuMP_model).state ==
                  MOI.Utilities.EMPTY_OPTIMIZER
            @test MOI.get(backend(dual_JuMP_model), MOI.SolverName()) ==
                  MOI.get(primal_linear_optimizer[i], MOI.SolverName())
        end
    end
    @testset "set_dot on different sets" begin
        for i in eachindex(primal_power_cone_factory)
            primal_scs = solve_vaf_sdp(primal_power_cone_factory[i])
            dual_scs = solve_vaf_sdp(dual_power_cone_factory[i])
            @test isapprox(primal_scs, dual_scs; atol = 1e-3)
        end
        for i in eachindex(primal_conic_factory)
            primal_csdp = solve_vaf_sdp(primal_conic_factory[i])
            dual_csdp = solve_vaf_sdp(dual_conic_factory[i])
            @test isapprox(primal_csdp, dual_csdp; atol = 1e-6)
        end
    end
    @testset "Access objects in the object_dictionary" begin
        model = Model()
        @variable(model, x)
        @variable(model, y)
        @variable(model, z)
        @constraint(model, soccon, [x; y; z] in SecondOrderCone())
        @constraint(model, eqcon, x == 1)
        @objective(model, Min, y + z)

        # Test that unnamed objects don't create a key `Symbol("")` in `dual_model`.
        @variable(model)
        @constraint(model, c, x == y)

        dual_model = dualize(model; dual_names = DualNames("dual", ""))

        @test typeof(dual_model[:dualeqcon]) == VariableRef
        @test !haskey(dual_model, Symbol(""))

        for var in (x, y, z)
            con = Dualization._get_dual_constraint(dual_model, x)
            @test con[1] isa ConstraintRef
            @test con[2] isa Int
        end

        var = Dualization._get_dual_variables(dual_model, soccon)
        @test var === nothing
        con = Dualization._get_dual_constraint(dual_model, soccon)
        @test con === nothing

        con = Dualization._get_primal_constraint(dual_model, y)
        @test con[1] isa ConstraintRef
        @test con[2] == 2

        var = Dualization._get_dual_variables(dual_model, eqcon)
        @test length(var) == 1
        @test var[1] isa VariableRef
        con = Dualization._get_dual_constraint(dual_model, eqcon)
        @test con === nothing

        var = Dualization._get_dual_variables(dual_model, c)
        @test length(var) == 1
        @test var[1] isa VariableRef
        con = Dualization._get_dual_constraint(dual_model, c)
        @test con === nothing
    end
    @testset "JuMP_dualize_kwargs" begin
        model = Model()
        @variable(model, x >= 0)
        @constraint(model, c, x <= 2)
        @objective(model, Max, 2 * x + 1)
        dual_model = Dualization.dualize(
            model;
            dual_names = DualNames("dual_", "dual_"),
            ignore_objective = true,
            consider_constrained_variables = false,
        )
        @test dual_model isa Model
        @test num_variables(dual_model) == 2
        con = Dualization._get_dual_constraint(dual_model, x)
        @test con[1] isa ConstraintRef
        @test con[2] == -1

        con = Dualization._get_primal_constraint(dual_model, x)
        @test con[1] === nothing
        @test con[2] == -1

        var = Dualization._get_dual_variables(dual_model, c)
        @test length(var) == 1
        @test var[] isa VariableRef
        con = Dualization._get_dual_constraint(dual_model, c)
        @test con isa ConstraintRef

        cv = LowerBoundRef(x)
        var = Dualization._get_dual_variables(dual_model, cv)
        @test length(var) == 1
        @test var[] isa VariableRef
        con = Dualization._get_dual_constraint(dual_model, cv)
        @test con isa ConstraintRef
    end
    @testset "JuMP parametric quadratic" begin
        model = Model()
        @variable(model, x)
        @variable(model, p ∈ Parameter(2.0))
        @constraint(model, c, x <= p)
        @objective(model, Max, 3x + x^2)
        dual_model = dualize(model, dual_names = DualNames())
        param = Dualization._get_dual_parameter(dual_model, p)
        @test param isa VariableRef
        @test owner_model(param) === dual_model
        @test MOI.get(dual_model, MOI.VariableName(), param) == "param_p"
        quadslack = Dualization._get_dual_slack_variable(dual_model, x)
        @test quadslack isa VariableRef
        @test owner_model(quadslack) === dual_model
        @test MOI.get(dual_model, MOI.VariableName(), quadslack) ==
              "quadslack_x"
    end
end
