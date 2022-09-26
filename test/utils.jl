# Copyright (c) 2017: Guilherme Bodin, and contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

function dual_model_and_map(primal_model::MOI.ModelLike)
    dual = Dualization.dualize(primal_model)
    return dual.dual_model, dual.primal_dual_map
end
