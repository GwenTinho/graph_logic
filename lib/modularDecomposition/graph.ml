open Base

type atom = {
    label : string;
    pol : bool;
  }
  [@@deriving compare, sexp, hash]

module ISet = struct
  type t = Base.Set.M(Int).t [@@deriving compare, sexp, hash]
end
include Comparable.Make(ISet)

module IMap = struct
  type t = ISet.t Base.Map.M(Int).t [@@deriving compare, sexp, hash]
end
include Comparable.Make(IMap)

type node =
  | Atom of atom
  | Tensor of ISet.t
  | Par of ISet.t
  | Before of int list
  | Prime of IMap.t
  [@@deriving compare, sexp, hash]

type vertex = {
    connective : node;
    id : int;
  }
  [@@deriving compare, sexp, hash]

let getLabel vertex = 
  match vertex.connective with
  | Atom atom -> atom.label
  | Tensor _ -> "⊗"
  | Par _ -> "⅋"
  | Before _ -> "◃"
  | Prime _ -> "prime"

module Vertex = struct
  module T = struct
    type t = vertex [@@deriving compare, sexp, hash]
    let show t = Stdio.printf "%s %d" (getLabel t) t.id
  end
  include T
  include Comparable.Make(T)
end

let vertex_index elem l =
  let rec index_r elem l i =
    match l with
    | [] -> raise_s [%message "error" "Vertex not found when looking for index"]
    | h :: t ->
      if Vertex.equal h elem then i else index_r elem t (i+1)
  in
  index_r elem l 0

module VSet = struct
  module T = struct
    type t = Base.Set.M(Vertex).t [@@deriving compare, sexp, hash]
  end
  include T
  include Comparable.Make(T)
end

module VMap = struct
  type t = VSet.t Base.Map.M(Vertex).t
end

type graph = {
    nodes : VSet.t;
    edges : VMap.t;
    edges_from : VMap.t;
  }

let show graph =
  let () = Stdio.printf "Nodes: "; Set.iter graph.nodes ~f:(fun v -> Stdio.printf "%s " (getLabel v)); Stdio.printf "\n"; in
  Stdio.printf "Edges: \n"; Map.iteri graph.edges ~f:(fun ~key:k ~data:d -> 
    Stdio.printf "\t%s: " (getLabel k);
    Set.iter d ~f:(fun v -> Stdio.printf "%s, " (getLabel v));
    Stdio.printf "\n")

type state = {
  mutable total_vertices : int;
  id_map : (int, Vertex.t) Hashtbl.t;
}

let fresh_id state = 
  state.total_vertices <- state.total_vertices + 1;
  state.total_vertices

let add_vertices_to_hash vertices state =
  Set.iter vertices
  ~f:(fun v -> Hashtbl.add_exn state.id_map ~key:v.id ~data:v)

(** [add_vertex vertex graph]: remove [vertex] from [graph] in both the nodes 
    and edges *)
let add_vertex vertex graph =
    {nodes = Set.add graph.nodes vertex; edges = graph.edges; edges_from = graph.edges_from}

(** [remove_vertex vertex edges]: given a mapping [edges], remove [vertex] from 
    its keys and values  *)
let remove_vertex_edges v edges =
  Map.remove edges v |> Map.map ~f:(Util.flip Set.remove v)

let remove_vertices_edges vertices edges = 
  Set.fold vertices ~init:edges ~f:(fun accum v -> remove_vertex_edges v accum)

let remove_vertex v graph =
  let new_nodes = Set.remove graph.nodes v in
  let new_edges = remove_vertex_edges v graph.edges in 
  let new_edges_from = remove_vertex_edges v graph.edges_from in
  {nodes = new_nodes; edges = new_edges; edges_from = new_edges_from}

let disjoint s1 s2 =
  let diff = Set.diff s1 s2 in (* O(l1 + l2) *)
  Set.equal s1 diff (* O(l1 + l2) *)

let complement_map set map =
  Map.filter_keys map ~f:(fun ele -> Set.mem set ele |> not)
  |> Map.map ~f:(Util.flip Set.diff set)

(** [<~> graph vertices]: subgraph of [graph] that contains all vertices not in 
    [vertices] *)
let (<~>) graph vertices =
  let nodes = Set.diff graph.nodes vertices in
  let edges = complement_map vertices graph.edges in
  let edges_from = complement_map vertices graph.edges_from in
  {nodes = nodes; edges = edges; edges_from = edges_from}

let find_or_empty map v =
  match Base.Map.find map v with 
  | None -> Base.Set.empty (module Vertex)
  | Some vset -> vset

(** [successors graph vertices]: set of vertices to which [vertices] is 
    connected *)
let successors graph vertices =
    Set.fold vertices
      ~init:(Set.empty (module Vertex))
      ~f:(fun accum v -> 
        let to_add = 
          match Map.find graph.edges v with
          | None -> Set.empty (module Vertex)
          | Some vset -> vset
        in
        Set.union accum to_add)
    |> Util.flip Set.diff vertices

let predecessors graph vertices = 
    Set.fold vertices
      ~init:(Set.empty (module Vertex))
      ~f:(fun accum v -> 
        let to_add = 
          match Map.find graph.edges_from v with
          | None -> Set.empty (module Vertex)
          | Some vset -> vset
        in
        Set.union accum to_add)
    |> Util.flip Set.diff vertices

let connected graph vertices =
  Set.union (successors graph vertices) (predecessors graph vertices)

let neighbour graph vertex =
  let edges_to = match Map.find graph.edges vertex with
    | None -> Set.empty (module Vertex)
    | Some set -> set
  in
  let edges_from = match Map.find graph.edges_from vertex with
    | None -> Set.empty (module Vertex)
    | Some set -> set
  in
  Set.union edges_to edges_from

let neighbours graph vertices =
  Set.union (successors graph vertices) (predecessors graph vertices)

(** [replace graph vertices vertex]: replace all vertices in [vertices] by 
    [vertex] in [graph] *)
let replace graph h vertex state =
  let () = assert(Set.is_subset h ~of_:graph.nodes) in
  let () = add_vertices_to_hash h state in
  (* let () = Stdio.printf "Replacing { "; Set.iter h ~f:(fun v -> Vertex.show v; Stdio.printf ", "); Stdio.printf "} with:\n";
    Vertex.show vertex; Stdio.printf "\n"
  in *)
  let new_nodes = Set.diff graph.nodes h |> Util.flip Set.add vertex in
  let removed_edges = remove_vertices_edges h graph.edges in
  let removed_edges_from = remove_vertices_edges h graph.edges_from in

  let new_successors = successors graph h |> Util.flip Set.diff h in
  let new_predecessors = predecessors graph h |> Util.flip Set.diff h in
  let new_edges = Map.update removed_edges vertex ~f:(function 
    | None -> new_successors
    | Some vset -> Set.union vset new_successors)
  in
  let new_edges = Set.fold new_predecessors ~init:new_edges ~f:(fun accum v ->
    Map.update accum v ~f:(function
      | None -> Set.singleton (module Vertex) vertex
      | Some vset -> Set.add vset vertex))
  in
  let new_edges_from = Map.update removed_edges_from vertex ~f:(function
    | None -> new_predecessors
    | Some vset -> Set.union vset new_predecessors)
  in
  let new_edges_from = Set.fold new_successors ~init:new_edges_from ~f:(fun accum v ->
    Map.update accum v ~f:(function
      | None -> Set.singleton (module Vertex) vertex
      | Some vset -> Set.add vset vertex))
  in 
  {nodes = new_nodes; edges = new_edges; edges_from = new_edges_from}

(** [connect_vertices vertices vertex graph]: for a given [graph],
    add edges connecting every element of [vertices] to [vertex] *)
let connect_vertices ?directed vertices vertex graph =
  let () = assert(Set.mem graph.nodes vertex) in
  let () = assert(Set.for_all vertices ~f:(Set.mem graph.nodes)) in
  let edges = Set.fold vertices ~init:graph.edges ~f:(fun accum v ->
    Map.update accum v ~f:(function
    | None -> Set.singleton (module Vertex) vertex
    | Some vset -> Set.add vset vertex))
  in
  if Util.resolve directed then
    let edges_from = Map.update graph.edges_from vertex ~f:(function | None -> vertices | Some vset -> Set.union vset vertices) in
    {nodes=graph.nodes; edges=edges; edges_from=edges_from}
  else
    let edges = Map.update edges vertex ~f:(function | None -> vertices | Some vset -> (Set.union vset vertices)) in
    {nodes=graph.nodes; edges=edges; edges_from=edges}
        
let intersect_map set map =
  Map.filter_keys map ~f:(Set.mem set)
  |> Map.map ~f:(Util.flip Set.inter set)

(** [induced_subgraph graph vertices]: subgraph of [graph] that contains only 
    the vertices in [vertices]  *)
let induced_subgraph graph vertices =
  let edges = intersect_map vertices graph.edges in
  let edges_from = intersect_map vertices graph.edges_from in
  {nodes = vertices; edges = edges; edges_from = edges_from}

(** [w G H h]: set of vertices of [G <~> H] to which [h] is connected *)
let w g h v =
  let new_h = Set.remove h v in
  match Map.find (g <~> new_h).edges v with
  | None -> Set.empty (module Vertex)
  | Some vset -> vset
  
(** [is_module G H]: checks if [H] is a module of [G] *)  
let is_module g h =
  let connected = 
    match Set.choose h with
    | None -> Set.empty (module Vertex)
    | Some v -> 
    w g h v
  in
  Set.for_all h 
    ~f:(fun v -> 
      let v_connected = w g h v in
      Set.equal connected v_connected)

(** [edge_tuple_list ?directed edges]: given a mapping [edges],
    return a corresponding list of edges  *)
let rec edge_tuple_list ?directed edge_map =
  if Map.is_empty edge_map then
    []
  else
    let vi, vi_neighbours = Map.min_elt_exn edge_map in
    let new_edges = Set.fold vi_neighbours
      ~init:[]
      ~f:(fun accum vj -> (vi, vj) :: accum) 
    in
    let new_edge_map = if Util.resolve directed then 
        Map.remove edge_map vi
      else 
        remove_vertex_edges vi edge_map
    in
    new_edges @ edge_tuple_list ?directed:directed new_edge_map

let add_or_init v y = 
  match v with
  | None -> Some (Set.singleton (module Vertex) y)
  | Some z -> Some (Set.add z y)

(** [edge_map ~reverse edge_tuple_list]: given a list of edges [edge_tuple_list], 
    return a corresponding mapping, if [reverse] then the mapping is from targets to sources *)
let edge_map ~reverse edge_tuple_list =
  let rec edge_list_to_map edges map = 
    match edges with
    | [] -> map
    | (x, y) :: t -> 
      let new_map =
        if reverse then
          Map.change map y ~f:(fun v -> add_or_init v x)
        else
          Map.change map x ~f:(fun v -> add_or_init v y) 
      in
      edge_list_to_map t new_map
  in
  edge_list_to_map edge_tuple_list (Map.empty (module Vertex))

let edge_maps ?directed edge_list =
  let edges = 
    if Util.resolve directed then
      edge_map ~reverse:false edge_list
    else
      Map.merge_skewed (edge_map ~reverse:false edge_list) (edge_map ~reverse:true edge_list)
        ~combine:(fun ~key:_ v1 v2 -> Set.union v1 v2)
  in
  let edges_from = 
    if Util.resolve directed then edge_map ~reverse:true edge_list else edges
  in
  edges, edges_from

let to_graph ?directed vertex_list edge_list = 
  let vertices, max_id = List.fold vertex_list
    ~init:(Set.empty (module Vertex), 0)
    ~f:(fun (acum, max) v ->
      (Set.add acum v), (Int.max max v.id))
  in
  let edges, edges_from = edge_maps ?directed:directed edge_list in
  {nodes=vertices; edges=edges; edges_from=edges_from}, {total_vertices=max_id; id_map=Hashtbl.create (module Int)}

let vset_to_iset vset =
  Set.map (module Int) vset ~f:(fun v -> v.id)

let iset_to_vset map iset =
  Set.map (module Vertex) iset ~f:(fun i -> Map.find_exn map i)

let vmap_to_imap map nodes =
  let empty_map = Set.fold nodes ~init:(Map.empty (module Int))
    ~f:(fun accum vertex ->
      Map.add_exn accum ~key:vertex.id ~data:(Set.empty (module Int)))
  in 
  Map.fold map
    ~init:empty_map
    ~f:(fun ~key:k ~data:v accum ->
      let data = vset_to_iset v in
      Map.update accum k.id ~f:(function
        | None -> data
        | Some iset -> Set.union iset data))

(** [id_map vset]: returns a map from the [id]s of the elements of [vset] to 
    the elements themselves *)
let id_map vset =
  Set.fold vset
    ~init:(Map.empty (module Int)) 
    ~f:(fun accum vertex -> 
      Map.add_exn accum ~key:vertex.id ~data:vertex)

(** [vertex_neighbour_pairs vertices edge_map]: return an assoc list from every 
    vertex to one of its neighbours *)
let vertex_neighbour_pairs v edge_map =
  List.map v 
    ~f:(fun vi ->
      let vi_neighbours = Map.find_exn edge_map vi in
      let vj = Set.choose vi_neighbours in
      match vj with
      | None -> Set.singleton (module Vertex) vi
      | Some vj -> Set.of_list (module Vertex) [vi; vj])
