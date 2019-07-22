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


MOIU.@model(DualizableModel,
            (),
            (MOI.EqualTo, MOI.GreaterThan, MOI.LessThan,),
            (MOI.Reals, MOI.Zeros, MOI.Nonnegatives, MOI.Nonpositives,
             MOI.SecondOrderCone, MOI.RotatedSecondOrderCone,
             MOI.ExponentialCone, MOI.DualExponentialCone,
             MOI.PositiveSemidefiniteConeTriangle,),
            (MOI.PowerCone, MOI.DualPowerCone),
            (MOI.SingleVariable,),
            (MOI.ScalarAffineFunction,),
            (MOI.VectorOfVariables,),
            (MOI.VectorAffineFunction,))


struct PrimalDualMap{T}
    primal_var_dual_con::Dict{VI, CI}
    primal_con_dual_var::Dict{CI, Vector{VI}}
    primal_con_dual_con::Dict{CI, Union{Nothing, CI}}
    primal_con_constants::Dict{CI, Vector{T}}

    function PrimalDualMap{T}() where T
        return new(Dict{VI, CI}(),
                    Dict{CI, Vector{VI}}(),
                    Dict{CI, Union{Nothing, CI}}(),
                    Dict{CI, Vector{T}}())
    end
end

struct DualProblem
    dual_model::MOI.ModelLike 
    primal_dual_map::PrimalDualMap
end

include("utils.jl")
include("dual_sets.jl")
include("supported.jl")
include("objective_coefficients.jl")
include("add_dual_cone_constraint.jl")
include("dual_model_variables.jl")
include("dual_equality_constraints.jl")
include("dualize.jl")
include("MOI_wrapper.jl")

end # module
