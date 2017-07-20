using Documenter
using AWSCore
using AWSS3
using AWSSQS
using AWSSES

makedocs(
    modules = [
        AWSCore,
        AWSS3,
        AWSSQS,
        AWSSES
    ],
    format = :html,
    sitename = "AWSCore.jl",
    pages = [
        "AWSCore.jl" => "index.md",
        "AWSS3.jl" => "AWSS3.md",
        "AWSSQS.jl" => "AWSSQS.md",
        "AWSSES.jl" => "AWSSES.md"
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
