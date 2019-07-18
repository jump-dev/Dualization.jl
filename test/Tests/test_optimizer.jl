using SCS, GLPK

# Optimizers
linear_optimizer = Dualization.DualOptimizer(GLPK.Optimizer())
conic_optimizer = Dualization.DualOptimizer(SCS.Optimizer(verbose = 0))

@testset "optimizer.jl" begin    
    linear_config = MOIT.TestConfig(atol=1e-5, rtol = 1e-5)
    linear_cache = MOIU.UniversalFallback(Dualization.DualizableModel{Float64}())
    linear_cached = MOIU.CachingOptimizer(linear_cache, linear_optimizer)
    linear_bridged = MOIB.full_bridge_optimizer(linear_cached, Float64)

    @testset "contlineartest" begin
        MOIT.contlineartest(linear_bridged, linear_config, ["linear7", "linear13"]) # linear13 is Feasibility problem
    end

    conic_config = MOIT.TestConfig(atol=1e-4, rtol=1e-4)
    conic_cache = MOIU.UniversalFallback(Dualization.DualizableModel{Float64}())
    conic_cached = MOIU.CachingOptimizer(conic_cache, conic_optimizer)
    conic_bridged = MOIB.full_bridge_optimizer(conic_cached, Float64)

    @testset "contconictest" begin
        MOIT.contconictest(conic_bridged, conic_config, ["rootdets", "logdets"])
    end
end

# using JuMP

# model = Model(with_optimizer(GLPK.Optimizer))
# @variable(model, x[1:2] >= 0)
# @constraint(model,con1, 2*x[1] + x[2] <= 4)
# @constraint(model,con2, x[1] + 2*x[2] <= 4)
# @objective(model, Max, 4*x[1] + 3x[2])
# optimize!(model)
# JuMP.value.(x)
# JuMP.dual(con1)
# JuMP.dual(con2)

# model = Model(with_optimizer(GLPK.Optimizer))
# @variable(model, x[1:2] >= 0)
# @constraint(model,con1, 2*x[1] + x[2] >= 4)
# @constraint(model,con2, x[1] + 2*x[2] >= 3)
# @objective(model, Min, 4*x[1] + 4x[2])
# optimize!(model)
# JuMP.value.(x)
# JuMP.dual(con1)
# JuMP.dual(con2)

# model = Model(with_optimizer(GLPK.Optimizer))
# @variable(model, x[1:2])
# @variable(model, z[1:2])
# @constraint(model, con3, z[1] >= 0)
# @constraint(model, con4, z[2] >= 0)
# @constraint(model,con1, 2*x[1] + x[2] - 4 + z[1] == 0)
# @constraint(model,con2, x[1] + 2*x[2] - 3 + z[2] == 0)
# @objective(model, Max, 4*x[1] + 4x[2])
# optimize!(model)
# JuMP.value.(z)
# JuMP.value.(x)
# JuMP.dual(con1)
# JuMP.dual(con2)