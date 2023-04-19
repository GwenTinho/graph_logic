open Base
open Id_graph


type connective =
  | Atom of Graph.atom
  | Tensor of tree list
  | Par of tree list
  | Prime of id_graph * (tree list)

and tree = {
    connective : connective;
    id: int;
    }

let empty_tree id = {id; connective=Par []}

let successors tree =
  match tree.connective with
  | Atom _ -> []
  | Tensor tl -> tl
  | Par tl -> tl
  | Prime (_, tl) -> tl

let from_map (map: Util.IMap.t) =
  let nodes = Map.keys map in
  let edges =
    let rec id_tuples_from_map (map : Util.IMap.t) =
      if Map.is_empty map then
        []
      else
        let id, id_neighbours = Map.min_elt_exn map in
        let new_imap = Util.remove_id id map
        in
        let new_edges = Set.fold id_neighbours
          ~init:[]
          ~f:(fun accum id2 -> (id, id2) :: accum)
        in
        new_edges @ id_tuples_from_map new_imap
    in
    id_tuples_from_map map
  in
  {nodes = nodes; edges = edges}

(** [tree_to_graph tree] converts a tree to a graph *)
let tree_to_graph tree =
  let join_sets vs1 vs2 =
    Set.fold vs1 ~init:([]) ~f:(fun li vi ->
      Set.fold vs2 ~init:(li) ~f:(fun lj vj -> (vi, vj) :: (vj, vi) :: lj))
  in
  let rec tree_to_graph_r tree =
    match tree.connective with
    | Atom atom ->
      let node = Set.singleton (module Graph.Vertex) {connective=Atom atom; id=tree.id} in
      (node, [])

    | Par tl ->
      let nodes, edges = List.fold tl ~init:(Graph.empty_vertex_set (), [])
        ~f:(fun (vset, el) t ->
          let nodes, el_to_add = tree_to_graph_r t in
          (Set.union vset nodes, el_to_add @ el))
      in
      (nodes, edges)

    | Tensor tl ->
      let nel = List.map tl ~f:(tree_to_graph_r) in
      let nodes, edges = List.fold nel ~init:(Graph.empty_vertex_set (), [])
        ~f:(fun (vsetacc, elacc) (vset, el) ->
          let vertices = Set.union vsetacc vset in
          let edge_base = el @ elacc in
          let edges = join_sets vsetacc vset in
          vertices, edges @ edge_base)
      in
      (nodes, edges)
    | Prime (id_graph, tl) ->
      let vertices, edges, id_map = List.fold tl ~init:(Graph.empty_vertex_set (), [], Map.empty (module Int))
        ~f:(fun (vset, el, map) t ->
          let nodes, edges = tree_to_graph_r t in
          let nmap = Map.add_exn map ~key:t.id ~data:nodes in
          (Set.union vset nodes, edges @ el, nmap))
      in
      let new_edges = List.fold id_graph.edges ~init:([])
        ~f:(fun el (id1, id2) ->
          let new_edges = join_sets
            (Graph.find_or_empty id_map id1)
            (Graph.find_or_empty id_map id2)
          in
          new_edges @ el)
      in
      (vertices, new_edges @ edges)
  in
  let vertices, edges = tree_to_graph_r tree in
  let edges = Graph.edge_maps edges in
  {Graph.nodes = vertices; edges}
