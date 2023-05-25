type id_graph = { nodes : int list; edges : (int * int) list }

val idg_of_tidg : Quartic.Tree.id_graph -> id_graph
val tidg_of_idg : id_graph -> Quartic.Tree.id_graph
val length : id_graph -> int
val length_edges : id_graph -> int

val find_sub_iso :
  id_graph ->
  id_graph ->
  (int, int, Base.Int.comparator_witness) Base.Map.t option

val is_sub_iso : id_graph -> id_graph -> bool
val is_iso : id_graph -> id_graph -> bool

val find_iso :
  id_graph ->
  id_graph ->
  (int, int, Base.Int.comparator_witness) Base.Map.t option

val completetion_graph : id_graph -> id_graph
val edge_diff : id_graph -> id_graph -> (int * int) list
val id_graph_complement : id_graph -> id_graph
val is_dual : id_graph -> id_graph -> bool