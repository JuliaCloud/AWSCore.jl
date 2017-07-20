var documenterSearchIndex = {"docs": [

{
    "location": "index.html#",
    "page": "AWSCore.jl",
    "title": "AWSCore.jl",
    "category": "page",
    "text": ""
},

{
    "location": "index.html#AWSCore.jl-Documentation-1",
    "page": "AWSCore.jl",
    "title": "AWSCore.jl Documentation",
    "category": "section",
    "text": "Amazon Web Services Core Functions and Types.https://github.com/samoconnor/AWSCore.jl"
},

{
    "location": "index.html#AWSCore.AWSConfig",
    "page": "AWSCore.jl",
    "title": "AWSCore.AWSConfig",
    "category": "Type",
    "text": "Most AWSCore functions take a AWSConfig dictionary as the first argument. This dictionary holds AWSCredentials and AWS region configuration.\n\naws = AWSConfig(:creds => AWSCredentials(), :region => \"us-east-1\")`\n\n\n\n"
},

{
    "location": "index.html#AWSCore.aws_config",
    "page": "AWSCore.jl",
    "title": "AWSCore.aws_config",
    "category": "Function",
    "text": "The aws_config function provides a simple way to creates an AWSConfig configuration dictionary.\n\n>aws = aws_config()\n>aws = aws_config(creds = my_credentials)\n>aws = aws_config(region = \"ap-southeast-2\")\n\nBy default, the aws_config attempts to load AWS credentials from:\n\nAWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY environemnt variables,\n~/.aws/credentials or\nEC2 Instance Credentials.\n\nA ~/.aws/credentials file can be created using the AWS CLI command aws configrue. Or it can be created manually:\n\n[default]\naws_access_key_id = AKIAXXXXXXXXXXXXXXXX\naws_secret_access_key = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX\n\nIf your ~/.aws/credentials file contains multiple profiles you can select a profile by setting the AWS_DEFAULT_PROFILE environment variable.\n\naws_config understands the following AWS CLI environment variables: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN, AWS_DEFAULT_REGION, AWS_DEFAULT_PROFILE and AWS_CONFIG_FILE.\n\nAn configuration dictionary can also be created directly from a key pair as follows. However, putting access credentials in source code is discouraged.\n\naws = aws_config(creds = AWSCredentials(\"AKIAXXXXXXXXXXXXXXXX\",\n                                        \"XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX\"))\n\n\n\n"
},

{
    "location": "index.html#AWSCore.default_aws_config",
    "page": "AWSCore.jl",
    "title": "AWSCore.default_aws_config",
    "category": "Function",
    "text": "default_aws_config returns a global shared AWSConfig object obtained by calling aws_config with no optional arguments.\n\n\n\n"
},

{
    "location": "index.html#AWSCore.aws_user_arn",
    "page": "AWSCore.jl",
    "title": "AWSCore.aws_user_arn",
    "category": "Function",
    "text": "aws_user_arn(::AWSConfig)\n\nUnique Amazon Resource Name for configrued user.\n\ne.g. \"arn:aws:iam::account-ID-without-hyphens:user/Bob\"\n\n\n\n"
},

{
    "location": "index.html#AWSCore.aws_account_number",
    "page": "AWSCore.jl",
    "title": "AWSCore.aws_account_number",
    "category": "Function",
    "text": "aws_account_number(::AWSConfig)\n\n12-digit AWS Account Number.\n\n\n\n"
},

{
    "location": "index.html#AWSCore-Configuration-1",
    "page": "AWSCore.jl",
    "title": "AWSCore Configuration",
    "category": "section",
    "text": "CurrentModule = AWSCoreusing AWSCoreAWSConfig\naws_config\ndefault_aws_config\naws_user_arn\naws_account_number"
},

{
    "location": "index.html#AWSCore-Internals-1",
    "page": "AWSCore.jl",
    "title": "AWSCore Internals",
    "category": "section",
    "text": ""
},

{
    "location": "index.html#AWSCore.AWSCredentials",
    "page": "AWSCore.jl",
    "title": "AWSCore.AWSCredentials",
    "category": "Type",
    "text": "When you interact with AWS, you specify your AWS Security Credentials to verify who you are and whether you have permission to access the resources that you are requesting. AWS uses the security credentials to authenticate and authorize your requests.\n\nThe fields access_key_id and secret_key hold the access keys used to authenticate API requests (see Creating, Modifying, and Viewing Access Keys).\n\nTemporary Security Credentials require the extra session token field.\n\nThe user_arn and account_number fields are used to cache the result of the aws_user_arn and aws_account_number functions.\n\nThe AWSCredentials() constructor tries to load local Credentials from environment variables, ~/.aws/credentials or EC2 instance credentials. \n\n\n\n"
},

{
    "location": "index.html#AWSCore.env_instance_credentials",
    "page": "AWSCore.jl",
    "title": "AWSCore.env_instance_credentials",
    "category": "Function",
    "text": "Load Credentials from environment variables AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY etc. (e.g. in Lambda sandbox).\n\n\n\n"
},

{
    "location": "index.html#AWSCore.dot_aws_credentials",
    "page": "AWSCore.jl",
    "title": "AWSCore.dot_aws_credentials",
    "category": "Function",
    "text": "Load Credentials from AWS CLI ~/.aws/credentials file.\n\n\n\n"
},

{
    "location": "index.html#AWSCore.ec2_instance_credentials",
    "page": "AWSCore.jl",
    "title": "AWSCore.ec2_instance_credentials",
    "category": "Function",
    "text": "Load Instance Profile Credentials for EC2 virtual machine.\n\n\n\n"
},

{
    "location": "index.html#AWS-Security-Credentials-1",
    "page": "AWSCore.jl",
    "title": "AWS Security Credentials",
    "category": "section",
    "text": "AWSCredentials\nenv_instance_credentials\ndot_aws_credentials\nec2_instance_credentials"
},

{
    "location": "index.html#AWSCore.aws_endpoint",
    "page": "AWSCore.jl",
    "title": "AWSCore.aws_endpoint",
    "category": "Function",
    "text": "aws_endpoint(service, [region, [hostname_prefix]])\n\nGenerate service endpoint URL for service and  region.\n\n\n\n"
},

{
    "location": "index.html#AWSCore.arn",
    "page": "AWSCore.jl",
    "title": "AWSCore.arn",
    "category": "Function",
    "text": "arn([::AWSConfig], service, resource, [region, [account]])\n\nGenerate an Amazon Resource Name for service and resource.\n\n\n\n"
},

{
    "location": "index.html#AWSCore.arn_region",
    "page": "AWSCore.jl",
    "title": "AWSCore.arn_region",
    "category": "Function",
    "text": "arg_region(arn)\n\nExtract region name from arn.\n\n\n\n"
},

{
    "location": "index.html#Endpoints-and-Resource-Names-1",
    "page": "AWSCore.jl",
    "title": "Endpoints and Resource Names",
    "category": "section",
    "text": "aws_endpointAWSCore.aws_endpoint(\"sqs\", \"eu-west-1\")arnAWSCore.arn(\"sqs\", \"au-test-queue\", \"ap-southeast-2\", \"1234\")AWSCore.arn(default_aws_config(), \"sns\", \"au-test-topic\")arn_region"
},

{
    "location": "index.html#AWSCore.AWSRequest",
    "page": "AWSCore.jl",
    "title": "AWSCore.AWSRequest",
    "category": "Type",
    "text": "The AWSRequest dictionary describes a single API request: It contains the following keys:\n\n:creds => AWSCredentials for authentication.\n:verb => \"GET\", \"PUT\", \"POST\" or \"DELETE\"\n:url => service endpoint url (returned by aws_endpoint)\n:headers => HTTP headers\n:content => HTTP body\n:resource => HTTP request path\n:region => AWS region\n:service => AWS service name\n\n\n\n"
},

{
    "location": "index.html#AWSCore.do_request",
    "page": "AWSCore.jl",
    "title": "AWSCore.do_request",
    "category": "Function",
    "text": "do_request(::AWSRequest)\n\nSubmit an API request, return the result.\n\n\n\n"
},

{
    "location": "index.html#AWSCore.dump_aws_request",
    "page": "AWSCore.jl",
    "title": "AWSCore.dump_aws_request",
    "category": "Function",
    "text": "Pretty-print AWSRequest dictionary.\n\n\n\n"
},

{
    "location": "index.html#AWSCore.post_request",
    "page": "AWSCore.jl",
    "title": "AWSCore.post_request",
    "category": "Function",
    "text": "post_request(::AWSConfig, service, version, query)\n\nConstruct a AWSRequest dictionary for a HTTP POST request.\n\n\n\n"
},

{
    "location": "index.html#API-Requests-1",
    "page": "AWSCore.jl",
    "title": "API Requests",
    "category": "section",
    "text": "AWSRequest\ndo_request\ndump_aws_request\npost_requestpost_request(aws_config(), \"sdb\", \"2009-04-15\", Dict(\"Action\" => \"ListDomains\"))"
},

{
    "location": "index.html#AWSCore.localhost_is_lambda",
    "page": "AWSCore.jl",
    "title": "AWSCore.localhost_is_lambda",
    "category": "Function",
    "text": "Is Julia running in an AWS Lambda sandbox?\n\n\n\n"
},

{
    "location": "index.html#AWSCore.localhost_is_ec2",
    "page": "AWSCore.jl",
    "title": "AWSCore.localhost_is_ec2",
    "category": "Function",
    "text": "Is Julia running on an EC2 virtual machine?\n\n\n\n"
},

{
    "location": "index.html#AWSCore.ec2_metadata",
    "page": "AWSCore.jl",
    "title": "AWSCore.ec2_metadata",
    "category": "Function",
    "text": "ec2_metadata(key)\n\nFetch EC2 meta-data for key.\n\n\n\n"
},

{
    "location": "index.html#Execution-Environemnt-1",
    "page": "AWSCore.jl",
    "title": "Execution Environemnt",
    "category": "section",
    "text": "localhost_is_lambda\nlocalhost_is_ec2\nec2_metadata"
},

{
    "location": "index.html#AWSCore.mime_multipart",
    "page": "AWSCore.jl",
    "title": "AWSCore.mime_multipart",
    "category": "Function",
    "text": "mime_multipart([header,] parts)\n\nEncode parts as a MIME Multipart message.\n\nparts is a Vector of (filename, content_type, content) Tuples.\n\n\n\n"
},

{
    "location": "index.html#Utility-Functions-1",
    "page": "AWSCore.jl",
    "title": "Utility Functions",
    "category": "section",
    "text": "mime_multipartprintln(AWSCore.mime_multipart([\n     (\"foo.txt\", \"text/plain\", \"foo\"),\n     (\"bar.txt\", \"text/plain\", \"bar\")\n ]))"
},

{
    "location": "AWSS3.html#",
    "page": "AWSS3.jl",
    "title": "AWSS3.jl",
    "category": "page",
    "text": ""
},

{
    "location": "AWSS3.html#AWS-S3-1",
    "page": "AWSS3.jl",
    "title": "AWS S3",
    "category": "section",
    "text": "CurrentModule = AWSS3using AWSS3https://github.com/samoconnor/AWSS3.jlPages = [\"AWSS3.md\"]"
},

{
    "location": "AWSS3.html#AWSS3.s3_get",
    "page": "AWSS3.jl",
    "title": "AWSS3.s3_get",
    "category": "Function",
    "text": "s3_get([::AWSConfig], bucket, path; <keyword arguments>)\n\nGet Object from path in bucket.\n\nOptional Arguments\n\nversion=: version of object to get.\nretry=true: try again on \"NoSuchBucket\", \"NoSuchKey\"               (common if object was recently created).\nraw=false:  return response as Vector{UInt8}               (by default return type depends on Content-Type header).\n\n\n\n"
},

{
    "location": "AWSS3.html#AWSS3.s3_get_file",
    "page": "AWSS3.jl",
    "title": "AWSS3.s3_get_file",
    "category": "Function",
    "text": "s3_get_file([::AWSConfig], bucket, path, filename; [version=])\n\nLike s3_get but streams result directly to filename.\n\n\n\n"
},

{
    "location": "AWSS3.html#AWSS3.s3_get_meta",
    "page": "AWSS3.jl",
    "title": "AWSS3.s3_get_meta",
    "category": "Function",
    "text": "s3_get_meta([::AWSConfig], bucket, path; [version=])\n\nHEAD Object\n\nRetrieves metadata from an object without returning the object itself.\n\n\n\n"
},

{
    "location": "AWSS3.html#AWSS3.s3_exists",
    "page": "AWSS3.jl",
    "title": "AWSS3.s3_exists",
    "category": "Function",
    "text": "s3_exists([::AWSConfig], bucket, path [version=])\n\nIs there an object in bucket at path?\n\n\n\n"
},

{
    "location": "AWSS3.html#AWSS3.s3_put",
    "page": "AWSS3.jl",
    "title": "AWSS3.s3_put",
    "category": "Function",
    "text": "s3_put([::AWSConfig], bucket, path, data; <keyword arguments>\n\nPUT Object data at path in bucket.\n\nOptional Arguments\n\ndata_type=; Content-Type header.\nencoding=; Content-Encoding header.\nmetadata::Dict=; x-amz-meta- headers.\ntags::Dict=; x-amz-tagging- headers                (see also s3_put_tags and s3_get_tags).\n\n\n\n"
},

{
    "location": "AWSS3.html#AWSS3.s3_purge_versions",
    "page": "AWSS3.jl",
    "title": "AWSS3.s3_purge_versions",
    "category": "Function",
    "text": "s3_purge_versions([::AWSConfig], bucket, [path [, pattern]])\n\nDELETE all object versions except for the latest version.\n\n\n\n"
},

{
    "location": "AWSS3.html#AWSS3.s3_delete",
    "page": "AWSS3.jl",
    "title": "AWSS3.s3_delete",
    "category": "Function",
    "text": "s3_delete([::AWSConfig], bucket, path; [version=]\n\nDELETE Object\n\n\n\n"
},

{
    "location": "AWSS3.html#AWSS3.s3_copy",
    "page": "AWSS3.jl",
    "title": "AWSS3.s3_copy",
    "category": "Function",
    "text": "s3_copy([::AWSConfig], bucket, path; to_bucket=bucket, to_path=path)\n\nPUT Object - Copy\n\nOptional Arguments\n\nmetadata::Dict=; optional x-amz-meta- headers.\n\n\n\n"
},

{
    "location": "AWSS3.html#AWSS3.s3_sign_url",
    "page": "AWSS3.jl",
    "title": "AWSS3.s3_sign_url",
    "category": "Function",
    "text": "s3_sign_url([::AWSConfig], bucket, path, [seconds=3600];\n            [verb=\"GET\"], [content_type=\"application/octet-stream\"])\n\nCreate a pre-signed url for bucket and path (expires after for seconds).\n\nTo create an upload URL use verb=\"PUT\" and set content_type to match the type used in the Content-Type header of the PUT request.\n\nurl = s3_sign_url(\"my_bucket\", \"my_file.txt\"; verb=\"PUT\")\nRequests.put(URI(url), \"Hello!\")\n\nurl = s3_sign_url(\"my_bucket\", \"my_file.txt\";\n                  verb=\"PUT\", content_type=\"text/plain\")\n\nRequests.put(URI(url), \"Hello!\";\n             headers=Dict(\"Content-Type\" => \"text/plain\"))\n\n\n\n"
},

{
    "location": "AWSS3.html#AWS-S3-Objects-1",
    "page": "AWSS3.jl",
    "title": "AWS S3 Objects",
    "category": "section",
    "text": "s3_get\ns3_get_file\ns3_get_meta\ns3_exists\ns3_put\ns3_purge_versions\ns3_delete\ns3_copy\ns3_sign_url"
},

{
    "location": "AWSS3.html#AWSS3.s3_list_buckets",
    "page": "AWSS3.jl",
    "title": "AWSS3.s3_list_buckets",
    "category": "Function",
    "text": "s3_list_buckets([::AWSConfig])\n\nList of all buckets owned by the sender of the request.\n\n\n\n"
},

{
    "location": "AWSS3.html#AWSS3.s3_list_objects",
    "page": "AWSS3.jl",
    "title": "AWSS3.s3_list_objects",
    "category": "Function",
    "text": "s3_list_objects([::AWSConfig], bucket, [path_prefix])\n\nList Objects in bucket with optional path_prefix.\n\n\n\n"
},

{
    "location": "AWSS3.html#AWSS3.s3_list_versions",
    "page": "AWSS3.jl",
    "title": "AWSS3.s3_list_versions",
    "category": "Function",
    "text": "s3_list_versions([::AWSConfig], bucket, [path_prefix])\n\nList object versions in bucket with optional path_prefix.\n\n\n\n"
},

{
    "location": "AWSS3.html#AWSS3.s3_create_bucket",
    "page": "AWSS3.jl",
    "title": "AWSS3.s3_create_bucket",
    "category": "Function",
    "text": "s3_create_bucket([:AWSConfig], bucket)\n\nPUT Bucket\n\n\n\n"
},

{
    "location": "AWSS3.html#AWSS3.s3_put_cors",
    "page": "AWSS3.jl",
    "title": "AWSS3.s3_put_cors",
    "category": "Function",
    "text": "s3_put_cors([::AWSConfig], bucket, cors_config)\n\nPUT Bucket cors\n\ns3_put_cors(\"my_bucket\", \"\"\"\n    <?xml version=\"1.0\" encoding=\"UTF-8\"?>\n    <CORSConfiguration xmlns=\"http://s3.amazonaws.com/doc/2006-03-01/\">\n        <CORSRule>\n            <AllowedOrigin>http://my.domain.com</AllowedOrigin>\n            <AllowedOrigin>http://my.other.domain.com</AllowedOrigin>\n            <AllowedMethod>GET</AllowedMethod>\n            <AllowedMethod>HEAD</AllowedMethod>\n            <AllowedHeader>*</AllowedHeader>\n            <ExposeHeader>Content-Range</ExposeHeader>\n        </CORSRule>\n    </CORSConfiguration>\n\"\"\"\n\n\n\n"
},

{
    "location": "AWSS3.html#AWSS3.s3_enable_versioning",
    "page": "AWSS3.jl",
    "title": "AWSS3.s3_enable_versioning",
    "category": "Function",
    "text": "s3_enable_versioning([::AWSConfig], bucket)\n\nEnable versioning for bucket.\n\n\n\n"
},

{
    "location": "AWSS3.html#AWSS3.s3_delete_bucket",
    "page": "AWSS3.jl",
    "title": "AWSS3.s3_delete_bucket",
    "category": "Function",
    "text": "s3_delete_bucket([::AWSConfig], \"bucket\")\n\nDELETE Bucket.\n\n\n\n"
},

{
    "location": "AWSS3.html#AWS-S3-Buckets-1",
    "page": "AWSS3.jl",
    "title": "AWS S3 Buckets",
    "category": "section",
    "text": "s3_list_buckets\ns3_list_objects\ns3_list_versions\ns3_create_bucket\ns3_put_cors\ns3_enable_versioning\ns3_delete_bucket"
},

{
    "location": "AWSS3.html#AWSS3.s3_put_tags",
    "page": "AWSS3.jl",
    "title": "AWSS3.s3_put_tags",
    "category": "Function",
    "text": "s3_put_tags([::AWSConfig], bucket, [path,] tags::Dict)\n\nPUT tags on  bucket or object (path).\n\nSee also tags= option on s3_put.\n\n\n\n"
},

{
    "location": "AWSS3.html#AWSS3.s3_get_tags",
    "page": "AWSS3.jl",
    "title": "AWSS3.s3_get_tags",
    "category": "Function",
    "text": "s3_get_tags([::AWSConfig], bucket, [path])\n\nGet tags from bucket or object (path).\n\n\n\n"
},

{
    "location": "AWSS3.html#AWSS3.s3_delete_tags",
    "page": "AWSS3.jl",
    "title": "AWSS3.s3_delete_tags",
    "category": "Function",
    "text": "s3_delete_tags([::AWSConfig], bucket, [path])\n\nDelete tags from bucket or object (path).\n\n\n\n"
},

{
    "location": "AWSS3.html#AWS-S3-Bucket-and-Object-Tagging-1",
    "page": "AWSS3.jl",
    "title": "AWS S3 Bucket and Object Tagging",
    "category": "section",
    "text": "s3_put_tags\ns3_get_tags\ns3_delete_tags"
},

{
    "location": "AWSS3.html#AWSS3.s3_arn",
    "page": "AWSS3.jl",
    "title": "AWSS3.s3_arn",
    "category": "Function",
    "text": "s3_arn(resource)\ns3_arn(bucket,path)\n\nAmazon Resource Name for S3 resource or bucket and path.\n\n\n\n"
},

{
    "location": "AWSS3.html#AWSS3-Internals-1",
    "page": "AWSS3.jl",
    "title": "AWSS3 Internals",
    "category": "section",
    "text": "s3_arns3_arn(\"my_bucket/foo/bar.txt\")s3_arn(\"my_bucket\",\"foo/bar.txt\")"
},

{
    "location": "AWSSQS.html#",
    "page": "AWSSQS.jl",
    "title": "AWSSQS.jl",
    "category": "page",
    "text": ""
},

{
    "location": "AWSSQS.html#AWS-SQS-1",
    "page": "AWSSQS.jl",
    "title": "AWS SQS",
    "category": "section",
    "text": "CurrentModule = AWSSQSusing AWSSQShttps://github.com/samoconnor/AWSSQS.jlPages = [\"AWSSQS.md\"]"
},

{
    "location": "AWSSQS.html#AWSSQS.sqs_list_queues",
    "page": "AWSSQS.jl",
    "title": "AWSSQS.sqs_list_queues",
    "category": "Function",
    "text": "sqs_list_queues([::AWSConfig], prefix=\"\")\n\nReturns a list of ::AWSQueue.\n\nfor q in sqs_list_queues()\n    println(\"$(sqs_name(q)) has ~$(sqs_count(q)) messages.\")\nend\n\n\n\n"
},

{
    "location": "AWSSQS.html#AWSSQS.sqs_get_queue",
    "page": "AWSSQS.jl",
    "title": "AWSSQS.sqs_get_queue",
    "category": "Function",
    "text": "sqs_get_queue([::AWSConfig], name)\n\nLook up a queue by name. Returns ::AWSQueue.\n\nq = sqs_get_queue(\"my-queue\")\nsqs_send_message(q, \"my message\")\n\n\n\n"
},

{
    "location": "AWSSQS.html#AWSSQS.sqs_create_queue",
    "page": "AWSSQS.jl",
    "title": "AWSSQS.sqs_create_queue",
    "category": "Function",
    "text": "sqs_create_queue([::AWSConfig], name; options...)\n\nCreate new queue with name. Returns ::AWSQueue.\n\noptions: VisibilityTimeout, MessageRetentionPeriod, DelaySeconds etc...\n\nSee SQS API Reference for detail.\n\nq = sqs_create_queue(\"my-queue\")\nsqs_send_message(q, \"my message\")\n\n\n\n"
},

{
    "location": "AWSSQS.html#AWSSQS.sqs_set_policy",
    "page": "AWSSQS.jl",
    "title": "AWSSQS.sqs_set_policy",
    "category": "Function",
    "text": "sqs_set_policy(::AWSQueue, policy)\n\nSet access policy for a queue.\n\n\n\n"
},

{
    "location": "AWSSQS.html#AWSSQS.sqs_delete_queue",
    "page": "AWSSQS.jl",
    "title": "AWSSQS.sqs_delete_queue",
    "category": "Function",
    "text": "sqs_delete_queue(::AWSQueue)\n\nDelete a queue.\n\n\n\n"
},

{
    "location": "AWSSQS.html#SQS-Queues-1",
    "page": "AWSSQS.jl",
    "title": "SQS Queues",
    "category": "section",
    "text": "sqs_list_queues\nsqs_get_queue\nsqs_create_queue\nsqs_set_policy\nsqs_delete_queue"
},

{
    "location": "AWSSQS.html#AWSSQS.sqs_send_message",
    "page": "AWSSQS.jl",
    "title": "AWSSQS.sqs_send_message",
    "category": "Function",
    "text": "sqs_send_message(::AWSQueue, message)\n\nSend a message to a queue.\n\n\n\n"
},

{
    "location": "AWSSQS.html#AWSSQS.sqs_send_message_batch",
    "page": "AWSSQS.jl",
    "title": "AWSSQS.sqs_send_message_batch",
    "category": "Function",
    "text": "sqs_send_message_batch(::AWSQueue, messages)\n\nSend a collection of messages to a queue.\n\n\n\n"
},

{
    "location": "AWSSQS.html#AWSSQS.sqs_receive_message",
    "page": "AWSSQS.jl",
    "title": "AWSSQS.sqs_receive_message",
    "category": "Function",
    "text": "sqs_receive_message(::AWSQueue)\n\nReturns a Dict containing :message and :handle or nothing if the queue is empty.\n\nm = sqs_receive_message(q)\nprintln(m[:message])\nsqs_delete_message(m)\n\n\n\n"
},

{
    "location": "AWSSQS.html#AWSSQS.sqs_messages",
    "page": "AWSSQS.jl",
    "title": "AWSSQS.sqs_messages",
    "category": "Function",
    "text": "sqs_messages(::AWSQueue)\n\nReturns an iterator that retrieves messages from a queue.\n\nfor m in sqs_messages(q)\n    println(m[:message])\n    sqs_delete_message(m)\nend\n\n\n\n"
},

{
    "location": "AWSSQS.html#AWSSQS.sqs_delete_message",
    "page": "AWSSQS.jl",
    "title": "AWSSQS.sqs_delete_message",
    "category": "Function",
    "text": "sqs_delete_message(::AWSQueue, message)\n\nDelete a message from a queue.\n\n\n\n"
},

{
    "location": "AWSSQS.html#AWSSQS.sqs_flush",
    "page": "AWSSQS.jl",
    "title": "AWSSQS.sqs_flush",
    "category": "Function",
    "text": "sqs_flush(::AWSQueue)\n\nDelete all messages from a queue.\n\n\n\n"
},

{
    "location": "AWSSQS.html#SQS-Messages-1",
    "page": "AWSSQS.jl",
    "title": "SQS Messages",
    "category": "section",
    "text": "sqs_send_message\nsqs_send_message_batch\nsqs_receive_message\nsqs_messages\nsqs_delete_message\nsqs_flush"
},

{
    "location": "AWSSQS.html#AWSSQS.sqs_name",
    "page": "AWSSQS.jl",
    "title": "AWSSQS.sqs_name",
    "category": "Function",
    "text": "sqs_name(::AWSQueue)\n\nName of a queue.\n\n\n\n"
},

{
    "location": "AWSSQS.html#AWSSQS.sqs_arn",
    "page": "AWSSQS.jl",
    "title": "AWSSQS.sqs_arn",
    "category": "Function",
    "text": "sqs_arn(::AWSQueue)\n\nARN of a queue.\n\n\n\n"
},

{
    "location": "AWSSQS.html#AWSSQS.sqs_get_queue_attributes",
    "page": "AWSSQS.jl",
    "title": "AWSSQS.sqs_get_queue_attributes",
    "category": "Function",
    "text": "sqs_get_queue_attributes(::AWSQueue)\n\nGet Queue Attributes for a queue.\n\n\n\n"
},

{
    "location": "AWSSQS.html#AWSSQS.sqs_count",
    "page": "AWSSQS.jl",
    "title": "AWSSQS.sqs_count",
    "category": "Function",
    "text": "sqs_count(::AWSQueue)\n\nApproximate number of messages in a queue.\n\n\n\n"
},

{
    "location": "AWSSQS.html#AWSSQS.sqs_busy_count",
    "page": "AWSSQS.jl",
    "title": "AWSSQS.sqs_busy_count",
    "category": "Function",
    "text": "sqs_busy_count(::AWSQueue)\n\nApproximate number of messages not visible in a queue.\n\n\n\n"
},

{
    "location": "AWSSQS.html#SQS-Metadata-1",
    "page": "AWSSQS.jl",
    "title": "SQS Metadata",
    "category": "section",
    "text": "sqs_name\nsqs_arn\nsqs_get_queue_attributes\nsqs_count\nsqs_busy_count"
},

{
    "location": "AWSSES.html#",
    "page": "AWSSES.jl",
    "title": "AWSSES.jl",
    "category": "page",
    "text": ""
},

{
    "location": "AWSSES.html#AWSSES.ses_send-Tuple{Dict{Symbol,Any}}",
    "page": "AWSSES.jl",
    "title": "AWSSES.ses_send",
    "category": "Method",
    "text": "ses_send([::AWSConfig]; to=, from=, subject=, body=)\n\nSend plain text email.\n\nses_send(\n    to=\"sam@octech.com.au\"\n    from=\"sam@octech.com.au\"\n    subject=\"Hi Sam!\"\n    body=\"Hello!\"\n)\n\n\n\n"
},

{
    "location": "AWSSES.html#AWSSES.ses_send_attachments-Tuple{Dict{Symbol,Any}}",
    "page": "AWSSES.jl",
    "title": "AWSSES.ses_send_attachments",
    "category": "Method",
    "text": "ses_send_attachments([::AWSConfig],\n                     to=, from=, subject=, body=,\n                     attachments=[])\n\nSend an email with attachments.\n\nses_send_attachments(to=\"sam@octech.com.au\", from=\"sam@octech.com.au\"\n                     subject=\"Attachments attached\",    \n                     body=\"See attached attachments...\",\n                     [(\"bar.txt\", \"text/plain\", \"bar\\n\"),\n                      (\"foo.txt\", \"text/plain\", \"foo\\n\")])\n\n\n\n"
},

{
    "location": "AWSSES.html#AWSSES.ses_send_raw-Tuple{Dict{Symbol,Any}}",
    "page": "AWSSES.jl",
    "title": "AWSSES.ses_send_raw",
    "category": "Method",
    "text": "ses_send_raw([::AWSConfig]; to=, from=, raw=)\n\nSend a raw email.\n\nraw must contain both headers and message body.\n\n\n\n"
},

{
    "location": "AWSSES.html#AWS-SES-1",
    "page": "AWSSES.jl",
    "title": "AWS SES",
    "category": "section",
    "text": "CurrentModule = AWSSEShttps://github.com/samoconnor/AWSSES.jlPages = [\"AWSSES.md\"]Modules = [AWSSES]"
},

{
    "location": "AWSSNS.html#",
    "page": "AWSSNS.jl",
    "title": "AWSSNS.jl",
    "category": "page",
    "text": ""
},

{
    "location": "AWSSNS.html#AWSSNS.send_sms-Tuple{Dict{Symbol,Any},Any,Any}",
    "page": "AWSSNS.jl",
    "title": "AWSSNS.send_sms",
    "category": "Method",
    "text": "send_sms([::AWSConfig], number, message)\n\nSend SMS message to number.\n\n\n\n"
},

{
    "location": "AWSSNS.html#AWSSNS.sns_create_topic-Tuple{Dict{Symbol,Any},Any}",
    "page": "AWSSNS.jl",
    "title": "AWSSNS.sns_create_topic",
    "category": "Method",
    "text": "sns_create_topic([::AWSConfig], topic_name)\n\nCreate a named topic.\n\n\n\n"
},

{
    "location": "AWSSNS.html#AWSSNS.sns_delete_topic-Tuple{Dict{Symbol,Any},Any}",
    "page": "AWSSNS.jl",
    "title": "AWSSNS.sns_delete_topic",
    "category": "Method",
    "text": "sns_delete_topic([::AWSConfig], topic_name)\n\nDelete a named topic.\n\n\n\n"
},

{
    "location": "AWSSNS.html#AWSSNS.sns_list_subscriptsion-Tuple{Dict{Symbol,Any},Any}",
    "page": "AWSSNS.jl",
    "title": "AWSSNS.sns_list_subscriptsion",
    "category": "Method",
    "text": "sns_list_subscriptsion([::AWSConfig], topic_name)\n\nList endpoints that are subscribed to topic_name.\n\n\n\n"
},

{
    "location": "AWSSNS.html#AWSSNS.sns_list_topics",
    "page": "AWSSNS.jl",
    "title": "AWSSNS.sns_list_topics",
    "category": "Function",
    "text": "sns_list_topics([::AWSConfig])\n\nReturns a list of topic names.\n\n\n\n"
},

{
    "location": "AWSSNS.html#AWSSNS.sns_publish",
    "page": "AWSSNS.jl",
    "title": "AWSSNS.sns_publish",
    "category": "Function",
    "text": "sns_publish([::AWSConfig], topic_name, message, subject=\"No Subject\")\n\nSend a message to a named topic (with optional subject).\n\n\n\n"
},

{
    "location": "AWSSNS.html#AWSSNS.sns_subscribe_email-Tuple{Dict{Symbol,Any},Any,Any}",
    "page": "AWSSNS.jl",
    "title": "AWSSNS.sns_subscribe_email",
    "category": "Method",
    "text": "sns_subscribe_email([::AWSConfig], topic_name, email)\n\nConnect email to topic_name.\n\n\n\n"
},

{
    "location": "AWSSNS.html#AWSSNS.sns_subscribe_lambda-Tuple{Dict{Symbol,Any},Any,Any}",
    "page": "AWSSNS.jl",
    "title": "AWSSNS.sns_subscribe_lambda",
    "category": "Method",
    "text": "sns_subscribe_lambda([::AWSConfig], topic_name, lambda_name)\n\nConnect lambda_name to topic_name.\n\n\n\n"
},

{
    "location": "AWSSNS.html#AWSSNS.sns_subscribe_sqs-Tuple{Dict{Symbol,Any},Any,Any}",
    "page": "AWSSNS.jl",
    "title": "AWSSNS.sns_subscribe_sqs",
    "category": "Method",
    "text": "sns_subscribe_sqs([::AWSConfig], topic_name, queue; raw=false)\n\nConnect SQS queue to topic_name.\n\n\n\n"
},

{
    "location": "AWSSNS.html#AWSSNS.sns_unsubscribe-Tuple{Dict{Symbol,Any},Any,Any}",
    "page": "AWSSNS.jl",
    "title": "AWSSNS.sns_unsubscribe",
    "category": "Method",
    "text": "sns_unsubscribe([::AWSConfig], topic_name, SubscriptionArn)\nsns_unsubscribe([::AWSConfig], topic_name, ::Regex)\n\nDisconnect SubscriptionArn from topic_name.\n\n\n\n"
},

{
    "location": "AWSSNS.html#AWS-SNS-1",
    "page": "AWSSNS.jl",
    "title": "AWS SNS",
    "category": "section",
    "text": "CurrentModule = AWSSNShttps://github.com/samoconnor/AWSSNS.jlPages = [\"AWSSNS.md\"]Modules = [AWSSNS]"
},

]}
