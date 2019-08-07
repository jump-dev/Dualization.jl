@testset "structures" begin
    primal_dual_map = Dualization.PrimalDualMap{Float64}()
    @test Dualization.is_empty(primal_dual_map)
    push!(primal_dual_map.primal_var_dual_con, VI(1) => CI{SVF, MOI.EqualTo}(1))
    @test !Dualization.is_empty(primal_dual_map)
end