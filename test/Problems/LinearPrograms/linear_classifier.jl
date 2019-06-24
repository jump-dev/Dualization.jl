using CSV

function linear_classifier(path::String, optimizer)    
    data_tumors = CSV.read(path, header = false)
    
    num_attributes = 30
    train_set_size = 400
    
    train_set_attrs = convert(Matrix{Float64}, data_tumors[1:train_set_size, 3:end])
    train_set_diagnosis = convert(Vector{String}, data_tumors[1:train_set_size, 2])

    test_set_attrs = convert(Matrix{Float64}, data_tumors[train_set_size + 1:end, 3:end])
    test_set_diagnosis = convert(Vector{String}, data_tumors[train_set_size + 1:end, 2])
    
    model = JuMP.Model(with_optimizer(optimizer))
    n = 30
    @variable(model, x[i = 1:n])
    @variable(model, c)
    @variable(model, ϵ[i = 1:train_set_size] >= 0)
    
    for i in 1:train_set_size
        if train_set_diagnosis[i] == "M"
            @constraint(model, sum(train_set_attrs[i, j]*x[j] for j in 1:n) + c >= -ϵ[i])
        elseif train_set_diagnosis[i] == "B"
            @constraint(model, sum(train_set_attrs[i, j]*x[j] for j in 1:n) + c <= ϵ[i] - 1)
        end
    end
    
    @objective(model, Min, sum(ϵ))
    return model
end

