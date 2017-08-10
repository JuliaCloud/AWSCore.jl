#==============================================================================#
# names.jl
#
# AWS Endpoint URLs and Amazon Resource Names.
#
# http://docs.aws.amazon.com/general/latest/gr/rande.html
# http://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html
#
# Copyright OC Technology Pty Ltd 2014 - All rights reserved
#==============================================================================#


export aws_endpoint, arn, is_arn,
       arn_service, arn_region, arn_account, arn_resource,
       arn_iam_type, arn_iam_name



"""
    aws_endpoint(service, [region, [hostname_prefix]])

Generate service endpoint URL for `service` and  `region`.
"""

function aws_endpoint(service, region="", hostname_prefix="")

    protocol = "http"

    # HTTPS where required...
    if service in ["iam", "sts", "lambda", "apigateway", "email"]
        protocol = "https"
    end

    # Identity and Access Management API has no region suffix...
    if service == "iam"
        region = ""
    end

    # SES not available in all regions...
    if service == "ses" && !(region in ["us-east-1", "us-west-2", "eu-west-1"])
        region = "us-east-1"
    end

    # No region sufix for s3 or sdb in default region...
    if region == "us-east-1" && service in ["s3", "sdb"]
        region = ""
    end

    # Append region to service...
    if region != ""
        if service == "s3"
            service = "$service-$region"
        else
            service = "$service.$region"
        end
    end

    # Add optional hostname prefix (e.g. S3 Bucket Name)...
    if hostname_prefix != ""
        service = "$hostname_prefix.$service"
    end

    return "$protocol://$service.amazonaws.com"
end




"""
    arn([::AWSConfig], service, resource, [region, [account]])

Generate an [Amazon Resource Name](http://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) for `service` and `resource`.
"""

function arn(service, resource,
             region=get(default_aws_config(), :region, ""),
             account=aws_account_number(default_aws_config()))

    if service == "s3"
        region = ""
        account = ""
    elseif service == "iam"
        region = ""
    end

    "arn:aws:$service:$region:$account:$resource"
end


function arn(aws::AWSConfig,
             service,
             resource,
             region=get(aws, :region, ""),
             account=aws_account_number(aws))

    arn(service, resource, region, account)
end


"""
    arn_service(arn)

Extract service name from `arn`.
"""

arn_service(arn) = split(arn, ":")[3]


"""
    arn_region(arn)

Extract region name from `arn`.
"""

arn_region(arn) = split(arn, ":")[4]


"""
    arn_account(arn)

Extract account number from `arn`.
"""

arn_account(arn) = split(arn, ":")[5]


"""
    arn_resource(arn)

Extract resource name from `arn`.
"""

arn_resource(arn) = split(arn, ":")[6]


"""
    arn_iam_type

Extract IAM resource type from `arn`.
e.g. \"role\", \"policy\"...
"""
arn_iam_type(arn) = split(arn_resource(arn), "/")[1]


"""
    arn_iam_name

Extract IAM resource name from `arn`.
"""
arn_iam_name(arn) = split(arn_resource(arn), "/")[end]


"""
    is_arn(arn)

Is `arn` in the [correct format]?
(http://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html)
"""

function is_arn(arn)

    v = split(arn, ":")
    p = [is_arn_prefix, is_partition, is_service, is_region, is_account]

    return length(v) >= 6 && all(v[1:5] .|> p)
end

arn_match(s, n, p) = ismatch(p, s) ||
                     (debug_level == 0 || warn("Bad ARN $n: \"$s\""); false)

is_arn_prefix(s) = arn_match(s, "prefix",   r"^arn$")
is_partition(s)  = arn_match(s, "partiton", r"^aws[a-z-]*$")
is_service(s)    = arn_match(s, "service",  r"^[a-zA-Z0-9\-]+$")
is_region(s)     = arn_match(s, "region",   r"^([a-z]{2}-[a-z]+-\d)?$")
is_account(s)    = arn_match(s, "account",  r"^(\d{12})?$")



#==============================================================================#
# End of file.
#==============================================================================#
