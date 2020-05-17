type
  GemCode* = distinct range[0 .. 65]


const
  Gem10 = GemCode(10)
  Gem20 = GemCode(20)
  Gem21 = GemCode(21)
  Gem30 = GemCode(30)
  Gem31 = GemCode(31)
  Gem40 = GemCode(40)
  Gem41 = GemCode(41)
  Gem42 = GemCode(42)
  Gem43 = GemCode(43)
  Gem44 = GemCode(44)
  Gem50 = GemCode(50)
  Gem51 = GemCode(51)
  Gem52 = GemCode(52)
  Gem53 = GemCode(53)
  Gem59 = GemCode(59)
  Gem60 = GemCode(60)
  Gem61 = GemCode(61)
  Gem62 = GemCode(62)
  Gem63 = GemCode(63)
  Gem64 = GemCode(64)
  Gem65 = GemCode(65)


proc `$`(code: GemCode): string =
  case code.int
  of 10: "INPUT"
  of 20: "SUCCESS"
  of 21: "SUCCESS - END OF CLIENT CERTIFICATE SESSION"
  of 30: "REDIRECT - TEMPORARY"
  of 31: "REDIRECT - PERMANENT"
  of 40: "TEMPORARY FAILURE"
  of 41: "SERVER UNAVAILABLE"
  of 42: "CGI ERROR"
  of 43: "PROXY ERROR"
  of 44: "SLOW DOWN"
  of 50: "PERMANENT FAILURE"
  of 51: "NOT FOUND"
  of 52: "GONE"
  of 53: "PROXY REQUEST REFUSED"
  of 59: "BAD REQUEST"
  of 60: "CLIENT CERTIFICATE REQUIRED"
  of 61: "TRANSIENT CERTIFICATE REQUESTED"
  of 62: "AUTHORISED CERTIFICATE REQUIRED"
  of 63: "CERTIFICATE NOT ACCEPTED"
  of 64: "FUTURE CERTIFICATE REJECTED"
  of 65: "EXPIRED CERTIFICATE REJECTED"
  else: $(int(code))


proc `==`*(a, b: GemCode): bool {.borrow.}

proc redirection*(code: GemCode): bool =
  return (code == Gem30) or (code == Gem31)
