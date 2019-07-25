push!(LOAD_PATH, "/home/guilhermebodin/Documents/Github/Dualization.jl/src")
using JuMP, Dualization
using MathOptInterface
const MOI = MathOptInterface

function create_model(n)
    model = Model()
    @variable(model, x[1:n])
    @constraint(model, x[1:n] in MOI.Nonnegatives(n))
    @objective(model, Min, sum(x))
    return model
end

@time model = create_model(10_000);
@time m = backend(model);
@time dm = dualize(m);

