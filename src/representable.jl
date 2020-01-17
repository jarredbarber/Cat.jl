"Representable is a functor from a category into a computation "

abstract type StatefulFunctor{C}; end
export StatefulFunctor

macro stateful(name, variance, category, state_def)
    esc(quote
        mutable struct $name <: StatefulFunctor{$category.Arrow}
        $(state_def.args...)
        end

        (s::$name)(m::$category.Composed, inp...) = s(m.g, s(m.f, inp...)...)
        (s::$name)(m::$category.Product, inp...) = tuple([s(x, inp...) for x in m.factors]...)
        (s::$name)(m::$category.Proj, inp...) = inp[m.m]
        (s::$name)(m::$category.Constant, inp...) = m.val
        (s::$name)(m::$category.Terminal, inp...) = nothing
        end)
end
