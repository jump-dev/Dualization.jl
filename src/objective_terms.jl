obj = MOI.get(model, MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}())
a0 = obj.terms


function builda0(model)
    zeros(numvariables)
    for each variable index add the a0 term
end

function buildb0()
    b0 = obj.constant
end

#1 - Query all variables
#2 - Build a0 and b0