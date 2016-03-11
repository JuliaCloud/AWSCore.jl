#==============================================================================#
# mime.jl
#
# Simple MIME Multipart encoder.
#
# e.g.
#
# mime_multipart([
#     ("foo.txt", "text/plain", "foo"),
#     ("bar.txt", "text/plain", "bar")
# ])
# 
# returns...
#
#   "MIME-Version: 1.0
#   Content-Type: multipart/mixed; boundary=\"=PRZLn8Nm1I82df0Dtj4ZvJi=\"
#
#   --=PRZLn8Nm1I82df0Dtj4ZvJi=
#   Content-Disposition: attachment; filename=foo.txt
#   Content-Type: text/plain
#   Content-Transfer-Encoding: binary 
#
#   foo
#   --=PRZLn8Nm1I82df0Dtj4ZvJi=
#   Content-Disposition: attachment; filename=bar.txt
#   Content-Type: text/plain
#   Content-Transfer-Encoding: binary 
#
#   bar
#   --=PRZLn8Nm1I82df0Dtj4ZvJi=
#
#
# Copyright Sam O'Connor 2015 - All rights reserved
#==============================================================================#


mime_multipart(parts::Array) = mime_multipart("", parts::Array)


function mime_multipart(header::AbstractString, parts::Array)

    boundary = "=PRZLn8Nm1I82df0Dtj4ZvJi="

    mime = 
    """
    MIME-Version: 1.0
    Content-Type: multipart/mixed; boundary="$boundary"
    $header

    --$boundary
    """

    for (filename, content_type, content) in parts

        if filename != ""
            mime *= "Content-Disposition: attachment;\n    filename=$filename\n"
        end

        if isa(content, AbstractString)
            mime *= "Content-Transfer-Encoding: binary\n"
        else
            mime *= "Content-Transfer-Encoding: base64\n"
            b64 = base64encode(content)
            b64 = [b64[i:min(length(b64),i+75)] for i in 1:76:length(b64)]
            content = join(b64, "\n")
        end

        mime *= """Content-Type: $content_type

                   $content
                   --$boundary
                   """
    end
    return mime
end



#==============================================================================#
# End of file
#==============================================================================#
