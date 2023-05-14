open Quartic
open Idgraph


type ltree =
  | Atom of Graph.atom
  | Tensor of ltree list
  | Par of ltree list
  | Prime of  id_graph * ltree list

let rec ltree_of_mdtree (mdtree: Tree.tree) = match mdtree.connective with
  | Tree.Atom a -> Atom a
  | Tree.Tensor ts -> Tensor (List.map ltree_of_mdtree ts)
  | Tree.Par ts -> Par (List.map ltree_of_mdtree ts)
  | Tree.Prime (g, ts) -> Prime (idg_of_tidg g, List.map ltree_of_mdtree ts)
  | _ -> failwith "ltree_of_mdtree: not implemented"

let mdtree_of_ltree (ltree: ltree) =
  let id = ref 0 in
  let rec aux ltree  =
    id := !id + 1;
    match ltree with
    | Atom a ->
      { Tree.connective = Tree.Atom a;
        Tree.id = !id }
    | Tensor ts ->
      (*We want unique ids*)
    { Tree.connective = Tree.Tensor (List.map aux ts);
        Tree.id = !id }
    | Par ts -> { Tree.connective = Tree.Par (List.map aux ts);
        Tree.id = !id }
    | Prime (g, ts) -> { Tree.connective = Tree.Prime (tidg_of_idg g,(List.map aux ts));
        Tree.id = !id } in
  aux ltree

let rec count_nodes tree =
  match tree with
  | Atom _ -> 1
  | Tensor tl -> Base.List.fold tl ~init:0 ~f:(fun acc t -> acc + count_nodes t)
  | Par tl -> Base.List.fold tl ~init:0 ~f:(fun acc t -> acc + count_nodes t)
  | Prime (_, tl) -> Base.List.fold tl ~init:0 ~f:(fun acc t -> acc + count_nodes t)

let count_children tree =
  match tree with
  | Atom _ -> 0
  | Tensor tl -> List.length tl
  | Par tl -> List.length tl
  | Prime (_, tl) -> List.length tl

let simplify ltree =
  let mdtree = mdtree_of_ltree ltree in
  let graph = Quartic.Tree.tree_to_graph mdtree in
  let max_id = Base.Set.fold graph.nodes ~init:0 ~f:(fun acc n -> max acc n.id) in
  let state =  {Quartic.Graph.total_vertices=max_id; id_map=Base.Hashtbl.create (module Base.Int)}
  in
  let condensed = Quartic.Condense.process graph state in
  let simplifiedmd = Quartic.Tree.tree_from_condensed condensed state in
  match simplifiedmd with
  | None -> None
  | Some simplified -> Some (ltree_of_mdtree simplified )

let empty_tree () = Par []
let hash_tree (tree : ltree) = Hashtbl.hash tree

let successors tree =
  match tree with
  | Atom _ -> []
  | Tensor tl -> tl
  | Par tl -> tl
  | Prime (_, tl) -> tl
