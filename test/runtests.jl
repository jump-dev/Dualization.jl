# Copyright (c) 2017: Guilherme Bodin, and contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

using Dualization
using JuMP
using Test

MOI.Utilities.@model(
    TestModel,
    (MOI.ZeroOne, MOI.Integer),
    (
        MOI.EqualTo,
        MOI.GreaterThan,
        MOI.LessThan,
        MOI.Interval,
        MOI.Semicontinuous,
        MOI.Semiinteger,
    ),
    (
        MOI.Reals,
        MOI.Zeros,
        MOI.Nonnegatives,
        MOI.Nonpositives,
        MOI.SecondOrderCone,
        MOI.RotatedSecondOrderCone,
        MOI.GeometricMeanCone,
        MOI.ExponentialCone,
        MOI.DualExponentialCone,
        MOI.PositiveSemidefiniteConeTriangle,
        MOI.PositiveSemidefiniteConeSquare,
        MOI.RootDetConeTriangle,
        MOI.RootDetConeSquare,
        MOI.LogDetConeTriangle,
        MOI.LogDetConeSquare,
    ),
    (MOI.PowerCone, MOI.DualPowerCone, MOI.SOS1, MOI.SOS2),
    (),
    (MOI.ScalarAffineFunction, MOI.ScalarQuadraticFunction),
    (MOI.VectorOfVariables,),
    (MOI.VectorAffineFunction, MOI.VectorQuadraticFunction)
)

# Functions that are used inside tests
include("utils.jl")

# Problems database
include("Problems/Linear/linear_problems.jl")
include("Problems/Linear/conic_linear_problems.jl")
# include("Problems/Quadratic/quadratic_problems.jl")
# include("Problems/SOC/soc_problems.jl")
# include("Problems/RSOC/rsoc_problems.jl")
# include("Problems/SDP/sdp_triangle_problems.jl")
# include("Problems/Exponential/exponential_cone_problems.jl")
# include("Problems/Power/power_cone_problems.jl")

# Run tests to travis ci
# include("Tests/test_structures.jl")
# include("Tests/test_supported.jl")
# include("Tests/test_objective_coefficients.jl")
# include("Tests/test_dual_model_variables.jl")
# include("Tests/test_dual_sets.jl")
# include("Tests/test_dualize_conic_linear.jl")
include("Tests/test_dualize_linear.jl")
# include("Tests/test_dualize_soc.jl")
# include("Tests/test_dualize_rsoc.jl")
# include("Tests/test_dualize_sdp.jl")
# include("Tests/test_dualize_exponential.jl")
# include("Tests/test_dualize_power.jl")
# include("Tests/test_dualize_quadratic.jl")
# include("Tests/test_dual_names.jl")
# include("Tests/test_dot.jl")

# include("Tests/test_partial_dual_linear.jl")
# include("Tests/test_partial_dual_quadratic.jl")

#=
    Tests depending on solvers
=#

# include("optimize_abstract_models.jl")

primal_linear_factory = []
primal_conic_factory = []
primal_power_cone_factory = []

dual_linear_factory = []
dual_conic_factory = []
dual_power_cone_factory = []

dual_linear_optimizer = []
dual_conic_optimizer = []
dual_power_cone_optimizer = []

primal_linear_optimizer = []
primal_conic_optimizer = []
primal_power_cone_optimizer = []

# Load & Test strong duality in linear/conic problems
# Comment the solver that are not available for development
# include("Solvers/highs_test.jl")
# include("Solvers/csdp_test.jl")
# include("Solvers/scs_test.jl")

# include("Tests/test_JuMP_dualize.jl")
# include("Tests/test_MOI_wrapper.jl")
# include("Tests/test_modify.jl")
