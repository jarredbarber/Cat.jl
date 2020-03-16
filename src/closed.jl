quote
    # (a -> b, a) -> b
    struct Apply{A <: Arrow, B<:Arrow, T <: Arrow{A, B}} <: Arrow{Tuple{T, A}, B}
    end
    struct Curry{A <: Arrow, B<: Arrow, C <: Arrow}
            <: Arrow{A, Arrow{B, C}}
        thunk::Arrow{Tuple{A, B}, C}
    end
    struct Uncurry{A <: Arrow, B<: Arrow, C <: Arrow} <: Arrow{Tuple{A, B}, C}
        thunk::Arrow{A, Arrow{B, C}}
    end
end
