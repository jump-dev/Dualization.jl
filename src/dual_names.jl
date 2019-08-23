export DualNames
"""
    DualNames

DualNames is a struct to pass the prefix of dual variables and dual constraints names.
See more on naming the variables.
"""
mutable struct DualNames
    dual_variable_name_prefix::String
    dual_constraint_name_prefix::String
end