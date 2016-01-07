#==============================================================================#
# AWSCore/test/runtests.jl
#
# Copyright Sam O'Connor 2014 - All rights reserved
#==============================================================================#


using Base.Test
using AWSCore
using SymDict
using Retry
using XMLDict



#-------------------------------------------------------------------------------
# Load credentials...
#-------------------------------------------------------------------------------

aws = aws_config()

user = aws_user_arn(aws)

@test ismatch(r"^arn:aws:iam::[0-9]+:[^:]+$", user)

println("Authenticated as: $user")

println("Testing exceptions...")
try
    do_request(post_request(aws, "iam", "2010-05-08",
                            Dict("Action" => "GetFoo",
                                 "ContentType" => "JSON")))
    @test false
catch e
    println(e)
    @test isa(e, AWSCore.InvalidAction)
end

try
    do_request(post_request(aws, "iam", "2010-05-08",
                            Dict("Action" => "GetUser",
                                 "UserName" => "notauser",
                                 "ContentType" => "JSON")))
    @test false
catch e
    println(e)
    @test isa(e, AWSCore.AccessDenied)
end

try
    do_request(post_request(aws, "iam", "2010-05-08",
                            Dict("Action" => "GetUser",
                                 "UserName" => "@#!%%!",
                                 "ContentType" => "JSON")))
    @test false
catch e
    println(e)
    @test isa(e, AWSCore.ValidationError)
end

try
    do_request(post_request(aws, "iam", "2010-05-08",
                            Dict("Action" => "CreateUser",
                                 "UserName" => "root",
                                 "ContentType" => "JSON")))
    @test false
catch e
    println(e)
    @test isa(e, AWSCore.AccessDenied)
end


println("User ARN ok.")



#-------------------------------------------------------------------------------
# XML Parsing tests
#-------------------------------------------------------------------------------

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

d = [a["Name"] => a["Value"] for a in XML(xml)["GetQueueAttributesResult"]["Attribute"]]

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


println("XML parsing ok.")



#-------------------------------------------------------------------------------
# AWS Signature Version 4 test
#-------------------------------------------------------------------------------


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


println("AWS4 Signature ok.")



#-------------------------------------------------------------------------------
# Arn tests
#-------------------------------------------------------------------------------

@test arn(aws,"s3","foo/bar") == "arn:aws:s3:::foo/bar"
@test arn(aws,"s3","foo")     == "arn:aws:s3:::foo"
@test arn(aws,"sqs", "au-test-queue", "ap-southeast-2", "1234") ==
      "arn:aws:sqs:ap-southeast-2:1234:au-test-queue"

@test arn(aws,"sns","*","*",1234) == "arn:aws:sns:*:1234:*"
@test arn(aws,"iam","role/foo-role", "", 1234) == 
      "arn:aws:iam::1234:role/foo-role"


println("ARNs ok.")



#-------------------------------------------------------------------------------
# Endpoint URL tests
#-------------------------------------------------------------------------------


import AWSCore: aws_endpoint


@test aws_endpoint("sqs", "us-east-1") == "http://sqs.us-east-1.amazonaws.com"
@test aws_endpoint("sdb", "us-east-1") == "http://sdb.amazonaws.com"
@test aws_endpoint("iam", "us-east-1") == "https://iam.amazonaws.com"
@test aws_endpoint("iam", "eu-west-1") == "https://iam.amazonaws.com"
@test aws_endpoint("sts", "us-east-1") == "https://sts.amazonaws.com"
@test aws_endpoint("sqs", "eu-west-1") == "http://sqs.eu-west-1.amazonaws.com"
@test aws_endpoint("sdb", "eu-west-1") == "http://sdb.eu-west-1.amazonaws.com"
@test aws_endpoint("sns", "eu-west-1") == "http://sns.eu-west-1.amazonaws.com"

@test aws_endpoint("s3", "us-east-1", "bucket") == 
      "http://bucket.s3.amazonaws.com"
@test aws_endpoint("s3", "eu-west-1", "bucket") ==
      "http://bucket.s3-eu-west-1.amazonaws.com"


println("Endpoints ok.")



#==============================================================================#
# End of file.
#==============================================================================#
