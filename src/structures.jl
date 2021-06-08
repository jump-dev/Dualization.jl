MOIU.@model(
    DualizableModel,
    (),
    (MOI.EqualTo, MOI.GreaterThan, MOI.LessThan),
    (
        MOI.Reals,
        MOI.Zeros,
        MOI.Nonnegatives,
        MOI.Nonpositives,
        MOI.SecondOrderCone,
        MOI.RotatedSecondOrderCone,
        MOI.ExponentialCone,
        MOI.DualExponentialCone,
        MOI.PositiveSemidefiniteConeTriangle,
    ),
    (MOI.PowerCone, MOI.DualPowerCone),
    (),
    (MOI.ScalarAffineFunction,),
    (MOI.VectorOfVariables,),
    (MOI.VectorAffineFunction,)
)

mutable struct PrimalDualMap{T}
    constrained_var_idx::Dict{VI,Tuple{CI,Int}}
    constrained_var_dual::Dict{CI,CI}
    primal_var_dual_con::Dict{VI,CI}
    primal_con_dual_var::Dict{CI,Vector{VI}}
    primal_con_dual_con::Dict{CI,CI}
    primal_con_constants::Dict{CI,Vector{T}}

    primal_parameter::Dict{VI,VI} # in the future we could have Parameters, as in ParameterJuMP
    primal_var_dual_quad_slack::Dict{VI,VI}

    function PrimalDualMap{T}() where {T}
        return new(
            Dict{VI,Tuple{CI,Int}}(),
            Dict{CI,CI}(),
            Dict{VI,CI}(),
            Dict{CI,Vector{VI}}(),
            Dict{CI,CI}(),
            Dict{CI,Vector{T}}(),
            Dict{VI,VI}(),
            Dict{VI,VI}(),
        )
    end
end

function is_empty(primal_dual_map::PrimalDualMap{T}) where {T}
    return isempty(primal_dual_map.primal_var_dual_con) &&
           isempty(primal_dual_map.primal_con_dual_var) &&
           isempty(primal_dual_map.primal_con_dual_con) &&
           isempty(primal_dual_map.primal_con_constants) &&
           isempty(primal_dual_map.primal_parameter) &&
           isempty(primal_dual_map.primal_var_dual_quad_slack)
end

function empty!(primal_dual_map::PrimalDualMap{T}) where {T}
    primal_dual_map.primal_var_dual_con = Dict{VI,CI}()
    primal_dual_map.primal_con_dual_var = Dict{CI,Vector{VI}}()
    primal_dual_map.primal_con_dual_con = Dict{CI,CI}()
    primal_dual_map.primal_con_constants = Dict{CI,Vector{T}}()
    primal_dual_map.primal_parameter = Dict{VI,VI}()
    return primal_dual_map.primal_var_dual_quad_slack = Dict{VI,VI}()
end

struct DualProblem{T,OT<:MOI.ModelLike}
    dual_model::OT #It can be a model from an optimizer or a DualizableModel{T}
    primal_dual_map::PrimalDualMap{T}

    function DualProblem{T}(
        dual_optimizer::OT,
        pdmap::PrimalDualMap{T},
    ) where {T,OT<:MOI.ModelLike}
        return new{T,OT}(dual_optimizer, pdmap)
    end
end

function DualProblem{T}(dual_optimizer::OT) where {T,OT<:MOI.ModelLike}
    return DualProblem{T}(dual_optimizer, PrimalDualMap{T}())
end

function DualProblem(dual_optimizer::OT) where {OT<:MOI.ModelLike}
    return DualProblem{Float64}(dual_optimizer)
end

# Empty DualProblem cosntructor
function DualProblem{T}() where {T}
    return DualProblem{T}(DualizableModel{T}(), PrimalDualMap{T}())
end
