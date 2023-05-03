open Graph
open Base
open Yojson.Basic.Util

let to_node_and_id js_obj =
  let id = js_obj |> member "id" |> to_int in
  let label = js_obj |> member "label" |> to_string in
  let pol = js_obj |> member "polarisation" |> to_bool in
  let atom = Atom { label; pol } in
  (atom, id)

let to_nodes_and_ids js_obj =
  let json_list = to_list js_obj in
  Base.List.unzip (List.map json_list ~f:to_node_and_id)

let to_id_tuple js_obj =
  let src = js_obj |> member "source" |> to_int in
  let dest = js_obj |> member "target" |> to_int in
  (src, dest)

let to_id_list js_obj = to_list js_obj |> List.map ~f:to_id_tuple

(** [id_map vset]: returns a map from the [id]s of the elements of [vset] to
    the elements themselves *)
let id_map (vs : node list) ids =
  List.fold (List.zip_exn vs ids)
    ~init:(Map.empty (module Int))
    ~f:(fun accum (node, id) -> Map.add_exn accum ~key:id ~data:node)

let to_assoc_list id_list nodes ids =
  let map = id_map nodes ids in
  List.map id_list ~f:(fun (src, dest) ->
      (Map.find_exn map src, Map.find_exn map dest))

let to_edge_maps nodes ids js_obj =
  let id_list = to_id_list js_obj in
  let vertex_assoc = to_assoc_list id_list nodes ids in
  Graph.edge_maps vertex_assoc

let parse js_obj =
  let nodes_json = js_obj |> member "nodes" in
  let nodes, ids = to_nodes_and_ids nodes_json in
  let edges = js_obj |> member "edges" |> to_edge_maps nodes ids in
  let nodes = Set.of_list (module Node) nodes in
  { nodes; edges }

let make_tree_node node successors : Tree.tree =
  let connective_label = node |> member "connective" |> to_string in
  match connective_label with
  | "prime" ->
      let graph = node |> member "graph" in
      let nodes = List.map (graph |> member "nodes" |> to_list) ~f:to_int in
      let edges = graph |> member "edges" |> to_id_list in
      let idg : Id_graph.id_graph = { nodes; edges } in
      Tree.Prime (idg, successors)
  | "par" -> Par successors
  | "tensor" -> Tensor successors
  | "atom" ->
      let label = node |> member "label" |> to_string in
      let pol = node |> member "polarisation" |> to_bool in
      Atom { label; pol }
  | _ -> failwith "Tried to serialize malformed tree"

let rec parse_tree js_obj =
  let ( = ) = Poly.( = ) in
  (*check if object is an empty dictionary*)
  if js_obj = `Assoc [] then Tree.empty_tree ()
  else
    let successors =
      match js_obj |> member "successors" with `Null -> [] | s -> to_list s
    in
    let successors = List.map successors ~f:parse_tree in
    make_tree_node js_obj successors

let from_node node =
  let label, pol =
    match node with
    | Atom atom -> (`String atom.label, `Bool atom.pol)
    | _ -> failwith "Tried to serialize non-atomic graph"
  in
  `Assoc [ ("label", label); ("polarisation", pol) ]

let from_nodes nset =
  let node_list = Set.elements nset in
  let json_list = List.map node_list ~f:from_node in
  `List json_list

let from_id_tuple (id1, id2) =
  let source = `Int id1 in
  let target = `Int id2 in
  `Assoc [ ("source", source); ("target", target) ]

let from_edges edge_map =
  let edge_list = edge_tuple_list edge_map in
  let id_list =
    List.map edge_list ~f:(fun (v1, v2) -> (hash_node v1, hash_node v2))
  in
  let json_list = List.map id_list ~f:from_id_tuple in
  json_list

let serialize_graph graph =
  let nodes = from_nodes graph.nodes in
  let edges = `List (from_edges graph.edges) in
  `Assoc [ ("nodes", nodes); ("edges", edges) ]

let serialize_id_graph (id_graph : Id_graph.id_graph) =
  let nodesMapping = List.mapi id_graph.nodes ~f:(fun i v -> (v, i + 1)) in
  let reindexedEdges =
    List.map id_graph.edges ~f:(fun (s, t) ->
        ( snd @@ Caml.Option.get
          @@ List.find nodesMapping ~f:(fun (v, _) -> v = s),
          snd @@ Caml.Option.get
          @@ List.find nodesMapping ~f:(fun (v, _) -> v = t) ))
  in
  let nodeCount = `Int (List.length nodesMapping) in
  let edges = `List (List.map reindexedEdges ~f:from_id_tuple) in
  `Assoc [ ("nodeCount", nodeCount); ("edges", edges) ]

let from_id_graph (id_graph : Id_graph.id_graph) =
  let nodes = List.map id_graph.nodes ~f:(fun n -> `Int n) in
  let nodes_json = `List nodes in
  let edges =
    List.map id_graph.edges ~f:(fun (n1, n2) ->
        `Assoc [ ("source", `Int n1); ("target", `Int n2) ])
  in
  let edges_json = `List edges in
  `Assoc [ ("nodes", nodes_json); ("edges", edges_json) ]

let rec serialize_tree (tree : Tree.tree) : Yojson.Basic.t =
  match tree with
  | Tree.Atom a ->
      let node_base = [ ("connective", `String "atom") ] in
      let label = ("label", `String a.label) in
      let pol = ("polarisation", `Bool a.pol) in
      `Assoc (label :: pol :: node_base)
  | Tree.Tensor succ ->
      let node_base = [ ("connective", `String "tensor") ] in
      let successors = List.map succ ~f:serialize_tree in
      `Assoc (("successors", `List successors) :: node_base)
  | Tree.Par succ ->
      let node_base = [ ("connective", `String "par") ] in
      let successors = List.map succ ~f:serialize_tree in
      `Assoc (("successors", `List successors) :: node_base)
  | Tree.Prime (id_graph, succ) ->
      let connective = `String "prime" in
      let node_base = [ ("connective", connective) ] in

      let successors = List.map succ ~f:serialize_tree in
      `Assoc
        (("successors", `List successors)
        :: ("graph", from_id_graph id_graph)
        :: node_base)

let read_file_as_graph filepath =
  let s = Stdio.In_channel.read_all filepath in
  let js_obj = Yojson.Basic.from_string s in
  parse js_obj

let read_file_as_graphs filepath =
  let s = Stdio.In_channel.read_all filepath in
  let js_obj = Yojson.Basic.from_string s in
  List.map ~f:parse (to_list js_obj)

let parse_idg js_obj : Id_graph.id_graph =
  let nodes = js_obj |> member "nodeCount" |> to_int in
  let edges = js_obj |> member "edges" |> to_id_list in
  { nodes = List.init ~f:(fun x -> x + 1) nodes; edges }

let read_file_as_id_graph filepath =
  let s = Stdio.In_channel.read_all filepath in
  let js_obj = Yojson.Basic.from_string s in
  parse_idg js_obj

let read_file_as_id_graphs filepath =
  let s = Stdio.In_channel.read_all filepath in
  let js_obj = Yojson.Basic.from_string s in
  List.map ~f:parse_idg (to_list js_obj)

let read_file_as_tree filepath =
  let s = Stdio.In_channel.read_all filepath in
  let js_obj = Yojson.Basic.from_string s in
  parse_tree js_obj

let read_file_as_trees filepath =
  let s = Stdio.In_channel.read_all filepath in
  let js_obj = Yojson.Basic.from_string s in
  List.map ~f:parse_tree (to_list js_obj)

let to_step js_obj =
  let step_type = js_obj |> to_string in
  match step_type with
  | "sw" ->
      Fingerprint.Switch_Par
        (Rules.pick_first, Rules.pick_largest, Rules.pick_first_atom_or_first)
  | "ai" -> Fingerprint.AI_down
  | "pp" -> Fingerprint.Prime_down
  | _ -> failwith "Tried to serialize malformed proof"

let parse_fingerprint js_obj : Fingerprint.proof =
  let initial = js_obj |> member "initial" |> parse_tree in
  let expected = js_obj |> member "expected" |> parse_tree in
  let steps = List.map ~f:to_step (js_obj |> member "steps" |> to_list) in
  { initial; expected; steps }

let read_file_as_fingerprints filepath =
  let s = Stdio.In_channel.read_all filepath in
  let js_obj = Yojson.Basic.from_string s in
  List.map ~f:parse_fingerprint (to_list js_obj)

let clean_file_path filepath =
  Caml.Filename.concat
    (Caml.Filename.dirname filepath)
    (Caml.Filename.basename filepath)

let write_tree tree filepath =
  Yojson.Basic.to_file (clean_file_path filepath) (serialize_tree tree)

let write_graph graph filepath =
  Yojson.Basic.to_file (clean_file_path filepath) (serialize_graph graph)

(*Id_graphs are autoreindexed to be 1-indexed*)
let write_id_graph id_graph filepath =
  Yojson.Basic.to_file (clean_file_path filepath) (serialize_id_graph id_graph)
