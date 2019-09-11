@testset "ARN" begin
    @test arn(aws,"s3","foo/bar") == "arn:aws:s3:::foo/bar"
    @test arn(aws,"s3","foo")     == "arn:aws:s3:::foo"
    @test arn(aws,"sqs", "au-test-queue", "ap-southeast-2", "1234") ==
          "arn:aws:sqs:ap-southeast-2:1234:au-test-queue"
    @test arn(aws,"sns","*","*",1234) == "arn:aws:sns:*:1234:*"
    @test arn(aws,"iam","role/foo-role", "", 1234) == "arn:aws:iam::1234:role/foo-role"
end
