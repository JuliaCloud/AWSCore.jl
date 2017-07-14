# AWSCore

Amazon Web Services Core Functions and Types.

[Documentation](http://samoconnor.github.io/AWSCore.jl/build/index.html)

See seperate modules for service interfaces:

| Package | Status |
| --------| ------ |
| [AWS S3](http://github.com/samoconnor/AWSS3.jl) | [![Build Status](https://travis-ci.org/samoconnor/AWSS3.jl.svg)](https://travis-ci.org/samoconnor/AWSS3.jl) |
| [AWS SQS](http://github.com/samoconnor/AWSSQS.jl) | [![Build Status](https://travis-ci.org/samoconnor/AWSSQS.jl.svg)](https://travis-ci.org/samoconnor/AWSSQS.jl) |
| [AWS SNS](http://github.com/samoconnor/AWSSNS.jl) | [![Build Status](https://travis-ci.org/samoconnor/AWSSNS.jl.svg)](https://travis-ci.org/samoconnor/AWSSNS.jl) |
| [AWS IAM](http://github.com/samoconnor/AWSIAM.jl) | [![Build Status](https://travis-ci.org/samoconnor/AWSIAM.jl.svg)](https://travis-ci.org/samoconnor/AWSIAM.jl) |
| [AWS EC2](http://github.com/samoconnor/AWSEC2.jl) | [![Build Status](https://travis-ci.org/samoconnor/AWSEC2.jl.svg)](https://travis-ci.org/samoconnor/AWSEC2.jl) |
| [AWS Lambda](http://github.com/samoconnor/AWSLambda.jl) | [![Build Status](https://travis-ci.org/samoconnor/AWSLambda.jl.svg)](https://travis-ci.org/samoconnor/AWSLambda.jl) |
| [AWS SES](http://github.com/samoconnor/AWSSES.jl) | [![Build Status](https://travis-ci.org/samoconnor/AWSSES.jl.svg)](https://travis-ci.org/samoconnor/AWSSES.jl) |
| [AWS SDB](http://github.com/samoconnor/AWSSDB.jl) | [![Build Status](https://travis-ci.org/samoconnor/AWSSDB.jl.svg)](https://travis-ci.org/samoconnor/AWSSDB.jl) |

[![Build Status](https://travis-ci.org/samoconnor/AWSCore.jl.svg)](https://travis-ci.org/samoconnor/AWSCore.jl)

### Features

AWS Signature Version 4.

Automatic HTTP request retry with exponential back-off.

Parsing of XML and JSON API error messages to AWSException type.

Automatic API Request retry in case of ExpiredToken or HTTP Redirect.


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


Get a list of DynamoDB tables...

(See [DynamoDB.jl](https://github.com/samuelpowell/DynamoDB.jl))

```julia
r = dynamodb(aws, "ListTables", "{}")
println(r)
```
