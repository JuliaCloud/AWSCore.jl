# AWSSDK.CodeBuild

# AWS CodeBuild

AWS CodeBuild is a fully managed build service in the cloud. AWS CodeBuild compiles your source code, runs unit tests, and produces artifacts that are ready to deploy. AWS CodeBuild eliminates the need to provision, manage, and scale your own build servers. It provides prepackaged build environments for the most popular programming languages and build tools, such as Apache Maven, Gradle, and more. You can also fully customize build environments in AWS CodeBuild to use your own build tools. AWS CodeBuild scales automatically to meet peak build requests, and you pay only for the build time you consume. For more information about AWS CodeBuild, see the *AWS CodeBuild User Guide*.

AWS CodeBuild supports these operations:

*   `BatchDeleteBuilds`: Deletes one or more builds.

*   `BatchGetProjects`: Gets information about one or more build projects. A *build project* defines how AWS CodeBuild will run a build. This includes information such as where to get the source code to build, the build environment to use, the build commands to run, and where to store the build output. A *build environment* represents a combination of operating system, programming language runtime, and tools that AWS CodeBuild will use to run a build. Also, you can add tags to build projects to help manage your resources and costs.

*   `CreateProject`: Creates a build project.

*   `CreateWebhook`: For an existing AWS CodeBuild build project that has its source code stored in a GitHub repository, enables AWS CodeBuild to begin automatically rebuilding the source code every time a code change is pushed to the repository.

*   `DeleteProject`: Deletes a build project.

*   `DeleteWebhook`: For an existing AWS CodeBuild build project that has its source code stored in a GitHub repository, stops AWS CodeBuild from automatically rebuilding the source code every time a code change is pushed to the repository.

*   `ListProjects`: Gets a list of build project names, with each build project name representing a single build project.

*   `UpdateProject`: Changes the settings of an existing build project.

*   `BatchGetBuilds`: Gets information about one or more builds.

*   `ListBuilds`: Gets a list of build IDs, with each build ID representing a single build.

*   `ListBuildsForProject`: Gets a list of build IDs for the specified build project, with each build ID representing a single build.

*   `StartBuild`: Starts running a build.

*   `StopBuild`: Attempts to stop running a build.

*   `ListCuratedEnvironmentImages`: Gets information about Docker images that are managed by AWS CodeBuild.

This document is generated from
[apis/codebuild-2016-10-06.normal.json](https://github.com/aws/aws-sdk-js/blob/master/apis/codebuild-2016-10-06.normal.json).
See [JuliaCloud/AWSCore.jl](https://github.com/JuliaCloud/AWSCore.jl).

```@index
Pages = ["AWSSDK.CodeBuild.md"]
```

```@autodocs
Modules = [AWSSDK.CodeBuild]
```
