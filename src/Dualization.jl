module Dualization

using MathOptInterface
const MOI  = MathOptInterface
const MOIU = MathOptInterface.Utilities

const SVF = MOI.SingleVariable
const VVF = MOI.VectorOfVariables
const SAF{T} = MOI.ScalarAffineFunction{T}
const VAF{T} = MOI.VectorAffineFunction{T}

const VI = MOI.VariableIndex
const CI = MOI.ConstraintIndex

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

cd("src")
include("utils.jl")
include("supported.jl")
include("objective_coefficients.jl")
include("primal_constraint_coefficients.jl")
include("dual_constraint_coefficients.jl")

include("dualize.jl")

end # module
