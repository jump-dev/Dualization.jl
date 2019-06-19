push!(LOAD_PATH, "/home/guilhermebodin/Documents/Github/Dualization.jl/src")
using Pkg
Pkg.activate(".") # Just to make sure to use JuMP 0.19.1
using MathOptInterface, JuMP, Dualization

const MOI  = MathOptInterface
const MOIT = MathOptInterface.Test
const MOIU = MathOptInterface.Utilities
const MOIB = MathOptInterface.Bridges

MOIU.@model(Model,
            (MOI.ZeroOne, MOI.Integer),
            (MOI.EqualTo, MOI.GreaterThan, MOI.LessThan, MOI.Interval,
             MOI.Semicontinuous, MOI.Semiinteger),
            (MOI.Reals, MOI.Zeros, MOI.Nonnegatives, MOI.Nonpositives,
             MOI.SecondOrderCone, MOI.RotatedSecondOrderCone,
             MOI.GeometricMeanCone, MOI.ExponentialCone, MOI.DualExponentialCone,
             MOI.PositiveSemidefiniteConeTriangle, MOI.PositiveSemidefiniteConeSquare,
             MOI.RootDetConeTriangle, MOI.RootDetConeSquare, MOI.LogDetConeTriangle,
             MOI.LogDetConeSquare),
            (MOI.PowerCone, MOI.DualPowerCone, MOI.SOS1, MOI.SOS2),
            (MOI.SingleVariable,),
            (MOI.ScalarAffineFunction, MOI.ScalarQuadraticFunction),
            (MOI.VectorOfVariables,),
            (MOI.VectorAffineFunction, MOI.VectorQuadraticFunction))

#= 
min -4x1 -3x2 -1
  s.a.
    2x1 + x2 + 1 <= 4
    x1 + 2x2 <= 4
    x1 >= 1
    x2 >= 0
=#

primal_model = Model{Float64}()

X = MOI.add_variables(primal_model, 2)

g = MOI.VectorAffineFunction(MOI.VectorAffineTerm.([3, 3],
                                                    MOI.ScalarAffineTerm.([5.0, 2.0], X)),
                                                    [3.0, 1.0, 4.0])

MOI.add_constraint(primal_model, g, MOI.Zeros(0))

MOI.add_constraint(primal_model, 
    MOI.ScalarAffineFunction(
        [MOI.ScalarAffineTerm(1.0, X[1]), MOI.ScalarAffineTerm(2.0, X[2])], 1.0),
        MOI.LessThan(4.0))

MOI.add_constraint(primal_model, 
    MOI.SingleVariable(X[1]),
        MOI.GreaterThan(1.0))

MOI.add_constraint(primal_model, 
    MOI.SingleVariable(X[1]),
        MOI.GreaterThan(3.0))

MOI.set(primal_model, 
    MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(), 
    MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([-4.0], [X[2]]), -1.0)
    )

MOI.set(primal_model, MOI.ObjectiveSense(), MOI.MIN_SENSE)


primal_model
dualmodel = dualize(primal_model)

using Clp
model1 = JuMP.Model()
MOI.copy_to(JuMP.backend(model1), primal_model)
set_optimizer(model1, with_optimizer(Clp.Optimizer))
optimize!(model1)
termstatus1 = JuMP.termination_status(model1)
obj1 = JuMP.objective_value(model1)

model2 = JuMP.Model()
MOI.copy_to(JuMP.backend(model2), dualmodel.dual_model)
set_optimizer(model2, with_optimizer(Clp.Optimizer))
optimize!(model2)
termstatus2 = JuMP.termination_status(model2)
obj2 = JuMP.objective_value(model2)

@show termstatus1, termstatus2
@show obj1, obj2

# Separador linear
using JuMP, GLPK, CSV

#Read data from
data_tumors = CSV.read("/home/guilhermebodin/Downloads/Teaching.jl-master/Optimization/Class1/data_tumors.csv", header = false)

num_attributes = 30
train_set_size = 400

train_set_attrs = convert(Matrix{Float64}, data_tumors[1:train_set_size, 3:end])
train_set_diagnosis = convert(Vector{String}, data_tumors[1:train_set_size, 2])

test_set_attrs = convert(Matrix{Float64}, data_tumors[train_set_size + 1:end, 3:end])
test_set_diagnosis = convert(Vector{String}, data_tumors[train_set_size + 1:end, 2])

m = JuMP.Model(with_optimizer(GLPK.Optimizer))
n = 2
@variable(m, x[i = 1:n])
@variable(m, c)
@variable(m, ϵ[i = 1:train_set_size] >= 0)

for i in 1:train_set_size
    if train_set_diagnosis[i] == "M"
        @constraint(m, sum(train_set_attrs[i, j]*x[j] for j in 1:n) + c >= -ϵ[i])
    elseif train_set_diagnosis[i] == "B"
        @constraint(m, sum(train_set_attrs[i, j]*x[j] for j in 1:n) + c <= ϵ[i] - 1)
    end
end

@objective(m, Min, sum(ϵ))
m
optimize!(m)

x = value.(x)
c = value.(c)
obj_val = objective_value(m)

dualprob = dualize(m.moi_backend.model_cache.model)
model2 = JuMP.Model()
MOI.copy_to(JuMP.backend(model2), dualprob.dual_model)
set_optimizer(model2, with_optimizer(GLPK.Optimizer))
optimize!(model2)
termstatus2 = JuMP.termination_status(model2)
obj2 = JuMP.objective_value(model2)

@show obj_val, obj2


dualprob2 = dualize(dualprob.dual_model)
model3 = JuMP.Model()
MOI.copy_to(JuMP.backend(model3), dualprob2.dual_model)
set_optimizer(model3, with_optimizer(GLPK.Optimizer))
optimize!(model3)
termstatus2 = JuMP.termination_status(model3)
obj2 = JuMP.objective_value(model3)
