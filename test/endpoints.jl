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


@testset "rest-json" begin
    @testset "glacier - special case" begin
        vault_names = [string("test-vault-", UUIDs.uuid4()), string("test-vault-", UUIDs.uuid4())]

        @testset "Create Vaults" begin
            for vault in vault_names
                Services.glacier("PUT", "/-/vaults/$vault")
            end
        end

        @testset "Get Vaults" begin
            # If this is an Integer AWS Coral cannot convert it to a String
            # "class com.amazon.coral.value.json.numbers.TruncatingBigNumber can not be converted to an String"
            limit = "1"
            headers = Dict("foo"=>"bar")

            cases = [
                Dict("limit"=>limit, "headers"=>Dict("foo"=>"bar")),
                Dict("limit"=>limit, "headers"=>("foo"=>"bar")),
                Dict("limit"=>limit, "headers"=>[("foo"=>"bar"), ("biz"=>"baz")]),
                Dict("limit"=>limit),
                ("limit"=>limit, "headers"=>Dict("foo"=>"bar")),
                ("limit"=>limit, "headers"=>("foo"=>"bar")),
                ("limit"=>limit, "headers"=>[("foo"=>"bar"), ("biz"=>"baz")]),
                ("limit"=>limit),
                [("limit"=>limit), ("headers"=>Dict("foo"=>"bar"))],
                [("limit"=>limit), ("headers"=>("foo"=>"bar"))],
                [("limit"=>limit), ("headers"=>[("foo"=>"bar"), ("biz"=>"baz")])],
                [("limit"=>limit)]
            ]

            @testset "$case" for case in cases
                result = Services.glacier("GET", "/-/vaults", case)

                @test length(result["VaultList"]) == parse(Int, limit)
            end
        end

        @testset "Delete Vaults" begin
            for vault in vault_names
                Services.glacier("DELETE", "/-/vaults/$vault")
            end

            result = Services.glacier("GET", "/-/vaults")
            vaults = [v["VaultName"] for v in result["VaultList"]]

            for vault in vault_names
                @test !(vault in vaults)
            end
        end
    end
end
