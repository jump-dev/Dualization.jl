# Supported Functions
const SF = Union{MOI.SingleVariable, 
                 MOI.ScalarAffineFunction{Float64}, 
                 MOI.VectorOfVariables, 
                 MOI.VectorAffineFunction{Float64}}

# Supported Sets
const SS = Union{MOI.EqualTo{Float64}, MOI.GreaterThan{Float64}, MOI.LessThan{Float64}, 
                 MOI.Zeros, MOI.Nonnegatives, MOI.Nonpositives, 
                 MOI.SecondOrderCone, MOI.RotatedSecondOrderCone,
                 MOI.ExponentialCone, MOI.DualExponentialCone,
                 MOI.PowerCone, MOI.DualPowerCone,
                 MOI.PositiveSemidefiniteConeTriangle}

mutable struct DualOptimizer <: MOI.AbstractOptimizer
    dual_problem::Union{Nothing, Dualization.DualProblem}
    dual_optimizer::Union{Nothing, MOI.AbstractOptimizer}

    function DualOptimizer(dual_problem::Dualization.DualProblem)
        new(dual_problem, nothing)
    end
    function DualOptimizer(dual_optimizer::MOI.AbstractOptimizer)
        new(nothing, dual_optimizer)
    end
    function DualOptimizer()
        new(nothing, nothing)
    end
end

function MOI.supports(::DualOptimizer,
                      ::Union{MOI.ObjectiveSense,
                              MOI.ObjectiveFunction{MOI.SingleVariable},
                              MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}})
    return true
end

function MOI.supports_constraint(optimizer::DualOptimizer, F::Type{<:SF}, S::Type{<:SS})
    if optimizer.dual_optimizer !== nothing
        MOI.supports_constraint(optimizer.dual_optimizer, F, S)
    else
        return true
    end
end

function MOI.supports_constraint(::DualOptimizer, ::Type{MOI.AbstractFunction}, ::Type{MOI.AbstractSet})
    return false 
end

function MOI.copy_to(dest::DualOptimizer, src::MOI.ModelLike; kwargs...)
    dest.dual_problem = Dualization.dualize(src)

    idxmap = MOIU.IndexMap()

    for i in MOI.get(src,  MOI.ListOfVariableIndices())
        setindex!(idxmap, i, i)
    end

    for (F, S) in MOI.get(src, MOI.ListOfConstraints())
        for con in MOI.get(src, MOI.ListOfConstraintIndices{F,S}())
            setindex!(idxmap, con, con)
        end
    end
    return idxmap
end

function MOI.optimize!(optimizer::DualOptimizer)
    MOI.copy_to(optimizer.dual_optimizer, optimizer.dual_problem.dual_model)
    MOI.optimize!(optimizer.dual_optimizer)    
end

function MOI.get(optimizer::DualOptimizer, ::MOI.SolverName)
    if isnothing(optimizer.dual_optimizer)
        return "Dualizer with no solver attached"
    else
        return "Dual model with "*MOI.get(optimizer.dual_optimizer, MOI.SolverName())*" attached"
    end
end

function MOI.is_empty(optimizer::DualOptimizer)
    return (optimizer.dual_problem === nothing) && 
          ((optimizer.dual_optimizer === nothing) || MOI.is_empty(optimizer.dual_optimizer))
end

function MOI.empty!(optimizer::DualOptimizer)
    if optimizer.dual_optimizer !== nothing
        MOI.empty!(optimizer.dual_optimizer)
    end
    optimizer.dual_problem = nothing
    return
end

function MOI.get(optimizer::DualOptimizer, ::MOI.VariablePrimal, vi::VI)
    ci = optimizer.dual_problem.primal_dual_map.primal_var_dual_con[vi]
    MOI.get(optimizer.dual_optimizer, MOI.ConstraintDual(), ci)
end

function MOI.get(optimizer::DualOptimizer, ::MOI.ConstraintDual, 
                 ci::CI{F,S}) where {F <: MOI.AbstractScalarFunction, S}
    vi = optimizer.dual_problem.primal_dual_map.primal_con_dual_var[ci]
    return MOI.get(optimizer.dual_optimizer, MOI.VariablePrimal(), vi[1])
end

function MOI.get(optimizer::DualOptimizer, ::MOI.ConstraintDual, 
                 ci::CI{F,S}) where {F <: MOI.AbstractVectorFunction, S}
    vi = optimizer.dual_problem.primal_dual_map.primal_con_dual_var[ci]
    return MOI.get.(optimizer.dual_optimizer, MOI.VariablePrimal(), vi)
end

function MOI.get(optimizer::DualOptimizer, ::MOI.ConstraintPrimal, 
                 ci::CI{F,S}) where {F <: MOI.AbstractScalarFunction, S}
    ci_dual = optimizer.dual_problem.primal_dual_map.primal_con_dual_con[ci]
    if ci_dual === nothing
        return 0.0
    end
    return MOI.get(optimizer.dual_optimizer, MOI.ConstraintDual(), ci_dual)
end

function MOI.get(optimizer::DualOptimizer, ::MOI.ConstraintPrimal, 
                 ci::CI{F,S}) where {F <: MOI.AbstractVectorFunction, S}
    ci_dual = optimizer.dual_problem.primal_dual_map.primal_con_dual_con[ci]
    if ci_dual === nothing
        set = get_set(optimizer.dual_problem.dual_model, ci)
        return zeros(Float64, MOI.dimension(set))
    end
    return MOI.get(optimizer.dual_optimizer, MOI.ConstraintDual(), ci_dual)
end

function MOI.get(optimizer::DualOptimizer, ::MOI.SolveTime) 
    return MOI.get(optimizer.dual_optimizer, MOI.SolveTime())
end

function MOI.get(optimizer::DualOptimizer, ::MOI.TerminationStatus) 
    return dual_status(MOI.get(optimizer.dual_optimizer, MOI.TerminationStatus()))
end

function dual_status(term::MOI.TerminationStatusCode)
    if term == MOI.INFEASIBLE 
        return MOI.DUAL_INFEASIBLE
    elseif term == MOI.DUAL_INFEASIBLE
        return MOI.INFEASIBLE 
    elseif term == MOI.ALMOST_INFEASIBLE
        return MOI.ALMOST_DUAL_INFEASIBLE
    elseif term == MOI.ALMOST_DUAL_INFEASIBLE
        return MOI.ALMOST_INFEASIBLE
    end
    return term
end

# function MOI.get(optimizer::DualOptimizer, ::MOI.ObjectiveValue)
#     return MOI.get(optimizer.dual_optimizer, MOI.DualObjectiveValue())
# end

# function MOI.get(optimizer::DualOptimizer, ::MOI.DualObjectiveValue)
#     return MOI.get(optimizer.dual_optimizer, MOI.ObjectiveValue())
# end

function MOI.get(optimizer::DualOptimizer, ::MOI.ObjectiveValue)
    return MOI.get(optimizer.dual_optimizer, MOI.ObjectiveValue())
end

function MOI.get(optimizer::DualOptimizer, ::MOI.PrimalStatus)
    return MOI.get(optimizer.dual_optimizer, MOI.DualStatus())
end

function MOI.get(optimizer::DualOptimizer, ::MOI.DualStatus)
    return MOI.get(optimizer.dual_optimizer, MOI.PrimalStatus())
end

function MOI.get(optimizer::DualOptimizer, ::MOI.ResultCount)
    return 1
end