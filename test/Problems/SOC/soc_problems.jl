function soc1_test()
    #=
        max 0x + 1y + 1z
    s.t.
        x == 1
        x >= ||(y,z)||
    =#
    model = TestModel{Float64}()

    x,y,z = MOI.add_variables(model, 3)

    MOI.set(model, MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(), MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([1.0,1.0], [y,z]), 0.0))
    MOI.set(model, MOI.ObjectiveSense(), MOI.MAX_SENSE)

    ceq = MOI.add_constraint(model, 
            MOI.VectorAffineFunction(
                [MOI.VectorAffineTerm(1, MOI.ScalarAffineTerm(1.0, x))], [-1.0]),  
                 MOI.Zeros(1))

    vov = MOI.VectorOfVariables([x,y,z])

    csoc = MOI.add_constraint(model, vov, MOI.SecondOrderCone(3))

    return model
end

function soc2_test()
    #=
        max 0x + 1y + 1z
      s.t.
        x == 1
        x >= ||(y,z)||
    =#
    model = TestModel{Float64}()

    x,y,z = MOI.add_variables(model, 3)

    MOI.set(model, MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(), MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([1.0,1.0], [y,z]), 0.0))
    MOI.set(model, MOI.ObjectiveSense(), MOI.MAX_SENSE)

    ceq = MOI.add_constraint(model, 
            MOI.VectorAffineFunction(
                [MOI.VectorAffineTerm(1, MOI.ScalarAffineTerm(1.0, x))], [-1.0]),  
                 MOI.Zeros(1))

    vov = MOI.VectorOfVariables([x,y,z])
    
    csoc = MOI.add_constraint(model, MOI.VectorAffineFunction{Float64}(vov), MOI.SecondOrderCone(3))

    return model
end

function soc3_test()
    #=
        min  x
    s.t.
        y ≥ 1/√2
        x² + y² ≤ 1

    in conic form:
        min  x
    s.t.
        -1/√2 + y ∈ R₊
        1 - t ∈ {0}
        (t,x,y) ∈ SOC₃
    =#
    model = TestModel{Float64}()

    x,y,t = MOI.add_variables(model, 3)

    MOI.set(model, MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(), MOI.ScalarAffineFunction([MOI.ScalarAffineTerm(1.0, x)], 0.0))
    MOI.set(model, MOI.ObjectiveSense(), MOI.MIN_SENSE)

    cnon = MOI.add_constraint(model, MOI.VectorAffineFunction([MOI.VectorAffineTerm(1, MOI.ScalarAffineTerm(1.0, y))], [-1/√2]), MOI.Nonnegatives(1))
    ceq = MOI.add_constraint(model, MOI.VectorAffineFunction([MOI.VectorAffineTerm(1, MOI.ScalarAffineTerm(-1.0, t))], [1.0]), MOI.Zeros(1))
    csoc = MOI.add_constraint(model, MOI.VectorAffineFunction(MOI.VectorAffineTerm.([1,2,3], MOI.ScalarAffineTerm.(1.0, [t,x,y])), zeros(3)), MOI.SecondOrderCone(3))

    return model
end

function soc4_test()
    #=
        min  x
    s.t. 
        y ≥ 1/√2
        x² + y² ≤ 1

    in conic form:
        min  x
    s.t.
        1/√2 - y ∈ R₋
        1 - t ∈ {0}
        (t,x,y) ∈ SOC₃
    =#
    model = TestModel{Float64}()

    x,y,t = MOI.add_variables(model, 3)

    MOI.set(model, MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(), MOI.ScalarAffineFunction([MOI.ScalarAffineTerm(1.0, x)], 0.0))
    MOI.set(model, MOI.ObjectiveSense(), MOI.MIN_SENSE)

    cnon = MOI.add_constraint(model, MOI.VectorAffineFunction([MOI.VectorAffineTerm(1, MOI.ScalarAffineTerm(-1.0, y))], [1/√2]), MOI.Nonpositives(1))

    ceq = MOI.add_constraint(model, MOI.VectorAffineFunction([MOI.VectorAffineTerm(1, MOI.ScalarAffineTerm(-1.0, t))], [1.0]), MOI.Zeros(1))
    csoc = MOI.add_constraint(model, MOI.VectorAffineFunction(MOI.VectorAffineTerm.([1,2,3], MOI.ScalarAffineTerm.(1.0, [t,x,y])), zeros(3)), MOI.SecondOrderCone(3))

    return model
end

function soc5_test()
    #= 
        min x
    s.t.
        y ≥ 2
        x ≤ 1
        |y| ≤ x

    in conic form:
        min x
    s.t.
        -2 + y ∈ R₊
        -1 + x ∈ R₋
        (x,y) ∈ SOC₂
    =#
    model = TestModel{Float64}()

    x,y = MOI.add_variables(model, 2)

    MOI.add_constraint(model, MOI.VectorAffineFunction([MOI.VectorAffineTerm(1, MOI.ScalarAffineTerm(1.0, y))], [-2.0]), MOI.Nonnegatives(1))
    MOI.add_constraint(model, MOI.VectorAffineFunction([MOI.VectorAffineTerm(1, MOI.ScalarAffineTerm(1.0, x))], [-1.0]), MOI.Nonpositives(1))
    MOI.add_constraint(model, MOI.VectorAffineFunction(MOI.VectorAffineTerm.([1,2], MOI.ScalarAffineTerm.(1.0, [x,y])), zeros(2)), MOI.SecondOrderCone(2))

    MOI.set(model, MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(), MOI.ScalarAffineFunction([MOI.ScalarAffineTerm(1.0, x)], 0.0))
    MOI.set(model, MOI.ObjectiveSense(), MOI.MIN_SENSE)

    return model
end

function soc6_test()
    #= 
        min 0x[1] - 2x[2] - 1x[3]
    s.t.
        x[1]                    == 1 
            x[2]   - x[4]       == 0 
               x[3]      - x[5] == 0 
        x[1] >= ||(x[4],x[5])||                  

    in conic form:
        min  c^Tx
    s.t.
        Ax + b ∈ {0}₃
        (x[1],x[4],x[5]) ∈ SOC₃
    =#
    model = TestModel{Float64}()

    x = MOI.add_variables(model, 5)

    c1 = MOI.add_constraint(model, MOI.VectorAffineFunction(MOI.VectorAffineTerm.([1,2,3,2,3], MOI.ScalarAffineTerm.([1.0,1.0,1.0,-1.0,-1.0], x)),[-1.0, 0.0, 0.0]), MOI.Zeros(3))
    c2 = MOI.add_constraint(model, MOI.VectorOfVariables([x[1],x[4],x[5]]), MOI.SecondOrderCone(3))

    MOI.set(model, MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(), MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([0.0,-2.0,-1.0, 0.0, 0.0], x), 0.0))
    MOI.set(model, MOI.ObjectiveSense(), MOI.MIN_SENSE)

    return model
end
