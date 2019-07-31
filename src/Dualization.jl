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


mutable struct PrimalDualMap{T}
    primal_var_dual_con::Dict{VI, CI}
    primal_con_dual_var::Dict{CI, Vector{VI}}
    primal_con_dual_con::Dict{CI, CI}
    primal_con_constants::Dict{CI, Vector{T}}

    function PrimalDualMap{T}() where T
        return new(Dict{VI, CI}(),
                   Dict{CI, Vector{VI}}(),
                   Dict{CI, CI}(),
                   Dict{CI, Vector{T}}())
    end
end

function is_empty(primal_dual_map::PrimalDualMap{T}) where T
    if isempty(primal_dual_map.primal_var_dual_con) &&
       isempty(primal_dual_map.primal_con_dual_var) &&
       isempty(primal_dual_map.primal_con_dual_con) &&
       isempty(primal_dual_map.primal_con_constants)
       return true
    end
    return false
end

function empty!(primal_dual_map::PrimalDualMap{T}) where T
    primal_dual_map.primal_var_dual_con = Dict{VI, CI}()
    primal_dual_map.primal_con_dual_var = Dict{CI, Vector{VI}}()
    primal_dual_map.primal_con_dual_con = Dict{CI, CI}()
    primal_dual_map.primal_con_constants = Dict{CI, Vector{T}}()
end

struct DualProblem{T}
    dual_model::MOI.ModelLike #It can be a model from an optimizer or a DualizableModel{T}
    primal_dual_map::PrimalDualMap{T}

    # Empty DualProblem cosntructor
    function DualProblem{T}() where T
        return new(DualizableModel{T}(), PrimalDualMap{T}())
    end
    function DualProblem{T}(dual_optimizer::OT) where {T, OT <: MOI.ModelLike}
        return new(dual_optimizer, PrimalDualMap{T}())
    end
    function DualProblem(dual_optimizer::OT) where {OT <: MOI.ModelLike}
        return DualProblem{Float64}(MOIU.CachingOptimizer(DualizableModel{Float64}(), dual_optimizer))
    end
end

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
