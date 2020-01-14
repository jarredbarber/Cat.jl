using Cat
@category Z

# Next is a morphism in Z from Nothing~>Nothing
@morphism Z Next {} {Nothing, Nothing}
@morphism Z Prev {} {Nothing, Nothing}
@inverse Z Next Prev

println(Next(Prev()))
