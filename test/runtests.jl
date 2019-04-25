#==============================================================================#
# AWSCore/test/runtests.jl
#
# Copyright OC Technology Pty Ltd 2014 - All rights reserved
#==============================================================================#

using Test
using Dates
using AWSCore
using SymDict
using Retry
using XMLDict
using HTTP

using AWSCore: service_query

AWSCore.set_debug_level(1)


@testset "AWSCore" begin

aws = aws_config()

@testset "NoAuth" begin
    pub_request1 = Dict{Symbol, Any}(
        :service => "s3",
        :headers => Dict{String, String}("Range" => "bytes=0-0"),
        :content => "",
        :resource => "/invenia-static-website-content/invenia_ca/index.html",
        :url => "https://s3.us-east-1.amazonaws.com/invenia-static-website-content/invenia_ca/index.html",
        :verb => "GET",
        :region => "us-east-1",
        :creds => nothing,
    )
    pub_request2 = Dict{Symbol, Any}(
        :service => "s3",
        :headers => Dict{String, String}("Range" => "bytes=0-0"),
        :content => "",
        :resource => "ryft-public-sample-data/AWS-x86-AMI-queries.json",
        :url => "https://s3.amazonaws.com/ryft-public-sample-data/AWS-x86-AMI-queries.json",
        :verb => "GET",
        :region => "us-east-1",
        :creds => nothing,
    )
    response = nothing
    try
        response = AWSCore.do_request(pub_request1)
    catch e
        println(e)
        @test ecode(e) in ["AccessDenied", "NoSuchEntity"]
        try
            response = AWSCore.do_request(pub_request2)
        catch e
            println(e)
            @test ecode(e) in ["AccessDenied", "NoSuchEntity"]
        end
    end
    @test response == "<" || response == UInt8['[']
end
@testset "Load Credentials" begin
    user = aws_user_arn(aws)

    @test occursin(r"^arn:aws:iam::[0-9]+:[^:]+$", user)

    println("Authenticated as: $user")

    aws[:region] = "us-east-1"

    println("Testing exceptions...")
    try
        AWSCore.Services.iam("GetFoo", Dict("ContentType" => "JSON"))
        @test false
    catch e
        println(e)
        @test ecode(e) == "InvalidAction"
    end

    try
        AWSCore.Services.iam("GetUser", Dict("UserName" => "notauser",
                                           "ContentType" => "JSON"))
        @test false
    catch e
        println(e)
        @test ecode(e) in ["AccessDenied", "NoSuchEntity"]
    end

    try
        AWSCore.Services.iam("GetUser", Dict("UserName" => "@#!%%!",
                                           "ContentType" => "JSON"))
        @test false
    catch e
        println(e)
        @test ecode(e) == "ValidationError"
    end

    try
        AWSCore.Services.iam("CreateUser", Dict("UserName" => "root",
                                              "ContentType" => "JSON"))
        @test false
    catch e
        println(e)
        @test ecode(e) in ["AccessDenied", "EntityAlreadyExists"]
    end
end

@testset "AWSCredentials" begin
    @testset "Defaults" begin
        creds = AWSCredentials("access_key_id" ,"secret_key")
        @test creds.token == ""
        @test creds.user_arn == ""
        @test creds.account_number == ""
        @test creds.expiry == typemax(DateTime)
        @test creds.renew == nothing
    end

    @testset "Renewal" begin
        # Credentials shouldn't throw an error if no renew function is supplied
        creds = AWSCredentials("access_key_id", "secret_key", renew = nothing)
        newcreds = check_credentials(creds, force_refresh = true)
        # Creds should remain unchanged if no renew function exists
        @test creds === newcreds
        @test creds.access_key_id == "access_key_id"
        @test creds.secret_key == "secret_key"
        @test creds.renew == nothing

        # Creds should error if the renew function returns nothing
        creds = AWSCredentials("access_key_id", "secret_key", renew = () -> nothing)
        @test_throws ErrorException check_credentials(creds, force_refresh = true)
        # Creds should remain unchanged
        @test creds.access_key_id == "access_key_id"
        @test creds.secret_key == "secret_key"

        # Creds should take on value of a returned AWSCredentials except renew function
        function gen_credentials()
            i = 0
            () -> (i += 1; AWSCredentials("NEW_ID_$i", "NEW_KEY_$i"))
        end

        creds = AWSCredentials(
            "access_key_id",
            "secret_key",
            renew = gen_credentials(),
            expiry = now(UTC),
        )

        @test creds.renew !== nothing
        renewed = creds.renew()

        @test creds.access_key_id == "access_key_id"
        @test creds.secret_key == "secret_key"
        @test creds.expiry <= now(UTC)
        @test AWSCore.will_expire(creds)

        @test renewed.access_key_id === "NEW_ID_1"
        @test renewed.secret_key == "NEW_KEY_1"
        @test renewed.renew === nothing
        @test renewed.expiry == typemax(DateTime)
        @test !AWSCore.will_expire(renewed)
        renew = creds.renew

        # Check renewal on time out
        newcreds = check_credentials(creds, force_refresh = false)
        @test creds === newcreds
        @test creds.access_key_id == "NEW_ID_2"
        @test creds.secret_key == "NEW_KEY_2"
        @test creds.renew !== nothing
        @test creds.renew === renew
        @test creds.expiry == typemax(DateTime)
        @test !AWSCore.will_expire(creds)

        # Check renewal doesn't happen if not forced or timed out
        newcreds = check_credentials(creds, force_refresh = false)
        @test creds === newcreds
        @test creds.access_key_id == "NEW_ID_2"
        @test creds.secret_key == "NEW_KEY_2"
        @test creds.renew !== nothing
        @test creds.renew === renew
        @test creds.expiry == typemax(DateTime)

        # Check forced renewal works
        newcreds = check_credentials(creds, force_refresh = true)
        @test creds === newcreds
        @test creds.access_key_id == "NEW_ID_3"
        @test creds.secret_key == "NEW_KEY_3"
        @test creds.renew !== nothing
        @test creds.renew === renew
        @test creds.expiry == typemax(DateTime)
    end

    mktemp() do config_file, config_io
        write(config_io, """[profile test]
                output = json
                region = us-east-1

                [profile test:dev]
                source_profile = test
                role_arn = arn:aws:iam::123456789000:role/Dev

                [profile test:sub-dev]
                source_profile = test:dev
                role_arn = arn:aws:iam::123456789000:role/SubDev

                [profile test2]
                aws_access_key_id = WRONG_ACCESS_ID
                aws_secret_access_key = WRONG_ACCESS_KEY
                output = json
                region = us-east-1

                [profile test3]
                source_profile = test:dev
                role_arn = arn:aws:iam::123456789000:role/test3

                [profile test4]
                source_profile = test:dev
                role_arn = arn:aws:iam::123456789000:role/test3
                aws_access_key_id = RIGHT_ACCESS_ID4
                aws_secret_access_key = RIGHT_ACCESS_KEY4
            """)
        close(config_io)

        mktemp() do creds_file, creds_io
            write(creds_io, """[test]
                aws_access_key_id = TEST_ACCESS_ID
                aws_secret_access_key = TEST_ACCESS_KEY

                [test2]
                aws_access_key_id = RIGHT_ACCESS_ID2
                aws_secret_access_key = RIGHT_ACCESS_KEY2

                [test3]
                aws_access_key_id = RIGHT_ACCESS_ID3
                aws_secret_access_key = RIGHT_ACCESS_KEY3
                """)
            close(creds_io)

            withenv(
                "AWS_SHARED_CREDENTIALS_FILE" => creds_file,
                "AWS_CONFIG_FILE" => config_file,
                "AWS_DEFAULT_PROFILE" => "test",
                "AWS_ACCESS_KEY_ID" => nothing
                ) do

                @testset "Loading" begin
                    # Check credentials load
                    config = aws_config()
                    creds = config[:creds]
                    @test creds isa AWSCredentials

                    @test creds.access_key_id == "TEST_ACCESS_ID"
                    @test creds.secret_key == "TEST_ACCESS_KEY"
                    @test creds.renew !== nothing

                    # Check credential file takes precedence over config
                    ENV["AWS_DEFAULT_PROFILE"] = "test2"
                    config = aws_config()
                    creds = config[:creds]

                    @test creds.access_key_id == "RIGHT_ACCESS_ID2"
                    @test creds.secret_key == "RIGHT_ACCESS_KEY2"

                    # Check credentials take precedence over role
                    ENV["AWS_DEFAULT_PROFILE"] = "test3"
                    config = aws_config()
                    creds = config[:creds]

                    @test creds.access_key_id == "RIGHT_ACCESS_ID3"
                    @test creds.secret_key == "RIGHT_ACCESS_KEY3"

                    ENV["AWS_DEFAULT_PROFILE"] = "test4"
                    config = aws_config()
                    creds = config[:creds]

                    @test creds.access_key_id == "RIGHT_ACCESS_ID4"
                    @test creds.secret_key == "RIGHT_ACCESS_KEY4"
                end

                @testset "Refresh" begin
                    ENV["AWS_DEFAULT_PROFILE"] = "test"
                    # Check credentials refresh on timeout
                    config = aws_config()
                    creds = config[:creds]
                    creds.access_key_id = "EXPIRED_ACCESS_ID"
                    creds.secret_key = "EXPIRED_ACCESS_KEY"
                    creds.expiry = now(UTC)

                    @test creds.renew !== nothing
                    renew = creds.renew
                    @test renew() isa AWSCredentials

                    creds = check_credentials(config[:creds])

                    @test creds.access_key_id == "TEST_ACCESS_ID"
                    @test creds.secret_key == "TEST_ACCESS_KEY"
                    @test creds.expiry > now(UTC)

                    # Check renew function remains unchanged
                    @test creds.renew !== nothing
                    @test creds.renew === renew

                    # Check force_refresh
                    creds.access_key_id = "WRONG_ACCESS_KEY"
                    creds = check_credentials(creds, force_refresh = true)
                    @test creds.access_key_id == "TEST_ACCESS_ID"
                end

                @testset "Profile" begin
                    # Check profile kwarg
                    ENV["AWS_DEFAULT_PROFILE"] = "test"
                    creds = AWSCredentials(profile="test2")
                    @test creds.access_key_id == "RIGHT_ACCESS_ID2"
                    @test creds.secret_key == "RIGHT_ACCESS_KEY2"

                    config = aws_config(profile="test2")
                    creds = config[:creds]
                    @test creds.access_key_id == "RIGHT_ACCESS_ID2"
                    @test creds.secret_key == "RIGHT_ACCESS_KEY2"

                    # Check profile persists on renewal
                    creds.access_key_id = "WRONG_ACCESS_ID2"
                    creds.secret_key = "WRONG_ACCESS_KEY2"
                    creds = check_credentials(creds, force_refresh=true)

                    @test creds.access_key_id == "RIGHT_ACCESS_ID2"
                    @test creds.secret_key == "RIGHT_ACCESS_KEY2"
                end

                @testset "Assume Role" begin
                    # Check we try to assume a role
                    ENV["AWS_DEFAULT_PROFILE"] = "test:dev"

                    try
                        aws_config()
                        @test false
                    catch e
                        @test e isa AWSException
                        @test ecode(e) == "InvalidClientTokenId"
                    end

                    # Check we try to assume a role
                    ENV["AWS_DEFAULT_PROFILE"] = "test:sub-dev"
                    let oldout = stdout
                        r,w = redirect_stdout()
                        try
                            aws_config()
                            @test false
                        catch e
                            @test e isa AWSException
                            @test ecode(e) == "InvalidClientTokenId"
                        end
                        redirect_stdout(oldout)
                        close(w)
                        output = String(read(r))
                        occursin("Assuming \"test:dev\"", output)
                        occursin("Assuming \"test\"", output)
                        close(r)
                    end
                end
            end
        end
    end
end

@testset "XML Parsing" begin
    XML(x)=parse_xml(x)

    xml = """
    <CreateQueueResponse>
        <CreateQueueResult>
            <QueueUrl>
                http://queue.amazonaws.com/123456789012/testQueue
            </QueueUrl>
        </CreateQueueResult>
        <ResponseMetadata>
            <RequestId>
                7a62c49f-347e-4fc4-9331-6e8e7a96aa73
            </RequestId>
        </ResponseMetadata>
    </CreateQueueResponse>
    """

    @assert XML(xml)["CreateQueueResult"]["QueueUrl"] ==
          "http://queue.amazonaws.com/123456789012/testQueue"

    xml = """
    <GetUserResponse xmlns="https://iam.amazonaws.com/doc/2010-05-08/">
      <GetUserResult>
        <User>
          <PasswordLastUsed>2015-12-23T22:45:36Z</PasswordLastUsed>
          <Arn>arn:aws:iam::012541411202:root</Arn>
          <UserId>012541411202</UserId>
          <CreateDate>2015-09-15T01:07:23Z</CreateDate>
        </User>
      </GetUserResult>
      <ResponseMetadata>
        <RequestId>837446c9-abaf-11e5-9f63-65ae4344bd73</RequestId>
      </ResponseMetadata>
    </GetUserResponse>
    """

    @test XML(xml)["GetUserResult"]["User"]["Arn"] == "arn:aws:iam::012541411202:root"


    xml = """
    <GetQueueAttributesResponse>
      <GetQueueAttributesResult>
        <Attribute>
          <Name>ReceiveMessageWaitTimeSeconds</Name>
          <Value>2</Value>
        </Attribute>
        <Attribute>
          <Name>VisibilityTimeout</Name>
          <Value>30</Value>
        </Attribute>
        <Attribute>
          <Name>ApproximateNumberOfMessages</Name>
          <Value>0</Value>
        </Attribute>
        <Attribute>
          <Name>ApproximateNumberOfMessagesNotVisible</Name>
          <Value>0</Value>
        </Attribute>
        <Attribute>
          <Name>CreatedTimestamp</Name>
          <Value>1286771522</Value>
        </Attribute>
        <Attribute>
          <Name>LastModifiedTimestamp</Name>
          <Value>1286771522</Value>
        </Attribute>
        <Attribute>
          <Name>QueueArn</Name>
          <Value>arn:aws:sqs:us-east-1:123456789012:qfoo</Value>
        </Attribute>
        <Attribute>
          <Name>MaximumMessageSize</Name>
          <Value>8192</Value>
        </Attribute>
        <Attribute>
          <Name>MessageRetentionPeriod</Name>
          <Value>345600</Value>
        </Attribute>
      </GetQueueAttributesResult>
      <ResponseMetadata>
        <RequestId>1ea71be5-b5a2-4f9d-b85a-945d8d08cd0b</RequestId>
      </ResponseMetadata>
    </GetQueueAttributesResponse>
    """

    d = Dict(a["Name"] => a["Value"] for a in XML(xml)["GetQueueAttributesResult"]["Attribute"])

    @test d["MessageRetentionPeriod"] == "345600"
    @test d["CreatedTimestamp"] == "1286771522"


    xml = """
    <?xml version="1.0" encoding="UTF-8"?>
    <ListAllMyBucketsResult xmlns="http://s3.amazonaws.com/doc/2006-03-01">
      <Owner>
        <ID>bcaf1ffd86f461ca5fb16fd081034f</ID>
        <DisplayName>webfile</DisplayName>
      </Owner>
      <Buckets>
        <Bucket>
          <Name>quotes</Name>
          <CreationDate>2006-02-03T16:45:09.000Z</CreationDate>
        </Bucket>
        <Bucket>
          <Name>samples</Name>
          <CreationDate>2006-02-03T16:41:58.000Z</CreationDate>
        </Bucket>
      </Buckets>
    </ListAllMyBucketsResult>
    """

    @test map(b->b["Name"], XML(xml)["Buckets"]["Bucket"]) == ["quotes", "samples"]


    xml = """
    <ListDomainsResponse>
      <ListDomainsResult>
        <DomainName>Domain1</DomainName>
        <DomainName>Domain2</DomainName>
        <NextToken>TWV0ZXJpbmdUZXN0RG9tYWluMS0yMDA3MDYwMTE2NTY=</NextToken>
      </ListDomainsResult>
      <ResponseMetadata>
        <RequestId>eb13162f-1b95-4511-8b12-489b86acfd28</RequestId>
        <BoxUsage>0.0000219907</BoxUsage>
      </ResponseMetadata>
    </ListDomainsResponse>
    """

    @test XML(xml)["ListDomainsResult"]["DomainName"] == ["Domain1", "Domain2"]
end

@testset "AWS Signature Version 4" begin
    function aws4_request_headers_test()

        r = @SymDict(
            creds         = AWSCredentials(
                                "AKIDEXAMPLE",
                                "wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY"
                            ),
            region        = "us-east-1",
            verb          = "POST",
            service       = "iam",
            url           = "http://iam.amazonaws.com/",
            content       = "Action=ListUsers&Version=2010-05-08",
            headers       = Dict(
                                "Content-Type" =>
                                "application/x-www-form-urlencoded; charset=utf-8",
                                "Host" => "iam.amazonaws.com"
                            )
        )

        AWSCore.sign!(r, DateTime("2011-09-09T23:36:00"))

        h = r[:headers]
        out = join(["$k: $(h[k])\n" for k in sort(collect(keys(h)))])

        expected = (
            "Authorization: AWS4-HMAC-SHA256 " *
            "Credential=AKIDEXAMPLE/20110909/us-east-1/iam/aws4_request, " *
            "SignedHeaders=content-md5;content-type;host;" *
            "x-amz-content-sha256;x-amz-date, " *
            "Signature=1a6db936024345449ef4507f890c5161" *
                     "bbfa2ff2490866653bb8b58b7ba1554a\n" *
            "Content-MD5: r2d9jRneykOuUqFWSFXKCg==\n" *
            "Content-Type: application/x-www-form-urlencoded; " *
                         "charset=utf-8\n" *
            "Host: iam.amazonaws.com\n" *
            "x-amz-content-sha256: b6359072c78d70ebee1e81adcbab4f01" *
                                 "bf2c23245fa365ef83fe8f1f955085e2\n" *
            "x-amz-date: 20110909T233600Z\n")

        @test out == expected
    end

    aws4_request_headers_test()
end

@testset "ARN" begin
    @test arn(aws,"s3","foo/bar") == "arn:aws:s3:::foo/bar"
    @test arn(aws,"s3","foo")     == "arn:aws:s3:::foo"
    @test arn(aws,"sqs", "au-test-queue", "ap-southeast-2", "1234") ==
          "arn:aws:sqs:ap-southeast-2:1234:au-test-queue"

    @test arn(aws,"sns","*","*",1234) == "arn:aws:sns:*:1234:*"
    @test arn(aws,"iam","role/foo-role", "", 1234) ==
          "arn:aws:iam::1234:role/foo-role"
end

@testset "Misc" begin
    @test HTTP.escapepath("invocations/function:f:PROD") ==
                          "invocations/function%3Af%3APROD"
end

@testset "Exception" begin
    code = "InvalidSignatureException"
    message = "Signature expired: ..."
    body = """
        {
           "__type": "$code",
           "message": "$message"
        }
        """
    resp = HTTP.Messages.Response(400, body)
    HTTP.setheader(resp.headers, "Content-Type" => "application/x-amz-json-1.1")

    ex = AWSException(HTTP.StatusError(400, resp))

    @test ex.code == code
    @test ex.message == message
end

instance_type = get(ENV, "AWSCORE_INSTANCE_TYPE", "")
if instance_type == "EC2"
    @testset "EC2" begin
        @test_nowarn AWSCore.ec2_metadata("instance-id")
        @test startswith(AWSCore.ec2_metadata("instance-id"), "i-")

        @test AWSCore.localhost_maybe_ec2()
        @test AWSCore.localhost_is_ec2()
        @test_nowarn AWSCore.ec2_instance_credentials()
        ec2_creds = AWSCore.ec2_instance_credentials()
        @test ec2_creds !== nothing

        default_creds = AWSCredentials()
        @test default_creds.access_key_id == ec2_creds.access_key_id
        @test default_creds.secret_key == ec2_creds.secret_key
    end
elseif instance_type == "ECS"
    @testset "ECS" begin
        @test_nowarn AWSCore.ecs_instance_credentials()
        ecs_creds = AWSCore.ecs_instance_credentials()
        @test ecs_creds !== nothing

        default_creds = AWSCredentials()
        @test default_creds.access_key_id == ecs_creds.access_key_id
        @test default_creds.secret_key == ecs_creds.secret_key
    end
end

end # testset "AWSCore"


#==============================================================================#
# End of file.
#==============================================================================#
