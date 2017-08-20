# AWSSDK.Health

# AWS Health

The AWS Health API provides programmatic access to the AWS Health information that is presented in the [AWS Personal Health Dashboard](https://phd.aws.amazon.com/phd/home#/). You can get information about events that affect your AWS resources:

*   [DescribeEvents](@ref): Summary information about events.

*   [DescribeEventDetails](@ref): Detailed information about one or more events.

*   [DescribeAffectedEntities](@ref): Information about AWS resources that are affected by one or more events.

In addition, these operations provide information about event types and summary counts of events or affected entities:

*   [DescribeEventTypes](@ref): Information about the kinds of events that AWS Health tracks.

*   [DescribeEventAggregates](@ref): A count of the number of events that meet specified criteria.

*   [DescribeEntityAggregates](@ref): A count of the number of affected entities that meet specified criteria.

The Health API requires a Business or Enterprise support plan from [AWS Support](http://aws.amazon.com/premiumsupport/). Calling the Health API from an account that does not have a Business or Enterprise support plan causes a `SubscriptionRequiredException`.

For authentication of requests, AWS Health uses the [Signature Version 4 Signing Process](http://docs.aws.amazon.com/general/latest/gr/signature-version-4.html).

See the [AWS Health User Guide](http://docs.aws.amazon.com/health/latest/ug/what-is-aws-health.html) for information about how to use the API.

**Service Endpoint**

The HTTP endpoint for the AWS Health API is:

*   https://health.us-east-1.amazonaws.com

This document is generated from
[apis/health-2016-08-04.normal.json](https://github.com/aws/aws-sdk-js/blob/master/apis/health-2016-08-04.normal.json).
See [JuliaCloud/AWSCore.jl](https://github.com/JuliaCloud/AWSCore.jl).

```@index
Pages = ["AWSSDK.Health.md"]
```

```@autodocs
Modules = [AWSSDK.Health]
```
