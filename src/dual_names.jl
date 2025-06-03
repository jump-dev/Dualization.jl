# Copyright (c) 2017: Guilherme Bodin, and contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

"""
    DualNames(dual_variable_name_prefix, dual_constraint_name_prefix)

A struct to pass the prefix of dual variables and dual constraints names to
the `dual_names` keyword argument of [`dualize`](@ref).

## Example

```jldoctest
julia> using JuMP, Dualization

julia> begin
           model = Model()
           @variable(model, x)
           @constraint(model, c, x >= 1)
           @objective(model, Min, x)
           dual_model = dualize(model; dual_names = DualNames("dual_var_", "dual_con_"))
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
"""
mutable struct DualNames
    dual_variable_name_prefix::String
    dual_constraint_name_prefix::String
    parameter_name_prefix::String
    quadratic_slack_name_prefix::String
end

DualNames() = DualNames("", "", "", "")
DualNames(var, ctr) = DualNames(var, ctr, "", "")

const EMPTY_DUAL_NAMES = DualNames()

is_empty(dual_names::DualNames) = dual_names == EMPTY_DUAL_NAMES
