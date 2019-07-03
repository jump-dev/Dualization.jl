using MathOptInterface, Dualization, Test

const MOI  = MathOptInterface
const MOIU = MathOptInterface.Utilities
const MOIB = MathOptInterface.Bridges

const SVF = MOI.SingleVariable
const VVF = MOI.VectorOfVariables
const SAF{T} = MOI.ScalarAffineFunction{T}
const VAF{T} = MOI.VectorAffineFunction{T}

const VI = MOI.VariableIndex
const CI = MOI.ConstraintIndex

MOIU.@model(TestModel,
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

            
# Problems database
include("Problems/Linear/linear_problems.jl")
include("Problems/Quadratic/quadratic_problems.jl")
include("Problems/SOC/soc_problems.jl")

# Run tests to travis ci
include("Tests/test_supported.jl")
include("Tests/test_objective_coefficients.jl")
include("Tests/test_dual_model_variables.jl")
include("Tests/test_dual_sets.jl")
include("Tests/test_dualize.jl")


# Full version of tests, this hsould be all comented to pass travis ci because of dependencies
using JuMP
include("optimize_abstract_models.jl")

# Test strong duality in linear/conic problems
# include("Solvers/clp_test.jl") 
include("Solvers/glpk_test.jl")
include("Solvers/scs_test.jl")