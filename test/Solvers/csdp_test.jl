# Copyright (c) 2017: Guilherme Bodin, and contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

using CSDP
const CSDP_PRIMAL_FACTORY =
    MOI.OptimizerWithAttributes(CSDP.Optimizer, MOI.Silent() => true)
const CSDP_DUAL_FACTORY = dual_optimizer(CSDP_PRIMAL_FACTORY)
const CSDP_PRIMAL_OPT = MOI.instantiate(CSDP_PRIMAL_FACTORY)
const CSDP_DUAL_OPT = MOI.instantiate(CSDP_DUAL_FACTORY)

push!(primal_conic_factory, CSDP_PRIMAL_FACTORY)
push!(dual_conic_factory, CSDP_DUAL_FACTORY)
push!(dual_conic_optimizer, CSDP_DUAL_OPT)
push!(primal_conic_optimizer, CSDP_PRIMAL_OPT)

@testset "CSDP SDP triangle Problems" begin
    list_of_sdp_triang_problems = [
        # sdpt1_test, # CSDP is returning SLOW_PROGRESS
        # sdpt2_test, # CSDP is returning SLOW_PROGRESS
        sdpt3_test,
        sdpt4_test,
    ]
    test_strong_duality(list_of_sdp_triang_problems, CSDP_PRIMAL_FACTORY)
end
