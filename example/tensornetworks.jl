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

Base.:+(a::TensorNetwork.Arrow, b) = TSum(a, b)
Base.:+(a, b::TensorNetwork.Arrow) = TSum(a, b)
Base.:+(a::TensorNetwork.Arrow, b::TensorNetwork.Arrow) = TSum(a, b)

Base.:*(a::Float64, b::TensorNetwork.Arrow) = TProd(a*ones(), b)
Base.:*(a::TensorNetwork.Arrow, b::Float64) = TProd(b*ones(), a)
Base.:*(a, b::TensorNetwork.Arrow) = TProd(a, b)
Base.:*(a::TensorNetwork.Arrow, b) = TProd(a, b)
Base.:*(a::TensorNetwork.Arrow, b::TensorNetwork) = TProd(a, b)

tensor(nd::Int64) = TensorNetwork.Identity{Tensor{nd}}()

@interpretation Einsum (=>) TensorNetwork begin
    letters::Dict{TensorNetwork.Arrow, Char}
end

