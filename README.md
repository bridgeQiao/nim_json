# nim_json

`nim_json` is a small JSON package for Nimony. The runtime JSON value model is
built on Nimony's sum type object syntax.

## Current Shape

```nim
import nim_json

let j = parseJson("{\"name\":\"nimony\",\"n\":42}")
assert toString(fieldAt(j, "name")) == "nimony"
assert toInt64(fieldAt(j, "n")) == 42

echo toJsonString(j)
```

Parse errors raise `SyntaxError` and can be checked with Nimony's `ErrorCode`
exception handling:

```nim
try:
  discard parseJson("[1,]")
except ErrorCode as e:
  assert e == SyntaxError
```

The core parser and writer are normal runtime code. The derive layer is a Nimony
template plugin that generates thin per-type wrappers around runtime helpers.

```nim
import nim_json

type
  Person = object
    name: string
    age: int

deriveJson(Person)

let p = Person(name: "Ada", age: 37)
let j = toJson(p)
let p2 = fromJson(j, Person)
```

`deriveJson(T)` currently targets plain object types with scalar fields supported
by `readJsonInto` (`bool`, `int`, `float`, `string`). Serialization can also use
field types that already have a visible `toJson` overload.

## Modules

- `src/nim_json/value.nim`: `Json` sum type and access helpers.
- `src/nim_json/parse.nim`: string to `Json`.
- `src/nim_json/write.nim`: `Json` to compact JSON string.
- `src/nim_json/convert.nim`: basic conversions for bool, int, float, string,
  and simple seq values.
- `src/nim_json/derive.nim`: public `deriveJson` template.
- `src/nim_json/plugins/jsonderive.nim`: compiler plugin that emits wrappers.

## Test

```sh
nimony c -r -p:src tests/test_basic.nim
nimony c -r -p:src tests/test_derive.nim
```
