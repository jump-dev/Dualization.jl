# Copyright (c) 2017: Guilherme Bodin, and contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

"""
    DualNames(;
        variable_prefix = "",
        constraint_prefix = "",
        parameter_prefix = "",
        quadratic_slack_prefix = "",
        mapping = Pair{String,String}[],
    )

A struct to control the names given to the variables and constraints of the dual
model, passed to the `dual_names` keyword argument of [`dualize`](@ref).

The name of a dual object is derived from the name of the primal object it comes
from: a dual variable is named after the primal constraint it is associated
with, and a dual constraint is named after the primal variable it is associated
with. The primal model is never modified.

By default, the primal name is prepended with the prefix of its kind. Give
`mapping` to rename instead of prefixing. Each entry `"from" => "to"` replaces
the *leading* `"from"` of a primal name with `"to"`, so the index part of a
container name is preserved: with `"affine_cons" => "α"`, the primal constraint
`affine_cons[1]` gives the dual variable `α[1]`. Entries are tried in order and
the first match is applied, so the more specific ones should come first.

The prefixes are the fallback: a primal name that matches no entry of `mapping`
is prefixed as usual.

The parameters and the quadratic slack variables cannot take the name of the
primal variable they come from, because that name is already given to a dual
constraint. So when their prefix is empty, but some other prefix or a mapping
asks for the dual model to be named, they fall back to `param_` and
`quadslack_`. A `DualNames` with no prefix and no mapping names nothing.

    DualNames(variable_prefix, constraint_prefix)
    DualNames(
        variable_prefix,
        constraint_prefix,
        parameter_prefix,
        quadratic_slack_prefix,
    )

## Example

```jldoctest
julia> using JuMP, Dualization

julia> begin
           model = Model()
           @variable(model, x)
           @constraint(model, c, x >= 1)
           @objective(model, Min, x)
           names = DualNames(;
               variable_prefix = "dual_var_",
               constraint_prefix = "dual_con_",
           )
           dual_model = dualize(model; dual_names = names)
       end;

julia> print(model)
Min x
Subject to
 c : x ≥ 1

julia> print(dual_model)
Max dual_var_c
Subject to
 dual_con_x : dual_var_c = 1
 dual_var_c ≥ 0
```

Renaming with `mapping` instead of prefixing:

```jldoctest
julia> using JuMP, Dualization

julia> begin
           model = Model()
           @variable(model, x)
           @constraint(model, c, x >= 1)
           @objective(model, Min, x)
           names = DualNames(; mapping = ["c" => "α", "x" => "β"])
           dual_model = dualize(model; dual_names = names)
       end;

julia> print(dual_model)
Max α
Subject to
 β : α = 1
 α ≥ 0
```
"""
mutable struct DualNames
    dual_variable_name_prefix::String
    dual_constraint_name_prefix::String
    parameter_name_prefix::String
    quadratic_slack_name_prefix::String
    mapping::Vector{Pair{String,String}}
end

function DualNames(;
    variable_prefix::String = "",
    constraint_prefix::String = "",
    parameter_prefix::String = "",
    quadratic_slack_prefix::String = "",
    mapping = Pair{String,String}[],
)
    return DualNames(
        variable_prefix,
        constraint_prefix,
        parameter_prefix,
        quadratic_slack_prefix,
        _to_mapping(mapping),
    )
end

# Legacy positional constructors.
function DualNames(var::String, ctr::String)
    return DualNames(; variable_prefix = var, constraint_prefix = ctr)
end

function DualNames(var::String, ctr::String, param::String, slack::String)
    return DualNames(;
        variable_prefix = var,
        constraint_prefix = ctr,
        parameter_prefix = param,
        quadratic_slack_prefix = slack,
    )
end

_to_mapping(mapping::Vector{Pair{String,String}}) = mapping

function _to_mapping(mapping)
    return Pair{String,String}[String(k) => String(v) for (k, v) in mapping]
end

const EMPTY_DUAL_NAMES = DualNames()

# `DualNames` names nothing when every prefix is empty and no renaming is asked
# for. Note that `DualNames` is mutable, so `==` would fall back to `===` and
# only the `EMPTY_DUAL_NAMES` sentinel would be considered empty.
function is_empty(dual_names::DualNames)
    return isempty(dual_names.dual_variable_name_prefix) &&
           isempty(dual_names.dual_constraint_name_prefix) &&
           isempty(dual_names.parameter_name_prefix) &&
           isempty(dual_names.quadratic_slack_name_prefix) &&
           isempty(dual_names.mapping)
end

# The four functions below return the name to give to a dual object, derived
# from the name of the primal object it comes from. Each family of dual object
# has its own function, so that the prefix is selected at the call site.
#
# A name that matches an entry of `dual_names.mapping` is rewritten instead of
# being prefixed, see `_apply_mapping`.

# Dual variable, named after the primal constraint it is associated with.
function _dual_variable_name(dual_names::DualNames, primal_name::String)
    return _mapped_or_prefixed(
        dual_names,
        dual_names.dual_variable_name_prefix,
        primal_name,
    )
end

# Dual constraint, named after the primal variable it is associated with.
function _dual_constraint_name(dual_names::DualNames, primal_name::String)
    return _mapped_or_prefixed(
        dual_names,
        dual_names.dual_constraint_name_prefix,
        primal_name,
    )
end

# Parameters and quadratic slacks need a default prefix, because they are named
# after a primal variable that also names a dual constraint, so an empty prefix
# could create duplicated names.
function _dual_parameter_name(dual_names::DualNames, primal_name::String)
    prefix = dual_names.parameter_name_prefix
    return _mapped_or_prefixed(
        dual_names,
        isempty(prefix) ? "param_" : prefix,
        primal_name,
    )
end

function _dual_quadratic_slack_name(dual_names::DualNames, primal_name::String)
    prefix = dual_names.quadratic_slack_name_prefix
    return _mapped_or_prefixed(
        dual_names,
        isempty(prefix) ? "quadslack_" : prefix,
        primal_name,
    )
end

function _mapped_or_prefixed(
    dual_names::DualNames,
    prefix::String,
    primal_name::String,
)
    renamed = _apply_mapping(dual_names.mapping, primal_name)
    if renamed !== nothing
        return renamed
    end
    return prefix * primal_name
end

# Name of the dual constraint associated with a vector of constrained
# variables. The dual object is a single constraint, while the primal side is a
# vector of variables, so a single name has to be derived from several.
#
# JuMP names the variables of `@variable(model, x[1:3] in SecondOrderCone())`
# `x[1]`, `x[2]` and `x[3]`, and leaves the name of the constraint empty. So
# when every variable is an entry of the same container, the name of that
# container is used. Otherwise there is no better option than the name of the
# first variable.
function _dual_constraint_name(
    dual_names::DualNames,
    primal_names::Vector{String},
)
    container = _container_name(primal_names)
    name = if container !== nothing
        container
    elseif isempty(primal_names)
        ""
    else
        first(primal_names)
    end
    # An unnamed primal stays unnamed in the dual, instead of getting a name
    # made of the sole prefix.
    return isempty(name) ? "" : _dual_constraint_name(dual_names, name)
end

# Return the common `x` of `["x[1]", "x[2]"]`, or `nothing` if the names are not
# all entries of the same container.
function _container_name(primal_names::Vector{String})
    if isempty(primal_names)
        return nothing
    end
    first_name = first(primal_names)
    bracket = findfirst('[', first_name)
    if bracket === nothing
        return nothing
    end
    container = first_name[1:prevind(first_name, bracket)]
    if isempty(container)
        return nothing
    end
    for name in primal_names
        if !startswith(name, container * "[") || !endswith(name, ']')
            return nothing
        end
    end
    return container
end

function _apply_mapping(
    mapping::Vector{Pair{String,String}},
    primal_name::String,
)
    for (from, to) in mapping
        if startswith(primal_name, from)
            return to * primal_name[(ncodeunits(from)+1):end]
        end
    end
    return nothing
end
