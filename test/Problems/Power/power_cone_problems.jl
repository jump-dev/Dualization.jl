function pow1_test()
    #=
        max z
    s.t.
        x^0.9 * y^(0.1) >= |z| (i.e (x, y, z) are in the 3d power cone with a=0.9)
        x == 2
        y == 1
    =#
    model = TestModel{Float64}()

    a = 0.9
    v = MOI.add_variables(model, 3)
    @test MOI.get(model, MOI.NumberOfVariables()) == 3

    vov = MOI.VectorOfVariables(v)

    vc = MOI.add_constraint(model, vov, MOI.PowerCone(a));
   
    cx = MOI.add_constraint(model, MOI.ScalarAffineFunction([MOI.ScalarAffineTerm(1.0, v[1])], 0.), MOI.EqualTo(2.))
    cy = MOI.add_constraint(model, MOI.ScalarAffineFunction([MOI.ScalarAffineTerm(1.0, v[2])], 0.), MOI.EqualTo(1.))

    MOI.set(model, MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(), MOI.ScalarAffineFunction([MOI.ScalarAffineTerm(1.0, v[3])], 0.0))
    MOI.set(model, MOI.ObjectiveSense(), MOI.MAX_SENSE)

    return model
end

function pow2_test()
    #=
        max z
    s.t.
        x^0.9 * y^(0.1) >= |z| (i.e (x, y, z) are in the 3d power cone with a=0.9)
        x == 2
        y == 1
    =#
    a = 0.9
    model = TestModel{Float64}()
    v = MOI.add_variables(model, 3)
    @test MOI.get(model, MOI.NumberOfVariables()) == 3

    vov = MOI.VectorOfVariables(v)

    vc = MOI.add_constraint(model, MOI.VectorAffineFunction{Float64}(vov), MOI.PowerCone(a))

    cx = MOI.add_constraint(model, MOI.ScalarAffineFunction([MOI.ScalarAffineTerm(1.0, v[1])], 0.), MOI.EqualTo(2.))
    cy = MOI.add_constraint(model, MOI.ScalarAffineFunction([MOI.ScalarAffineTerm(1.0, v[2])], 0.), MOI.EqualTo(1.))

    MOI.set(model, MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(), MOI.ScalarAffineFunction([MOI.ScalarAffineTerm(1.0, v[3])], 0.0))
    MOI.set(model, MOI.ObjectiveSense(), MOI.MAX_SENSE)

    return model
end
    