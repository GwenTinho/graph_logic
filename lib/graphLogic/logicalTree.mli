type ltree =
  | Atom of Quartic.Graph.atom
  | Tensor of ltree list
  | Par of ltree list
  | Prime of Idgraph.id_graph * ltree list

val ltree_of_mdtree : Quartic.Tree.tree -> ltree
val mdtree_of_ltree : ltree -> Quartic.Tree.tree
val count_nodes : ltree -> int
val count_children : ltree -> int
val ltree_of_graph : Quartic.Graph.graph -> ltree option
val remove_empty : ltree -> ltree option
val simplify : ltree -> ltree option
val empty_tree : unit -> ltree
val hash_tree : ltree -> int
val successors : ltree -> ltree list
val traverse_by_path : ltree -> int list -> ltree option
val map_at_path : ltree -> int list -> f:(ltree -> ltree option) -> ltree option
val mapi_successors : ltree -> f:(int -> ltree -> ltree) -> ltree
val regenerate : ltree -> ltree option
