# Copyright (c) 2017: Guilherme Bodin, and contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

module Dualization

import LinearAlgebra
import MathOptInterface as MOI

include("structures.jl")
include("utils.jl")
include("dual_sets.jl")
include("supported.jl")
include("dual_names.jl")
include("objective_coefficients.jl")
include("add_dual_cone_constraint.jl")
include("constrained_variables.jl")
include("dual_model_variables.jl")
include("dual_equality_constraints.jl")
include("dualize.jl")
include("MOI_wrapper.jl")

end # module
