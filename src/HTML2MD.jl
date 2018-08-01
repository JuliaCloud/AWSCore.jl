#==============================================================================#
# HTML2MD.jl
#
# Julia wrapper for the NodeJS to-markdown module.
#
# Copyright OC Technology Pty Ltd 2017 - All rights reserved
#==============================================================================#


module HTML2MD

export html2md


using NodeJS
using HTTP

const tcp_port = 34562

server_process = nothing

function start_node_server()

    global server_process

    @assert server_process == nothing

    if !isdir(joinpath(@__DIR__, "node_modules"))
        run(setenv(`$(npm_cmd()) install to-markdown`, dir=@__DIR__))
    end

    server_process = run(`$(nodejs_cmd()) -e """
        const http = require('http')  
        const port = $tcp_port
        const h2m = require('to-markdown')

        const requestHandler = (request, response) => {  
            if (request.method == 'POST') {
                var body = '';
                request.on('data', function (data) { body += data; });
            }

            request.on('end', function () {
                response.end(h2m(body, {converters: [{

                filter: function (node) {
                    return node.nodeName === 'A' && !node.getAttribute('href')
                },
                replacement: function(content) {
                    return '[' + content + '](@ref)';
                }
            },{
                filter: ['fullname'],
                replacement: function(content) {
                    return '\n\n# ' + content + '\n\n'
                } 
            },{
                filter: ['important'],
                replacement: function (content) {
                  return '\n**Important**\n> ' + content + '\n\n'
                }
            },{
                filter: ['note'],
                replacement: function (content) {
                  return '\n**Note**\n> ' + content + '\n\n'
                }
            },{
                filter: ['em', 'i'],
                replacement: function (content) {
                  return '*' + content + '*'
                }
            }]}))
            });
        }

        http.createServer(requestHandler).listen(port, (err) => {  
          if (err) {
            return console.log('HTML2MD Error:', err)
          }
        })
    """`, wait=false)

    atexit(() -> kill(server_process))

    sleep(2)
    server_started = true
end


function html2md(html)

    global server_process

    if server_process == nothing
        start_node_server()
    end

    html = replace(html, "\\" => "\\\\")
    html = replace(html, "\$" => "\\\$")
    html = replace(html, "\"\"\"" => "\\\"\\\"\\\"")

    md = String(HTTP.post("http://localhost:$tcp_port", [], html).body)

    # Work around for https://github.com/domchristie/to-markdown/issues/181
    md = replace(md, r"([0-9])\\[.]" => s"\1.")

    return md
end



end # module HTML2MD


#==============================================================================#
# End of file.
#==============================================================================#
