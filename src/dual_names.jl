# Copyright (c) 2017: Guilherme Bodin, and contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

export DualNames

"""
    DualNames

DualNames is a struct to pass the prefix of dual variables and dual constraints
names.

See more on naming the variables.
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
