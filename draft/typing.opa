// et si on avait un typer pour opa ?

// Example 1: does not work
type toto('a) = {toto : string} / 'a

type interface('a) = {
  toto : toto('a) -> void
}

type other = {other : int}

i = {
  toto(toto : toto(other)) =
    match toto with
    | {~toto} ->
      do jlog(toto)
      void
    | {~other} ->
      do jlog("other: "^string_of_int(other))
      void
} : interface(other)

_ =
  do i.toto({toto="toto"})
  do i.toto({other=42})
  void

// Example 2: does not work
type toto = {toto : string} / ...

type interface = {
  toto : toto -> void
}

i = {
  toto(toto : toto) =
    match toto with
    | {~toto} ->
      do jlog(toto)
      void
    | {~other} ->
      do jlog("other: "^string_of_int(other))
      void
} : interface

_ =
  do i.toto({toto="toto"})
  do i.toto({other=42})
  void


// test: does it work ??
type toto = {a} / {b}
type toto2 = toto / {c}

first(t) =
  match t : toto with
  | {a} -> jlog("a")
  | {b} -> jlog("b")

second(t) =
  match t : toto2 with
  | {c} -> jlog("c")
  | toto -> first(toto : toto)
