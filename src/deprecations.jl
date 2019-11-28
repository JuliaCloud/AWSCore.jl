# https://github.com/JuliaCloud/AWSCore.jl/commit/b719614b812fbec385833e607a2f8772d6009b59
import Base: copy!
Base.@deprecate copy!(dest::AWSCredentials, src::AWSCredentials) copyto!(dest, src) false
