open Base
open Util

let ( = ) = Poly.( = )

type atom = { label : string; pol : bool } [@@deriving compare, sexp, hash]

type node = Atom of atom | Tensor of ISet.t | Par of ISet.t | Prime of IMap.t
[@@deriving compare, sexp, hash]

let getLabel node =
  match node with
  | Atom atom -> atom.label
  | Tensor _ -> "⊗"
  | Par _ -> "⅋"
  | Prime _ -> "prime"

module Node = struct
  module T = struct
    type t = node [@@deriving compare, sexp, hash]

    let show t = Stdio.printf "%s" (getLabel t)
  end

  include T
  include Comparable.Make (T)
end

let node_index elem l =
  let rec index_r elem l i =
    match l with
    | [] -> raise_s [%message "error" "Vertex not found when looking for index"]
    | h :: t -> if Node.equal h elem then i else index_r elem t (i + 1)
  in
  index_r elem l 0

module NSet = struct
  module T = struct
    type t = Base.Set.M(Node).t [@@deriving compare, sexp, hash]
  end

  include T
  include Comparable.Make (T)
end

module NMap = struct
  type t = NSet.t Base.Map.M(Node).t
end

type nodes = NSet.t
type edges = NMap.t
type graph = { nodes : nodes; edges : edges }

let empty_node_set () : nodes = Set.empty (module Node)
let empty_node_map () : edges = Map.empty (module Node)
let empty_graph () = { nodes = empty_node_set (); edges = empty_node_map () }
let singleton v : nodes = Set.singleton (module Node) v

let add_node node graph =
  { nodes = Set.add graph.nodes node; edges = graph.edges }

(** [graph_difference graph vertices]: subgraph of [graph] that contains all vertices not in
    [vertices] *)
let graph_difference graph (nodes : nodes) =
  let nodes = Set.diff graph.nodes nodes in
  let edges = complement_map nodes graph.edges in
  { nodes; edges }

let find_or_empty map v =
  match Map.find map v with None -> empty_node_set () | Some vset -> vset

(** [successors graph vertices]: set of vertices to which [vertices] is
    connected *)
let successors graph (nodes : nodes) : nodes =
  Set.fold nodes ~init:(empty_node_set ()) ~f:(fun accum v ->
      let to_add =
        match Map.find graph.edges v with
        | None -> empty_node_set ()
        | Some vset -> vset
      in
      Set.union accum to_add)
  |> Fn.flip Set.diff nodes

(** [connect_vertices vertices vertex graph]: for a given [graph],
    add edges connecting every element of [vertices] to [vertex] *)
let connect_vertices_to_vertex (nodes : nodes) vertex graph =
  let () = assert (Set.mem graph.nodes vertex) in
  let () = assert (Set.for_all nodes ~f:(Set.mem graph.nodes)) in
  let edges =
    Set.fold nodes ~init:graph.edges ~f:(fun accum v ->
        Map.update accum v ~f:(function
          | None -> singleton vertex
          | Some vset -> Set.add vset vertex))
  in
  let edges =
    Map.update edges vertex ~f:(function
      | None -> nodes
      | Some vset -> Set.union vset nodes)
  in
  { nodes = graph.nodes; edges }

let connect_vertices v1 v2 g =
  let rec aux rem acc =
    match Set.find rem ~f:(fun _ -> true) with
    | None -> acc
    | Some v -> aux (Set.remove rem v) (connect_vertices_to_vertex v2 v acc)
  in
  aux v1 g

(** [induced_subgraph graph vertices]: subgraph of [graph] that contains only
    the vertices in [vertices]  *)
let induced_subgraph graph (nodes : nodes) =
  let edges = intersect_map nodes graph.edges in
  { nodes; edges }

(** [remove_vertex_edges]: given a mapping [edges], remove [vertex] from
  its keys and values  *)
let remove_node_edges (edges : edges) vertex : edges =
  Map.remove edges vertex |> Map.map ~f:(Fn.flip Set.remove vertex)

let remove_nodes_edges (nodes : nodes) edges =
  Set.fold nodes ~init:edges ~f:remove_node_edges

(** [edge_tuple_list edges]: given a mapping [edges],
    return a corresponding list of edges  *)
let rec edge_tuple_list (edge_map : edges) =
  if Map.is_empty edge_map then []
  else
    let vi, vi_neighbours = Map.min_elt_exn edge_map in
    let new_edges =
      Set.fold vi_neighbours ~init:[] ~f:(fun accum vj -> (vi, vj) :: accum)
    in
    let new_edge_map = remove_node_edges edge_map vi in
    new_edges @ edge_tuple_list new_edge_map

let add_or_init y (v : nodes option) : nodes option =
  match v with None -> Some (singleton y) | Some z -> Some (Set.add z y)

(** [edge_map ~reverse edge_tuple_list]: given a list of edges [edge_tuple_list],
    return a corresponding mapping, if [reverse] then the mapping is from targets to sources *)
let edge_maps edge_list : edges =
  let rec edge_list_to_map edges reverse map =
    match edges with
    | [] -> map
    | (x, y) :: t ->
        let new_map =
          if reverse then Map.change map y ~f:(add_or_init x)
          else Map.change map x ~f:(add_or_init y)
        in
        edge_list_to_map t reverse new_map
  in
  let mapping = edge_list_to_map edge_list false (empty_node_map ()) in
  let mappingRev = edge_list_to_map edge_list true (empty_node_map ()) in
  Map.merge_skewed mapping mappingRev ~combine:(fun ~key:_ v1 v2 ->
      Set.union v1 v2)

let to_graph node_list edge_list =
  let nodes =
    List.fold node_list ~init:(empty_node_set ()) ~f:(fun acum v ->
        Set.add acum v)
  in
  let edges = edge_maps edge_list in
  { nodes; edges }

let is_dual_atom (a : atom) (b : atom) = a.pol = not b.pol && a.label = b.label
let is_empty graph = Set.is_empty graph.nodes && Map.is_empty graph.edges
