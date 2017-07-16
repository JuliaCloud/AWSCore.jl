using Documenter
using AWSCore
using AWSS3

makedocs(
    modules = [
        AWSCore,
        AWSS3
    ],
    format = :html,
    sitename = "AWSCore.jl",
    pages = [
        "AWSCore.jl" => "index.md",
        "AWSS3.jl" => "AWSS3.md"
    ]
)

#=
deploydocs(
    repo = "github.com/JuliaWeb/AWSCore.jl.git",
    target = "build",
    deps = nothing,
    make = nothing,
    julia = "release",
    osname = "linux"
)
=#
