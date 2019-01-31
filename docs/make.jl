using AWSCore
using Documenter

makedocs(;
    modules=[AWSCore],
    sitename="AWSCore.jl",
    authors="The JuliaCloud Developers",
    pages=[
        "Home" => "index.md",
        "Test Stack" => "stack.md",
    ],
)

deploydocs(;
    repo="github.com/JuliaCloud/AWSCore.jl",
    target="build",
)
