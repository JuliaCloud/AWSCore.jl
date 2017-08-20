# AWSSDK.ELBv2

# Elastic Load Balancing

A load balancer distributes incoming traffic across targets, such as your EC2 instances. This enables you to increase the availability of your application. The load balancer also monitors the health of its registered targets and ensures that it routes traffic only to healthy targets. You configure your load balancer to accept incoming traffic by specifying one or more listeners, which are configured with a protocol and port number for connections from clients to the load balancer. You configure a target group with a protocol and port number for connections from the load balancer to the targets, and with health check settings to be used when checking the health status of the targets.

Elastic Load Balancing supports two types of load balancers: Classic Load Balancers and Application Load Balancers. A Classic Load Balancer makes routing and load balancing decisions either at the transport layer (TCP/SSL) or the application layer (HTTP/HTTPS), and supports either EC2-Classic or a VPC. An Application Load Balancer makes routing and load balancing decisions at the application layer (HTTP/HTTPS), supports path-based routing, and can route requests to one or more ports on each EC2 instance or container instance in your virtual private cloud (VPC). For more information, see the [Elastic Load Balancing User Guide](http://docs.aws.amazon.com/elasticloadbalancing/latest/userguide/).

This reference covers the 2015-12-01 API, which supports Application Load Balancers. The 2012-06-01 API supports Classic Load Balancers.

To get started, complete the following tasks:

1.  Create an Application Load Balancer using [CreateLoadBalancer](@ref).

2.  Create a target group using [CreateTargetGroup](@ref).

3.  Register targets for the target group using [RegisterTargets](@ref).

4.  Create one or more listeners for your load balancer using [CreateListener](@ref).

5.  (Optional) Create one or more rules for content routing based on URL using [CreateRule](@ref).

To delete an Application Load Balancer and its related resources, complete the following tasks:

1.  Delete the load balancer using [DeleteLoadBalancer](@ref).

2.  Delete the target group using [DeleteTargetGroup](@ref).

All Elastic Load Balancing operations are idempotent, which means that they complete at most one time. If you repeat an operation, it succeeds.

This document is generated from
[apis/elasticloadbalancingv2-2015-12-01.normal.json](https://github.com/aws/aws-sdk-js/blob/master/apis/elasticloadbalancingv2-2015-12-01.normal.json).
See [JuliaCloud/AWSCore.jl](https://github.com/JuliaCloud/AWSCore.jl).

```@index
Pages = ["AWSSDK.ELBv2.md"]
```

```@autodocs
Modules = [AWSSDK.ELBv2]
```
