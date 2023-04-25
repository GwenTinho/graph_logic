open Graph
open Base
open Graph_module

type subset = Singleton of vertex | Clique of VSet.t | IndSet of VSet.t
[@@deriving compare, sexp]

module Subset = struct
  module T = struct
    type t = subset [@@deriving compare, sexp]
  end

  include T
  include Comparable.Make (T)
end

type state = {
  mutable total_vertices : int;
  id_map : (int, Vertex.t) Hashtbl.t;
}

(* Algorithm 2.2 *)

(** [smallest_condensible graph set]: returns the smallest condensible set
    containing all vertices of [set] *)
let smallest_condensible graph (vset : verticies) : verticies option =
  if Set.length vset <= 1 then None
  else
    let rec add_to_set res to_add =
      if Set.is_empty to_add then res
      else
        let new_res = Set.union res to_add in
        let new_connected = successors graph new_res |> Fn.flip Set.diff res in
        let new_to_add =
          Set.fold new_res
            ~init:(Set.empty (module Vertex))
            ~f:(fun acum v ->
              let wgi = keep_links graph new_res v in
              Set.union acum (Set.diff new_connected wgi))
        in
        add_to_set new_res new_to_add
    in
    Some (add_to_set (Set.empty (module Vertex)) vset)

let state_of_graph graph =
  let max_id =
    let ids = List.map (Set.elements graph.nodes) ~f:(fun v -> v.id) in
    match List.max_elt ids ~compare:Int.compare with None -> 0 | Some n -> n
  in
  { total_vertices = max_id + 1; id_map = Hashtbl.create (module Int) }

let fresh_id state =
  state.total_vertices <- state.total_vertices + 1;
  state.total_vertices

let subset_contains v subset =
  match subset with
  | Singleton vertex -> Vertex.equal vertex v
  | Clique vset -> Set.mem vset v
  | IndSet vset -> Set.mem vset v

let subset_add v subset =
  match subset with
  | Singleton _ ->
      raise_s [%message "error" "Cannot add vertex to Singleton subset"]
  | Clique vset -> Clique (Set.add vset v)
  | IndSet vset -> IndSet (Set.add vset v)

let add_vertices_to_hash (vertices : verticies) state =
  Set.iter vertices ~f:(fun v -> Hashtbl.add_exn state.id_map ~key:v.id ~data:v)

let replace graph (h : verticies) vertex state =
  let () = assert (Set.is_subset h ~of_:graph.nodes) in
  let () = add_vertices_to_hash h state in
  let new_nodes = Set.diff graph.nodes h |> Fn.flip Set.add vertex in
  let removed_edges = remove_vertices_edges h graph.edges in
  let new_successors = successors graph h |> Fn.flip Set.diff h in
  let new_edges =
    Map.update removed_edges vertex ~f:(function
      | None -> new_successors
      | Some vset -> Set.union vset new_successors)
  in
  let new_edges =
    Set.fold new_successors ~init:new_edges ~f:(fun accum v ->
        Map.update accum v ~f:(function
          | None -> singleton vertex
          | Some vset -> Set.add vset vertex))
  in
  { nodes = new_nodes; edges = new_edges }

(* Algorithm 3.5 *)

(** [cc_and_is graph]: returns the set of maximal condensible cliques and
    independent set of [graph] *)
let cc_and_is g =
  let visited = ref (Set.empty (module Vertex)) in
  let res = ref (Set.empty (module Subset)) in
  let v = Set.elements g.nodes in
  List.iteri v ~f:(fun i vi ->
      let vi_successors = find_or_empty g.edges vi in
      List.iteri v ~f:(fun j vj ->
          if j <= i then ()
          else if Set.mem !visited vj then ()
          else if share_module g vi vj then
            let () = visited := Set.add !visited vj in
            if not (Set.mem !visited vi) then
              let () = visited := Set.add !visited vi in
              let subset =
                if Set.mem vi_successors vj then
                  Clique (Set.of_list (module Vertex) [ vi; vj ])
                else IndSet (Set.of_list (module Vertex) [ vi; vj ])
              in
              res := Set.add !res subset
            else
              let subset = Set.find_exn !res ~f:(subset_contains vi) in
              let new_subset = subset_add vj subset in
              let () = res := Set.remove !res subset in
              res := Set.add !res new_subset));
  !res

(** [condense_subset subset graph]: given [subset], condense its vertices into a
    fresh vertex in [graph] *)
let condense_subset subset graph state =
  let h, node =
    match subset with
    | Singleton _ -> raise_s [%message "error" "Cannot condense singleton"]
    | Clique set -> (set, Tensor (vset_to_iset set))
    | IndSet set -> (set, Par (vset_to_iset set))
  in
  let new_vertex = { connective = node; id = fresh_id state } in
  replace graph h new_vertex state

(** [condense_prime node vertices graph]: given a prime [node] and it's
    corresponding [vertices], condense vertices into a fresh vertex *)
let condense_prime node vertices graph state =
  let new_vertex = { connective = node; id = fresh_id state } in
  replace graph vertices new_vertex state

(* Algorithm 3.6 *)

(** [condensible_subgraphs graph]: returns the minimal condensible subgraphs of
    [graph]*)
let condensible_subgraphs graph =
  let v = Set.elements graph.nodes in
  let edge_list = edge_tuple_list graph.edges in
  let v_to_edge_index = Hashtbl.create (module Vertex) in
  let () =
    List.iteri edge_list ~f:(fun i (v1, v2) ->
        Hashtbl.change v_to_edge_index v1 ~f:(fun l ->
            match l with None -> Some [ i ] | Some l -> Some (i :: l));
        Hashtbl.change v_to_edge_index v2 ~f:(fun l ->
            match l with None -> Some [ i ] | Some l -> Some (i :: l)))
  in
  let min_con_edges =
    List.map edge_list ~f:(fun (v1, v2) ->
        smallest_condensible graph (Set.of_list (module Vertex) [ v1; v2 ]))
  in
  let h =
    List.map v ~f:(fun v ->
        let defined_on_v =
          List.map
            (match Hashtbl.find v_to_edge_index v with
            | None -> []
            | Some l -> l)
            ~f:(fun i -> List.nth_exn min_con_edges i)
        in
        let rec smallest_card l =
          match l with
          | [ a ] -> (
              match a with None -> Set.empty (module Vertex) | Some a -> a)
          | [] -> Set.empty (module Vertex)
          | h :: t -> (
              let min_card = smallest_card t in
              match h with
              | None -> min_card
              | Some h ->
                  if Set.length h < Set.length min_card then h else min_card)
        in
        smallest_card defined_on_v)
  in
  let considered = Set.of_list (module Vertex) v in
  let res =
    List.foldi v ~init:considered ~f:(fun i acum vi ->
        let hi = List.nth_exn h i in
        if not (Set.mem acum vi) then acum
        else
          Set.fold hi ~init:acum ~f:(fun acum2 vj ->
              let j = vertex_index vj v in
              if j = i then acum2
              else
                let vj = List.nth_exn v j in
                if not (Set.mem acum2 vj) then acum2
                else
                  let hj = List.nth_exn h j in
                  if Set.length hj >= Set.length hi then Set.remove acum2 vj
                  else Set.remove acum2 vi))
  in
  Set.fold res
    ~init:(Set.empty (module VSet))
    ~f:(fun acum vi ->
      let i = vertex_index vi v in
      let set = List.nth_exn h i in
      if Set.is_empty set then acum else Set.add acum set)

(** [condense_set subsets graph]: given a set of disjoint subsets, condense them
    all in [graph] *)
let condense_set subsets graph state =
  Set.fold subsets ~init:graph ~f:(fun accum ss ->
      condense_subset ss accum state)

(** [condense_cliques graph]: condense all of the condensible maximal cliques
    and independent sets in [graph] into fresh vertices *)
let rec condense_cliques graph state =
  let cliques_and_ind = cc_and_is graph in
  if Set.is_empty cliques_and_ind then graph
  else condense_cliques (condense_set cliques_and_ind graph state) state

let return graph state =
  let () =
    match Set.choose graph.nodes with
    | None -> ()
    | Some root -> Hashtbl.add_exn state.id_map ~key:root.id ~data:root
  in
  graph

(* Algorithm 3.4 *)
let process_state graph =
  let rec process_r graph state =
    if Set.length graph.nodes <= 1 then return graph state
    else
      let condensed_graph = condense_cliques graph state in
      if Set.length condensed_graph.nodes <= 1 then return condensed_graph state
      else
        let min_cond = condensible_subgraphs condensed_graph in
        if Set.is_empty min_cond then
          let node =
            Prime (vmap_to_imap condensed_graph.edges condensed_graph.nodes)
          in
          let res =
            condense_prime node condensed_graph.nodes condensed_graph state
          in
          return res state
        else
          let prime_list =
            Set.fold min_cond ~init:[] ~f:(fun accum vset ->
                let subgraph = induced_subgraph condensed_graph vset in
                let node = Prime (vmap_to_imap subgraph.edges subgraph.nodes) in
                (node, vset) :: accum)
          in
          let prime_condensed_graph =
            List.fold prime_list ~init:condensed_graph
              ~f:(fun graph (node, h) -> condense_prime node h graph state)
          in
          process_r prime_condensed_graph state
  in
  let state = state_of_graph graph in
  let processed = process_r graph state in
  (processed, state)

let process g = fst (process_state g)

let isPrime graph =
  let cliques_and_in = cc_and_is graph in
  if Set.is_empty cliques_and_in then
    let min_cond = condensible_subgraphs graph in
    if Set.is_empty min_cond then true
    else
      Set.length min_cond = 1
      && Set.length (Set.choose_exn min_cond) = Set.length graph.nodes
  else false

let from_map (map : Util.IMap.t) : Id_graph.id_graph =
  let nodes = Map.keys map in
  let edges =
    let rec id_tuples_from_map (map : Util.IMap.t) =
      if Map.is_empty map then []
      else
        let id, id_neighbours = Map.min_elt_exn map in
        let new_imap = Util.remove_id id map in
        let new_edges =
          Set.fold id_neighbours ~init:[] ~f:(fun accum id2 ->
              (id, id2) :: accum)
        in
        new_edges @ id_tuples_from_map new_imap
    in
    id_tuples_from_map map
  in
  { nodes; edges }

let print_state state =
  let () =
    Caml.print_string ("\nMax_id: " ^ Int.to_string state.total_vertices ^ "\n")
  in
  let () =
    Hashtbl.iter_keys state.id_map ~f:(fun id ->
        Caml.print_string
          ("\n" ^ Int.to_string id ^ ": "
          ^ getLabel (Hashtbl.find_exn state.id_map id)))
  in
  Caml.print_newline ()

let tree_from_condensed (graph, state) =
  let () = assert (Set.length graph.nodes <= 1) in
  match Set.choose graph.nodes with
  | None -> None
  | Some root ->
      let rec tree_from_id state id : Tree.tree =
        let () =
          Caml.print_string ("\nId to convert: " ^ Int.to_string id ^ "\n")
        in
        let () = print_state state in
        let vertex = Hashtbl.find_exn state.id_map id in
        match vertex.connective with
        | Atom atom ->
            let () = Caml.print_string "\natom\n" in
            { connective = Atom atom; id = vertex.id }
        | Tensor iset ->
            let () = Caml.print_string "\ntensor\n" in
            let tree_list = trees_from_id_list (Set.to_list iset) state in
            let tensor_lists, tree_list =
              List.partition_map tree_list ~f:(fun (t : Tree.tree) ->
                  match t.connective with
                  | Tensor tl -> First tl
                  | _ -> Second t)
            in
            let successors = List.concat (tree_list :: tensor_lists) in
            { connective = Tensor successors; id = vertex.id }
        | Par iset ->
            let () = Caml.print_string "\npar\n" in
            let tree_list = trees_from_id_list (Set.to_list iset) state in
            let par_lists, tree_list =
              List.partition_map tree_list ~f:(fun t ->
                  match t.connective with Par tl -> First tl | _ -> Second t)
            in
            let successors = List.concat (tree_list :: par_lists) in
            { connective = Par successors; id = vertex.id }
        | Prime map ->
            let () = Caml.print_string "\nprime\n" in
            let id_graph = from_map map in
            let tree_list = trees_from_id_list id_graph.nodes state in
            { connective = Prime (id_graph, tree_list); id = vertex.id }
      and trees_from_id_list id_list state =
        List.map id_list ~f:(tree_from_id state)
      in
      Some (tree_from_id state root.id)

let tree_from_graph (graph : Graph.graph) =
  if Graph.is_empty graph then Some (Tree.empty_tree 1)
  else tree_from_condensed (process_state graph)
