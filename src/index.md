# AWSCore.jl Documentation

Amazon Web Services Core Functions and Types.

[https://github.com/samoconnor/AWSCore.jl](https://github.com/samoconnor/AWSCore.jl)


# AWSCore Configuration

```@meta
CurrentModule = AWSCore
```
```@setup AWSCore
using AWSCore
```

```@docs
AWSConfig
aws_config
default_aws_config
aws_user_arn
aws_account_number
```


# AWSCore Internals

## AWS Security Credentials

```@docs
AWSCredentials
env_instance_credentials
dot_aws_credentials
ec2_instance_credentials
```

## Endpoints and Resource Names
```@docs
aws_endpoint
```
```@example AWSCore
AWSCore.aws_endpoint("sqs", "eu-west-1")
```
```@docs
arn
```
```@example AWSCore
AWSCore.arn("sqs", "au-test-queue", "ap-southeast-2", "1234")
```
```@example AWSCore
AWSCore.arn(default_aws_config(), "sns", "au-test-topic")
```
```@docs
arn_region
```

## API Requests

```@docs
AWSRequest
do_request
dump_aws_request
post_request
```
```@example AWSCore
post_request(aws_config(), "sdb", "2009-04-15", Dict("Action" => "ListDomains"))
```


## Execution Environemnt

```@docs
localhost_is_lambda
localhost_is_ec2
ec2_metadata
```


## Utility Functions

```@docs
mime_multipart
```
```@example AWSCore
println(AWSCore.mime_multipart([
     ("foo.txt", "text/plain", "foo"),
     ("bar.txt", "text/plain", "bar")
 ]))
```
