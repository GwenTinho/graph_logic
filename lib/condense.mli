type subset =
  | Singleton of Graph.node
  | Clique of Graph.nodes
  | IndSet of Graph.nodes

val compare_subset : subset -> subset -> int
val subset_of_sexp : Sexplib0.Sexp.t -> subset
val sexp_of_subset : subset -> Sexplib0.Sexp.t
val subset_contains : Graph.node -> subset -> bool
val smallest_condensible : Graph.graph -> Graph.nodes -> Graph.nodes option
val subset_add : Graph.node -> subset -> subset
val isPrime : Graph.graph -> bool
val tree_from_graph : Graph.graph -> Tree.tree option
