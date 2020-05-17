import gemclient    

var client = newGeminiClient()
let resp = client.fetch("gemini://mozz.us/markdown")
echo "Hello: ", resp.body
