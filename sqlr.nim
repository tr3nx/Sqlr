type
  Query = object
    fields: seq[string]
    table: string
    joins: seq[Join]
    wheres: seq[Where]
    limits: int
    orderby: string
    sort: string

  Where = object
    this: string
    that: string
    op: string

  Join = object
    kind: string
    fields: seq[string]
    table: string
    on: seq[Where]

proc toSql(query: Query): string =
  var q = query
  var s = "SELECT "

  for f in q.fields:
    s.add f & ", "
  s = s[0..^3] & " " # trim trailing comma

  if q.joins.len > 0:
    for j in q.joins:
      for f in j.fields:
        s.add j.table & "." & f & ", "
    s = s[0..^3] & " " # trim trailing comma

  s.add "FROM " & q.table & " "

  if q.joins.len > 0:
    for j in q.joins:
      if j.kind.len > 0:
        s.add j.kind & " "
      else:
        s.add "INNER "
      s.add "JOIN " & q.table & " ON "
      for o in j.on:
        s.add "`" & j.table & "." & o.this & "` " & o.op & " `" & o.that & "` AND "
      s = s[0..^5] # trim trailing AND

  if q.wheres.len > 0:
    s.add "WHERE "
    for where in q.wheres:
      s.add "`" & where.this & "` " & where.op & " `" & where.that & "` AND "
  s = s[0..^5] # trim trailing AND

  if q.orderby.len > 0:
    s.add "ORDER BY `" & q.orderby & "` "
    if q.sort == "desc":
      s.add "DESC "
    else:
      s.add "ASC "

  if q.limits > 0:
    s.add "LIMIT " & $q.limits & " "

  return s[0..^2] & ";"

proc select(q: Query, fields: seq[string], table: string): Query =
  result = q
  result.fields = fields
  result.table = table

proc where(q: Query, this, that, op: string): Query =
  result = q
  result.wheres.add(Where(this: this, that: that, op: op))

proc order(q: Query, by, sort: string): Query =
  result = q
  result.orderby = by
  result.sort = sort

proc limit(q: Query, l: int): Query =
  result = q
  result.limits = l

proc join(q: Query, fields: seq[string], table: string, on: seq[Where]): Query =
  result = q
  result.joins.add(Join(fields: fields, table: table, on: on))

echo Query()
  .select(@["id", "title", "file"], "pages")
  .where("title", "Homepage", "=")
  .where("file", "home.tmpl", "=")
  .join(@["name", "path", "page"], "nav", @[Where(this: "page", that: "id", op: "=")])
  .order("id", "desc")
  .limit(1)
  .toSql()
