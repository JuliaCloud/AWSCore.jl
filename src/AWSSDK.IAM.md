# AWSSDK.IAM

# AWS Identity and Access Management

AWS Identity and Access Management (IAM) is a web service that you can use to manage users and user permissions under your AWS account. This guide provides descriptions of IAM actions that you can call programmatically. For general information about IAM, see [AWS Identity and Access Management (IAM)](http://aws.amazon.com/iam/). For the user guide for IAM, see [Using IAM](http://docs.aws.amazon.com/IAM/latest/UserGuide/).

**Note**
> AWS provides SDKs that consist of libraries and sample code for various programming languages and platforms (Java, Ruby, .NET, iOS, Android, etc.). The SDKs provide a convenient way to create programmatic access to IAM and AWS. For example, the SDKs take care of tasks such as cryptographically signing requests (see below), managing errors, and retrying requests automatically. For information about the AWS SDKs, including how to download and install them, see the [Tools for Amazon Web Services](http://aws.amazon.com/tools/) page.

We recommend that you use the AWS SDKs to make programmatic API calls to IAM. However, you can also use the IAM Query API to make direct calls to the IAM web service. To learn more about the IAM Query API, see [Making Query Requests](http://docs.aws.amazon.com/IAM/latest/UserGuide/IAM_UsingQueryAPI.html) in the *Using IAM* guide. IAM supports GET and POST requests for all actions. That is, the API does not require you to use GET for some actions and POST for others. However, GET requests are subject to the limitation size of a URL. Therefore, for operations that require larger sizes, use a POST request.

**Signing Requests**

Requests must be signed using an access key ID and a secret access key. We strongly recommend that you do not use your AWS account access key ID and secret access key for everyday work with IAM. You can use the access key ID and secret access key for an IAM user or you can use the AWS Security Token Service to generate temporary security credentials and use those to sign requests.

To sign requests, we recommend that you use [Signature Version 4](http://docs.aws.amazon.com/general/latest/gr/signature-version-4.html). If you have an existing application that uses Signature Version 2, you do not have to update it to use Signature Version 4. However, some operations now require Signature Version 4. The documentation for operations that require version 4 indicate this requirement.

**Additional Resources**

For more information, see the following:

*   [AWS Security Credentials](http://docs.aws.amazon.com/general/latest/gr/aws-security-credentials.html). This topic provides general information about the types of credentials used for accessing AWS.

*   [IAM Best Practices](http://docs.aws.amazon.com/IAM/latest/UserGuide/IAMBestPractices.html). This topic presents a list of suggestions for using the IAM service to help secure your AWS resources.

*   [Signing AWS API Requests](http://docs.aws.amazon.com/general/latest/gr/signing_aws_api_requests.html). This set of topics walk you through the process of signing a request using an access key ID and secret access key.

This document is generated from
[apis/iam-2010-05-08.normal.json](https://github.com/aws/aws-sdk-js/blob/master/apis/iam-2010-05-08.normal.json).
See [JuliaCloud/AWSCore.jl](https://github.com/JuliaCloud/AWSCore.jl).

```@index
Pages = ["AWSSDK.IAM.md"]
```

```@autodocs
Modules = [AWSSDK.IAM]
```
