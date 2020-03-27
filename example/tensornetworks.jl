using Cat

const Tensor = Array{Float64}
@category TensorNetwork 

@arrow TensorNetwork TSum :: (Tensor, Tensor) --> Tensor
@arrow TensorNetwork TProd :: (Tensor, Tensor) --> Tensor
@arrow TensorNetwork Contract :: (Tensor, Int, Int) --> Tensor

function example()
    g = tensor(2) # metric
    R = tensor(4) # Riemann curvature tensor
    T = tensor(2) # Stress-energy tensor

    Ric = Contract(R, 1, 3) # Ricci tensor
    Rsc = Contract(Ric, 1, 2) # Ricci scalar
    EFE = Ric - 0.5*Rsc*g - (8*π)*T
end

@alias TensorNetwork TSum Base.:+ 2
@alias TensorNetwork TProd Base.:* 2
Base.:*(a::Float64, b::TensorNetwork.Arrow) = TProd(a*ones(), b)
Base.:*(a::TensorNetwork.Arrow, b::Float64) = TProd(b*ones(), a)

tensor(nd::Int64) = TensorNetwork.Identity{Tensor{nd}}()

@interpretation Einsum (=>) TensorNetwork begin
    letters::Dict{TensorNetwork.Arrow, Char}
end

