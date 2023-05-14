val share_module : Graph.graph -> Graph.node -> Graph.node -> bool
val is_module : Graph.graph -> Graph.nodes -> bool

val keep_links : Graph.graph -> Graph.nodes -> Graph.node -> Graph.nodes
(** keep_links g h v, finds all the nodes connected to v in g - h*)
