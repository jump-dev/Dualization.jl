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
    dual_optimizer_idx_map::Union{Nothing, MOIU.IndexMap}

    function DualOptimizer(dual_problem::Dualization.DualProblem)
        new(dual_problem, nothing, nothing)
    end
    function DualOptimizer(dual_optimizer::MOI.AbstractOptimizer)
        new(nothing, dual_optimizer, nothing)
    end
    function DualOptimizer()
        new(nothing, nothing, nothing)
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
    idx_map_optimizer = MOI.copy_to(dest.dual_optimizer, dest.dual_problem.dual_model; kwargs...)
    dest.dual_optimizer_idx_map = idx_map_optimizer

    idx_map = MOIU.IndexMap()

    for vi in MOI.get(src, MOI.ListOfVariableIndices())
        setindex!(idx_map, vi, vi)
    end

    for (F, S) in MOI.get(src, MOI.ListOfConstraints())
        for con in MOI.get(src, MOI.ListOfConstraintIndices{F,S}())
            setindex!(idx_map, con, con)
        end
    end
    return idx_map
end

function MOI.optimize!(optimizer::DualOptimizer)
    MOI.optimize!(optimizer.dual_optimizer)    
end

function MOI.get(optimizer::DualOptimizer, ::MOI.SolverName)
    if optimizer.dual_optimizer === nothing
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
    ci_dual_problem = optimizer.dual_problem.primal_dual_map.primal_var_dual_con[vi]
    ci_dual_optimizer = optimizer.dual_optimizer_idx_map.conmap[ci_dual_problem]
    return -MOI.get(optimizer.dual_optimizer, MOI.ConstraintDual(), ci_dual_optimizer)
end

function MOI.get(optimizer::DualOptimizer, ::MOI.ConstraintDual, 
                 ci::CI{F,S}) where {F <: MOI.AbstractScalarFunction, S}
    vi_dual_problem = optimizer.dual_problem.primal_dual_map.primal_con_dual_var[ci]
    vi_dual_optimizer = optimizer.dual_optimizer_idx_map.varmap[vi_dual_problem[1]]
    return MOI.get(optimizer.dual_optimizer, MOI.VariablePrimal(), vi_dual_optimizer)
end

function MOI.get(optimizer::DualOptimizer, ::MOI.ConstraintDual, 
                 ci::CI{F,S}) where {F <: MOI.AbstractVectorFunction, S}
    vi_dual_problem = optimizer.dual_problem.primal_dual_map.primal_con_dual_var[ci]
    vi_dual_optimizer = optimizer.dual_optimizer_idx_map.varmap[vi_dual_problem]
    return MOI.get.(optimizer.dual_optimizer, MOI.VariablePrimal(), vi)
end

function MOI.get(optimizer::DualOptimizer, ::MOI.ConstraintPrimal, 
                 ci::CI{F,S}) where {F <: MOI.AbstractScalarFunction, S}
    ci_dual = optimizer.dual_problem.primal_dual_map.primal_con_dual_con[ci]
    if ci_dual === nothing
        return 0.0
    end
    primal_ci_constant = optimizer.dual_problem.primal_dual_map.primal_con_constants[ci]
    return MOI.get(optimizer.dual_optimizer, MOI.ConstraintDual(), ci_dual) - primal_ci_constant[1]
end

function MOI.get(optimizer::DualOptimizer, ::MOI.ConstraintPrimal, 
                 ci::CI{F,S}) where {F <: MOI.AbstractVectorFunction, S}
    ci_dual = optimizer.dual_problem.primal_dual_map.primal_con_dual_con[ci]
    if ci_dual === nothing
        set = get_set(optimizer.dual_problem.dual_model, ci)
        return zeros(Float64, MOI.dimension(set))
    end
    primal_ci_constants = optimizer.dual_problem.primal_dual_map.primal_con_constants[ci]
    return MOI.get(optimizer.dual_optimizer, MOI.ConstraintDual(), ci_dual) .- primal_ci_constants
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

# To be added in MOI 0.9.0
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
    return MOI.get(optimizer.dual_optimizer, MOI.ResultCount())
end