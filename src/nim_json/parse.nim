import std/[parseutils, strutils, syncio]
import ./value

proc fail(msg: string) {.noreturn.} =
  quit "json parse error: " & msg

proc skipWs(s: string; i: var int) =
  while i < s.len and s[i] in Whitespace:
    inc i

proc expect(s: string; i: var int; token, name: string) =
  if s.continuesWith(token, i):
    inc i, token.len
  else:
    fail "expected " & name

proc readHexDigit(c: char): int =
  case c
  of '0'..'9':
    result = ord(c) - ord('0')
  of 'a'..'f':
    result = ord(c) - ord('a') + 10
  of 'A'..'F':
    result = ord(c) - ord('A') + 10
  else:
    result = -1

proc addUtf8Rune(dest: var string; code: int) =
  if code <= 0x7F:
    dest.add char(code)
  elif code <= 0x7FF:
    dest.add char(0xC0 or (code shr 6))
    dest.add char(0x80 or (code and 0x3F))
  else:
    dest.add char(0xE0 or (code shr 12))
    dest.add char(0x80 or ((code shr 6) and 0x3F))
    dest.add char(0x80 or (code and 0x3F))

proc parseUnicodeEscape(s: string; i: var int; dest: var string) =
  if i + 4 > s.len:
    fail "short unicode escape"
  var code = 0
  var n = 0
  while n < 4:
    let d = readHexDigit(s[i])
    if d < 0:
      fail "bad unicode escape"
    code = code * 16 + d
    inc i
    inc n
  addUtf8Rune dest, code

proc parseStringLit(s: string; i: var int): string =
  if i >= s.len or s[i] != '"':
    fail "expected string"
  inc i
  result = ""
  while i < s.len:
    let c = s[i]
    if c == '"':
      inc i
      return
    if ord(c) < 0x20:
      fail "control character in string"
    if c == '\\':
      inc i
      if i >= s.len:
        fail "bad escape in string"
      case s[i]
      of '"', '\\', '/':
        result.add s[i]
        inc i
      of 'b':
        result.add '\b'
        inc i
      of 'f':
        result.add '\f'
        inc i
      of 'n':
        result.add '\l'
        inc i
      of 'r':
        result.add '\r'
        inc i
      of 't':
        result.add '\t'
        inc i
      of 'u':
        inc i
        parseUnicodeEscape s, i, result
      else:
        fail "unsupported escape in string"
    else:
      result.add c
      inc i
  fail "unterminated string"

proc parseJsonValue(s: string; i: var int): Json

proc parseArray(s: string; i: var int): Json =
  inc i
  skipWs s, i
  var xs = default(seq[Json])
  if i < s.len and s[i] == ']':
    inc i
    let j: Json = JArray(elems: xs)
    return j
  while true:
    skipWs s, i
    xs.add parseJsonValue(s, i)
    skipWs s, i
    if i >= s.len:
      fail "unterminated array"
    if s[i] == ']':
      inc i
      break
    if s[i] != ',':
      fail "expected comma or closing bracket"
    inc i
  let j: Json = JArray(elems: xs)
  result = j

proc parseObject(s: string; i: var int): Json =
  inc i
  skipWs s, i
  var ps = default(seq[tuple[key: string, val: Json]])
  if i < s.len and s[i] == '}':
    inc i
    let j: Json = JObject(pairs: ps)
    return j
  while true:
    skipWs s, i
    let k = parseStringLit(s, i)
    skipWs s, i
    if i >= s.len or s[i] != ':':
      fail "expected colon after object key"
    inc i
    skipWs s, i
    let v = parseJsonValue(s, i)
    ps.add((key: k, val: v))
    skipWs s, i
    if i >= s.len:
      fail "unterminated object"
    if s[i] == '}':
      inc i
      break
    if s[i] != ',':
      fail "expected comma or closing brace"
    inc i
  let j: Json = JObject(pairs: ps)
  result = j

proc parseNumber(s: string; i: var int): Json =
  let start = i
  var isFloat = false
  var p = i
  if p < s.len and s[p] == '-':
    inc p
  if p >= s.len:
    fail "expected digit"
  if s[p] == '0':
    inc p
    if p < s.len and s[p] in {'0'..'9'}:
      fail "leading zero in number"
  elif s[p] in {'1'..'9'}:
    while p < s.len and s[p] in {'0'..'9'}:
      inc p
  else:
    fail "expected digit"
  if p < s.len and s[p] == '.':
    isFloat = true
    inc p
    if p >= s.len or s[p] notin {'0'..'9'}:
      fail "expected digit after decimal point"
    while p < s.len and s[p] in {'0'..'9'}:
      inc p
  if p < s.len and s[p] in {'e', 'E'}:
    isFloat = true
    inc p
    if p < s.len and s[p] in {'+', '-'}:
      inc p
    if p >= s.len or s[p] notin {'0'..'9'}:
      fail "expected digit in exponent"
    while p < s.len and s[p] in {'0'..'9'}:
      inc p

  var f = default(BiggestFloat)
  let n = parseBiggestFloat(s.toOpenArray(start, p - 1), f)
  if n == 0:
    fail "expected number"
  if n != p - start:
    fail "bad number"
  i = p
  if isFloat:
    let j: Json = JFloat(f: float64(f))
    result = j
  else:
    var x = default(BiggestInt)
    discard parseBiggestInt(s.toOpenArray(start, i - 1), x)
    let j: Json = JInt(i: int64(x))
    result = j

proc parseJsonValue(s: string; i: var int): Json =
  skipWs s, i
  if i >= s.len:
    fail "unexpected end of input"
  case s[i]
  of 'n':
    expect s, i, "null", "null"
    let j: Json = JNull(nilPad: false)
    result = j
  of 't':
    expect s, i, "true", "true"
    let j: Json = JBool(b: true)
    result = j
  of 'f':
    expect s, i, "false", "false"
    let j: Json = JBool(b: false)
    result = j
  of '"':
    let j: Json = JString(s: parseStringLit(s, i))
    result = j
  of '[':
    result = parseArray(s, i)
  of '{':
    result = parseObject(s, i)
  of '-', '0'..'9':
    result = parseNumber(s, i)
  else:
    fail "unexpected character"

proc parseJson*(s: string): Json =
  var i = 0
  result = parseJsonValue(s, i)
  skipWs s, i
  if i != s.len:
    fail "trailing characters"
