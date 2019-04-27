module Dualization

using MathOptInterface
const MOI  = MathOptInterface
const MOIU = MathOptInterface.Utilities

const SVF = MOI.SingleVariable
const VVF = MOI.VectorOfVariables
const SAF{T} = MOI.ScalarAffineFunction{T}
const VAF{T} = MOI.VectorAffineFunction{T}

const VI = MOI.VariableIndex
const CI = MOI.ConstraintIndex

include("supported.jl")

"""
    dualize(model::MOI.ModelLike, ::Type{T}) where T

Dualize the model
"""
function dualize(model::MOI.ModelLike, ::Type{T}) where T
    # Query all constraint types of the model
    constr_types = MOI.get(model, MOI.ListOfConstraints())
    supported_constraints(constr_types) # Throws an error if constraint cannot be dualized
    
    # Query the objective function type of the model
    obj_func_type = MOI.get(model, MOI.ObjectiveFunctionType())
    supported_objective(constr_types) # Throws an error if objective function cannot be dualized
    
    # Crates an empty model that supports the duals of the existing constraints
    dualmodel = emptydualmodel(model)
    
    # Fill the dual model with the dual constraint
    for (F, S) in constr_types
        # Query constraints of type (F,S)

        # Add the dualized constraint to the model
        add_dual(dualmodel, ...)
    end

    # Fill the dual model with the dual objective

    return dualmodel
end

"""
"""
function emptydualmodel(model::MOI.ModelLike, ::Type{T}) where T
    
    return dualmodel
end

include("SAF_GreaterThan.jl")
include("SAF_LessThan.jl")

end # module
