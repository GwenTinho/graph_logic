open Quartic
open Base

let js_obj =
    let s = Stdio.In_channel.read_all "./graph.json" in
    Yojson.Basic.from_string s

let graph, state = Parsegraph.parse js_obj
let graph2, state2 = Parsegraph.parse js_obj

let vertex = {Graph.connective = Atom {label = "new"; pol = true}; id = Graph.fresh_id state}
let%test _ = vertex.id = 9

let graph = Graph.add_vertex vertex graph
let%test _ = Set.mem graph.nodes vertex

let graph = Graph.remove_vertex vertex graph
let%test _ = Set.mem graph.nodes vertex |> not

let () = state.total_vertices <- state.total_vertices - 1

let vset1, vset2 = Set.partition_tf graph.nodes ~f:(fun v -> v.id % 2 = 0)
let%test _ = Graph.disjoint vset1 vset2
let%test _ = Graph.disjoint vset1 vset1 |> not

let%test _ = Graph.VSet.equal (Graph.(<~>) graph vset1).nodes vset2
let%test _ = Graph.VSet.equal (Graph.connected graph vset1) vset2

let dummy_state : Graph.state = {
  total_vertices = 8;
  id_map = Hashtbl.create (module Int)
}
let neighbours = Graph.neighbours graph vset1
let () = assert(Graph.VSet.equal neighbours vset2)
let dummy_graph = Graph.replace graph vset1 vertex dummy_state
let%test _ = Graph.disjoint vset1 dummy_graph.nodes
let%test _ = not (Hashtbl.is_empty dummy_state.id_map)
let%test _ = Graph.VSet.equal (Graph.neighbour dummy_graph vertex) neighbours

let%test _ =
    let graph = Graph.add_vertex vertex graph in
    let graph = Graph.connect_vertices vset1 vertex graph in
    Set.for_all vset1
      ~f:(fun v ->
        Set.mem (Map.find_exn graph.edges v) vertex)

let%test _ =
  let graph = Graph.(<~>) graph vset1 in
  Set.for_all graph.nodes
    ~f:(fun v -> not (Set.mem vset1 v))
  &&
  Map.for_all graph.edges
    ~f:(fun vset -> Graph.disjoint vset vset1)

let%test _ =
  let graph = Graph.induced_subgraph graph vset1 in
  Graph.VSet.equal graph.nodes vset1
  &&
  Map.for_all graph.edges
    ~f:(fun vset -> Set.is_subset vset ~of_:vset1)

let%test _ =
  let from_id_list list =
    Set.filter graph.nodes
      ~f:(fun v -> List.mem list v.id ~equal:Int.equal)
  in
  let module1 = [4;5] in
  let module2 = [1;2] in
  let notmodule = [3;7] in
  let vertices1 = from_id_list module1 in
  let vertices2 = from_id_list module2 in
  let vertices3 = from_id_list notmodule in
  Graph.is_module graph vertices1
  &&
  Graph.is_module graph vertices2
  &&
  not (Graph.is_module graph vertices3)

let condensed_graph = Condense.condense_cliques graph state
let%test _ = Set.length condensed_graph.nodes = 5
let%test _ = Map.length condensed_graph.edges = 5
let%test _ = List.length (Graph.edge_tuple_list condensed_graph.edges) = 6

let min_cond = Condense.condensible_subgraphs condensed_graph
let%test _ = Set.length min_cond = 1

let prime_list =
  Set.fold min_cond
    ~init:[]
    ~f:(fun accum vset ->
      let subgraph = Graph.induced_subgraph condensed_graph vset in
      let node = Graph.Prime (Graph.vmap_to_imap subgraph.edges subgraph.nodes) in
      (node, vset) :: accum)
let%test _ = List.length prime_list = 1
let%test _ = Set.length (snd (List.nth_exn prime_list 0)) = 5

let res =
  List.fold prime_list
    ~init:condensed_graph
    ~f:(fun graph (node, h) -> Condense.condense_prime node h graph state)
let%test _ = Set.length res.nodes = 1
let () =
  let root = Set.choose_exn res.nodes in
  Hashtbl.add_exn state.id_map ~key:(root.id) ~data:(root)

let res2 = Condense.process graph2 state2
let%test _ = Graph.VSet.equal res.nodes res2.nodes
let%test _  = Hashtbl.equal (Graph.Vertex.equal) state.id_map state2.id_map

let tree = Tree.tree_from_condensed res state |> Caml.Option.get

let json_as_graph = Parsegraph.serialize_tree_as_graph tree
let json = Parsegraph.serialize_tree tree

(* let () = print_endline (Yojson.Basic.pretty_to_string json_as_graph)
let () = print_endline (Yojson.Basic.pretty_to_string json) *)
