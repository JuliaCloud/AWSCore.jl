# AWSSDK.Pricing

AWS Price List Service API (AWS Price List Service) is a centralized and convenient way to programmatically query Amazon Web Services for services, products, and pricing information. The AWS Price List Service uses standardized product attributes such as `Location`, `Storage Class`, and `Operating System`, and provides prices at the SKU level. You can use the AWS Price List Service to build cost control and scenario planning tools, reconcile billing data, forecast future spend for budgeting purposes, and provide cost benefit analysis that compare your internal workloads with AWS.

Use `GetServices` without a service code to retrieve the service codes for all AWS services, then `GetServices` with a service code to retreive the attribute names for that service. After you have the service code and attribute names, you can use `GetAttributeValues` to see what values are available for an attribute. With the service code and an attribute name and value, you can use `GetProducts` to find specific products that you're interested in, such as an `AmazonEC2` instance, with a `Provisioned IOPS` `volumeType`.

Service Endpoint

AWS Price List Service API provides the following two endpoints:

*   https://api.pricing.us-east-1.amazonaws.com

*   https://api.pricing.ap-south-1.amazonaws.com

This document is generated from
[apis/pricing-2017-10-15.normal.json](https://github.com/aws/aws-sdk-js/blob/master/apis/pricing-2017-10-15.normal.json).
See [JuliaCloud/AWSCore.jl](https://github.com/JuliaCloud/AWSCore.jl).

```@index
Pages = ["AWSSDK.Pricing.md"]
```

```@autodocs
Modules = [AWSSDK.Pricing]
```
