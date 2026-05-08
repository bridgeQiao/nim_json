import std/[formatfloat, syncio]
import ./value

proc appendHex4(dest: var string; x: int) =
  const digits = "0123456789abcdef"
  dest.add "\\u"
  dest.add digits[(x shr 12) and 0xF]
  dest.add digits[(x shr 8) and 0xF]
  dest.add digits[(x shr 4) and 0xF]
  dest.add digits[x and 0xF]

proc appendQuoted*(dest: var string; s: string) =
  dest.add '"'
  var i = 0
  while i < s.len:
    let c = s[i]
    case c
    of '"':
      dest.add "\\\""
    of '\\':
      dest.add "\\\\"
    of '\b':
      dest.add "\\b"
    of '\f':
      dest.add "\\f"
    of '\l':
      dest.add "\\n"
    of '\r':
      dest.add "\\r"
    of '\t':
      dest.add "\\t"
    else:
      if ord(c) < 0x20:
        appendHex4 dest, ord(c)
      else:
        dest.add c
    inc i
  dest.add '"'

proc writeJson*(dest: var string; j: Json)

proc writeArray(dest: var string; elems: seq[Json]) =
  dest.add '['
  var i = 0
  while i < elems.len:
    if i > 0:
      dest.add ','
    writeJson dest, elems[i]
    inc i
  dest.add ']'

proc writeObject(dest: var string; pairs: seq[tuple[key: string, val: Json]]) =
  dest.add '{'
  var i = 0
  while i < pairs.len:
    if i > 0:
      dest.add ','
    appendQuoted dest, pairs[i].key
    dest.add ':'
    writeJson dest, pairs[i].val
    inc i
  dest.add '}'

proc writeJson*(dest: var string; j: Json) =
  case j
  of JNull(nilPad):
    discard nilPad
    dest.add "null"
  of JBool(b):
    if b:
      dest.add "true"
    else:
      dest.add "false"
  of JInt(i):
    dest.add $i
  of JFloat(f):
    addFloat dest, f
  of JString(s):
    appendQuoted dest, s
  of JArray(elems):
    writeArray dest, elems
  of JObject(pairs):
    writeObject dest, pairs

proc toJsonString*(j: Json): string =
  result = ""
  writeJson result, j

proc echoJson*(j: Json) =
  echo toJsonString(j)
