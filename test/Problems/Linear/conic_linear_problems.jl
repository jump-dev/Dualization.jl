function conic_linear1_test()
    #= 
        min -3x - 2y - 4z
    s.t.    
        x +  y +  z == 3
        y +  z == 2
        x>=0 y>=0 z>=0
    =#
    model = TestModel{Float64}()

    v = MOI.add_variables(model, 3)

    vov = MOI.VectorOfVariables(v)
    
    vc = MOI.add_constraint(model, vov, MOI.Nonnegatives(3))

    c = MOI.add_constraint(model, MOI.VectorAffineFunction(MOI.VectorAffineTerm.([1,1,1,2,2], MOI.ScalarAffineTerm.(1.0, [v;v[2];v[3]])), [-3.0,-2.0]), MOI.Zeros(2))

    MOI.set(model, MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(), MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([-3.0, -2.0, -4.0], v), 0.0))
    MOI.set(model, MOI.ObjectiveSense(), MOI.MIN_SENSE)
    
    return model
end

function conic_linear2_test()
    #= 
        min -3x - 2y - 4z
    s.t.    
        x +  y +  z == 3
        y +  z == 2
        x>=0 y>=0 z>=0
    =#
    model = TestModel{Float64}()

    v = MOI.add_variables(model, 3)

    vov = MOI.VectorOfVariables(v)

    vc = MOI.add_constraint(model, MOI.VectorAffineFunction{Float64}(vov), MOI.Nonnegatives(3))

    c = MOI.add_constraint(model, MOI.VectorAffineFunction(MOI.VectorAffineTerm.([1,1,1,2,2], MOI.ScalarAffineTerm.(1.0, [v;v[2];v[3]])), [-3.0,-2.0]), MOI.Zeros(2))

    MOI.set(model, MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(), MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([-3.0, -2.0, -4.0], v), 0.0))
    MOI.set(model, MOI.ObjectiveSense(), MOI.MIN_SENSE)
    
    return model
end

function conic_linear3_test()
    #=
        min  3x + 2y - 4z + 0s
    s.t.  
           x           -  s  == -4    (i.e. x >= -4)
                y            == -3
           x      +  z       == 12
           x free
           y <= 0
           z >= 0
           s zero
    =#
    model = TestModel{Float64}()

    x,y,z,s = MOI.add_variables(model, 4)

    MOI.set(model, MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(), MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([3.0, 2.0, -4.0], [x,y,z]), 0.0))
    MOI.set(model, MOI.ObjectiveSense(), MOI.MIN_SENSE)

    c = MOI.add_constraint(model, MOI.VectorAffineFunction(MOI.VectorAffineTerm.([1,1,2,3,3], MOI.ScalarAffineTerm.([1.0,-1.0,1.0,1.0,1.0], [x,s,y,x,z])), [4.0,3.0,-12.0]), MOI.Zeros(3))

    vov = MOI.VectorOfVariables([y])

    vc = MOI.add_constraint(model, vov, MOI.Nonpositives(1))

        # test fallback
    vz = MOI.add_constraint(model, [z], MOI.Nonnegatives(1))

    vov = MOI.VectorOfVariables([s])

    vs = MOI.add_constraint(model, vov, MOI.Zeros(1))

    return model    
end

function conic_linear4_test()
    #=
        min  3x + 2y - 4z + 0s
    s.t.  
           x           -  s  == -4    (i.e. x >= -4)
                y            == -3
           x      +  z       == 12
           x free
           y <= 0
           z >= 0
           s zero
    =#
    model = TestModel{Float64}()

    x,y,z,s = MOI.add_variables(model, 4)

    MOI.set(model, MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(), MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([3.0, 2.0, -4.0], [x,y,z]), 0.0))
    MOI.set(model, MOI.ObjectiveSense(), MOI.MIN_SENSE)

    c = MOI.add_constraint(model, MOI.VectorAffineFunction(MOI.VectorAffineTerm.([1,1,2,3,3], MOI.ScalarAffineTerm.([1.0,-1.0,1.0,1.0,1.0], [x,s,y,x,z])), [4.0,3.0,-12.0]), MOI.Zeros(3))

    vov = MOI.VectorOfVariables([y])
    vc = MOI.add_constraint(model, MOI.VectorAffineFunction{Float64}(vov), MOI.Nonpositives(1))
    
    vz = MOI.add_constraint(model, MOI.VectorAffineFunction([MOI.VectorAffineTerm(1, MOI.ScalarAffineTerm(1.0, z))], [0.]), MOI.Nonnegatives(1))

    vov = MOI.VectorOfVariables([s])
    
    vs = MOI.add_constraint(model, MOI.VectorAffineFunction{Float64}(vov), MOI.Zeros(1))

    return model    
end