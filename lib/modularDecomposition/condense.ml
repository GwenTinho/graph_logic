open Graph
open Base

module VSetSet = struct
  type t = Base.Set.M(VSet).t
end

type subset =
  | Singleton of vertex
  | Clique of VSet.t
  | Before of vertex list 
  | IndSet of VSet.t
  [@@deriving compare, sexp]

module Subset = struct
  module T = struct
    type t = subset [@@deriving compare, sexp]
  end
  include T
  include Comparable.Make(T)
end

module Subsetset = struct
  type t = Set.M(Subset).t
end

(* Algorithm 2.2 *)
(** [smallest_condensible graph set]: returns the smallest condensible set 
    containing all vertices of [set] *)
let smallest_condensible graph vset =
  if Set.length vset < 2 then None else
  let rec add_to_set res to_add =
    if Set.is_empty to_add then res else
    let new_res = Set.union res to_add in
    let new_connected = connected graph new_res |> Util.flip Set.diff res in
    let new_to_add = Set.fold new_res 
      ~init:(Set.empty (module Vertex))
      ~f:(fun acum v ->
        let wgi = w graph new_res v in
        Set.union acum (Set.diff new_connected wgi))
    in
    add_to_set new_res new_to_add
  in
  Some (add_to_set (Set.empty (module Vertex)) vset)

(** [update_subset subset v1 succ(v1) v2 succ(v2)]: add [v2] to [subset]
    if it belongs to the same subset as [v1] *)
let update_subset subset vi vi_neighbours vj vj_neighbours =
  match subset with
  | Singleton vertex ->
    if VSet.equal vj_neighbours vi_neighbours then
      IndSet (Set.of_list (module Vertex) [vertex; vj])
    else
      if VSet.equal (Set.remove vj_neighbours vi) (Set.remove vi_neighbours vj) then
        if Set.mem vj_neighbours vi then
          if Set.mem vi_neighbours vj then Clique (Set.of_list (module Vertex) [vertex; vj])
          else Before [vj; vi]
        else
          Before [vi; vj]
      else
        subset
  | IndSet set -> 
    if VSet.equal vj_neighbours vi_neighbours then
      IndSet (Set.add set vj)
    else
      subset
  | Clique set ->
    if Set.equal (Set.add vj_neighbours vj) (Set.add vi_neighbours vi) then
      Clique (Set.add set vj)
    else
      subset
  | Before vlist ->
    match vlist with
    | [] -> raise_s [%message "error" "Found Empty Before"]
    | h :: _ ->
      if not (Set.mem vi_neighbours h) && Set.equal (Set.add vi_neighbours h) vj_neighbours then
        Before (vj :: vlist)
      else
        subset

(** [update_subsetset subsetset new_subset]: given a set of subsets [subsetset],
    update it by adding [new_subset] *)
let update_subsetset subsetset new_subset =
  match new_subset with
  | Singleton _ -> subsetset
  | _ -> Set.add subsetset new_subset

let subset_contains v subset =
  match subset with
  | Singleton vertex -> Vertex.equal vertex v
  | Clique vset -> Set.mem vset v
  | IndSet vset -> Set.mem vset v
  | Before vlist -> List.mem vlist v ~equal:(Vertex.equal)

let subset_add graph v subset =
  match subset with 
  | Singleton _ -> raise_s [%message "error" "Cannot add vertex to Singleton subset"]
  | Clique vset -> Clique (Set.add vset v)
  | IndSet vset -> IndSet (Set.add vset v)
  | Before vlist -> 
    let last = List.hd_exn vlist in 
    if Set.mem (find_or_empty graph.edges last) v then
      Before (v :: vlist)
    else
      Before (vlist@[v])

let share_module graph vi vj =
  let si = find_or_empty graph.edges vi |> Util.flip Set.remove vj in
  let sj = find_or_empty graph.edges vj |> Util.flip Set.remove vi in
  let pi = find_or_empty graph.edges_from vi |> Util.flip Set.remove vj in
  let pj = find_or_empty graph.edges_from vj |> Util.flip Set.remove vi in
  VSet.equal si sj && VSet.equal pi pj

(* Algorithm 3.5 *)
(** [cc_and_is graph]: returns the set of maximal condensible cliques and 
    independent set of [graph] *)
let cc_and_is g =
  let visited = ref (Set.empty (module Vertex)) in
  let res = ref (Set.empty (module Subset)) in
  let v = Set.elements g.nodes in
  List.iteri v ~f:(fun i vi ->
    let vi_successors = find_or_empty g.edges vi in
    let vi_predecessors = find_or_empty g.edges_from vi in
    List.iteri v ~f:(fun j vj ->
      if j <= i then () else
      if Set.mem !visited vj then () else
      if share_module g vi vj then
        let () = visited := Set.add !visited vj in
        if not (Set.mem !visited vi) then
          let () = visited := Set.add !visited vi in
          let subset = 
            if Set.mem vi_successors vj then
              if Set.mem vi_predecessors vj then
                Clique (Set.of_list (module Vertex) [vi; vj])
              else
                Before [vj; vi]
            else
              if Set.mem vi_predecessors vj then
                Before [vi; vj]
              else
                IndSet (Set.of_list (module Vertex) [vi; vj])
          in
          res := Set.add !res subset;
        else
          let subset = Set.find_exn !res ~f:(subset_contains vi) in 
          let new_subset = subset_add g vj subset in
          let () = res := Set.remove !res subset in
          res := Set.add !res new_subset
    )
  );
  !res

(** [subset_set_to_nodes subsetset]: given a set of subsets, convert each subset
    to a [node] and return them in a list *)
let subset_set_to_nodes subsetset =
  Set.fold subsetset
    ~init:[]
    ~f:(fun accum ss -> 
      match ss with
      | Singleton _ -> accum
      | Clique vset -> Tensor (vset_to_iset vset) :: accum
      | IndSet vset -> Par (vset_to_iset vset) :: accum
      | Before vlist -> Before (List.map vlist ~f:(fun v -> v.id)) :: accum)

(** [condense_subset subset graph]: given [subset], condense its vertices into a
    fresh vertex in [graph] *)
let condense_subset subset graph state =
  let h, node = 
    match subset with
    | Singleton _ -> raise_s [%message "error" "Cannot condense singleton"]
    | Clique set -> set, Tensor (vset_to_iset set)
    | IndSet set -> set, Par (vset_to_iset set)
    | Before vlist -> 
      Set.of_list (module Vertex) vlist, Before (List.map vlist ~f:(fun v -> v.id))
  in
  let new_vertex = 
    {
      connective = node;
      id = fresh_id state;
    }
  in
  replace graph h new_vertex state

(** [condense_prime node vertices graph]: given a prime [node] and it's 
    corresponding [vertices], condense vertices into a fresh vertex *)
let condense_prime node vertices graph state =
  let new_vertex =
    {
      connective = node;
      id = fresh_id state;
    }
  in 
  replace graph vertices new_vertex state

(* Algorithm 3.6 *)
(** [condensible_subgraphs graph]: returns the minimal condensible subgraphs of 
    [graph]*)
let condensible_subgraphs graph =
  let v = Set.elements graph.nodes in
  let edge_list = edge_tuple_list graph.edges in
  let v_to_edge_index = Hashtbl.create (module Vertex) in
  let () = List.iteri edge_list ~f:(fun i (v1, v2) ->
    Hashtbl.change v_to_edge_index v1
      ~f:(fun l ->
        match l with
        | None -> Some [i]
        | Some l -> Some (i :: l));
    Hashtbl.change v_to_edge_index v2
      ~f:(fun l ->
        match l with
        | None -> Some [i]
        | Some l -> Some (i :: l)))
  in
  let min_con_edges = List.map edge_list 
    ~f:(fun (v1, v2) -> smallest_condensible graph (Set.of_list (module Vertex) [v1; v2]))
  in
  let h = List.map v ~f:(fun v ->
    let defined_on_v = List.map 
      (match Hashtbl.find v_to_edge_index v with
        | None -> []
        | Some l -> l)
      ~f:(fun i -> List.nth_exn min_con_edges i)
    in
    let rec smallest_card l = match l with
      | [a] -> (match a with
        | None -> Set.empty (module Vertex) 
        | Some a -> a)
      | [] -> Set.empty (module Vertex)
      | h :: t -> 
        let min_card = smallest_card t in
        match h with 
        | None -> min_card
        | Some h ->
          if Set.length h < Set.length min_card then
            h
          else
            min_card
    in
    smallest_card defined_on_v)
  in 
  let considered = Set.of_list (module Vertex) v in
  let res = List.foldi v ~init:considered
    ~f:(fun i acum vi ->
      let hi = List.nth_exn h i in
      if not (Set.mem acum vi) then acum else
      Set.fold hi ~init:acum
        ~f:(fun acum2 vj ->
          let j = vertex_index vj v in
          if j = i then acum2 else
          let vj = List.nth_exn v j in
          if not (Set.mem acum2 vj) then acum2 else
          let hj = List.nth_exn h j in
          if (Set.length hj) >= (Set.length hi) then
            Set.remove acum2 vj
          else
            Set.remove acum2 vi))
  in
  Set.fold res ~init:(Set.empty (module VSet))
    ~f:(fun acum vi ->
      let i = vertex_index vi v in
      let set = List.nth_exn h i in
      if Set.is_empty set then acum else
      Set.add acum set)

(** [condense_set subsets graph]: given a set of disjoint subsets, condense them
    all in [graph] *)
let condense_set subsets graph state =
  Set.fold subsets
    ~init:graph
    ~f:(fun accum ss -> condense_subset ss accum state)

(** [condense_cliques graph]: condense all of the condensible maximal cliques 
    and independent sets in [graph] into fresh vertices *)
let rec condense_cliques graph state =
  let cliques_and_ind = cc_and_is graph in
  if Set.is_empty cliques_and_ind then
    graph
  else
    condense_cliques (condense_set cliques_and_ind graph state) state

let return graph state = 
    let () =
      match Set.choose graph.nodes with
      | None -> ()
      | Some root -> Hashtbl.add_exn state.id_map ~key:root.id ~data:root
    in
    graph

(* Algorithm 3.4 *)
let rec process graph state =
  if Set.length graph.nodes <= 1 then return graph state else
  let condensed_graph = condense_cliques graph state in
  if Set.length condensed_graph.nodes <= 1 then return condensed_graph state else
  let min_cond = condensible_subgraphs condensed_graph in
  if Set.is_empty min_cond then
    let node = Prime (vmap_to_imap condensed_graph.edges condensed_graph.nodes) in
    let res = condense_prime node condensed_graph.nodes condensed_graph state in
    return res state
  else
    let prime_list = 
      Set.fold min_cond
        ~init:[]
        ~f:(fun accum vset -> 
          let subgraph = induced_subgraph condensed_graph vset in
          let node = Prime (vmap_to_imap subgraph.edges subgraph.nodes) in
          (node, vset) :: accum)
    in
    let prime_condensed_graph =
      List.fold prime_list
        ~init:condensed_graph 
        ~f:(fun graph (node, h) -> condense_prime node h graph state)
    in
    process prime_condensed_graph state

let isPrime graph =
  let cliques_and_in = cc_and_is graph in 
  if Set.is_empty cliques_and_in then
    let min_cond = condensible_subgraphs graph in
    if Set.is_empty min_cond then
      true
    else
      if Set.length min_cond = 1 && Set.length (Set.choose_exn min_cond) = Set.length graph.nodes then
        true
      else
        false
  else
    false