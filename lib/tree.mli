type tree =
  | Atom of Graph.atom
  | Tensor of tree list
  | Par of tree list
  | Prime of Id_graph.id_graph * tree list

val successors : tree -> tree list
val tree_to_graph : tree -> Graph.graph
val empty_tree : unit -> tree
val count_nodes : tree -> int
val count_children : tree -> int
