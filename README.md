# AWSCore.jl

[![Travis](https://travis-ci.org/JuliaCloud/AWSCore.jl.svg?branch=master)](https://travis-ci.org/JuliaCloud/AWSCore.jl)

Julia interface for [Amazon Web Services](https://aws.amazon.com).

This package provides core infrastructure functions and types.

The [AWSSDK.jl](https://github.com/JuliaCloud/AWSSDK.jl) package provides
automatically generated low-level API wrappers for each operation in each
Amazon Web Service.

The following high-level packages are also available:
[AWS S3](http://github.com/samoconnor/AWSS3.jl),
[AWS SQS](http://github.com/samoconnor/AWSSQS.jl),
[AWS SNS](http://github.com/samoconnor/AWSSNS.jl),
[AWS IAM](http://github.com/samoconnor/AWSIAM.jl),
[AWS EC2](http://github.com/samoconnor/AWSEC2.jl),
[AWS Lambda](http://github.com/samoconnor/AWSLambda.jl),
[AWS SES](http://github.com/samoconnor/AWSSES.jl) and
[AWS SDB](http://github.com/samoconnor/AWSSDB.jl).
These packages include operation specific result structure parsing, error
handling, type convenience functions, iterators, etc.

Full documentation [is available here](https://juliacloud.github.io/AWSCore.jl/build/index.html),
or see below for some examples of how to get started.


There are three ways to use `AWSCore`:

1. Call [`AWSCore/Services.jl`](https://github.com/JuliaCloud/AWSCore.jl/blob/master/src/Services.jl)
functions directly:
```julia
using AWSCore.Services.cloudformation
cloudformation("CreateStack",
               StackName = "mystack",
               TemplateBody = readstring("cloudformation_template.yaml"),
               Parameters = [["ParameterKey"   => "Foo",
                              "ParameterValue" => "bar"]],
               Capabilities = ["CAPABILITY_IAM"])
```

2. Use the low-level [`AWSSDK`](https://github.com/JuliaCloud/AWSSDK.jl) wrappers:
```
using AWSSDK.S3.list_buckets
r = list_buckets()
buckets = [b["Name"] for b in r["Buckets"]["Bucket"]]
```

3. Use one of the high-level convenience packages:
```
using AWSS3
buckets = s3_list_buckets()
```


### Examples


Create an S3 bucket and store some data...

```julia
aws = aws_config()
s3_create_bucket(aws, "my.bucket")
s3_enable_versioning(aws, "my.bucket")

s3_put(aws, "my.bucket", "key", "Hello!")
println(s3_get(aws, "my.bucket", "key"))
```


Post a message to a queue...

```julia
q = sqs_get_queue(aws, "my-queue")

sqs_send_message(q, "Hello!")

m = sqs_receive_message(q)
println(m["message"])
sqs_delete_message(q, m)
```


Post a message to a notification topic...

```julia
sns_create_topic(aws, "my-topic")
sns_subscribe_sqs(aws, "my-topic", q; raw = true)

sns_publish(aws, "my-topic", "Hello!")

m = sqs_receive_message(q)
println(m["message"])
sqs_delete_message(q, m)

```


Start an EC2 server and fetch info...

```julia
ec2(aws, "StartInstances", {"InstanceId.1" => my_instance_id})
r = ec2(aws, "DescribeInstances", {"Filter.1.Name" => "instance-id",
                                   "Filter.1.Value.1" => my_instance_id})
println(r)
```


Create an IAM user...

```julia
iam(aws, "CreateUser", {"UserName" => "me"})
```


Automatically assume a role([details](https://docs.aws.amazon.com/cli/latest/userguide/cli-roles.html))...

For a user with the IAM profile `valid-iam-profile` already in their credentials file
that has permissions to a role called `example-role-name`:
 
~/.aws/config:
```
[profile example-role-name]
role_arn = arn:aws:iam::[role number here]:role/example-role-name
source_profile = valid-iam-profile
```


```julia
ENV["AWS_PROFILE"] = "example-role-name"
AWSCore.aws_config()
```
