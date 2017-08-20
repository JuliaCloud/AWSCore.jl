# AWSSDK.CodeStar

# AWS CodeStar

This is the API reference for AWS CodeStar. This reference provides descriptions of the operations and data types for the AWS CodeStar API along with usage examples.

You can use the AWS CodeStar API to work with:

Projects and their resources, by calling the following:

*   [DeleteProject](@ref), which deletes a project in AWS CodeStar.

*   [DescribeProject](@ref), which lists the attributes of a project.

*   [ListProjects](@ref), which lists all AWS CodeStar projects associated with your AWS account.

*   [ListResources](@ref), which lists the resources associated with an AWS CodeStar project.

*   [UpdateProject](@ref), which updates the attributes of an AWS CodeStar project.

Teams and team members, by calling the following:

*   [AssociateTeamMember](@ref), which adds an IAM user to the team for an AWS CodeStar project.

*   [DisassociateTeamMember](@ref), which removes an IAM user from the team for an AWS CodeStar project.

*   [ListTeamMembers](@ref), which lists all the IAM users in the team for an AWS CodeStar project, including their roles and attributes.

Users, by calling the following:

*   [CreateUserProfile](@ref), which creates a user profile that contains data associated with the user across all AWS CodeStar projects.

*   [DeleteUserProfile](@ref), which deletes all user profile information across all AWS CodeStar projects.

*   [DescribeUserProfile](@ref), which describes the profile of a user.

*   [ListUserProfiles](@ref), which lists all AWS CodeStar user profiles.

*   [UpdateUserProfile](@ref), which updates the profile for an AWS CodeStar user.

This document is generated from
[apis/codestar-2017-04-19.normal.json](https://github.com/aws/aws-sdk-js/blob/master/apis/codestar-2017-04-19.normal.json).
See [JuliaCloud/AWSCore.jl](https://github.com/JuliaCloud/AWSCore.jl).

```@index
Pages = ["AWSSDK.CodeStar.md"]
```

```@autodocs
Modules = [AWSSDK.CodeStar]
```
