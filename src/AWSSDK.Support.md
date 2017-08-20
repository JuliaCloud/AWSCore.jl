# AWSSDK.Support

# AWS Support

The AWS Support API reference is intended for programmers who need detailed information about the AWS Support operations and data types. This service enables you to manage your AWS Support cases programmatically. It uses HTTP methods that return results in JSON format.

The AWS Support service also exposes a set of [Trusted Advisor](http://aws.amazon.com/premiumsupport/trustedadvisor/) features. You can retrieve a list of checks and their descriptions, get check results, specify checks to refresh, and get the refresh status of checks.

The following list describes the AWS Support case management operations:

*   **Service names, issue categories, and available severity levels.** The [DescribeServices](@ref) and [DescribeSeverityLevels](@ref) operations return AWS service names, service codes, service categories, and problem severity levels. You use these values when you call the [CreateCase](@ref) operation.

*   **Case creation, case details, and case resolution.** The [CreateCase](@ref), [DescribeCases](@ref), [DescribeAttachment](@ref), and [ResolveCase](@ref) operations create AWS Support cases, retrieve information about cases, and resolve cases.

*   **Case communication.** The [DescribeCommunications](@ref), [AddCommunicationToCase](@ref), and [AddAttachmentsToSet](@ref) operations retrieve and add communications and attachments to AWS Support cases.

The following list describes the operations available from the AWS Support service for Trusted Advisor:

*   [DescribeTrustedAdvisorChecks](@ref) returns the list of checks that run against your AWS resources.

*   Using the `checkId` for a specific check returned by [DescribeTrustedAdvisorChecks](@ref), you can call [DescribeTrustedAdvisorCheckResult](@ref) to obtain the results for the check you specified.

*   [DescribeTrustedAdvisorCheckSummaries](@ref) returns summarized results for one or more Trusted Advisor checks.

*   [RefreshTrustedAdvisorCheck](@ref) requests that Trusted Advisor rerun a specified check.

*   [DescribeTrustedAdvisorCheckRefreshStatuses](@ref) reports the refresh status of one or more checks.

For authentication of requests, AWS Support uses [Signature Version 4 Signing Process](http://docs.aws.amazon.com/general/latest/gr/signature-version-4.html).

See [About the AWS Support API](http://docs.aws.amazon.com/awssupport/latest/user/Welcome.html) in the *AWS Support User Guide* for information about how to use this service to create and manage your support cases, and how to call Trusted Advisor for results of checks on your resources.

This document is generated from
[apis/support-2013-04-15.normal.json](https://github.com/aws/aws-sdk-js/blob/master/apis/support-2013-04-15.normal.json).
See [JuliaCloud/AWSCore.jl](https://github.com/JuliaCloud/AWSCore.jl).

```@index
Pages = ["AWSSDK.Support.md"]
```

```@autodocs
Modules = [AWSSDK.Support]
```
