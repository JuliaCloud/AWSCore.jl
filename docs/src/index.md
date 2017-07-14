# AWSCore.jl Documentation

Amazon Web Services Core Functions and Types.

```@contents
```

```@meta
CurrentModule = AWSCore
```

## Configruation

```@docs
AWSConfig
aws_config
default_aws_config
aws_user_arn
aws_account_number
```


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
arn
arn_region
```


## API Requests

```@docs
AWSRequest
post_request
do_request
dump_aws_request
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
