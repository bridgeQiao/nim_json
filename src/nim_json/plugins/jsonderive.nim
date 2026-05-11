import nimonyplugins

proc tr(n: NifCursor): NifBuilder =
  var typ = if n.stmtKind == StmtsS: firstChild(n) else: n
  if typ.kind notin {Ident, Symbol}:
    return errorTree("deriveJson expects a type name", n)

  result = """
(stmts
  (proc toJson x . .
    (params
      (param x . . $typ .))
    Json . .
    (stmts
      (call objectToJson x)))
  (proc fromJson x . .
    (params
      (param j . . Json .)
      (param t . . (at typedesc $typ) .))
    $typ . .
    (stmts
      (call objectFromJson j $typ))))
""" %~ {"typ": ~typ}

var inp = loadPluginInput()
saveTree tr(inp)
