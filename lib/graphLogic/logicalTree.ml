open Base
open Quartic
open Idgraph

type ltree =
  | Atom of Graph.atom
  | Tensor of ltree list
  | Par of ltree list
  | Prime of id_graph * ltree list

let ( let* ) o f = match o with None -> None | Some x -> f x

let rec ltree_of_mdtree (mdtree : Tree.tree) =
  match mdtree.connective with
  | Tree.Atom a -> Atom a
  | Tree.Tensor ts -> Tensor (List.map ~f:ltree_of_mdtree ts)
  | Tree.Par ts -> Par (List.map ~f:ltree_of_mdtree ts)
  | Tree.Prime (g, ts) -> Prime (idg_of_tidg g, List.map ~f:ltree_of_mdtree ts)
  | _ -> failwith "ltree_of_mdtree: not implemented"

let mdtree_of_ltree (ltree : ltree) =
  let id = ref 0 in
  let rec aux ltree =
    id := !id + 1;
    match ltree with
    | Atom a -> { Tree.connective = Tree.Atom a; Tree.id = !id }
    | Tensor ts ->
        (*We want unique ids*)
        { Tree.connective = Tree.Tensor (List.map ~f:aux ts); Tree.id = !id }
    | Par ts ->
        { Tree.connective = Tree.Par (List.map ~f:aux ts); Tree.id = !id }
    | Prime (g, ts) ->
        {
          Tree.connective = Tree.Prime (tidg_of_idg g, List.map ~f:aux ts);
          Tree.id = !id;
        }
  in
  aux ltree

let rec count_nodes tree =
  match tree with
  | Atom _ -> 1
  | Tensor tl -> List.fold tl ~init:0 ~f:(fun acc t -> acc + count_nodes t)
  | Par tl -> List.fold tl ~init:0 ~f:(fun acc t -> acc + count_nodes t)
  | Prime (_, tl) -> List.fold tl ~init:0 ~f:(fun acc t -> acc + count_nodes t)

let count_children tree =
  match tree with
  | Atom _ -> 0
  | Tensor tl -> List.length tl
  | Par tl -> List.length tl
  | Prime (_, tl) -> List.length tl

let ltree_of_graph (graph : Graph.graph) =
  match Tree.tree_from_graph graph with
  | None -> None
  | Some md_tree -> Some (ltree_of_mdtree md_tree)

let combineConnectives tree =
  (*Idea: if a par has par subnodes, combine those subnodes into the highest par*)
  let rec aux tree =
    match tree with
    | Atom _ -> tree
    | Tensor tl ->
        let tl = List.map ~f:aux tl in
        let tl =
          List.fold tl ~init:[] ~f:(fun acc t ->
              match t with
              | Tensor tl' -> List.append acc tl'
              | _ -> List.append acc [ t ])
        in
        Tensor tl
    | Par tl ->
        let tl = List.map ~f:aux tl in
        let tl =
          List.fold tl ~init:[] ~f:(fun acc t ->
              match t with
              | Par tl' -> List.append acc tl'
              | _ -> List.append acc [ t ])
        in
        Par tl
    | Prime (g, tl) -> Prime (g, List.map ~f:aux tl)
  in
  aux tree

let rec remove_empty ltree =
  match ltree with
  | Atom _ -> Some ltree
  | Tensor [] -> None
  | Tensor [ t ] -> remove_empty t
  | Tensor tl -> Some (Tensor (List.filter_map ~f:remove_empty tl))
  | Par [] -> None
  | Par [ t ] -> remove_empty t
  | Par tl -> Some (Par (List.filter_map ~f:remove_empty tl))
  | Prime (g, tl) ->
      (*Idea: if a node evaluates to None, then remove that node and all connected edges in the idg*)
      (*To do that first zip up the nodes with the successors*)
      let zipped = List.zip_exn g.nodes tl in
      (*Then filter out the nodes that evaluate to None*)
      let filtered =
        List.filter_map
          ~f:(fun (n, t) ->
            match remove_empty t with None -> None | Some t' -> Some (n, t'))
          zipped
      in
      (*Then unzip the nodes and successors*)
      let nodes, tl = List.unzip filtered in
      let node_map = Map.of_alist_exn (module Int) filtered in
      (*Then remove the edges from the idg*)
      let g' = restrict g nodes in
      (*Now if the new graph is disconnected make a new graph for each connected component*)
      let components = Idgraph.connected_components g' in
      if List.length components = 1 then Some (Prime (g', tl))
      else
        Some
          (Par
             (List.filter_map
                ~f:(fun component ->
                  let component = component in
                  match List.length component.nodes with
                  | 0 -> None
                  | 1 ->
                      let i1 = List.nth_exn component.nodes 0 in
                      let t1 = Map.find_exn node_map i1 in
                      Some t1
                  | 2 ->
                      let i1 = List.nth_exn component.nodes 0 in
                      let i2 = List.nth_exn component.nodes 1 in
                      let t1 = Map.find_exn node_map i1 in
                      let t2 = Map.find_exn node_map i2 in

                      Some (Tensor [ t1; t2 ])
                  | 3 ->
                      let i1 = List.nth_exn component.nodes 0 in
                      let i2 = List.nth_exn component.nodes 1 in
                      let i3 = List.nth_exn component.nodes 2 in
                      let t1 = Map.find_exn node_map i1 in
                      let t2 = Map.find_exn node_map i2 in
                      let t3 = Map.find_exn node_map i3 in
                      Some (Tensor [ t2; Par [ t1; t3 ] ])
                  | _ -> Some (Prime (component, tl)))
                components))

let simplify tree = tree |> combineConnectives |> remove_empty
let empty_tree () = Par []
let hash_tree (tree : ltree) = Hashtbl.hash tree

let successors tree =
  match tree with
  | Atom _ -> []
  | Tensor tl -> tl
  | Par tl -> tl
  | Prime (_, tl) -> tl

let traverse_by_path tree path =
  let rec aux tree path =
    match path with
    | [] -> Some tree
    | h :: t ->
        let* next = Base.List.nth (successors tree) h in
        aux next t
  in
  aux tree path

let map_at_path tree path ~f =
  let* path_part_from_head = Base.List.tl path in
  let rec aux tree path =
    match path with
    | [] -> f tree
    | h :: t ->
        let* next = Base.List.nth (successors tree) h in
        let* new_tree = aux next t in
        let updated_tree =
          match tree with
          | Atom _ -> new_tree
          | Tensor tl ->
              Tensor
                (Base.List.mapi
                   ~f:(fun i t -> if i = h then new_tree else t)
                   tl)
          | Par tl ->
              Par
                (Base.List.mapi
                   ~f:(fun i t -> if i = h then new_tree else t)
                   tl)
          | Prime (g, tl) ->
              Prime
                ( g,
                  Base.List.mapi
                    ~f:(fun i t -> if i = h then new_tree else t)
                    tl )
        in
        Some updated_tree
  in
  aux tree path_part_from_head
