val serialize_tree : Tree.tree -> Yojson.Basic.t
val serialize_graph : Graph.graph -> Yojson.Basic.t
val read_file_as_graph : string -> Graph.graph
val read_file_as_graphs : string -> Graph.graph list
val read_file_as_id_graph : string -> Id_graph.id_graph
val read_file_as_id_graphs : string -> Id_graph.id_graph list
val read_file_as_tree : string -> Tree.tree
val read_file_as_trees : string -> Tree.tree list
val read_file_as_fingerprints : string -> Fingerprint.proof list
(*Id_graphs are autoreindexed to be 1-indexed*)

val write_graph : Graph.graph -> string -> unit
val write_tree : Tree.tree -> string -> unit
val write_id_graph : Id_graph.id_graph -> string -> unit
