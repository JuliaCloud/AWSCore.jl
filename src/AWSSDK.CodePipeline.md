# AWSSDK.CodePipeline

# AWS CodePipeline

**Overview**

This is the AWS CodePipeline API Reference. This guide provides descriptions of the actions and data types for AWS CodePipeline. Some functionality for your pipeline is only configurable through the API. For additional information, see the [AWS CodePipeline User Guide](http://docs.aws.amazon.com/codepipeline/latest/userguide/welcome.html).

You can use the AWS CodePipeline API to work with pipelines, stages, actions, gates, and transitions, as described below.

*Pipelines* are models of automated release processes. Each pipeline is uniquely named, and consists of actions, gates, and stages.

You can work with pipelines by calling:

*   [CreatePipeline](@ref), which creates a uniquely-named pipeline.

*   [DeletePipeline](@ref), which deletes the specified pipeline.

*   [GetPipeline](@ref), which returns information about a pipeline structure.

*   [GetPipelineExecution](@ref), which returns information about a specific execution of a pipeline.

*   [GetPipelineState](@ref), which returns information about the current state of the stages and actions of a pipeline.

*   [ListPipelines](@ref), which gets a summary of all of the pipelines associated with your account.

*   [StartPipelineExecution](@ref), which runs the the most recent revision of an artifact through the pipeline.

*   [UpdatePipeline](@ref), which updates a pipeline with edits or changes to the structure of the pipeline.

Pipelines include *stages*, which are logical groupings of gates and actions. Each stage contains one or more actions that must complete before the next stage begins. A stage will result in success or failure. If a stage fails, then the pipeline stops at that stage and will remain stopped until either a new version of an artifact appears in the source location, or a user takes action to re-run the most recent artifact through the pipeline. You can call [GetPipelineState](@ref), which displays the status of a pipeline, including the status of stages in the pipeline, or [GetPipeline](@ref), which returns the entire structure of the pipeline, including the stages of that pipeline. For more information about the structure of stages and actions, also refer to the [AWS CodePipeline Pipeline Structure Reference](http://docs.aws.amazon.com/codepipeline/latest/userguide/pipeline-structure.html).

Pipeline stages include *actions*, which are categorized into categories such as source or build actions performed within a stage of a pipeline. For example, you can use a source action to import artifacts into a pipeline from a source such as Amazon S3\. Like stages, you do not work with actions directly in most cases, but you do define and interact with actions when working with pipeline operations such as [CreatePipeline](@ref) and [GetPipelineState](@ref).

Pipelines also include *transitions*, which allow the transition of artifacts from one stage to the next in a pipeline after the actions in one stage complete.

You can work with transitions by calling:

*   [DisableStageTransition](@ref), which prevents artifacts from transitioning to the next stage in a pipeline.

*   [EnableStageTransition](@ref), which enables transition of artifacts between stages in a pipeline.

**Using the API to integrate with AWS CodePipeline**

For third-party integrators or developers who want to create their own integrations with AWS CodePipeline, the expected sequence varies from the standard API user. In order to integrate with AWS CodePipeline, developers will need to work with the following items:

**Jobs**, which are instances of an action. For example, a job for a source action might import a revision of an artifact from a source.

You can work with jobs by calling:

*   [AcknowledgeJob](@ref), which confirms whether a job worker has received the specified job,

*   [GetJobDetails](@ref), which returns the details of a job,

*   [PollForJobs](@ref), which determines whether there are any jobs to act upon,

*   [PutJobFailureResult](@ref), which provides details of a job failure, and

*   [PutJobSuccessResult](@ref), which provides details of a job success.

**Third party jobs**, which are instances of an action created by a partner action and integrated into AWS CodePipeline. Partner actions are created by members of the AWS Partner Network.

You can work with third party jobs by calling:

*   [AcknowledgeThirdPartyJob](@ref), which confirms whether a job worker has received the specified job,

*   [GetThirdPartyJobDetails](@ref), which requests the details of a job for a partner action,

*   [PollForThirdPartyJobs](@ref), which determines whether there are any jobs to act upon,

*   [PutThirdPartyJobFailureResult](@ref), which provides details of a job failure, and

*   [PutThirdPartyJobSuccessResult](@ref), which provides details of a job success.

This document is generated from
[apis/codepipeline-2015-07-09.normal.json](https://github.com/aws/aws-sdk-js/blob/master/apis/codepipeline-2015-07-09.normal.json).
See [JuliaCloud/AWSCore.jl](https://github.com/JuliaCloud/AWSCore.jl).

```@index
Pages = ["AWSSDK.CodePipeline.md"]
```

```@autodocs
Modules = [AWSSDK.CodePipeline]
```
