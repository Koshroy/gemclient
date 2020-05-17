import asyncdispatch
import asyncfutures
import asyncnet

import gemclient    

proc main(): Future[void] {.async.} =
  var client = newAsyncGeminiClient()
  let resp = await client.fetch("gemini://mozz.us/markdown")
  let respBody = await resp.body
  echo "Response: ", respBody

waitFor(main())
