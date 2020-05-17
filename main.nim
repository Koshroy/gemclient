import gemclient    

# proc main(): Future[void] {.async.} =
#   var socket = newAsyncSocket()
#   let sslContext = newContext(verifyMode = CVerifyNone)
#   sslContext.wrapSocket(socket)

#   await socket.connect("mozz.us", Port(1965))
#   # socket.connect("127.0.0.1", Port(9999))

#   await socket.send("gemini://mozz.us/markdown/\x0d\x0a")
#   var line = await socket.recvLine()
#   while line != "":
#     echo line
#     line = await socket.recvLine()

# waitFor(main())

var client = newGeminiClient()
let resp = client.fetch("gemini://mozz.us/markdown")
echo "Hello: ", resp.body
