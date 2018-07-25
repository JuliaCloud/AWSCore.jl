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

@testset "AssumeRole" begin
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

                # Check credentials load 
                config = AWSCore.aws_config()
                creds = config[:creds]

                @test creds.access_key_id == "TEST_ACCESS_ID"
                @test creds.secret_key == "TEST_ACCESS_KEY"

                # Check credential file takes precedence over config
                ENV["AWS_DEFAULT_PROFILE"] = "test2"
                config = AWSCore.aws_config()
                creds = config[:creds]

                @test creds.access_key_id == "RIGHT_ACCESS_ID2"
                @test creds.secret_key == "RIGHT_ACCESS_KEY2"

                # Check credentials take precedence over role
                ENV["AWS_DEFAULT_PROFILE"] = "test3"
                config = AWSCore.aws_config()
                creds = config[:creds]

                @test creds.access_key_id == "RIGHT_ACCESS_ID3"
                @test creds.secret_key == "RIGHT_ACCESS_KEY3"

                ENV["AWS_DEFAULT_PROFILE"] = "test4"
                config = AWSCore.aws_config()
                creds = config[:creds]

                @test creds.access_key_id == "RIGHT_ACCESS_ID4"
                @test creds.secret_key == "RIGHT_ACCESS_KEY4"

                # Check we try to assume a role
                ENV["AWS_DEFAULT_PROFILE"] = "test:dev"

                try
                    AWSCore.aws_config()
                    @test false
                catch e
                    @test e isa AWSCore.AWSException
                    @test ecode(e) == "InvalidClientTokenId"
                end

                # Check we try to assume a role
                ENV["AWS_DEFAULT_PROFILE"] = "test:sub-dev"
                let oldout = STDOUT
                    r,w = redirect_stdout()
                    try
                        AWSCore.aws_config()
                        @test false
                    catch e
                        @test e isa AWSCore.AWSException
                        @test ecode(e) == "InvalidClientTokenId"
                    end
                    redirect_stdout(oldout)
                    close(w)
                    output = convert(String, read(r))
                    contains(output, "Assuming \"test:dev\"")
                    contains(output, "Assuming \"test\"")
                    close(r)
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

end # testset "AWSCore"


#==============================================================================#
# End of file.
#==============================================================================#
