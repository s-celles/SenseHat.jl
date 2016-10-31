using ColorTypes, FixedPointNumbers

function _led_fb_dev()
    for devname in readdir("/sys/class/graphics")
        sysfname = joinpath("/sys/class/graphics",devname,"name")
        if startswith(devname, "fb") && isfile(sysfname)
            if startswith(readstring(sysfname),"RPi-Sense FB")
                return joinpath("/dev",devname)
            end
        end
    end
    error("Sense Hat not found.")
end

const LED_FB_DEV = _led_fb_dev()


typealias U5 UFixed{UInt8,5}
typealias U6 UFixed{UInt8,6}

immutable RGB565 <: AbstractRGB{U8}
    data::UInt16
end

function RGB565(r::U5, g::U6, b::U5)
    RGB565( (UInt16(reinterpret(r)) << 11) |
            (UInt16(reinterpret(g)) << 5) |
            (UInt16(reinterpret(b))) )
end

RGB565(r::Real, g::Real, b::Real) = 
    RGB565(convert(U5,r), convert(U6,g), convert(U5,b))
RGB565(c::Union{Color,Colorant}) = RGB565(red(c), green(c), blue(c))

ColorTypes.red(c::RGB565) = U5(c.data >> 11, Val{true})
ColorTypes.green(c::RGB565) = U6((c.data >> 5) & 0x3f, Val{true})
ColorTypes.blue(c::RGB565) = U5(c.data & 0x1f, Val{true})

ColorTypes.ccolor{Csrc<:Colorant}(::Type{RGB565}, ::Type{Csrc}) = RGB565
ColorTypes.base_color_type(::Type{RGB565}) = RGB565

"""
    led_display(X)

Display an image `X` on the SenseHat LED matrix.

`X` should be an 8×8 matrix of colors (see the ColorTypes.jl package).

See also:
* `rotl90`, `rotr90` and `rot180` for rotating the image.
* `flipdim` for reflecting the image.
* `led_clear` for clearing the LED matrix.
"""
function led_display(X)
    size(X) == (8,8) || throw(DimensionMismatch("Can only display 8x8 images"))
    open(LED_FB_DEV, "w") do fb
        for j = 1:8
            for i = 1:8
                write(fb, convert(RGB565, X[i,j]).data)
            end
        end
    end
end

"""
    led_clear()

Clears the SenseHat LED matrix.
"""
function led_clear()
    open(LED_FB_DEV, "w") do fb
        for j = 1:8
            for i = 1:8
                write(fb, UInt16(0))
            end
        end
    end
end
