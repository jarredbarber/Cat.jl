using MacroTools

"Representable is a functor from a category into a computation "
abstract type StatefulFunctor{C}; end
export StatefulFunctor, @interpretation, @interpret

macro interpretation(name, variance, category, state_def=Expr(:dummy))
    esc(quote
        mutable struct $name <: StatefulFunctor{$category.Arrow}
        $(state_def.args...)
        end

        (s::$name)(m::$category.Composed, inp...) = s(m.g, s(m.f, inp...)...)
        (s::$name)(m::$category.Product, inp...) = tuple([s(x, inp...) for x in m.factors]...)
        (s::$name)(m::$category.Proj, inp...) = inp[m.m]
        (s::$name)(m::$category.Constant, inp...) = m.val
        (s::$name)(m::$category.Terminal, inp...) = nothing
        interp_state_hook(s::$name, m::$category.Arrow, value_expr) = value_expr()
        end)
end

macro interpret(fn)
    @capture(fn, function (s_::functor_)(m_::arrow_, args__) expr__ end) || error("Can't destructure input expression")
    esc(quote
          function ($s::$functor)($m::$arrow, $(args...))
            value_expr = () -> begin $(expr...) end
            interp_state_hook($s, $m, value_expr)
          end
        end)
end
