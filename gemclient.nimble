# Package

version       = "0.1.0"
author        = "Koushk Roy"
description   = "A rich client library for the Gemini Protocol"
license       = "GPL-3.0"
srcDir        = "src"



# Dependencies

requires "nim >= 1.2.0"

when defined(nimdistros):
  import distros
  if detectOs(Ubuntu):
    foreignDep "libssl-dev"
  else:
    foreignDep "openssl"
