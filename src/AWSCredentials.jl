#==============================================================================#
# AWSCredentials.jl
#
# Load AWS Credentials from:
# - EC2 Instance Profile,
# - Environment variables, or
# - ~/.aws/credentials file.
#
# Copyright Sam O'Connor 2014 - All rights reserved
#==============================================================================#

export AWSCredentials,
       localhost_is_lambda,
       localhost_is_ec2,
       aws_user_arn,
       aws_account_number


type AWSCredentials
    access_key_id::String
    secret_key::String
    token::String
    user_arn::String
    account_number::String

    function AWSCredentials(access_key_id, secret_key,
                            token="", user_arn="", account_number="")
        new(access_key_id, secret_key, token, user_arn, account_number)
    end
end

function Base.show(io::IO,c::AWSCredentials)
    println(io, string(c.user_arn,
                       " (",
                       c.account_number,
                       c.access_key_id,
                       c.secret_key == "" ? "" : ", $(c.secret_key[1:3])...",
                       c.token == "" ? "" : ", $(c.token[1:3])..."),
                       ")")
end


# Discover AWS Credentials for local host.

function AWSCredentials()

    if localhost_is_ec2()

        return ec2_instance_credentials()

    elseif haskey(ENV, "AWS_ACCESS_KEY_ID")

        return env_instance_credentials()

    elseif isfile(dot_aws_credentials_file())

        return dot_aws_credentials()
    end

    error("Can't find AWS credentials!")
end


# Is Julia running in an AWS Lambda sandbox?

localhost_is_lambda() = haskey(ENV, "LAMBDA_TASK_ROOT")


# Is Julia running on an EC2 virtual machine?

function localhost_is_ec2()

    if localhost_is_lambda()
        return false
    end

    @static if is_unix()
        return isfile("/sys/hypervisor/uuid") &&
               bytestring(readbytes("/sys/hypervisor/uuid",3)) == "ec2"
    end

    return false
end


# Get User ARN for "creds".

function aws_user_arn(aws::AWSConfig)

    creds = aws[:creds]

    if creds.user_arn == ""

        r = do_request(post_request(aws, "sts", "2011-06-15",
                                    Dict("Action" => "GetCallerIdentity",
                                         "ContentType" => "JSON")))
        creds.user_arn = r["Arn"]
        creds.account_number = r["Account"]
    end

    return creds.user_arn
end


# Get Account Number for "creds".

function aws_account_number(aws::AWSConfig)
    creds = aws[:creds]
    if creds.account_number == ""
        aws_user_arn(aws)
    end
    return creds.account_number
end


# Fetch EC2 meta-data for "key".
# http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AESDG-chapter-instancedata.html

function ec2_metadata(key)

    @assert localhost_is_ec2()

    bytestring(http_request("169.254.169.254", "/latest/meta-data/$key").data)
end


# Load Instance Profile Credentials for EC2 virtual machine.

using JSON

function ec2_instance_credentials()

    @assert localhost_is_ec2()

    info  = ec2_metadata("iam/info")
    info  = JSON.parse(info, dicttype=Dict{String,String})

    name  = ec2_metadata("iam/security-credentials/")
    creds = ec2_metadata("iam/security-credentials/$name")
    new_creds = JSON.parse(creds, dicttype=Dict{String,String})

    AWSCredentials(new_creds["AccessKeyId"],
                   new_creds["SecretAccessKey"],
                   new_creds["Token"],
                   info["InstanceProfileArn"])
end


# Load Credentials from environment variables (e.g. in Lambda sandbox)

function env_instance_credentials()

    AWSCredentials(ENV["AWS_ACCESS_KEY_ID"],
                   ENV["AWS_SECRET_ACCESS_KEY"],
                   get(ENV, "AWS_SESSION_TOKEN", ""),
                   get(ENV, "AWS_USER_ARN", ""))
end


# Load Credentials from AWS CLI ~/.aws/credentials file.

using IniFile

dot_aws_credentials_file() = get(ENV, "AWS_CONFIG_FILE",
                                 joinpath(homedir(), ".aws", "credentials"))

function dot_aws_credentials()

    @assert isfile(dot_aws_credentials_file())

    ini = read(Inifile(), dot_aws_credentials_file())

    profile = get(ENV, "AWS_DEFAULT_PROFILE", "default")

    AWSCredentials(get(ini, profile, "aws_access_key_id"),
                   get(ini, profile, "aws_secret_access_key"))
end



#==============================================================================#
# End of file.
#==============================================================================#
