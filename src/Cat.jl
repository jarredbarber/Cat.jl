module Cat

export Arrow, Identity, Initial, Terminal, FreeComposition
include("arrow.jl")

export Product, Proj
include("cartesian.jl")

end # end module
