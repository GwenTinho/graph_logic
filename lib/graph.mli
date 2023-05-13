val ( = ) : 'a -> 'a -> bool

type atom = { label : string; pol : bool }

val compare_atom : atom -> atom -> int
val atom_of_sexp : Sexplib0.Sexp.t -> atom
val sexp_of_atom : atom -> Sexplib0.Sexp.t

val hash_fold_atom :
  Base_internalhash_types.state -> atom -> Base_internalhash_types.state

val hash_atom : atom -> int

type node =
  | Atom of atom
  | Tensor of Util.ISet.t
  | Par of Util.ISet.t
  | Prime of Util.IMap.t

val compare_node : node -> node -> int
val node_of_sexp : Sexplib0.Sexp.t -> node
val sexp_of_node : node -> Sexplib0.Sexp.t

val hash_fold_node :
  Base_internalhash_types.state -> node -> Base_internalhash_types.state

val hash_node : node -> int
val getLabel : node -> string

module Node : sig
  module T : sig
    type t = node

    val compare : t -> t -> int
    val t_of_sexp : Sexplib0.Sexp.t -> t
    val sexp_of_t : t -> Sexplib0.Sexp.t

    val hash_fold_t :
      Base_internalhash_types.state -> t -> Base_internalhash_types.state

    val hash : t -> int
    val show : t -> unit
  end

  type t = node

  val t_of_sexp : Sexplib0.Sexp.t -> t
  val sexp_of_t : t -> Sexplib0.Sexp.t

  val hash_fold_t :
    Base_internalhash_types.state -> t -> Base_internalhash_types.state

  val hash : t -> int
  val show : t -> unit
  val ( >= ) : t -> t -> bool
  val ( <= ) : t -> t -> bool
  val ( = ) : t -> t -> bool
  val ( > ) : t -> t -> bool
  val ( < ) : t -> t -> bool
  val ( <> ) : t -> t -> bool
  val equal : t -> t -> bool
  val compare : t -> t -> int
  val min : t -> t -> t
  val max : t -> t -> t
  val ascending : t -> t -> int
  val descending : t -> t -> int
  val between : t -> low:t -> high:t -> bool
  val clamp_exn : t -> min:t -> max:t -> t
  val clamp : t -> min:t -> max:t -> t Base.Or_error.t

  type comparator_witness = Base.Comparable.Make(T).comparator_witness

  val comparator : (t, comparator_witness) Base.Comparator.t
end

val node_index : node -> node list -> int

module NSet : sig
  module T : sig
    type t = Base.Set.M(Node).t

    val compare : t -> t -> int
    val t_of_sexp : Sexplib0.Sexp.t -> t
    val sexp_of_t : t -> Sexplib0.Sexp.t

    val hash_fold_t :
      Base_internalhash_types.state -> t -> Base_internalhash_types.state

    val hash : t -> int
  end

  type t = Base.Set.M(Node).t

  val t_of_sexp : Sexplib0.Sexp.t -> t
  val sexp_of_t : t -> Sexplib0.Sexp.t

  val hash_fold_t :
    Base_internalhash_types.state -> t -> Base_internalhash_types.state

  val hash : t -> int
  val ( >= ) : t -> t -> bool
  val ( <= ) : t -> t -> bool
  val ( = ) : t -> t -> bool
  val ( > ) : t -> t -> bool
  val ( < ) : t -> t -> bool
  val ( <> ) : t -> t -> bool
  val equal : t -> t -> bool
  val compare : t -> t -> int
  val min : t -> t -> t
  val max : t -> t -> t
  val ascending : t -> t -> int
  val descending : t -> t -> int
  val between : t -> low:t -> high:t -> bool
  val clamp_exn : t -> min:t -> max:t -> t
  val clamp : t -> min:t -> max:t -> t Base.Or_error.t

  type comparator_witness = Base.Comparable.Make(T).comparator_witness

  val comparator : (t, comparator_witness) Base.Comparator.t
end

module NMap : sig
  type t = Base.Set.M(Node).t Base.Map.M(Node).t
end

type nodes = Base.Set.M(Node).t
type edges = NMap.t
type graph = { nodes : Base.Set.M(Node).t; edges : edges }

val empty_node_set : unit -> nodes
val empty_node_map : unit -> edges
val empty_graph : unit -> graph
val singleton : node -> nodes
val add_node : node -> graph -> graph
val graph_difference : graph -> nodes -> graph
val find_or_empty : ('a, nodes, 'b) Base.Map.t -> 'a -> nodes
val successors : graph -> nodes -> nodes
val connect_vertices_to_vertex : nodes -> node -> graph -> graph
val connect_vertices : (node, 'a) Base.Set.t -> nodes -> graph -> graph
val induced_subgraph : graph -> nodes -> graph
val remove_node_edges : edges -> node -> edges
val remove_nodes_edges : nodes -> edges -> edges
val edge_tuple_list : edges -> (node * node) list
val add_or_init : node -> nodes option -> nodes option
val edge_maps : (node * node) list -> edges
val to_graph : node list -> (node * node) list -> graph
val is_dual_atom : atom -> atom -> bool
val is_empty : graph -> bool
