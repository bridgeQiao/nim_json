import std/[assertions, syncio]
import nim_json

type
  Person = object
    name: string
    age: int

deriveJson(Person)

proc main() =
  let p = Person(name: "Ada", age: 37)
  let j = toJson(p)
  assert toString(fieldAt(j, "name")) == "Ada"
  assert toInt(fieldAt(j, "age")) == 37
  let p2 = fromJson(j, Person)
  assert p2.name == "Ada"
  assert p2.age == 37
  echo "test_derive: OK"

main()
