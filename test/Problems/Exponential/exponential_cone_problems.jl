function exp1_test()    
    #=
        min x + y + z
    s.t.  
        y e^(x/y) <= z, y > 0 (i.e (x, y, z) are in the exponential primal cone)
        x == 1
        y == 2
    =#
    model = TestModel{Float64}()
    
    v = MOI.add_variables(model, 3)
    vov = MOI.VectorOfVariables(v)

    vc = MOI.add_constraint(model, vov, MOI.ExponentialCone())

    cx = MOI.add_constraint(model, MOI.ScalarAffineFunction([MOI.ScalarAffineTerm(1.0, v[1])], 0.), MOI.EqualTo(1.))
    cy = MOI.add_constraint(model, MOI.ScalarAffineFunction([MOI.ScalarAffineTerm(1.0, v[2])], 0.), MOI.EqualTo(2.))

    MOI.set(model, MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(), MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.(1.0, v), 0.0))
    MOI.set(model, MOI.ObjectiveSense(), MOI.MIN_SENSE)

    return model
end

function exp2_test()    
    #=
        min x + y + z
    s.t.  
        y e^(x/y) <= z, y > 0 (i.e (x, y, z) are in the exponential primal cone)
        x == 1
        y == 2
    =#
    model = TestModel{Float64}()
    
    v = MOI.add_variables(model, 3)
    vov = MOI.VectorOfVariables(v)

    vc = MOI.add_constraint(model, MOI.VectorAffineFunction{Float64}(vov), MOI.ExponentialCone())

    cx = MOI.add_constraint(model, MOI.ScalarAffineFunction([MOI.ScalarAffineTerm(1.0, v[1])], 0.), MOI.EqualTo(1.))
    cy = MOI.add_constraint(model, MOI.ScalarAffineFunction([MOI.ScalarAffineTerm(1.0, v[2])], 0.), MOI.EqualTo(2.))

    MOI.set(model, MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(), MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.(1.0, v), 0.0))
    MOI.set(model, MOI.ObjectiveSense(), MOI.MIN_SENSE)

    return model
end