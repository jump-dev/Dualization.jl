function add_dual(dualmodel::MOI.ModelLike, 
                  constr::CI{SAF{T}, MOI.GreaterThan{T}}) where T
    println("oi")
    # Dualization process
end

function add_dual(dualmodel::MOI.ModelLike, 
                  constr::CI{SAF{T}, MOI.LessThan{T}}) where T
    println("oi")
    # Dualization process
end