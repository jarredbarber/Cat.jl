using MacroTools

"Representable is a functor from a category into a computation "
abstract type StatefulFunctor{C}; end
export StatefulFunctor, @interpretation, @interpret, @functor

macro interpretation(name, variance, category, state_def=Expr(:dummy))
    esc(quote
        mutable struct $name <: StatefulFunctor{$category.Arrow}
        $(state_def.args...)
        end

        (s::$name)(m::$category.Composed, inp...) = s(m.g, s(m.f, inp...)...)
        (s::$name)(m::$category.Product, inp...) = tuple([s(x, inp...) for x in m.factors]...)
        (s::$name)(m::$category.Proj, inp...) = inp[m.m]
        (s::$name)(m::$category.Constant, inp...) = m.val
        (s::$name)(m::$category.Identity, inp) = inp
        (s::$name)(m::$category.Terminal, inp...) = ()
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

macro functor(sig, obj_map)
    @capture(obj_map, var_ -> body_)
    comp_body = 
        if @capture(sig, name_ :: src_ => tgt_)
            :($name(m::$src.Composed) = compose($name(m.g), $name(m.f)))
        elseif @capture(sig, name_ :: src_ <= tgt_)
            :($name(m::$src.Composed) = compose($name(m.f), $name(m.g)))
        else
        end
    esc(quote
        struct $name
        end

        function $name($var::Type)
           $(body.args...)
        end
        $comp_body
        # Functions are (src morphism × input) -> (tgt morphism)
        $name(m::$src.Identity{T}) where {T} = $tgt.Identity{$name(T)}()
        # Cartesian
        $name(m::$src.Product) = $tgt.Product([$name(x) for x in m.factors]...)
        $name(m::$src.Proj{A, B}) where {A,B} = $tgt.Proj{$name(A), $name(B)}(m.m)
        # need to define this
        # $name(m::$src.Constant) = $tgt.Constant(m.val)
        $name(m::$src.Terminal{T}) where {T} = $tgt.Terminal{$name(T)}()
        end)
end

