open Quartic
open Base

let js_obj =
  let s = Stdio.In_channel.read_all "before_trans.json" in
  Yojson.Basic.from_string s

let graph, state = Parsegraph.parse ~directed:true js_obj
let condensed = Condense.process graph state
let%test _ = Set.length condensed.nodes = 1
let%test _ = match (Set.choose_exn condensed.nodes).connective with
  | Graph.Before tl ->
    if List.equal (=) tl [3;2;1] then true else false
  | _ -> false

let tree = Tree.tree_from_condensed ~directed:true condensed state |> Caml.Option.get

let graph2 = Tree.tree_to_graph ~directed:true tree
let%test _ = Graph.VSet.equal graph.nodes graph2.nodes
let%test _ = Map.equal (Graph.VSet.equal) graph.edges graph2.edges
