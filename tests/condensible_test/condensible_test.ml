open Gscore
open Base
open Graph

let graph = Parsegraph.read_file_as_graph "./condensible_graph.json"
let%test _ = Set.length graph.nodes = 5

let%test _ =
  let total_edges =
    Map.fold graph.edges ~init:0 ~f:(fun ~key:_ ~data:d acc ->
        acc + Set.length d)
  in
  total_edges = 14

let v1 = Atom { label = "1"; pol = true }
let v3 = Atom { label = "3"; pol = true }
let v4 = Atom { label = "4"; pol = true }
let v7 = Atom { label = "7"; pol = true }
let v8 = Atom { label = "8"; pol = true }
let vset13 = Set.of_list (module Node) [ v1; v3 ]
let vset34 = Set.of_list (module Node) [ v3; v4 ]
let vset47 = Set.of_list (module Node) [ v4; v7 ]
let vset78 = Set.of_list (module Node) [ v7; v8 ]
let vset18 = Set.of_list (module Node) [ v1; v8 ]
let vset38 = Set.of_list (module Node) [ v3; v8 ]
let vset48 = Set.of_list (module Node) [ v4; v8 ]
let scond13 = Condense.smallest_condensible graph vset13 |> Caml.Option.get
let%test _ = Set.length scond13 = 4
let scond34 = Condense.smallest_condensible graph vset34 |> Caml.Option.get
let%test _ = Set.length scond34 = 4
let scond47 = Condense.smallest_condensible graph vset47 |> Caml.Option.get
let%test _ = Set.length scond47 = 4
let scond78 = Condense.smallest_condensible graph vset78 |> Caml.Option.get
let%test _ = Set.length scond78 = 5
let scond18 = Condense.smallest_condensible graph vset18 |> Caml.Option.get
let%test _ = Set.length scond18 = 5
let scond38 = Condense.smallest_condensible graph vset38 |> Caml.Option.get
let%test _ = Set.length scond38 = 5
let scond48 = Condense.smallest_condensible graph vset48 |> Caml.Option.get
let%test _ = Set.length scond48 = 5
