import std/[assertions, syncio]
import nim_json

proc expectSyntaxError(input: string) =
  var raised = false
  try:
    discard parseJson(input)
  except ErrorCode as e:
    assert e == SyntaxError
    raised = true
  assert raised

proc main() {.raises.} =
  let j = parseJson("{\"name\":\"nimony\",\"ok\":true,\"n\":42,\"f\":1.5,\"xs\":[1,2,3],\"u\":\"A\\u0042\"}")

  assert hasField(j, "name")
  assert toString(fieldAt(j, "name")) == "nimony"
  assert toBool(fieldAt(j, "ok"))
  assert toInt64(fieldAt(j, "n")) == 42
  assert toFloat64(fieldAt(j, "f")) == 1.5
  assert toString(fieldAt(j, "u")) == "AB"

  let xs = toSeq(fieldAt(j, "xs"), int)
  assert xs.len == 3
  assert xs[0] == 1
  assert xs[2] == 3

  let packed = toJsonString(j)
  assert packed == "{\"name\":\"nimony\",\"ok\":true,\"n\":42,\"f\":1.5,\"xs\":[1,2,3],\"u\":\"AB\"}"

  var arr = default(seq[Json])
  arr.add toJson("a\nb")
  let seven: int = 7
  arr.add toJson(seven)
  let arrJson: Json = JArray(elems: arr)
  assert toJsonString(arrJson) == "[\"a\\nb\",7]"

  let concat = parseJsonConcat("[{\"a\":1}][{\"b\":true}]")
  assert concat.len == 2
  assert concat[0].len == 1
  assert concat[1].len == 1
  assert toInt(fieldAt(elemAt(concat[0], 0), "a")) == 1
  assert toBool(fieldAt(elemAt(concat[1], 0), "b"))
  assert toJsonConcatString(concat) == "[{\"a\":1}][{\"b\":true}]"

  expectSyntaxError("{\"missing\":")
  expectSyntaxError("[1,]")
  expectSyntaxError("[{}][{}]")

  echo "test_basic: OK"

try:
  main()
except ErrorCode as e:
  discard e
  assert false
