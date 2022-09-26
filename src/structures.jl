# Copyright (c) 2017: Guilherme Bodin, and contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

MOI.Utilities.@model(
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

"""
    PrimalDualMap{T}

Maps information from all structures of the primal to the dual model.

* `constrained_var_idx::Dict{MOI.VariableIndex,Tuple{MOI.ConstraintIndex,Int}}`: maps original primal
constrained variables to their primal original constraints (the special ones
that makes them constrained variables) and their internal index (if vector
constraints, VectorOfVariables-in-Set), 1 otherwise (VariableIndex-in-Set).

* `constrained_var_dual::Dict{MOI.ConstraintIndex,MOI.ConstraintIndex}`: maps the original primal constraint index
of constrained variables to the dual model's constraint index of the
associated dual constraint.

* `constrained_var_zero::Dict{MOI.ConstraintIndex,Unions{MOI.ScalarAffineFunction,MOI.VectorAffineFunction}}`: caches scalar affine
functions or vector affine functions associated with constrained variables
of type `VectorOfVariables`-in-`Zeros` or
`VariableIndex`-in-`EqualTo(zero(T))` as
their duals would be `func`-in-`Reals`, which are "irrelevant" to the model.
This information is cached for completeness of the `DualOptimizer` for
`get`ting `ConstraintDuals`.

* `primal_var_dual_con::Dict{MOI.VariableIndex,MOI.ConstraintIndex}`: maps "free" primal variables to their
associated dual constraints. Free variables as opposed to constrained
variables. Note that Dualization will select automatically which variables
are free and which are constrained.

* `primal_con_dual_var::Dict{MOI.ConstraintIndex,Vector{MOI.VariableIndex}}`: maps primal constraint indices to
vectors of dual variable indices. For scalar constraints those vectors will be
single element vectors.

* `primal_con_dual_con::Dict{MOI.ConstraintIndex,MOI.ConstraintIndex}`: maps primal constraints to
dual variable constraints (if there is such constraint the dual
dual variable is said to be constrained). If the primal constraint's set
is EqualTo or Zeros, no constraint is added in the dual variable (the
dual variable is said to be free).

* `primal_con_constants::Dict{MOI.ConstraintIndex,Vector{T}}`: maps primal constraints to
their respective constants, which might be inside the set.
This map is used in `MOI.get(::DualOptimizer,::MOI.ConstraintPrimal,ci)`
that requires extra information in the case that the scalar set constrains
a constant (`EqualtTo`, `GreaterThan`, `LessThan`).

* `primal_parameter::Dict{MOI.VariableIndex,MOI.VariableIndex}`: maps parameters in the primal to parameters
in the dual model.

* `primal_var_dual_quad_slack::Dict{MOI.VariableIndex,MOI.VariableIndex}`: maps primal variables
(that appear in quadratic objective terms) to dual "slack" variables.

"""
mutable struct PrimalDualMap{T}
    constrained_var_idx::Dict{MOI.VariableIndex,Tuple{MOI.ConstraintIndex,Int}}
    constrained_var_dual::Dict{MOI.ConstraintIndex,MOI.ConstraintIndex}
    constrained_var_zero::Dict{
        MOI.ConstraintIndex,
        Union{MOI.VectorAffineFunction{T},MOI.ScalarAffineFunction{T}},
    }
    primal_var_dual_con::Dict{MOI.VariableIndex,MOI.ConstraintIndex}
    primal_con_dual_var::Dict{MOI.ConstraintIndex,Vector{MOI.VariableIndex}}
    primal_con_dual_con::Dict{MOI.ConstraintIndex,MOI.ConstraintIndex}
    primal_con_constants::Dict{MOI.ConstraintIndex,Vector{T}}

    primal_parameter::Dict{MOI.VariableIndex,MOI.VariableIndex}
    primal_var_dual_quad_slack::Dict{MOI.VariableIndex,MOI.VariableIndex}

    function PrimalDualMap{T}() where {T}
        return new(
            Dict{MOI.VariableIndex,Tuple{MOI.ConstraintIndex,Int}}(),
            Dict{MOI.ConstraintIndex,MOI.ConstraintIndex}(),
            Dict{
                MOI.ConstraintIndex,
                Union{MOI.VectorAffineFunction{T},MOI.ScalarAffineFunction{T}},
            }(),
            Dict{MOI.VariableIndex,MOI.ConstraintIndex}(),
            Dict{MOI.ConstraintIndex,Vector{MOI.VariableIndex}}(),
            Dict{MOI.ConstraintIndex,MOI.ConstraintIndex}(),
            Dict{MOI.ConstraintIndex,Vector{T}}(),
            Dict{MOI.VariableIndex,MOI.VariableIndex}(),
            Dict{MOI.VariableIndex,MOI.VariableIndex}(),
        )
    end
end

function is_empty(primal_dual_map::PrimalDualMap{T}) where {T}
    return isempty(primal_dual_map.constrained_var_idx) &&
           isempty(primal_dual_map.constrained_var_dual) &&
           isempty(primal_dual_map.constrained_var_zero) &&
           isempty(primal_dual_map.primal_var_dual_con) &&
           isempty(primal_dual_map.primal_con_dual_var) &&
           isempty(primal_dual_map.primal_con_dual_con) &&
           isempty(primal_dual_map.primal_con_constants) &&
           isempty(primal_dual_map.primal_parameter) &&
           isempty(primal_dual_map.primal_var_dual_quad_slack)
end

function empty!(primal_dual_map::PrimalDualMap)
    Base.empty!(primal_dual_map.constrained_var_idx)
    Base.empty!(primal_dual_map.constrained_var_dual)
    Base.empty!(primal_dual_map.constrained_var_zero)
    Base.empty!(primal_dual_map.primal_var_dual_con)
    Base.empty!(primal_dual_map.primal_con_dual_var)
    Base.empty!(primal_dual_map.primal_con_dual_con)
    Base.empty!(primal_dual_map.primal_con_constants)
    Base.empty!(primal_dual_map.primal_parameter)
    Base.empty!(primal_dual_map.primal_var_dual_quad_slack)
    return
end

"""
    DualProblem{T,OT<:MOI.ModelLike}

Result of the `dualize` function. Contains the fields:

* `dual_model::OT`: contaninf a optimizer or data structure with the
`MathOptInterface` definition of the resulting dual model.

* `primal_dual_map::PrimalDualMap{T}`: a data structure to hold information of
how the primal and dual model are related in terms of indices (`VariableIndex`
and `ConstraintIndex`) and other data.
"""
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
