import asyncdispatch
import asyncfutures
import asyncnet
import gemcode
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


proc code*(response: Response): GemCode {.raises: ValueError.} =
  return response.header[0 .. 1].parseInt.GemCode


proc meta*(response: Response): string =
  var matches : array[1, string]
  let foundMeta = response.header.match(MetaRe, matches, 1)
  if foundMeta:
    return matches[0]
  else:
    return ""


proc body*(response: Response): string =
  if response.bodyStr.len == 0:
    response.bodyStream.setPosition(0)
    response.bodyStr = response.bodyStream.readAll()
  return response.bodyStr


type
  GeminiClient = ref object
    socket: Socket
    currentURL: Uri
    maxRedirects: Natural
    timeout*: int
    sslContext: net.SslContext
    bodyStream: Stream
    body: string


proc newGeminiClient*(maxRedirects = 5,
                     sslContext = getDefaultSSL()): GeminiClient =
  new result
  result.maxRedirects = maxRedirects
  result.sslContext = sslContext
  result.bodyStream = newStringStream("")


proc sendRequest(client: GeminiClient, url: string) =
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

  client.socket = newSocket()
  client.sslContext.wrapSocket(client.socket)
  client.socket.connect(hostname, port)
  client.socket.send($requestUrl & "\x0d\x0a")


proc parseResponse(client: GeminiClient): Response =
  new result
  var parsedHeader = false
  var line = "initial"
  while line != "":
    line = client.socket.recvLine()
    if not parsedHeader:
      result.header = line
      parsedHeader = true
      client.bodyStream = newStringStream()
      result.bodyStream = client.bodyStream
      continue
    client.bodyStream.writeLine(line)


proc fetch*(client: GeminiClient, url: string): Response =
  client.sendRequest(url)

  var redirCount = 0
  var response = parseResponse(client)
  while response.code.redirection:
    redirCount += 1
    if redirCount >= client.maxRedirects:
      break
    client.socket.close()
    client.sendRequest(response.meta)
    response = parseResponse(client)
    
  client.socket.close()
  return response
