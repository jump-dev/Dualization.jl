push!(LOAD_PATH, "/home/guilhermebodin/Documents/Github/Dualization.jl/src")
using Pkg
Pkg.activate(".") # Just to make sure to use JuMP 0.19.1
using MathOptInterface, JuMP, Dualization

const MOI  = MathOptInterface
const MOIT = MathOptInterface.Test
const MOIU = MathOptInterface.Utilities
const MOIB = MathOptInterface.Bridges

MOIU.@model(DualizableModel,
            (),
            (MOI.EqualTo, MOI.GreaterThan, MOI.LessThan, MOI.Interval,),
            (MOI.Reals, MOI.Zeros, MOI.Nonnegatives, MOI.Nonpositives,
             MOI.SecondOrderCone, MOI.RotatedSecondOrderCone,
             MOI.GeometricMeanCone, MOI.ExponentialCone, MOI.DualExponentialCone,
             MOI.PositiveSemidefiniteConeTriangle, MOI.PositiveSemidefiniteConeSquare,
             MOI.RootDetConeTriangle, MOI.RootDetConeSquare, MOI.LogDetConeTriangle,
             MOI.LogDetConeSquare),
            (MOI.PowerCone, MOI.DualPowerCone),
            (MOI.SingleVariable,),
            (MOI.ScalarAffineFunction,),
            (MOI.VectorOfVariables,),
            (MOI.VectorAffineFunction,))

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

# g = MOI.VectorAffineFunction(MOI.VectorAffineTerm.([3, 3],
#                                                     MOI.ScalarAffineTerm.([5.0, 2.0], X)),
#                                                     [3.0, 1.0, 4.0])

# MOI.add_constraint(primal_model, g, MOI.Zeros(0))

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