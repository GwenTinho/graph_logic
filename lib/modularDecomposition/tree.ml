open Base

type id_graph = {
    nodes : int list;
    edges : (int * int) list;
}

type connective =
  | Atom of Graph.atom
  | Tensor of tree list
  | Par of tree list
  | Before of tree list
  | Prime of id_graph * (tree list)

and tree = {
    connective : connective;
    id: int;
    }

let successors tree =
  match tree.connective with
  | Atom _ -> []
  | Tensor tl -> tl
  | Par tl -> tl
  | Before tl -> tl
  | Prime (_, tl) -> tl

let remove_id id map =
  Map.remove map id |> Map.map ~f:(fun v -> Set.remove v id)

let from_map ?directed map =
  let nodes = Map.keys map in
  let edges =
    let rec id_tuples_from_map (map : Graph.IMap.t) =
      if Map.is_empty map then
        []
      else
        let id, id_neighbours = Map.min_elt_exn map in
        let new_imap = 
          if Util.resolve directed then Map.remove map id else remove_id id map
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

let tree_from_condensed ?directed (graph : Graph.graph) state =
  let () = assert(Set.length graph.nodes <= 1) in
  match Set.choose graph.nodes with
    | None -> None 
    | Some root ->
      let rec tree_from_id id (state : Graph.state) =
        let vertex : Graph.vertex = Hashtbl.find_exn state.id_map id in
        match vertex.connective with
        | Graph.Atom atom -> {connective = Atom atom; id = vertex.id}

        | Graph.Tensor iset -> 
          let tree_list = trees_from_id_list (Set.elements iset) state in
          let tensor_lists, tree_list = List.partition_map tree_list ~f:(fun t ->
            match t.connective with
            | Tensor tl -> First tl
            | _ -> Second t)
          in
          let successors = List.concat (tree_list :: tensor_lists) in
          {connective = Tensor successors; id = vertex.id}

        | Graph.Par iset ->
          let tree_list = trees_from_id_list (Set.elements iset) state in
          let par_lists, tree_list = List.partition_map tree_list ~f:(fun t ->
            match t.connective with
            | Par tl -> First tl
            | _ -> Second t)
          in
          let successors = List.concat (tree_list :: par_lists) in
          {connective = Par successors; id = vertex.id}

        | Graph.Before ilist ->
          let tree_list = trees_from_id_list ilist state in
          let rec parse_before tl =
            match tl with 
            | [] -> []
            | h :: t ->
              match h.connective with
              | Before tl -> tl @ (parse_before t)
              | _ -> h :: (parse_before t)
          in
          let successors = parse_before tree_list in
          {connective = Before successors; id = vertex.id}

        | Graph.Prime map ->
          let id_graph = from_map ?directed:directed map in
          let tree_list = trees_from_id_list id_graph.nodes state in
          {connective = Prime (id_graph, tree_list); id = vertex.id}

      and trees_from_id_list id_list state =
        List.map id_list ~f:(Util.flip tree_from_id state)
      in
      Some (tree_from_id root.id state)

(** [tree_to_graph ?directed tree] converts a tree to a graph, using [directed] to specify if the tree is directed *)
let tree_to_graph ?directed tree = 
  let join_sets ?symmetric vs1 vs2 = 
    Set.fold vs1 ~init:([]) ~f:(fun li vi ->
      Set.fold vs2 ~init:(li) ~f:(fun lj vj ->
        match symmetric with
        | None -> (vi, vj) :: lj
        | Some bool -> if bool then (vi, vj) :: (vj, vi) :: lj else
          (vi, vj) :: lj))
  in
  let rec tree_to_graph_r tree = 
    match tree.connective with
    | Atom atom -> 
      let node = Set.singleton (module Graph.Vertex) {connective=Atom atom; id=tree.id} in
      (node, [])

    | Par tl ->
      let nodes, edges = List.fold tl ~init:(Set.empty (module Graph.Vertex), [])
        ~f:(fun (vset, el) t ->
          let nodes, el_to_add = tree_to_graph_r t in
          (Set.union vset nodes, el_to_add @ el))
      in 
      (nodes, edges)

    | Tensor tl ->
      let nel = List.map tl ~f:(tree_to_graph_r) in
      let nodes, edges = List.fold nel ~init:(Set.empty (module Graph.Vertex), [])
        ~f:(fun (vsetacc, elacc) (vset, el) ->
          let vertices = Set.union vsetacc vset in
          let edge_base = el @ elacc in
          let edges = join_sets ?symmetric:directed vsetacc vset in
          vertices, edges @ edge_base)
      in
      nodes, edges
    
    | Before tl ->
      let nel = List.map tl ~f:(tree_to_graph_r) in
      let nodes, edges = List.fold nel ~init:(Set.empty (module Graph.Vertex), [])
        ~f:(fun (vsetacc, elacc) (vset, el) ->
          let vertices = Set.union vsetacc vset in
          let edge_base = el @ elacc in
          let edges = join_sets ~symmetric:false vset vsetacc in
          vertices, edges @ edge_base)
      in
      nodes, edges

    | Prime (id_graph, tl) ->
      let vertices, edges, id_map = List.fold tl ~init:(Set.empty (module Graph.Vertex), [], Map.empty (module Int))
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
      vertices, new_edges @ edges
  in
  let vertices, edges = tree_to_graph_r tree in
  let edges, edges_from = Graph.edge_maps ?directed edges in
  {Graph.nodes = vertices; edges = edges; edges_from = edges_from}