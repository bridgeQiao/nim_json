import std / tables

type
  Json* = ref object
    case
    of JNull:
      nilPad*: bool
    of JBool:
      b*: bool
    of JInt:
      i*: int64
    of JFloat:
      f*: float64
    of JString:
      s*: string
    of JArray:
      elems*: seq[Json]
    of JObject:
      pairs*: Table[string, nil Json]

proc newNull*(): Json =
  let j: Json = JNull(nilPad: false)
  result = j

proc newBool*(value: bool): Json =
  let j: Json = JBool(b: value)
  result = j

proc newInt*(value: int64): Json =
  let j: Json = JInt(i: value)
  result = j

proc newFloat*(value: float64): Json =
  let j: Json = JFloat(f: value)
  result = j

proc newString*(value: string): Json =
  let j: Json = JString(s: value)
  result = j

proc newArray*(elems: sink seq[Json]): Json =
  let j: Json = JArray(elems: elems)
  result = j

proc newObject*(pairs: sink Table[string, nil Json]): Json =
  let j: Json = JObject(pairs: pairs)
  result = j

proc len*(j: Json): int =
  case j
  of JArray(elems):
    result = elems.len
  of JObject(pairs):
    result = pairs.len
  else:
    result = 0

proc elemAt*(j: Json; index: int): Json =
  case j
  of JArray(elems):
    result = elems[index]
  else:
    result = default(Json)

proc fieldAt*(j: Json; key: string): Json =
  result = default(Json)
  case j
  of JObject(pairs):
    try:
      if pairs.contains(key):
        let value = pairs[key]
        if value != nil:
          return value
    except:
      discard
  else:
    discard

proc hasField*(j: Json; key: string): bool =
  case j
  of JObject(pairs):
    if pairs.contains(key):
      return true
  else:
    discard
  result = false
