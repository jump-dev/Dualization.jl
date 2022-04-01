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
        JuMP_model =
            JuMP.direct_model(MOIU.MockOptimizer(MOIU.Model{Float64}()))
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
            @test backend(dual_JuMP_model).state == MOIU.NO_OPTIMIZER
            dual_JuMP_model = dualize(JuMP_model, primal_linear_factory[i])
            @test backend(dual_JuMP_model).state == MOIU.EMPTY_OPTIMIZER
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
        @constraint(model, x == y)

        dual_model = dualize(model; dual_names = DualNames("dual", ""))

        @test typeof(dual_model[:dualeqcon_1]) == VariableRef
        @test !haskey(dual_model, Symbol(""))
    end
end
