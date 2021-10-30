import asyncdispatch
import asyncfutures
import asyncnet
import gemclient/gemcode
import net
import re
import streams
import strutils
import uri


let MetaRe = re"\d\s(\S*)"

var defaultSslContext {.threadvar.}: SslContext

proc getDefaultSSL(): SslContext =
  result = defaultSslContext
  if result == nil:
    defaultSslContext = newContext(verifyMode = CVerifyNone)
    result = defaultSslContext
    doAssert result != nil, "failure to initialize the SSL context"


type
  Response* = ref object
    header*: string
    bodyStr: string
    bodyStream*: Stream

type
  AsyncResponse* = ref object
    header*: string
    bodyStr: string
    bodyStream*: FutureStream[string]


proc code*(response: Response | AsyncResponse):
         GemCode {.raises: ValueError.} =
  return response.header[0 .. 1].parseInt.GemCode


proc meta*(response: Response | AsyncResponse): string =
  var matches : array[1, string]
  let foundMeta = response.header.match(MetaRe, matches, 1)
  if foundMeta:
    return matches[0]
  else:
    return ""


proc body*(response: Response | AsyncResponse):
         Future[string] {.multisync.} =
  if response.bodyStr.len == 0:
    response.bodyStr = await response.bodyStream.readAll()
  return response.bodyStr


type
  GeminiClientBase*[SocketType] = ref object
    socket: SocketType
    currentURL: Uri
    maxRedirects: Natural
    timeout*: int
    sslContext: net.SslContext
    when SocketType is AsyncSocket:
      bodyStream: FutureStream[string]
      parseBodyFut: Future[void]
    else:
      bodyStream: Stream
    body: string


type
  GeminiClient* = GeminiClientBase[Socket]

proc newGeminiClient*(maxRedirects = 5,
                     sslContext = getDefaultSSL()): GeminiClient =
  new result
  result.maxRedirects = maxRedirects
  result.sslContext = sslContext
  result.bodyStream = newStringStream("")

type
  AsyncGeminiClient* = GeminiClientBase[AsyncSocket]


proc newAsyncGeminiClient*(maxRedirects = 5,
                     sslContext = getDefaultSSL()): AsyncGeminiClient =
  new result
  result.maxRedirects = maxRedirects
  result.sslContext = sslContext
  result.bodyStream = newFutureStream[string]("newAsyncGeminiClient")


proc sendRequest(client: GeminiClient | AsyncGeminiClient, url: string):
                Future[void] {.multisync.} =
  # Should we set the client current URL to the post
  # cleaned up values in the logic below?
  let requestUrl = parseUri(url)
  client.currentURL = requestUrl

  if requestUrl.scheme == "":
    raise newException(ValueError, "No uri scheme supplied.")

  let hostname =
    if requestUrl.hostname == "":
      "127.0.0.1"
    else:
      requestUrl.hostname

  let port =
    if requestUrl.port == "":
      Port(1965)
    else:
      Port(requestUrl.port.parseInt)

  when client is AsyncGeminiClient:
    client.socket = newAsyncSocket()
  else:
    client.socket = newSocket()
  client.sslContext.wrapSocket(client.socket)
  await client.socket.connect(hostname, port)
  await client.socket.send($requestUrl & "\x0d\x0a")


proc parseResponse(client: GeminiClient | AsyncGeminiClient):
                  Future[Response | AsyncResponse] {.multisync.} =
  new result
  var parsedHeader = false
  var line = "initial"
  while line != "":
    line = await client.socket.recvLine()
    if not parsedHeader:
      result.header = line
      parsedHeader = true
      when client is AsyncGeminiClient:
        client.bodyStream = newFutureStream[string]("newAsyncGeminiClient")
      else:
        client.bodyStream = newStringStream()
      result.bodyStream = client.bodyStream
      continue
    await client.bodyStream.write(line & "\n")
  when client is AsyncGeminiClient:
    result.bodyStream.complete()
  else:
    result.bodyStream.setPosition(0)


proc fetch*(client: GeminiClient | AsyncGeminiClient, url: string):
          Future[Response | AsyncResponse] {.multisync.} =
  await client.sendRequest(url)

  var redirCount = 0
  var response = await parseResponse(client)
  while response.code.redirection:
    redirCount += 1
    if redirCount >= client.maxRedirects:
      break
    client.socket.close()
    await client.sendRequest(response.meta)
    response = await parseResponse(client)
    
  client.socket.close()
  return response
