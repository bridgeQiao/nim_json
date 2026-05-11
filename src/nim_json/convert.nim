import std / [syncio, tables]
import ./value

proc expectKind(msg: string) {.noreturn.} =
  quit "json conversion error: expected " & msg

proc toJson*(x: bool): Json =
  let j: Json = JBool(b: x)
  result = j

proc toJson*(x: int): Json =
  let j: Json = JInt(i: int64(x))
  result = j

proc toJson*(x: float): Json =
  let j: Json = JFloat(f: float64(x))
  result = j

proc toJson*(x: string): Json =
  let j: Json = JString(s: x)
  result = j

proc objectToJson*[O: object](x: O): Json =
  var pairs = initTable[string, nil Json]()
  for name, f in fieldPairs(x):
    pairs.add((key: name, val: toJson(f)))
  let j: Json = JObject(pairs: pairs)
  result = j

proc toJson*[T](xs: seq[T]): Json =
  var elems = default(seq[Json])
  var i = 0
  while i < xs.len:
    when T is bool:
      elems.add toJson(xs[i])
    elif T is int:
      elems.add toJson(xs[i])
    elif T is float:
      elems.add toJson(xs[i])
    elif T is string:
      elems.add toJson(xs[i])
    else:
      expectKind "supported seq element"
    inc i
  let j: Json = JArray(elems: elems)
  result = j

proc toBool*(j: Json): bool =
  case j
  of JBool(b):
    result = b
  else:
    expectKind "bool"

proc toInt*(j: Json): int =
  case j
  of JInt(i):
    result = int(i)
  else:
    expectKind "int"

proc toInt64*(j: Json): int64 =
  case j
  of JInt(i):
    result = i
  else:
    expectKind "int64"

proc toFloat64*(j: Json): float64 =
  case j
  of JFloat(f):
    result = f
  of JInt(i):
    result = float64(i)
  else:
    expectKind "float"

proc toString*(j: Json): string =
  case j
  of JString(s):
    result = s
  else:
    expectKind "string"

proc toSeq*[T](j: Json; elemType: typedesc[T]): seq[T] =
  case j
  of JArray(elems):
    var xs = default(seq[T])
    var i = 0
    while i < elems.len:
      when T is bool:
        xs.add toBool(elems[i])
      elif T is int:
        xs.add toInt(elems[i])
      elif T is int64:
        xs.add toInt64(elems[i])
      elif T is float64:
        xs.add toFloat64(elems[i])
      elif T is string:
        xs.add toString(elems[i])
      else:
        expectKind "supported seq element"
      inc i
    result = xs
  else:
    expectKind "array"

proc readJsonInto*(dest: var bool; j: Json) =
  dest = toBool(j)

proc readJsonInto*(dest: var int; j: Json) =
  dest = toInt(j)

proc readJsonInto*(dest: var float; j: Json) =
  dest = float(toFloat64(j))

proc readJsonInto*(dest: var string; j: Json) =
  dest = toString(j)

proc objectFromJson*[O: object](j: Json; t: typedesc[O]): O {.noinit.} =
  case j
  of JObject(pairs):
    discard pairs
    for name, f in fieldPairs(result):
      let child = fieldAt(j, name)
      if child == default(Json):
        expectKind "object field " & name
      readJsonInto f, child
  else:
    expectKind "object"
