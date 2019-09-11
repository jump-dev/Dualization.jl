module Dualization

using JuMP, MathOptInterface
const MOI  = MathOptInterface
const MOIU = MathOptInterface.Utilities
const MOIB = MathOptInterface.Bridges

const SVF = MOI.SingleVariable
const VVF = MOI.VectorOfVariables
const SAF{T} = MOI.ScalarAffineFunction{T}
const VAF{T} = MOI.VectorAffineFunction{T}

const VI = MOI.VariableIndex
const CI = MOI.ConstraintIndex

import MathOptInterface: dual_set

include("structures.jl")
include("utils.jl")
include("dual_sets.jl")
include("supported.jl")
include("dual_names.jl")
include("objective_coefficients.jl")
include("add_dual_cone_constraint.jl")
include("dual_model_variables.jl")
include("dual_equality_constraints.jl")
include("dualize.jl")
include("MOI_wrapper.jl")

end # module
