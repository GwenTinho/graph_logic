val serialize_id_graph :
  Idgraph.id_graph ->
  [> `Assoc of
     (string
     * [> `Int of int
       | `List of [> `Assoc of (string * [> `Int of int ]) list ] list ])
     list ]

val serialize_ltree : LogicalTree.ltree -> Yojson.Basic.t
val parse_idg : Yojson.Basic.t -> Idgraph.id_graph
val read_file_as_id_graph : string -> Idgraph.id_graph
val read_file_as_id_graphs : string -> Idgraph.id_graph list
val read_file_as_tree : string -> LogicalTree.ltree
val read_file_as_trees : string -> LogicalTree.ltree list
val parse_fingerprint : Yojson.Basic.t -> Fingerprint.proof
val read_file_as_fingerprints : string -> Fingerprint.proof list
val write_tree : LogicalTree.ltree -> string -> unit
val write_id_graph : Idgraph.id_graph -> string -> unit
val parse_tree : Yojson.Basic.t -> LogicalTree.ltree
val serialize_rule : Fingerprint.rule_id -> Yojson.Basic.t
val serialize_fingerprint : Fingerprint.proof -> Yojson.Basic.t
