using GLPK, ECOS, CSDP


const cache = MOIU.UniversalFallback(Dualization.DualizableModel{Float64}())
optimizer = Dualization.DualOptimizer(GLPK.Optimizer())
MOI.empty!(optimizer)
cached = MOIU.CachingOptimizer(cache, optimizer)
bridged = MOIB.full_bridge_optimizer(cached, Float64)

model = lp1_test()
model = lp9_test()
MOI.copy_to(bridged, model)
MOI.optimize!(bridged)

@testset "optimizer.jl" begin
    @testset "Linear bridge" begin
        model = lp9_test()
    end
end

m = lp1_test()
dm = dualize(m)
dm.primal_dual_map.primal_con_dual_var
dm.primal_dual_map.primal_var_dual_con
dm.primal_dual_map.primal_con_dual_con
const MOIT = MathOptInterface.Test
config = MOIT.TestConfig(atol=1e-5)
@testset begin
    MOIT.contlineartest(bridged, config)
end

using JuMP

model = Model(with_optimizer(GLPK.Optimizer))
@variable(model, x[1:2] >= 0)
@constraint(model,con1, 2*x[1] + x[2] <= 4)
@constraint(model,con2, x[1] + 2*x[2] <= 4)
@objective(model, Max, 4*x[1] + 3x[2])
optimize!(model)
JuMP.value.(x)
JuMP.dual(con1)
JuMP.dual(con2)

model = Model(with_optimizer(GLPK.Optimizer))
@variable(model, x[1:2] >= 0)
@constraint(model,con1, 2*x[1] + x[2] >= 4)
@constraint(model,con2, x[1] + 2*x[2] >= 3)
@objective(model, Min, 4*x[1] + 4x[2])
optimize!(model)
JuMP.value.(x)
JuMP.dual(con1)
JuMP.dual(con2)

model = Model(with_optimizer(GLPK.Optimizer))
@variable(model, x[1:2])
@variable(model, z[1:2])
@constraint(model, con3, z[1] >= 0)
@constraint(model, con4, z[2] >= 0)
@constraint(model,con1, 2*x[1] + x[2] - 4 + z[1] == 0)
@constraint(model,con2, x[1] + 2*x[2] - 3 + z[2] == 0)
@objective(model, Max, 4*x[1] + 4x[2])
optimize!(model)
JuMP.value.(z)
JuMP.value.(x)
JuMP.dual(con1)
JuMP.dual(con2)