using CSDP
const CSDPOPT = with_optimizer(CSDP.Optimizer, printlevel = 0)

@testset "CSDP SDP triangle Problems" begin
    list_of_sdp_triang_problems = [     
        sdpt1_test,
        sdpt2_test,
        sdpt3_test,
        sdpt4_test
    ]
    test_strong_duality(list_of_sdp_triang_problems, CSDPOPT)
end