open Quartic
open Base

let js_obj =
  let s = Stdio.In_channel.read_all "graph3.json" in
  Yojson.Basic.from_string s

let graph, state = Parsegraph.parse js_obj
let graph2, state2 = Parsegraph.parse js_obj

let condensed_graph = Condense.condense_cliques graph state
let%test _ = Set.length condensed_graph.nodes = 5
let%test _ = Map.length condensed_graph.edges = 4
let%test _ = List.length (Graph.edge_tuple_list condensed_graph.edges) = 3

let min_cond = Condense.condensible_subgraphs condensed_graph
let%test _ = Set.length min_cond = 1
let%test _ = Set.length (Set.choose_exn min_cond) = 4

let prime_list =
  Set.fold min_cond
    ~init:[]
    ~f:(fun accum vset ->
      let subgraph = Graph.induced_subgraph condensed_graph vset in
      let node = Graph.Prime (Graph.vmap_to_imap subgraph.edges subgraph.nodes) in
      (node, vset) :: accum)
let%test _ = List.length prime_list = 1
let%test _ = Set.length (snd (List.nth_exn prime_list 0)) = 4

let prime_condensed_graph =
  List.fold prime_list
    ~init:condensed_graph
    ~f:(fun graph (node, h) -> Condense.condense_prime node h graph state)
let%test _ = Set.length prime_condensed_graph.nodes = 2

let res = Condense.condense_cliques prime_condensed_graph state
let%test _ = Set.length res.nodes = 1
let () =
  let root = Set.choose_exn res.nodes in
  Hashtbl.add_exn state.id_map ~key:root.id ~data:root

let res2 = Condense.process graph2 state2
let%test _ = Graph.VSet.equal res.nodes res2.nodes
let%test _  = Hashtbl.equal (Graph.Vertex.equal) state.id_map state2.id_map

let tree = Tree.tree_from_condensed res state |> Caml.Option.get

let json_as_graph = Parsegraph.serialize_tree_as_graph tree
let json = Parsegraph.serialize_tree tree

(* let () = print_endline (Yojson.Basic.pretty_to_string json_as_graph)
let () = print_endline (Yojson.Basic.pretty_to_string json) *)
