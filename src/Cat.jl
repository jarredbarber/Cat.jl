module Cat

export Arrow, Identity, @category, compose, lift, composition_obj, @inverse, parent_category, @morphism, @stateful
include("arrow.jl")
include("representable.jl")

end # end module
