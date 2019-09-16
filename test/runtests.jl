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
            (),
            (MOI.ScalarAffineFunction, MOI.ScalarQuadraticFunction),
            (MOI.VectorOfVariables,),
            (MOI.VectorAffineFunction, MOI.VectorQuadraticFunction))

# Functions that are used inside tests
include("utils.jl")

# Problems database
include("Problems/Linear/linear_problems.jl")
include("Problems/Linear/conic_linear_problems.jl")
include("Problems/Quadratic/quadratic_problems.jl")
include("Problems/SOC/soc_problems.jl")
include("Problems/RSOC/rsoc_problems.jl")
include("Problems/SDP/sdp_triangle_problems.jl")
include("Problems/Exponential/exponential_cone_problems.jl")
include("Problems/Power/power_cone_problems.jl")

# Run tests to travis ci
include("Tests/test_structures.jl")
include("Tests/test_supported.jl")
include("Tests/test_objective_coefficients.jl")
include("Tests/test_dual_model_variables.jl")
include("Tests/test_dual_sets.jl")
include("Tests/test_dualize_conic_linear.jl")
include("Tests/test_dualize_linear.jl")
include("Tests/test_dualize_soc.jl")
include("Tests/test_dualize_rsoc.jl")
include("Tests/test_dualize_sdp.jl")
include("Tests/test_dualize_exponential.jl")
include("Tests/test_dualize_power.jl")
include("Tests/test_dual_names.jl")
include("Tests/test_JuMP_dualize.jl")
include("Tests/test_MOI_wrapper.jl")

# Full version of tests, this hsould be all comented to pass travis ci because of dependencies
include("optimize_abstract_models.jl")

# Test strong duality in linear/conic problems
include("Solvers/glpk_test.jl")
include("Solvers/ecos_test.jl")
include("Solvers/csdp_test.jl")
include("Solvers/scs_test.jl")
