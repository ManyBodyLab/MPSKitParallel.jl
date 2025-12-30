# Programmatically generated typed forwarding macros.

"""
Typed forwarding macro generator.

This file programmatically defines a small family of helper macros that
generate thin forwarding methods. Each generated macro has the form

    @forward_a Type.field f, g, h

where `a` is the number of leading non-container positional arguments
to keep unchanged. The macro emits methods that take `a` leading
arguments followed by a container argument typed as `::Type` and
delegate the call to the `field` of that container.

Examples
    - `@forward_0 Type.field f` =>
            `f(x::Type, args...; kwargs...) = f(x.field, args...; kwargs...)`
    - `@forward_1 Type.field f` =>
            `f(a, x::Type, args...; kwargs...) = f(a, x.field, args...; kwargs...)`

Each `@forward_a` also has an `_astype` sibling, `@forward_a_astype`,
which wraps the forwarded call's result back into the container type
using `Type(result, x.reduction, x.comm)`. Use the `_astype` variant
when the underlying function returns a bare value that should be
converted to the container type.
"""

# helper used in many macros
using MacroTools: @capture, isexpr

# generator: create macros forward_a and forward_a_astype for a in 0:3
for a in 0:3
    # macro names
    name_sym = Symbol("forward_$(a)")
    name_astype_sym = Symbol("forward_$(a)_astype")

    # Generate explicit argument names for this iteration
    # e.g., if a=2, arg_names = [:x_1, :x_2]
    arg_names = [Symbol("x_$i") for i in 1:a]

    @eval begin
        macro $(name_sym)(ex, fs)
            @capture(ex, T_.field_) || error("Syntax: @$(string($(name_sym))) T.x f, g, h")
            T = esc(T)
            fs = isexpr(fs, :tuple) ? map(esc, fs.args) : [esc(fs)]

            _args = $arg_names

            return :(
                $(
                    [
                        :(
                                $f($(_args...), y::$T, args...; kwargs...) =
                                (Base.@inline; $f($(_args...), y.$field, args...; kwargs...))
                            ) for f in fs
                    ]...
                );
                nothing
            )
        end

        macro $(name_astype_sym)(ex, fs)
            @capture(ex, T_.field_) || error("Syntax: @$(string($(name_astype_sym))) T.x f, g, h")
            T = esc(T)
            fs = isexpr(fs, :tuple) ? map(esc, fs.args) : [esc(fs)]

            _args = $arg_names

            return :(
                $(
                    [
                        :(
                                $f($(_args...), y::$T, args...; kwargs...) =
                                (Base.@inline; $T($f($(_args...), y.$field, args...; kwargs...), y.reduction, y.comm))
                            ) for f in fs
                    ]...
                );
                nothing
            )
        end
    end
end

# Convenience wrappers for the common a=0 case
macro forward(ex, fs)
    return :(@forward_0 $ex $fs)
end

macro forward_astype(ex, fs)
    return :(@forward_0_astype $ex $fs)
end
