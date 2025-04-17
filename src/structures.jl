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

The following abbreviations are used in the maps:

* `var`: variable index
* `con`: constraint index
* `convar`: constrained variable, variable index
* `convarcon`: constrained variable, constraint index

Main maps:

  * `primal_convar_to_primal_convarcon_and_index::Dict{MOI.VariableIndex,Tuple{MOI.ConstraintIndex,Int}}`:
    maps primal constrained variables to their primal
    constraints (the special ones that makes them constrained variables) and
    their internal index from 1 to dimension(set) (if vector constraints:
    VectorOfVariables-in-Set), 1 otherwise (scalar: VariableIndex-in-Set).

  * `primal_convarcon_to_dual_con::Dict{MOI.ConstraintIndex,MOI.ConstraintIndex}`: maps
    the primal constraint index of constrained variables to the dual
    model's constraint index of the associated dual constraint. This dual
    constraint is a regular constraint (not a constrained variable constraint).
    `VectorOfVariables`-in-`Zeros` and `VariableIndex`-in-`EqualTo(zero(T))`
    are not in this map, as they are not dualized (See
    primal_convarcon_to_dual_function).

  * `primal_var_to_dual_con::Dict{MOI.VariableIndex,MOI.ConstraintIndex}`: maps
    "free" primal variables to their associated dual (equality) constraints.
    Free variables as opposed to constrained variables. Note that Dualization
    will select automatically which variables are free and which are
    constrained.

  * `primal_con_to_dual_var_vec::Dict{MOI.ConstraintIndex,Vector{MOI.VariableIndex}}`:
    maps primal constraint indices to vectors of dual variable indices. For
    scalar constraints those vectors will be single element vectors.
    Primal constrained variables constraints (the main ones) are not in this
    map. However, `VariableIndex`-in-set and `VectorOfVariables`-in-set might
    appear in this map if they were not chosen as the main ones.

  * `primal_con_to_dual_convarcon::Dict{MOI.ConstraintIndex,MOI.ConstraintIndex}`:
    maps regular primal constraints to dual constrained variable. If the primal
    constraint's set is EqualTo or Zeros, no constraint is added in the dual
    variable (the dual variable is said to be free).
    Primal constrained variables constraints (the main ones) are not in this
    map. However, `VariableIndex`-in-set and `VectorOfVariables`-in-set might
    appear in this map if they were not chosen as the main ones.
    The keys are similar to the (# primal_con_to_dual_var_vec) map, except
    that `VariableIndex`-in-`EqualTo(zero(T))` and `VectorOfVariables`-in-`Zeros`
    are not in this map, as the dual constraint would belong to the `Reals` set,
    and would be innocuous (hence, not added).

  Additional helper maps:

  * `primal_con_to_primal_constants_vec::Dict{MOI.ConstraintIndex,Vector{T}}`: maps primal
    constraints to their respective constants, which might be inside the set.
    This map is used in `MOI.get(::DualOptimizer,::MOI.ConstraintPrimal,ci)`
    that requires extra information in the case that the scalar set constains
    a constant (`EqualtTo`, `GreaterThan`, `LessThan`).

  * `primal_parameter_to_dual_parameter::Dict{MOI.VariableIndex,MOI.VariableIndex}`: maps
    parameters in the primal to parameters in the dual model.

  * `primal_convarcon_to_dual_function::Dict{MOI.ConstraintIndex,Unions{MOI.ScalarAffineFunction,MOI.VectorAffineFunction}}`:
    caches scalar affine functions or vector affine functions associated with
    constrained variables of type `VectorOfVariables`-in-`Zeros` or
    `VariableIndex`-in-`EqualTo(zero(T))` as their duals would be `func`-in-`Reals`,
    which are "irrelevant" to the model. This information is cached for
    completeness of the `DualOptimizer` for `get`ting `ConstraintDuals`.

  * `primal_var_in_quad_obj_to_dual_slack_var::Dict{MOI.VariableIndex,MOI.VariableIndex}`:
    maps primal variables (that appear in quadratic objective terms) to dual
    "slack" variables. These primal variables might appear in other maps.
    Future name: primal_var_in_quad_obj_to_dual_slack_var
"""
mutable struct PrimalDualMap{T}
    primal_convar_to_primal_convarcon_and_index::Dict{
        MOI.VariableIndex,
        Tuple{MOI.ConstraintIndex,Int},
    }
    primal_convarcon_to_dual_con::Dict{MOI.ConstraintIndex,MOI.ConstraintIndex}
    primal_var_to_dual_con::Dict{MOI.VariableIndex,MOI.ConstraintIndex}
    primal_con_to_dual_var_vec::Dict{
        MOI.ConstraintIndex,
        Vector{MOI.VariableIndex},
    }
    primal_con_to_dual_convarcon::Dict{MOI.ConstraintIndex,MOI.ConstraintIndex}

    primal_con_to_primal_constants_vec::Dict{MOI.ConstraintIndex,Vector{T}}
    primal_parameter_to_dual_parameter::Dict{
        MOI.VariableIndex,
        MOI.VariableIndex,
    }
    primal_convarcon_to_dual_function::Dict{
        MOI.ConstraintIndex,
        Union{MOI.VectorAffineFunction{T},MOI.ScalarAffineFunction{T}},
    }
    primal_var_in_quad_obj_to_dual_slack_var::Dict{
        MOI.VariableIndex,
        MOI.VariableIndex,
    }

    function PrimalDualMap{T}() where {T}
        return new(
            Dict{MOI.VariableIndex,Tuple{MOI.ConstraintIndex,Int}}(),
            Dict{MOI.ConstraintIndex,MOI.ConstraintIndex}(),
            Dict{MOI.VariableIndex,MOI.ConstraintIndex}(),
            Dict{MOI.ConstraintIndex,Vector{MOI.VariableIndex}}(),
            Dict{MOI.ConstraintIndex,MOI.ConstraintIndex}(),
            Dict{MOI.ConstraintIndex,Vector{T}}(),
            Dict{MOI.VariableIndex,MOI.VariableIndex}(),
            Dict{
                MOI.ConstraintIndex,
                Union{MOI.VectorAffineFunction{T},MOI.ScalarAffineFunction{T}},
            }(),
            Dict{MOI.VariableIndex,MOI.VariableIndex}(),
        )
    end
end

function Base.getproperty(m::PrimalDualMap{T}, name::Symbol) where {T}
    if name === :constrained_var_idx
        @warn "constrained_var_idx field is deprecated, use primal_convar_to_primal_convarcon_and_index instead"
        return getfield(m, :primal_convar_to_primal_convarcon_and_index)
    elseif name === :constrained_var_dual
        @warn "constrained_var_dual field is deprecated, use primal_convarcon_to_dual_con instead"
        return getfield(m, :primal_convarcon_to_dual_con)
    elseif name === :primal_var_dual_con
        @warn "primal_var_dual_con field is deprecated, use primal_var_to_dual_con instead"
        return getfield(m, :primal_var_to_dual_con)
    elseif name === :primal_con_dual_var
        @warn "primal_con_dual_var field is deprecated, use primal_con_to_dual_var_vec instead"
        return getfield(m, :primal_con_to_dual_var_vec)
    elseif name === :primal_con_dual_con
        @warn "primal_con_dual_con field is deprecated, use primal_con_to_dual_convarcon instead"
        return getfield(m, :primal_con_to_dual_convarcon)
    elseif name === :primal_con_constants
        @warn "primal_con_constants field is deprecated, use primal_con_to_primal_constants_vec instead"
        return getfield(m, :primal_con_to_primal_constants_vec)
    elseif name === :primal_parameter
        @warn "primal_parameter field is deprecated, use primal_parameter_to_dual_parameter instead"
        return getfield(m, :primal_parameter_to_dual_parameter)
    elseif name === :constrained_var_zero
        @warn "constrained_var_zero field is deprecated, use primal_convarcon_to_dual_function instead"
        return getfield(m, :primal_convarcon_to_dual_function)
    elseif name === :primal_var_dual_quad_slack
        @warn "primal_var_dual_quad_slack field is deprecated, use primal_var_in_quad_obj_to_dual_slack_var instead"
        return getfield(m, :primal_var_in_quad_obj_to_dual_slack_var)
    else
        return getfield(m, name)
    end
end

function is_empty(primal_dual_map::PrimalDualMap{T}) where {T}
    return isempty(
               primal_dual_map.primal_convar_to_primal_convarcon_and_index,
           ) &&
           isempty(primal_dual_map.primal_convarcon_to_dual_con) &&
           isempty(primal_dual_map.primal_convarcon_to_dual_function) &&
           isempty(primal_dual_map.primal_var_to_dual_con) &&
           isempty(primal_dual_map.primal_con_to_dual_var_vec) &&
           isempty(primal_dual_map.primal_con_to_dual_convarcon) &&
           isempty(primal_dual_map.primal_con_to_primal_constants_vec) &&
           isempty(primal_dual_map.primal_parameter_to_dual_parameter) &&
           isempty(primal_dual_map.primal_var_in_quad_obj_to_dual_slack_var)
end

function empty!(primal_dual_map::PrimalDualMap)
    Base.empty!(primal_dual_map.primal_convar_to_primal_convarcon_and_index)
    Base.empty!(primal_dual_map.primal_convarcon_to_dual_con)
    Base.empty!(primal_dual_map.primal_convarcon_to_dual_function)
    Base.empty!(primal_dual_map.primal_var_to_dual_con)
    Base.empty!(primal_dual_map.primal_con_to_dual_var_vec)
    Base.empty!(primal_dual_map.primal_con_to_dual_convarcon)
    Base.empty!(primal_dual_map.primal_con_to_primal_constants_vec)
    Base.empty!(primal_dual_map.primal_parameter_to_dual_parameter)
    Base.empty!(primal_dual_map.primal_var_in_quad_obj_to_dual_slack_var)
    return
end

"""
    DualProblem{T,OT<:MOI.ModelLike}

Result of the `dualize` function. Contains the fields:

  * `dual_model::OT`: contaninf a optimizer or data structure with the
    `MathOptInterface` definition of the resulting dual model.

  * `primal_dual_map::PrimalDualMap{T}`: a data structure to hold information of
    how the primal and dual model are related in terms of indices
    (`VariableIndex` and `ConstraintIndex`) and other data.
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

function DualProblem{T}() where {T}
    return DualProblem{T}(DualizableModel{T}(), PrimalDualMap{T}())
end
