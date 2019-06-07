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

model = Model{Float64}()

X = MOI.add_variables(model, 2)

MOI.add_constraint(model, 
    MOI.ScalarAffineFunction(
        [MOI.ScalarAffineTerm(1.0, X[1]), MOI.ScalarAffineTerm(1.0, X[2])], 1.0),
         MOI.LessThan(4.0))

MOI.add_constraint(model, 
    MOI.ScalarAffineFunction(
        [MOI.ScalarAffineTerm(1.0, X[1]), MOI.ScalarAffineTerm(1.0, X[2])], 0.0),
         MOI.EqualTo(4.0))

# MOI.add_constraint(model, 
#     MOI.SingleVariable(X[1]),
#         MOI.LessThan(0.5))

# MOI.add_constraint(model, 
#     MOI.SingleVariable(X[2]),
#          MOI.GreaterThan(0.0))

MOI.set(model, 
    MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(), 
    MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([-4.0, -3.0], [X[1], X[2]]), -1.0)
    )

MOI.set(model, MOI.ObjectiveSense(), MOI.MIN_SENSE)

using GLPK
model1 = JuMP.Model()
MOI.copy_to(JuMP.backend(model1), model)
set_optimizer(model1, with_optimizer(GLPK.Optimizer))
optimize!(model1)
obj1 = JuMP.objective_value(model1)

model2 = JuMP.Model()
MOI.copy_to(JuMP.backend(model2), dualize(model))
set_optimizer(model2, with_optimizer(GLPK.Optimizer))
optimize!(model2)
obj2 = JuMP.objective_value(model2)


@show obj1, obj2
