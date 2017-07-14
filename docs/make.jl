using Documenter, AWSCore

makedocs(
    modules = [AWSCore],
    format = :html,
    sitename = "AWSCore.jl",
    pages = ["Home" => "index.md"]
)

deploydocs(
    repo = "github.com/JuliaWeb/AWSCore.jl.git",
    target = "build",
    deps = nothing,
    make = nothing,
    julia = "release",
    osname = "linux"
)
