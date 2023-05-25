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
  | Tree.Tensor ts -> Tensor (List.map ltree_of_mdtree ts)
  | Tree.Par ts -> Par (List.map ltree_of_mdtree ts)
  | Tree.Prime (g, ts) -> Prime (idg_of_tidg g, List.map ltree_of_mdtree ts)
  | _ -> failwith "ltree_of_mdtree: not implemented"

let mdtree_of_ltree (ltree : ltree) =
  let id = ref 0 in
  let rec aux ltree =
    id := !id + 1;
    match ltree with
    | Atom a -> { Tree.connective = Tree.Atom a; Tree.id = !id }
    | Tensor ts ->
        (*We want unique ids*)
        { Tree.connective = Tree.Tensor (List.map aux ts); Tree.id = !id }
    | Par ts -> { Tree.connective = Tree.Par (List.map aux ts); Tree.id = !id }
    | Prime (g, ts) ->
        {
          Tree.connective = Tree.Prime (tidg_of_idg g, List.map aux ts);
          Tree.id = !id;
        }
  in
  aux ltree

let rec count_nodes tree =
  match tree with
  | Atom _ -> 1
  | Tensor tl -> Base.List.fold tl ~init:0 ~f:(fun acc t -> acc + count_nodes t)
  | Par tl -> Base.List.fold tl ~init:0 ~f:(fun acc t -> acc + count_nodes t)
  | Prime (_, tl) ->
      Base.List.fold tl ~init:0 ~f:(fun acc t -> acc + count_nodes t)

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

let simplify ltree =
  let mdtree = mdtree_of_ltree ltree in
  let graph = Tree.tree_to_graph mdtree in
  ltree_of_graph graph

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
