# Copyright (c) 2017: Guilherme Bodin, and contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

module DualizationJuMPExt

import Dualization
import JuMP
import MathOptInterface as MOI

function Dualization.dualize(
    model::JuMP.Model,
    optimizer_constructor = nothing;
    kwargs...,
)
    mode = JuMP.mode(model)
    if mode != JuMP.AUTOMATIC
        error("Dualization does not support solvers in $(mode) mode")
    end
    dual_model = JuMP.Model()
    dual_problem = Dualization.DualProblem(JuMP.backend(dual_model))
    Dualization.dualize(JuMP.backend(model), dual_problem; kwargs...)
    _fill_obj_dict_with_variables!(dual_model)
    _fill_obj_dict_with_constraints!(dual_model)
    if optimizer_constructor !== nothing
        JuMP.set_optimizer(dual_model, optimizer_constructor)
    end
    dual_model.ext[:_Dualization_jl_PrimalDualMap] =
        dual_problem.primal_dual_map
    return dual_model
end

function _fill_obj_dict_with_variables!(model::JuMP.Model)
    list = MOI.get(model, MOI.ListOfVariableAttributesSet())
    if !(MOI.VariableName() in list)
        return
    end
    for vi in MOI.get(model, MOI.ListOfVariableIndices())
        name = MOI.get(JuMP.backend(model), MOI.VariableName(), vi)
        if !isempty(name)
            model[Symbol(name)] = JuMP.VariableRef(model, vi)
        end
    end
    return
end

function _fill_obj_dict_with_constraints!(model::JuMP.Model)
    con_types = MOI.get(model, MOI.ListOfConstraintTypesPresent())
    for (F, S) in con_types
        _fill_obj_dict_with_constraints!(model, F, S)
    end
    return
end

function _fill_obj_dict_with_constraints!(
    model::JuMP.Model,
    ::Type{F},
    ::Type{S},
) where {F,S}
    list = MOI.get(model, MOI.ListOfConstraintAttributesSet{F,S}())
    if !(MOI.ConstraintName() in list)
        return
    end
    for ci in MOI.get(JuMP.backend(model), MOI.ListOfConstraintIndices{F,S}())
        name = MOI.get(JuMP.backend(model), MOI.ConstraintName(), ci)
        if !isempty(name)
            model[Symbol(name)] = JuMP.constraint_ref_with_index(model, ci)
        end
    end
    return
end

function _get_primal_dual_map(model::JuMP.Model)
    return model.ext[:_Dualization_jl_PrimalDualMap]
end

function Dualization._get_dual_constraint(
    dual_model,
    primal_ref::JuMP.VariableRef,
)
    map = _get_primal_dual_map(dual_model)
    moi_primal_vi = JuMP.index(primal_ref)
    moi_dual_ci, idx = Dualization._get_dual_constraint(map, moi_primal_vi)
    # dual_model = nothing # TODO
    if idx === nothing
        # variables fixed at zero
        return nothing, idx
    end
    return JuMP.constraint_ref_with_index(dual_model, moi_dual_ci), idx
end

function Dualization._get_primal_constraint(
    dual_model::JuMP.Model,
    primal_vi::JuMP.VariableRef,
)
    primal_model = JuMP.owner_model(primal_vi)
    map = _get_primal_dual_map(dual_model)
    moi_primal_vi = JuMP.index(primal_vi)
    primal_ci, idx = Dualization._get_primal_constraint(map, moi_primal_vi)
    if primal_ci === nothing
        return nothing, idx
    end
    return JuMP.constraint_ref_with_index(primal_model, primal_ci), idx
end

function Dualization._get_dual_variables(
    dual_model::JuMP.Model,
    primal_ref::JuMP.ConstraintRef,
)
    map = _get_primal_dual_map(dual_model)
    moi_primal_ci = JuMP.index(primal_ref)
    moi_dual_vis = Dualization._get_dual_variables(map, moi_primal_ci)
    if moi_dual_vis === nothing
        # main constraint of a constrained variable
        return nothing
    end
    return [JuMP.VariableRef(dual_model, vi) for vi in moi_dual_vis]
end

# this is a constrained variable constraint
function Dualization._get_dual_constraint(
    dual_model::JuMP.Model,
    primal_ref::JuMP.ConstraintRef,
)
    map = _get_primal_dual_map(dual_model)
    moi_primal_ci = JuMP.index(primal_ref)
    moi_dual_ci = Dualization._get_dual_constraint(map, moi_primal_ci)
    if moi_dual_ci === nothing
        # main constraint of a constrained variable
        # or
        # primal constraint is equality
        return nothing
    end
    return JuMP.constraint_ref_with_index(dual_model, moi_dual_ci)
end

function Dualization._get_dual_parameter(
    dual_model::JuMP.Model,
    primal_ref::JuMP.VariableRef,
)
    map = _get_primal_dual_map(dual_model)
    moi_primal_vi = JuMP.index(primal_ref)
    moi_dual_vi = Dualization._get_dual_parameter(map, moi_primal_vi)
    # the above line might error
    return JuMP.VariableRef(dual_model, moi_dual_vi)
end

end # module DualizationJuMPExt
