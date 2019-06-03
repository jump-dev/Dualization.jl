#= 
min -4x1 -3x2 -1
  s.a.
    2x1 + x2 + 1 <= 4
    x1 + 2x2 + 1 <= 4
    x1 >= 1
    x2 >= 0
=#

model = Model{Float64}()

X = MOI.add_variables(model, 2)

MOI.add_constraint(model, 
    MOI.ScalarAffineFunction(
        [MOI.ScalarAffineTerm(2.0, X[1]), MOI.ScalarAffineTerm(1.0, X[2])], 1.0),
         MOI.LessThan(4.0))

MOI.add_constraint(model, 
    MOI.ScalarAffineFunction(
        [MOI.ScalarAffineTerm(1.0, X[1]), MOI.ScalarAffineTerm(2.0, X[2])], 1.0),
         MOI.LessThan(4.0))

MOI.add_constraint(model, 
    MOI.ScalarAffineFunction(
        [MOI.ScalarAffineTerm(1.0, X[1])], 0.0),
         MOI.GreaterThan(1.0))

MOI.add_constraint(model, 
    MOI.ScalarAffineFunction(
        [MOI.ScalarAffineTerm(1.0, X[2])], 0.0),
         MOI.GreaterThan(0.0))

MOI.set(model, 
    MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(), 
    MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([-4.0, -3.0], [X[1], X[2]]), -1.0)
    )

MOI.set(model, MOI.ObjectiveSense(), MOI.MIN_SENSE)

