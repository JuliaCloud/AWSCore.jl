# Julia 1.0: Type definition not allowed inside a local scope, therefore we must define our
# TestLayer outside of the @testset
abstract type TestLayer{Next <: HTTP.Layer} <: HTTP.Layer{Next} end

@testset "AWS Signature Version 4" begin
    r = @SymDict(
        creds = AWSCredentials("AKIDEXAMPLE","wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY"),
        region = "us-east-1",
        verb = "POST",
        service = "iam",
        url = "http://iam.amazonaws.com/",
        content = "Action=ListUsers&Version=2010-05-08",
        headers = Dict(
            "Content-Type" => "application/x-www-form-urlencoded; charset=utf-8",
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
        "Signature=1a6db936024345449ef4507f890c5161bbfa2ff2490866653bb8b58b7ba1554a\n" *
        "Content-MD5: r2d9jRneykOuUqFWSFXKCg==\n" *
        "Content-Type: application/x-www-form-urlencoded; charset=utf-8\n" *
        "Host: iam.amazonaws.com\n" *
        "x-amz-content-sha256: b6359072c78d70ebee1e81adcbab4f01bf2c23245fa365ef83fe8f1f955085e2\n" *
        "x-amz-date: 20110909T233600Z\n"
    )

    @test out == expected
end

@testset "HTTP Request - AWS4AuthLayer" begin
    test_access_key = "TEST_ACCESS_KEY"
    test_secret_key = "TEST_SECRET_KEY"

    function HTTP.request(::Type{TestLayer{Next}}, io::IO, req, body; kw...) where Next
        @test kw[:aws_access_key_id] == test_access_key
        @test kw[:aws_secret_access_key] == test_secret_key
        return HTTP.request(Next, io, req, body; kw...)
    end

    function _create_stack()
        custom_stack = insert(stack(), StreamLayer, TestLayer)
        custom_stack = insert(custom_stack, RetryLayer, SignatureV4.AWS4AuthLayer)
        result = HTTP.request(custom_stack, "GET", "http://httpbin.org/ip")
        @test result.status == 200
    end

    @testset "Environment Variables" begin
        withenv(
            "AWS_ACCESS_KEY_ID" => test_access_key,
            "AWS_SECRET_ACCESS_KEY" => test_secret_key,
        ) do
            _create_stack()
        end
    end

    @testset "Credentials File - Default" begin
        mktemp() do creds_file, creds_io
            write(creds_io, """
                [default]
                aws_access_key_id=$(test_access_key)
                aws_secret_access_key=$(test_secret_key)
            """)
            close(creds_io)

            withenv(
                "AWS_ACCESS_KEY_ID" => nothing,
                "AWS_SECRET_ACCESS_KEY" => nothing,
                "AWS_SHARED_CREDENTIALS_FILE" => creds_file,
            ) do
                _create_stack()
            end
        end
    end

    @testset "Credentials File - Specified Profile" begin
        aws_profile = "test"

        mktemp() do creds_file, creds_io
            write(creds_io, """
                [$(aws_profile)]
                aws_access_key_id=$(test_access_key)
                aws_secret_access_key=$(test_secret_key)
            """)
            close(creds_io)

            withenv(
                "AWS_PROFILE" => aws_profile,
                "AWS_ACCESS_KEY_ID" => nothing,
                "AWS_SECRET_ACCESS_KEY" => nothing,
                "AWS_SHARED_CREDENTIALS_FILE" => creds_file,
            ) do
                _create_stack()
            end
        end
    end

    @testset "Configuration File" begin
        mktemp() do config_file, config_io
            write(config_io, """
                [default]
                aws_access_key_id=$(test_access_key)
                aws_secret_access_key=$(test_secret_key)
            """)
            close(config_io)

            withenv(
                "AWS_ACCESS_KEY_ID" => nothing,
                "AWS_SECRET_ACCESS_KEY" => nothing,
                "AWS_CONFIG_FILE" => config_file,
            ) do
                cred_patch = @patch dot_aws_credentials_file() = ""

                apply([cred_patch]) do
                    _create_stack()
                end
            end
        end
    end
end
