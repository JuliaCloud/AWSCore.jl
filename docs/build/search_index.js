var documenterSearchIndex = {"docs": [

{
    "location": "index.html#",
    "page": "Home",
    "title": "Home",
    "category": "page",
    "text": ""
},

{
    "location": "index.html#AWSCore.jl-Documentation-1",
    "page": "Home",
    "title": "AWSCore.jl Documentation",
    "category": "section",
    "text": "Amazon Web Services Core Functions and Types.CurrentModule = AWSCore"
},

{
    "location": "index.html#AWSCore.AWSConfig",
    "page": "Home",
    "title": "AWSCore.AWSConfig",
    "category": "Type",
    "text": "Most AWSCore functions take a AWSConfig dictionary as the first argument. This dictionary holds AWSCredentials and AWS region configuration.\n\naws = AWSConfig(:creds => AWSCredentials(), :region => \"us-east-1\")`\n\n\n\n"
},

{
    "location": "index.html#AWSCore.aws_config",
    "page": "Home",
    "title": "AWSCore.aws_config",
    "category": "Function",
    "text": "The aws_config function provides a simple way to creates an AWSConfig configuration dictionary.\n\n>aws = aws_config()\n>aws = aws_config(creds = my_credentials)\n>aws = aws_config(region = \"ap-southeast-2\")\n\nBy default, the aws_config attempts to load AWS credentials from:\n\nAWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY environemnt variables,\n~/.aws/credentials or\nEC2 Instance Credentials.\n\nA ~/.aws/credentials file can be created using the AWS CLI command aws configrue. Or it can be created manually:\n\n[default]\naws_access_key_id = AKIAXXXXXXXXXXXXXXXX\naws_secret_access_key = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX\n\nIf your ~/.aws/credentials file contains multiple profiles you can select a profile by setting the AWS_DEFAULT_PROFILE environment variable.\n\naws_config understands the following AWS CLI environment variables: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN, AWS_DEFAULT_REGION, AWS_DEFAULT_PROFILE and AWS_CONFIG_FILE.\n\nAn configuration dictionary can also be created directly from a key pair as follows. However, putting access credentials in source code is discouraged.\n\naws = aws_config(creds = AWSCredentials(\"AKIAXXXXXXXXXXXXXXXX\",\n                                        \"XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX\"))\n\n\n\n"
},

{
    "location": "index.html#AWSCore.default_aws_config",
    "page": "Home",
    "title": "AWSCore.default_aws_config",
    "category": "Function",
    "text": "default_aws_config returns a global shared AWSConfig object obtained by calling aws_config with no optional arguments.\n\n\n\n"
},

{
    "location": "index.html#AWSCore.aws_user_arn",
    "page": "Home",
    "title": "AWSCore.aws_user_arn",
    "category": "Function",
    "text": "aws_user_arn(::AWSConfig)\n\nUnique Amazon Resource Name for configrued user.\n\ne.g. \"arn:aws:iam::account-ID-without-hyphens:user/Bob\"\n\n\n\n"
},

{
    "location": "index.html#AWSCore.aws_account_number",
    "page": "Home",
    "title": "AWSCore.aws_account_number",
    "category": "Function",
    "text": "aws_account_number(::AWSConfig)\n\n12-digit AWS Account Number.\n\n\n\n"
},

{
    "location": "index.html#Configruation-1",
    "page": "Home",
    "title": "Configruation",
    "category": "section",
    "text": "AWSConfig\naws_config\ndefault_aws_config\naws_user_arn\naws_account_number"
},

{
    "location": "index.html#AWSCore.AWSCredentials",
    "page": "Home",
    "title": "AWSCore.AWSCredentials",
    "category": "Type",
    "text": "When you interact with AWS, you specify your AWS Security Credentials to verify who you are and whether you have permission to access the resources that you are requesting. AWS uses the security credentials to authenticate and authorize your requests.\n\nThe fields access_key_id and secret_key hold the access keys used to authenticate API requests (see Creating, Modifying, and Viewing Access Keys).\n\nTemporary Security Credentials require the extra session token field.\n\nThe user_arn and account_number fields are used to cache the result of the aws_user_arn and aws_account_number functions.\n\nThe AWSCredentials() constructor tries to load local Credentials from environment variables, ~/.aws/credentials or EC2 instance credentials. \n\n\n\n"
},

{
    "location": "index.html#AWSCore.env_instance_credentials",
    "page": "Home",
    "title": "AWSCore.env_instance_credentials",
    "category": "Function",
    "text": "Load Credentials from environment variables AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY etc. (e.g. in Lambda sandbox).\n\n\n\n"
},

{
    "location": "index.html#AWSCore.dot_aws_credentials",
    "page": "Home",
    "title": "AWSCore.dot_aws_credentials",
    "category": "Function",
    "text": "Load Credentials from AWS CLI ~/.aws/credentials file.\n\n\n\n"
},

{
    "location": "index.html#AWSCore.ec2_instance_credentials",
    "page": "Home",
    "title": "AWSCore.ec2_instance_credentials",
    "category": "Function",
    "text": "Load Instance Profile Credentials for EC2 virtual machine.\n\n\n\n"
},

{
    "location": "index.html#AWS-Security-Credentials-1",
    "page": "Home",
    "title": "AWS Security Credentials",
    "category": "section",
    "text": "AWSCredentials\nenv_instance_credentials\ndot_aws_credentials\nec2_instance_credentials"
},

{
    "location": "index.html#AWSCore.aws_endpoint",
    "page": "Home",
    "title": "AWSCore.aws_endpoint",
    "category": "Function",
    "text": "aws_endpoint(service, [region, [hostname_prefix]])\n\nGenerate service endpoint URL for service and  region.\n\naws_endpoint(\"sqs\", \"eu-west-1\")\n\"http://sqs.eu-west-1.amazonaws.com\"\n\n\n\n"
},

{
    "location": "index.html#AWSCore.arn",
    "page": "Home",
    "title": "AWSCore.arn",
    "category": "Function",
    "text": "arn([::AWSConfig], service, resource, [region, [account]])\n\nGenerate an Amazon Resource Name for service and resource.\n\narn(aws,\"sqs\", \"au-test-queue\", \"ap-southeast-2\", \"1234\")\n\"arn:aws:sqs:ap-southeast-2:1234:au-test-queue\"\n\n\n\n"
},

{
    "location": "index.html#AWSCore.arn_region",
    "page": "Home",
    "title": "AWSCore.arn_region",
    "category": "Function",
    "text": "arg_region(arn)\n\nExtract region name from arn.\n\n\n\n"
},

{
    "location": "index.html#Endpoints-and-Resource-Names-1",
    "page": "Home",
    "title": "Endpoints and Resource Names",
    "category": "section",
    "text": "aws_endpoint\narn\narn_region"
},

{
    "location": "index.html#AWSCore.AWSRequest",
    "page": "Home",
    "title": "AWSCore.AWSRequest",
    "category": "Type",
    "text": "The AWSRequest dictionary describes a single API request: It contains the following keys:\n\n:creds => AWSCredentials for authentication.\n:verb => \"GET\", \"PUT\", \"POST\" or \"DELETE\"\n:url => service endpoint url (returned by aws_endpoint)\n:headers => HTTP headers\n:content => HTTP body\n:resource => HTTP request path\n:region => AWS region\n:service => AWS service name\n\n\n\n"
},

{
    "location": "index.html#AWSCore.post_request",
    "page": "Home",
    "title": "AWSCore.post_request",
    "category": "Function",
    "text": "post_request(::AWSConfig, service, version, query)\n\nConstruct a AWSRequest dictionary for a HTTP POST request.\n\ne.g.\n\naws = AWSConfig(:creds  => AWSCredentials(),\n                :region => \"ap-southeast-2\")\n\npost_request(aws, \"sdb\", \"2009-04-15\", Dict(\"Action\" => \"ListDomains\"))\n\nDict{Symbol, Any}(\n    :creds    => creds::AWSCredentials\n    :verb     => \"POST\"\n    :url      => \"http://sdb.ap-southeast-2.amazonaws.com/\"\n    :headers  => Dict(\"Content-Type\" =>\n                      \"application/x-www-form-urlencoded; charset=utf-8)\n    :content  => \"Version=2009-04-15&Action=ListDomains\"\n    :resource => \"/\"\n    :region   => \"ap-southeast-2\"\n    :service  => \"sdb\"\n)\n\n\n\n"
},

{
    "location": "index.html#AWSCore.do_request",
    "page": "Home",
    "title": "AWSCore.do_request",
    "category": "Function",
    "text": "do_request(::AWSRequest)\n\nSubmit an API request, return the result.\n\n\n\n"
},

{
    "location": "index.html#AWSCore.dump_aws_request",
    "page": "Home",
    "title": "AWSCore.dump_aws_request",
    "category": "Function",
    "text": "Pretty-print AWSRequest dictionary.\n\n\n\n"
},

{
    "location": "index.html#API-Requests-1",
    "page": "Home",
    "title": "API Requests",
    "category": "section",
    "text": "AWSRequest\npost_request\ndo_request\ndump_aws_request"
},

{
    "location": "index.html#AWSCore.localhost_is_lambda",
    "page": "Home",
    "title": "AWSCore.localhost_is_lambda",
    "category": "Function",
    "text": "Is Julia running in an AWS Lambda sandbox?\n\n\n\n"
},

{
    "location": "index.html#AWSCore.localhost_is_ec2",
    "page": "Home",
    "title": "AWSCore.localhost_is_ec2",
    "category": "Function",
    "text": "Is Julia running on an EC2 virtual machine?\n\n\n\n"
},

{
    "location": "index.html#AWSCore.ec2_metadata",
    "page": "Home",
    "title": "AWSCore.ec2_metadata",
    "category": "Function",
    "text": "ec2_metadata(key)\n\nFetch EC2 meta-data for key.\n\n\n\n"
},

{
    "location": "index.html#Execution-Environemnt-1",
    "page": "Home",
    "title": "Execution Environemnt",
    "category": "section",
    "text": "localhost_is_lambda\nlocalhost_is_ec2\nec2_metadata"
},

{
    "location": "index.html#AWSCore.mime_multipart",
    "page": "Home",
    "title": "AWSCore.mime_multipart",
    "category": "Function",
    "text": "mime_multipart([header,] parts)\n\ne.g.\n\nmime_multipart([\n     (\"foo.txt\", \"text/plain\", \"foo\"),\n     (\"bar.txt\", \"text/plain\", \"bar\")\n ])\n\nreturns...\n\n\"MIME-Version: 1.0\nContent-Type: multipart/mixed; boundary=\"=PRZLn8Nm1I82df0Dtj4ZvJi=\"\n\n--=PRZLn8Nm1I82df0Dtj4ZvJi=\nContent-Disposition: attachment; filename=foo.txt\nContent-Type: text/plain\nContent-Transfer-Encoding: binary \n\nfoo\n--=PRZLn8Nm1I82df0Dtj4ZvJi=\nContent-Disposition: attachment; filename=bar.txt\nContent-Type: text/plain\nContent-Transfer-Encoding: binary \n\nbar\n--=PRZLn8Nm1I82df0Dtj4ZvJi=\n\n\n\n"
},

{
    "location": "index.html#Utility-Functions-1",
    "page": "Home",
    "title": "Utility Functions",
    "category": "section",
    "text": "mime_multipart"
},

]}
