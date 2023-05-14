open Quartic
open Base

let js_obj =
  let s = Stdio.In_channel.read_all "graph3.json" in
  Yojson.Basic.from_string s

let graph, state = Parsegraph.parse js_obj
let condensed = Condense.process graph state
let tree = Tree.tree_from_condensed condensed state |> Caml.Option.get

let graph2 = Tree.tree_to_graph tree
let%test _ = Graph.VSet.equal graph.nodes graph2.nodes
let%test _ = Map.equal (Graph.VSet.equal) graph.edges graph2.edges
