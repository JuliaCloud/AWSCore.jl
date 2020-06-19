#==============================================================================#
# AWSCore/test/runtests.jl
#
# Copyright OC Technology Pty Ltd 2014 - All rights reserved
#==============================================================================#

using AWSCore
using AWSCore: Services
using Dates
using HTTP
using HTTP: Headers, URI
using IniFile
using JSON
using Mocking
using Retry
using SymDict
using Test
using XMLDict
using .SignatureV4

Mocking.activate()
aws = aws_config()

@testset "AWSCore" begin
    include("aws4.jl")
    include("arn.jl")
    include("credentials.jl")
    include("exceptions.jl")
    include("endpoints.jl")
    include("localhost.jl")
    include("signaturev4.jl")
    include("xml.jl")
end
