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
val simplify : ltree -> ltree option
val empty_tree : unit -> ltree
val hash_tree : ltree -> int
val successors : ltree -> ltree list
