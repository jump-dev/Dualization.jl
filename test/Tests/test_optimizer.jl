using SCS, GLPK, CSDP, Clp
push!(LOAD_PATH, "/home/guilhermebodin/Documents/Github/Dualization.jl/src")
import Pkg
Pkg.activate(".")
cd("test")
using MathOptInterface, JuMP, Dualization, Test

const MOI  = MathOptInterface
const MOIU = MathOptInterface.Utilities
const MOIB = MathOptInterface.Bridges
const MOIT = MathOptInterface.Test

const SVF = MOI.SingleVariable
const VVF = MOI.VectorOfVariables
const SAF{T} = MOI.ScalarAffineFunction{T}
const VAF{T} = MOI.VectorAffineFunction{T}

const VI = MOI.VariableIndex
const CI = MOI.ConstraintIndex

# Optimizers
linear_optimizer = Dualization.DualOptimizer(GLPK.Optimizer())
conic_optimizer = Dualization.DualOptimizer(CSDP.Optimizer(printlevel = 0))

@testset "optimizer.jl" begin    
    linear_config = MOIT.TestConfig(atol=1e-4, rtol = 1e-4)
    linear_cache = MOIU.UniversalFallback(Dualization.DualizableModel{Float64}())
    linear_cached = MOIU.CachingOptimizer(linear_cache, linear_optimizer)
    linear_bridged = MOIB.full_bridge_optimizer(linear_cached, Float64)

    @testset "contlineartest" begin
        MOIT.contlineartest(linear_bridged, linear_config, ["linear8b", # Asks for infeasibility ray
                                                            "linear8c", # Asks for infeasibility ray
                                                            "linear12", # Asks for infeasibility ray
                                                            "linear13"]) # Feasibility problem
    end

    conic_config = MOIT.TestConfig(atol=1e-4, rtol=1e-4)
    conic_cache = MOIU.UniversalFallback(Dualization.DualizableModel{Float64}())
    conic_cached = MOIU.CachingOptimizer(conic_cache, conic_optimizer)
    conic_bridged = MOIB.full_bridge_optimizer(conic_cached, Float64)

    @testset "contconictest" begin
        MOIT.contconictest(conic_bridged, conic_config, ["lin3", # Feasibility problem
                                                         "lin4", # Feasibility problem
                                                         "soc3", # Feasibility problem
                                                         "rotatedsoc2", # Feasibility problem
                                                         "exp", # Not yet implemented
                                                         "rootdets", # Not yet implemented
                                                         "logdets", # Not yet implemented
                                                         "geomean", # Not yet implemented
                                                         "rootdet", # Not yet implemented
                                                         "logdet" # Not yet implemented
                                                         ])
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