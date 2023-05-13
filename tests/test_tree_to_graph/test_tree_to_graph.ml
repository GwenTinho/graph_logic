open Gscore
open Base

let graph = Parsegraph.read_file_as_graph "./graph.json"
let tree = Condense.tree_from_graph graph |> Caml.Option.get
let graphT = Tree.tree_to_graph tree
let%test "graph1_eq_nodes" = Graph.NSet.equal graph.nodes graphT.nodes
let%test "graph1_eq_maps" = Map.equal Graph.NSet.equal graph.edges graphT.edges
let graph2 = Parsegraph.read_file_as_graph "./graph2.json"
let tree = Condense.tree_from_graph graph2 |> Caml.Option.get (*these fail now*)
let graphT2 = Tree.tree_to_graph tree
let%test "graph2_eq_nodes" = Graph.NSet.equal graph2.nodes graphT2.nodes

let%test "graph2_eq_maps" =
  Map.equal Graph.NSet.equal graph2.edges graphT2.edges

let graph3 = Parsegraph.read_file_as_graph "./graph3.json"
let tree = Condense.tree_from_graph graph3 |> Caml.Option.get
let graphT3 = Tree.tree_to_graph tree
let%test "graph3_eq_nodes" = Graph.NSet.equal graph3.nodes graphT3.nodes

let%test "graph3_eq_maps" =
  Map.equal Graph.NSet.equal graph3.edges graphT3.edges
