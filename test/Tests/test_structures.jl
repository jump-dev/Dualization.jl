@testset "structures" begin
    primal_dual_map = Dualization.PrimalDualMap{Float64}()
    @test Dualization.is_empty(primal_dual_map)
    push!(primal_dual_map.primal_var_dual_con, VI(1) => CI{SVF, MOI.EqualTo}(1))
    @test !Dualization.is_empty(primal_dual_map)

    # Constructors
    model = lp1_test()
    dp_f32 = Dualization.DualProblem{Float32}(model)
    @test typeof(dp_f32) == Dualization.DualProblem{Float32,TestModel{Float64}}

    dp_f64 = Dualization.DualProblem(model) # default is Float64
    @test typeof(dp_f64) == Dualization.DualProblem{Float64,TestModel{Float64}}
end