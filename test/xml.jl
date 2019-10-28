@testset "QueueURL" begin
    expected = "http://queue.amazonaws.com/123456789012/testQueue"

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

    @assert parse_xml(xml)["CreateQueueResult"]["QueueUrl"] == expected
end

@testset "User ARN" begin
    expected = "arn:aws:iam::012541411202:root"

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

    @test parse_xml(xml)["GetUserResult"]["User"]["Arn"] == expected
end

@testset "Domain Names" begin
    expected = ["Domain1", "Domain2"]

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

    @test parse_xml(xml)["ListDomainsResult"]["DomainName"] == expected
end

@testset "Bucket Names" begin
    expected = ["quotes", "samples"]

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

    @test map(b->b["Name"], parse_xml(xml)["Buckets"]["Bucket"]) == expected
end

@testset "Attributes" begin
    expected_retention_period = "345600"
    expected_timestamp = "1286771522"

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

    d = Dict(a["Name"] => a["Value"] for a in parse_xml(xml)["GetQueueAttributesResult"]["Attribute"])

    @test d["MessageRetentionPeriod"] == expected_retention_period
    @test d["CreatedTimestamp"] == expected_timestamp
end