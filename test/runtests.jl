#==============================================================================#
# AWSCore/test/runtests.jl
#
# Copyright OC Technology Pty Ltd 2014 - All rights reserved
#==============================================================================#

using AWSCore
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
    include("localhost.jl")
    include("signaturev4.jl")
    include("xml.jl")
end

@testset "Non-Amazon S3" begin
  # Test accessing GCS
  aws_google = AWSCore.aws_config(creds=nothing, region="", service_host="googleapis.com", service_name="storage")
  data_prefix = "AerChemMIP/BCC/BCC-ESM1/piClim-CH4/r1i1p1f1/Amon/vas/gn"
  result = AWSCore.Services.s3(aws_google, "GET", "/{Bucket}", Dict(:Bucket=>"cmip6",:prefix=>data_prefix))
  @test result["Contents"][1]["Key"] == "AerChemMIP/BCC/BCC-ESM1/piClim-CH4/r1i1p1f1/Amon/vas/gn/.zattrs"
  @test String(AWSCore.Services.s3(aws_google, "GET", "/{Bucket}/{Key+}", Bucket="cmip6",Key="$(data_prefix)/.zgroup")) ==
   "{\n    \"zarr_format\": 2\n}"
  # Test accessing OTC object store
  aws_otc = aws_config(creds=nothing, region="eu-de", service_name="obs", service_host="otc.t-systems.com")
  result = AWSCore.Services.s3(aws_otc, "GET", "/{Bucket}?list-type=2", Dict(:Bucket=>"obs-esdc-v2.0.0",:prefix=>"",:delimiter=>"/"))
  @test result["CommonPrefixes"][1]["Prefix"]=="esdc-8d-0.0083deg-184x60x60-2.0.0_colombia.zarr/"
end

end # testset "AWSCore"


#==============================================================================#
# End of file.
#==============================================================================#