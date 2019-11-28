@testset "Localhost" begin
    wmic_command = "wmic path win32_computersystemproduct get uuid"

    windows_patch = @patch Sys.iswindows() = return true

    wmic_patch = @patch read(command::Cmd, ::Type{String}) =
        return "UUID\nEC2D1284-E32E-FB5E-20E4-F43F6E01CA7A"

    @testset "EC2 - Windows" begin
        apply([windows_patch, wmic_patch]) do
            @test localhost_is_ec2()
        end
    end
end

if Sys.iswindows()
    @testset "Windows - Is EC2" begin
        @test localhost_is_ec2()
    end
end