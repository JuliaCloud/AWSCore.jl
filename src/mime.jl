#==============================================================================#
# mime.jl
#
# Simple MIME Multipart encoder.
#
# Copyright OC Technology Pty Ltd 2015 - All rights reserved
#==============================================================================#

const Part = Tuple{String,String,String}

"""
    mime_multipart([header,] parts)

Encode `parts` as a
[MIME Multipart](https://www.w3.org/Protocols/rfc1341/7_2_Multipart.html)
message.

`parts` is a Vector of `(filename, content_type, content)` Tuples.
"""
mime_multipart(parts::Array) = mime_multipart("", parts::Vector{Part})


function mime_multipart(header::AbstractString, parts::Vector{Part})

    boundary = "=PRZLn8Nm1I82df0Dtj4ZvJi="

    mime =
    """
    MIME-Version: 1.0
    Content-Type: multipart/mixed; boundary="$boundary"
    $header

    """

    for (filename, content_type, content) in parts

        mime *= "--$boundary\n"

        if filename != ""
            mime *= "Content-Type: $content_type;\n    name=$filename\n"
            mime *= "Content-Disposition: attachment;\n    filename=$filename\n"
        else
            mime *= "Content-Type: $content_type\n"
        end

        if isa(content, AbstractString)
            mime *= "Content-Transfer-Encoding: binary\n"
        else
            mime *= "Content-Transfer-Encoding: base64\n"
            b64 = base64encode(content)
            b64 = [b64[i:min(length(b64),i+75)] for i in 1:76:length(b64)]
            content = join(b64, "\n")
        end

        mime *= "\n$content\n"
    end

    mime *= "--$boundary--\n"
    return mime
end



#==============================================================================#
# End of file
#==============================================================================#
