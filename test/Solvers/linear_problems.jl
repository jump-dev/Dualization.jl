#= 
Name: lp1

Model: 
min -4x_2 - 1
st
x_1 + 2x_2 <= 3
x_1 >= 1
x_1 >= 3
=#
primal_model_lp1 = TestModel{Float64}()

X = MOI.add_variables(primal_model_lp1, 2)

MOI.add_constraint(primal_model_lp1, 
    MOI.ScalarAffineFunction(
        [MOI.ScalarAffineTerm(1.0, X[1]), MOI.ScalarAffineTerm(2.0, X[2])], 0.0),
        MOI.LessThan(3.0))

MOI.add_constraint(primal_model_lp1, 
    MOI.SingleVariable(X[1]),
        MOI.GreaterThan(1.0))

MOI.add_constraint(primal_model_lp1, 
    MOI.SingleVariable(X[1]),
        MOI.GreaterThan(3.0))

MOI.set(primal_model_lp1, 
    MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(), 
    MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([-4.0], [X[2]]), -1.0)
    )

MOI.set(primal_model_lp1, MOI.ObjectiveSense(), MOI.MIN_SENSE)

dual_model_lp1 = dualize(primal_model_lp1)





#= 
Name: lp2

Model: 
min -4x1 -3x2 -1
  s.a.
    2x1 + x2 + 1 <= 4
    x1 + 2x2 + 1 <= 4
    x1 >= 1
    x2 >= 0
=#
primal_model_lp2 = TestModel{Float64}()

X = MOI.add_variables(primal_model_lp2, 2)

MOI.add_constraint(primal_model_lp2, 
    MOI.ScalarAffineFunction(
        [MOI.ScalarAffineTerm(2.0, X[1]), MOI.ScalarAffineTerm(1.0, X[2])], 1.0),
         MOI.LessThan(4.0))

MOI.add_constraint(primal_model_lp2, 
    MOI.ScalarAffineFunction(
        [MOI.ScalarAffineTerm(1.0, X[1]), MOI.ScalarAffineTerm(2.0, X[2])], 1.0),
         MOI.LessThan(4.0))

MOI.add_constraint(primal_model_lp2, 
    MOI.ScalarAffineFunction(
        [MOI.ScalarAffineTerm(1.0, X[1])], 0.0),
         MOI.GreaterThan(1.0))

MOI.add_constraint(primal_model_lp2, 
    MOI.ScalarAffineFunction(
        [MOI.ScalarAffineTerm(1.0, X[2])], 0.0),
         MOI.GreaterThan(0.0))

MOI.set(primal_model_lp2, 
    MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(), 
    MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([-4.0, -3.0], [X[1], X[2]]), -1.0)
    )

MOI.set(primal_model_lp2, MOI.ObjectiveSense(), MOI.MIN_SENSE)

dual_model_lp2 = dualize(primal_model_lp2)





#= 
Name: lp3

Model: 
min -4x1 -3x2 -1
  s.a.
    2x1 + x2 + 1 <= 4
    x1 + 2x2 + 1 <= 4
    x1 >= 1
    x2 >= 0
=#
primal_model_lp3 = TestModel{Float64}()

X = MOI.add_variables(primal_model_lp3, 2)

MOI.add_constraint(primal_model_lp3, 
    MOI.ScalarAffineFunction(
        [MOI.ScalarAffineTerm(2.0, X[1]), MOI.ScalarAffineTerm(1.0, X[2])], 1.0),
         MOI.LessThan(4.0))

MOI.add_constraint(primal_model_lp3, 
    MOI.ScalarAffineFunction(
        [MOI.ScalarAffineTerm(1.0, X[1]), MOI.ScalarAffineTerm(2.0, X[2])], 1.0),
         MOI.LessThan(4.0))

MOI.add_constraint(primal_model_lp3, 
    MOI.SingleVariable(X[1]),
         MOI.GreaterThan(1.0))

MOI.add_constraint(primal_model_lp3, 
    MOI.SingleVariable(X[2]),
         MOI.GreaterThan(0.0))

MOI.set(primal_model_lp3, 
    MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(), 
    MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([-4.0, -3.0], [X[1], X[2]]), -1.0)
    )

MOI.set(primal_model_lp3, MOI.ObjectiveSense(), MOI.MIN_SENSE)

dual_model_lp3 = dualize(primal_model_lp3)





#= 
Name: lp3

Model: 
max 4x1 3x2 
  s.a.
    x1 >= 1
    x2 >= 0
=#
primal_model_lp4 = TestModel{Float64}()

X = MOI.add_variables(primal_model_lp4, 2)

MOI.add_constraint(primal_model_lp4, 
    MOI.SingleVariable(X[1]),
         MOI.GreaterThan(1.0))

MOI.add_constraint(primal_model_lp4, 
    MOI.SingleVariable(X[2]),
         MOI.GreaterThan(0.0))

MOI.set(primal_model_lp4, 
    MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(), 
    MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([4.0, 3.0], [X[1], X[2]]), 0.0)
    )

MOI.set(primal_model_lp4, MOI.ObjectiveSense(), MOI.MAX_SENSE)

dual_model_lp4 = dualize(primal_model_lp4)





#= 
Name: lp3

Model: 
min -4x1 -3x2 -1
  s.a.
    2x1 + x2 + 1 == 4
    x1 + 2x2 + 1 == 4
    x1 >= 1
    x2 == 0
=#
primal_model_lp5= TestModel{Float64}()

X = MOI.add_variables(primal_model_lp5, 2)

MOI.add_constraint(primal_model_lp5, 
    MOI.ScalarAffineFunction(
        [MOI.ScalarAffineTerm(2.0, X[1]), MOI.ScalarAffineTerm(1.0, X[2])], 1.0),
         MOI.EqualTo(4.0))

MOI.add_constraint(primal_model_lp5, 
    MOI.ScalarAffineFunction(
        [MOI.ScalarAffineTerm(1.0, X[1]), MOI.ScalarAffineTerm(2.0, X[2])], 1.0),
         MOI.EqualTo(4.0))

MOI.add_constraint(primal_model_lp5, 
    MOI.SingleVariable(X[1]),
         MOI.GreaterThan(1.0))

MOI.add_constraint(primal_model_lp5, 
    MOI.SingleVariable(X[2]),
         MOI.EqualTo(0.0))

MOI.set(primal_model_lp5, 
    MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(), 
    MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([-4.0, -3.0], [X[1], X[2]]), -1.0)
    )

MOI.set(primal_model_lp5, MOI.ObjectiveSense(), MOI.MIN_SENSE)

dual_model_lp5 = dualize(primal_model_lp5)





#= 
Name: lp3

Model: 
min -4x1 -3x2 -1
  s.a.
    2x1 + x2 - 3 <= 0
    x1 + 2x2 - 3 <= 0
    x1 >= 1
    x2 >= 0
=#
primal_model_lp6= TestModel{Float64}()

X = MOI.add_variables(primal_model_lp6, 2)

g = MOI.VectorAffineFunction(
            MOI.VectorAffineTerm.([1, 1, 2, 2], MOI.ScalarAffineTerm.([2.0, 1.0, 1.0, 2.0], [X; X])),
            [-3.0, -3.0])

MOI.add_constraint(primal_model_lp6, g, MOI.Nonpositives(2))


MOI.add_constraint(primal_model_lp6, 
    MOI.SingleVariable(X[1]),
         MOI.GreaterThan(1.0))

MOI.add_constraint(primal_model_lp6, 
    MOI.SingleVariable(X[2]),
         MOI.GreaterThan(0.0))

MOI.set(primal_model_lp6, 
    MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(), 
    MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([-4.0, -3.0], [X[1], X[2]]), -1.0)
    )

MOI.set(primal_model_lp6, MOI.ObjectiveSense(), MOI.MIN_SENSE)

dual_model_lp6 = dualize(primal_model_lp6)





#= 
Name: lp3

Model: 
min -4x1 -3x2 -1
  s.a.
    2x1 + x2 - 3 <= 0
    x1 + 2x2 - 3 <= 0
    x1 >= 1
    x2 >= 0
=#
primal_model_lp7= TestModel{Int64}()

X = MOI.add_variables(primal_model_lp7, 2)

c1 = MOI.VectorAffineFunction(
            MOI.VectorAffineTerm.([1, 1, 2, 2], MOI.ScalarAffineTerm.([2, 1, 1, 2], [X; X])),
            [-3, -3])

MOI.add_constraint(primal_model_lp7, c1, MOI.Nonpositives(2))

c2 = MOI.VectorAffineFunction(
            MOI.VectorAffineTerm.([1, 2], MOI.ScalarAffineTerm.([1, 1], X)),
            [1, 0])

MOI.add_constraint(primal_model_lp7, c2, MOI.Nonnegatives(2))

MOI.set(primal_model_lp7, 
    MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(), 
    MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([-4, -3], X), -1)
    )

MOI.set(primal_model_lp7, MOI.ObjectiveSense(), MOI.MIN_SENSE)

dual_model_lp7 = dualize(primal_model_lp7)




# TODO 
# 3 random LPs