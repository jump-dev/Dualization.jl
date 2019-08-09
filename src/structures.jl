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

struct DualProblem{T, OT <: MOI.ModelLike}
    dual_model::OT #It can be a model from an optimizer or a DualizableModel{T}
    primal_dual_map::PrimalDualMap{T}

    function DualProblem{T}(dual_optimizer::OT, pdmap::PrimalDualMap{T}) where {T, OT <: MOI.ModelLike}
        return new{T, OT}(dual_optimizer, pdmap)
    end
end

function DualProblem{T}(dual_optimizer::OT) where {T, OT <: MOI.ModelLike}
    return DualProblem{T}(dual_optimizer, PrimalDualMap{T}())
end

function DualProblem(dual_optimizer::OT) where {OT <: MOI.ModelLike}
    return DualProblem{Float64}(dual_optimizer)
end

# Empty DualProblem cosntructor
function DualProblem{T}() where {T}
    return DualProblem{T}(DualizableModel{T}(), PrimalDualMap{T}())
end
