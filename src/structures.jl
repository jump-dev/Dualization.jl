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
    PrimalVariableData{T}

Data structure used in `PrimalDualMap` to hold information about primal
variables and their dual counterparts.

  * `primal_constrained_variable_constraint::Union{Nothing,MOI.ConstraintIndex}`:
    if primal variable is chosen to be a constrained variable by
    Dualization.jl, then this value is different from nothing.

  * `primal_constrained_variable_index::Int`: if variable is a scalar
    constrained variable then it is 0. If variable is not a constrained variable
    then it is -1. If variable is part of a vector constrained variable, then
    this is the position in that vector.

  * `dual_constraint::Union{Nothing,MOI.ConstraintIndex}`: dual constraint
    associated with the variable. If the variable is not constrained then the
    set is EqualTo{T}(zero(T)). If the variable is a constrained variable then
    the set is the dual set of the constrained variable set. If the dual set is
    `Reals` then the field is kept as `nothing` as teh constraint is not added.

  * `dual_function::Union{Nothing,MOI.ScalarAffineFunction{T}}`: if the
    constrained variable is `VectorOfVariables`-in-`Zeros` or
    `VariableIndex`-in-`EqualTo(zero(T))` then the dual is `func`-in-`Reals`,
    which is "irrelevant" to the model. But this information is cached for
    completeness of the `DualOptimizer` for `get`ting `ConstraintDuals`.

To got from the constrained variable constraint to the primal variable, use the
`primal_constrained_variables` field of `PrimalDualMap`.

See also `PrimalDualMap` and `PrimalConstraintData`.
"""
struct PrimalVariableData{T}
    primal_constrained_variable_constraint::Union{Nothing,MOI.ConstraintIndex}
    primal_constrained_variable_index::Int
    dual_constraint::Union{Nothing,MOI.ConstraintIndex}
    dual_function::Union{Nothing,MOI.ScalarAffineFunction{T}}
end

# constraints of primal constrained variables are not here
"""
    PrimalConstraintData{T}

Data structure used in `PrimalDualMap` to hold information about primal
constraints and their dual counterparts.

Constraint indices for constrained variables are not in this structure. They are
added in the `primal_constrained_variables` field of `PrimalDualMap`.

  * `primal_set_constants::Vector{T}`: a vector of primal set constants that are
    used in MOI getters. This is used to get the primal constants of the primal
    constraints.

  * `dual_variables::Vector{MOI.VariableIndex}`: vector of dual variables. If
    primal constraint is scalar then, the vector has length = 1.

  * `dual_constrained_variable_constraint::Union{Nothing,MOI.ConstraintIndex}`:
    if primal set is `EqualTo` or `Zeros`, then the dual constraint is `Reals`
    then the dual variable is free (no constraint in the dual model).
"""
struct PrimalConstraintData{T}
    primal_set_constants::Vector{T}
    dual_variables::Vector{MOI.VariableIndex}
    dual_constrained_variable_constraint::Union{Nothing,MOI.ConstraintIndex}
end

"""
    PrimalDualMap{T}

Maps information from all structures of the primal to the dual model.

Main maps:

  * `primal_variable_data::Dict{MOI.VariableIndex,Dualization.PrimalVariableData{T}}`:
    maps primal variable indices to their data. The data is a structure that
    contains information about the primal variable and its dual counterpart.
    In particular, it contains the primal constrained variable constraint index,
    the primal constrained variable index, the dual constraint index and the
    primal function for the case of constraints that are not added in the dual.

  * `primal_constraint_data::Dict{MOI.ConstraintIndex,Dualization.PrimalConstraintData{T}}`:
    maps primal constraint indices to their data. The data is a structure that
    contains information about the primal constraint and its dual counterpart.
    In particular, it contains the primal set constants, the dual variables and
    the dual constrained variable constraint index.

  * `primal_constrained_variables::Dict{MOI.ConstraintIndex,Vector{MOI.VariableIndex}}`:
    maps primal constrained variable constraint indices to their primal
    constrained variables.

Addtional maps

  * `primal_parameter_to_dual_parameter::Dict{MOI.VariableIndex,MOI.VariableIndex}`:
    maps parameters in the primal model to parameters in the dual model.

  * `primal_var_in_quad_obj_to_dual_slack_var::Dict{MOI.VariableIndex,MOI.VariableIndex}`:
    maps primal variables (that appear in quadratic objective terms) to dual
    "slack" variables. These primal variables might appear in other maps.
"""
mutable struct PrimalDualMap{T}
    primal_variable_data::Dict{MOI.VariableIndex,PrimalVariableData{T}}
    primal_constraint_data::Dict{MOI.ConstraintIndex,PrimalConstraintData{T}}
    primal_constrained_variables::Dict{
        MOI.ConstraintIndex,
        Vector{MOI.VariableIndex},
    }
    primal_parameter_to_dual_parameter::Dict{
        MOI.VariableIndex,
        MOI.VariableIndex,
    }
    primal_var_in_quad_obj_to_dual_slack_var::Dict{
        MOI.VariableIndex,
        MOI.VariableIndex,
    }
    function PrimalDualMap{T}() where {T}
        return new(
            Dict{MOI.VariableIndex,PrimalVariableData{T}}(),
            Dict{MOI.ConstraintIndex,PrimalConstraintData{T}}(),
            Dict{MOI.ConstraintIndex,Vector{MOI.VariableIndex}}(),
            #
            Dict{MOI.VariableIndex,MOI.VariableIndex}(),
            Dict{MOI.VariableIndex,MOI.VariableIndex}(),
        )
    end
end

function _get_dual_constraint(m::PrimalDualMap, vi::MOI.VariableIndex)
    data = m.primal_variable_data[vi]
    return data.dual_constraint, data.primal_constrained_variable_index
end

function _get_primal_constraint(m::PrimalDualMap, vi::MOI.VariableIndex)
    data = m.primal_variable_data[vi]
    return data.primal_constrained_variable_constraint,
    data.primal_constrained_variable_index
end

function _get_dual_variables(m::PrimalDualMap, ci::MOI.ConstraintIndex)
    if !haskey(m.primal_constrained_variables, ci)
        # if the constraint is a constrained variable, then the dual variable
        # is the first element of the vector of dual variables
        return m.primal_constraint_data[ci].dual_variables
    end
    return nothing # ci is a constrained variable constraint
end

function _get_dual_constraint(m::PrimalDualMap, ci::MOI.ConstraintIndex)
    if !haskey(m.primal_constrained_variables, ci)
        # if the constraint is a constrained variable, then the dual variable
        # is the first element of the vector of dual variables
        return m.primal_constraint_data[ci].dual_constrained_variable_constraint
    end
    return nothing # ci is a constrained variable constraint
end

function _get_dual_parameter(m::PrimalDualMap, vi::MOI.VariableIndex)
    return m.primal_parameter_to_dual_parameter[vi]
end

function Base.getproperty(m::PrimalDualMap{T}, name::Symbol) where {T}
    if name === :constrained_var_idx
        error(
            """
            Field `constrained_var_idx` was removed.
            From a primal variable index, use the field `primal_variable_data`.
            In the data structures returned the constraint can be found at
            `primal_constrained_variable_constraint` and the index at
            `primal_constrained_variable_index`.
            """,
        )
    elseif name === :constrained_var_dual
        error(
            """
            Field `constrained_var_dual` was removed.
            From a primal constrained variable constraint index, use the field
            `primal_constrained_variables` to obtain the primal varaibles.
            Then, from the primal variable index, use the field
            `primal_variable_data`.
            In the data structures returned, the constraint can be found at
            `dual_constraint`.
            """,
        )
    elseif name === :primal_var_dual_con
        error(
            """
            Field `primal_var_dual_con` was removed.
            From a primal variable index, use the field `primal_variable_data`.
            In the data structures returned, the constraint can be found at
            `dual_constraint`.
            """,
        )
    elseif name === :primal_con_dual_var
        error(
            """
            Field `primal_con_dual_var` was removed.
            From a primal constraint index, use the field
            `primal_constraint_data`.
            In the data structure returned, the dual variables can be found at
            `dual_varaibles`.
            """,
        )
    elseif name === :primal_con_dual_con
        error(
            """
            Field `primal_con_dual_con` was removed.
            From a primal constraint index, use the field
            `primal_constraint_data`.
            In the data structure returned, the dual constrained variable
            constraint can be found at `dual_constrained_variable_constraint`.
            """,
        )
    elseif name === :primal_con_constants
        error(
            """
            Field `primal_con_constants` was removed.
            From a primal constraint index, use the field `primal_constraint_data`.
            In the data structure returned, the primal set constants can be found
            at `primal_set_constants`.
            """,
        )
    elseif name === :constrained_var_zero
        error(
            """
            Field `constrained_var_zero` was removed.
            From a primal constrained variable constraint index, use the field
            `primal_constrained_variables` to obtain the primal varaibles.
            Then, from the primal variable index, use the field
            `primal_variable_data`.
            In the data structure returned, the primal function can be found at
            `dual_function`.
            """,
        )
    elseif name === :primal_parameter
        @warn "primal_parameter field is deprecated, use primal_parameter_to_dual_parameter instead"
        return getfield(m, :primal_parameter_to_dual_parameter)
    elseif name === :primal_var_dual_quad_slack
        @warn "primal_var_dual_quad_slack field is deprecated, use primal_var_in_quad_obj_to_dual_slack_var instead"
        return getfield(m, :primal_var_in_quad_obj_to_dual_slack_var)
    else
        return getfield(m, name)
    end
end

function is_empty(primal_dual_map::PrimalDualMap{T}) where {T}
    return isempty(primal_dual_map.primal_variable_data) &&
           isempty(primal_dual_map.primal_constraint_data) &&
           isempty(primal_dual_map.primal_constrained_variables) &&
           #
           isempty(primal_dual_map.primal_parameter_to_dual_parameter) &&
           isempty(primal_dual_map.primal_var_in_quad_obj_to_dual_slack_var)
end

function empty!(primal_dual_map::PrimalDualMap)
    Base.empty!(primal_dual_map.primal_variable_data)
    Base.empty!(primal_dual_map.primal_constraint_data)
    Base.empty!(primal_dual_map.primal_constrained_variables)
    #
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
