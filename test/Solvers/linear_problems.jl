#= 
Name: lp1

Model: 


Result: 
X[1] = 
X[2] = 
objective_value = 
=#
primal_model_lp1 = Model{Float64}()

X = MOI.add_variables(primal_model_lp1, 2)

MOI.add_constraint(primal_model_lp1, 
    MOI.ScalarAffineFunction(
        [MOI.ScalarAffineTerm(1.0, X[1]), MOI.ScalarAffineTerm(2.0, X[2])], 1.0),
        MOI.LessThan(4.0))

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





# #= 
# Name: lp1

# Model: 


# Result: 
# X[1] = 
# X[2] = 
# objective_value = 
# =#
# primal_model_lp1 = Model{Float64}()

# X = MOI.add_variables(primal_model_lp1, 2)

# MOI.add_constraint(primal_model_lp1, 
#     MOI.ScalarAffineFunction(
#         [MOI.ScalarAffineTerm(1.0, X[1]), MOI.ScalarAffineTerm(2.0, X[2])], 1.0),
#         MOI.LessThan(4.0))

# MOI.add_constraint(primal_model_lp1, 
#     MOI.SingleVariable(X[1]),
#         MOI.GreaterThan(1.0))

# MOI.add_constraint(primal_model_lp1, 
#     MOI.SingleVariable(X[1]),
#         MOI.GreaterThan(3.0))

# MOI.set(primal_model_lp1, 
#     MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(), 
#     MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([-4.0], [X[2]]), -1.0)
#     )

# MOI.set(primal_model_lp1, MOI.ObjectiveSense(), MOI.MIN_SENSE)

# dual_model_lp1 = dualize(primal_model_lp1)





# #= 
# Name: lp1

# Model: 


# Result: 
# X[1] = 
# X[2] = 
# objective_value = 
# =#
# primal_model_lp1 = Model{Float64}()

# X = MOI.add_variables(primal_model_lp1, 2)

# MOI.add_constraint(primal_model_lp1, 
#     MOI.ScalarAffineFunction(
#         [MOI.ScalarAffineTerm(1.0, X[1]), MOI.ScalarAffineTerm(2.0, X[2])], 1.0),
#         MOI.LessThan(4.0))

# MOI.add_constraint(primal_model_lp1, 
#     MOI.SingleVariable(X[1]),
#         MOI.GreaterThan(1.0))

# MOI.add_constraint(primal_model_lp1, 
#     MOI.SingleVariable(X[1]),
#         MOI.GreaterThan(3.0))

# MOI.set(primal_model_lp1, 
#     MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(), 
#     MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([-4.0], [X[2]]), -1.0)
#     )

# MOI.set(primal_model_lp1, MOI.ObjectiveSense(), MOI.MIN_SENSE)

# dual_model_lp1 = dualize(primal_model_lp1)





# #= 
# Name: lp1

# Model: 


# Result: 
# X[1] = 
# X[2] = 
# objective_value = 
# =#
# primal_model_lp1 = Model{Float64}()

# X = MOI.add_variables(primal_model_lp1, 2)

# MOI.add_constraint(primal_model_lp1, 
#     MOI.ScalarAffineFunction(
#         [MOI.ScalarAffineTerm(1.0, X[1]), MOI.ScalarAffineTerm(2.0, X[2])], 1.0),
#         MOI.LessThan(4.0))

# MOI.add_constraint(primal_model_lp1, 
#     MOI.SingleVariable(X[1]),
#         MOI.GreaterThan(1.0))

# MOI.add_constraint(primal_model_lp1, 
#     MOI.SingleVariable(X[1]),
#         MOI.GreaterThan(3.0))

# MOI.set(primal_model_lp1, 
#     MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(), 
#     MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([-4.0], [X[2]]), -1.0)
#     )

# MOI.set(primal_model_lp1, MOI.ObjectiveSense(), MOI.MIN_SENSE)

# dual_model_lp1 = dualize(primal_model_lp1)





# #= 
# Name: lp1

# Model: 


# Result: 
# X[1] = 
# X[2] = 
# objective_value = 
# =#
# primal_model_lp1 = Model{Float64}()

# X = MOI.add_variables(primal_model_lp1, 2)

# MOI.add_constraint(primal_model_lp1, 
#     MOI.ScalarAffineFunction(
#         [MOI.ScalarAffineTerm(1.0, X[1]), MOI.ScalarAffineTerm(2.0, X[2])], 1.0),
#         MOI.LessThan(4.0))

# MOI.add_constraint(primal_model_lp1, 
#     MOI.SingleVariable(X[1]),
#         MOI.GreaterThan(1.0))

# MOI.add_constraint(primal_model_lp1, 
#     MOI.SingleVariable(X[1]),
#         MOI.GreaterThan(3.0))

# MOI.set(primal_model_lp1, 
#     MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(), 
#     MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([-4.0], [X[2]]), -1.0)
#     )

# MOI.set(primal_model_lp1, MOI.ObjectiveSense(), MOI.MIN_SENSE)

# dual_model_lp1 = dualize(primal_model_lp1)




# #= 
# Name: lp1

# Model: 


# Result: 
# X[1] = 
# X[2] = 
# objective_value = 
# =#
# primal_model_lp1 = Model{Float64}()

# X = MOI.add_variables(primal_model_lp1, 2)

# MOI.add_constraint(primal_model_lp1, 
#     MOI.ScalarAffineFunction(
#         [MOI.ScalarAffineTerm(1.0, X[1]), MOI.ScalarAffineTerm(2.0, X[2])], 1.0),
#         MOI.LessThan(4.0))

# MOI.add_constraint(primal_model_lp1, 
#     MOI.SingleVariable(X[1]),
#         MOI.GreaterThan(1.0))

# MOI.add_constraint(primal_model_lp1, 
#     MOI.SingleVariable(X[1]),
#         MOI.GreaterThan(3.0))

# MOI.set(primal_model_lp1, 
#     MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(), 
#     MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([-4.0], [X[2]]), -1.0)
#     )

# MOI.set(primal_model_lp1, MOI.ObjectiveSense(), MOI.MIN_SENSE)

# dual_model_lp1 = dualize(primal_model_lp1)




# #= 
# Name: lp1

# Model: 


# Result: 
# X[1] = 
# X[2] = 
# objective_value = 
# =#
# primal_model_lp1 = Model{Float64}()

# X = MOI.add_variables(primal_model_lp1, 2)

# MOI.add_constraint(primal_model_lp1, 
#     MOI.ScalarAffineFunction(
#         [MOI.ScalarAffineTerm(1.0, X[1]), MOI.ScalarAffineTerm(2.0, X[2])], 1.0),
#         MOI.LessThan(4.0))

# MOI.add_constraint(primal_model_lp1, 
#     MOI.SingleVariable(X[1]),
#         MOI.GreaterThan(1.0))

# MOI.add_constraint(primal_model_lp1, 
#     MOI.SingleVariable(X[1]),
#         MOI.GreaterThan(3.0))

# MOI.set(primal_model_lp1, 
#     MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(), 
#     MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([-4.0], [X[2]]), -1.0)
#     )

# MOI.set(primal_model_lp1, MOI.ObjectiveSense(), MOI.MIN_SENSE)

# dual_model_lp1 = dualize(primal_model_lp1)
