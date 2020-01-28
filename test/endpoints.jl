using AWSCore.Services: route53

@testset "Endpoints" begin
    @testset "Route53" begin
        try
            route53("GET", "/2013-04-01/accountlimit/MAX_HEALTH_CHECKS_BY_OWNER")
            @test true
        catch
            @test false
        end
    end
end
