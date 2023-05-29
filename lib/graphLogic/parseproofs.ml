open Quartic.Graph
open Base
open Yojson.Basic.Util

let to_id_tuple js_obj =
  let src = js_obj |> member "source" |> to_int in
  let dest = js_obj |> member "target" |> to_int in
  (src, dest)

let to_id_list js_obj = to_list js_obj |> List.map ~f:to_id_tuple

let make_tree_node node successors : LogicalTree.ltree =
  let connective_label = node |> member "connective" |> to_string in
  match connective_label with
  | "prime" ->
      let graph = node |> member "graph" in
      let nodes = List.map (graph |> member "nodes" |> to_list) ~f:to_int in
      let edges = graph |> member "edges" |> to_id_list in
      let idg : Idgraph.id_graph = { nodes; edges } in
      LogicalTree.Prime (idg, successors)
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
  if js_obj = `Assoc [] then LogicalTree.empty_tree ()
  else
    let successors =
      match js_obj |> member "successors" with `Null -> [] | s -> to_list s
    in
    let successors = List.map successors ~f:parse_tree in
    make_tree_node js_obj successors

let from_id_tuple (id1, id2) =
  let source = `Int id1 in
  let target = `Int id2 in
  `Assoc [ ("source", source); ("target", target) ]

let serialize_id_graph (id_graph : Idgraph.id_graph) =
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

let from_id_graph (id_graph : Idgraph.id_graph) =
  let nodes = List.map id_graph.nodes ~f:(fun n -> `Int n) in
  let nodes_json = `List nodes in
  let edges =
    List.map id_graph.edges ~f:(fun (n1, n2) ->
        `Assoc [ ("source", `Int n1); ("target", `Int n2) ])
  in
  let edges_json = `List edges in
  `Assoc [ ("nodes", nodes_json); ("edges", edges_json) ]

let rec serialize_ltree (tree : LogicalTree.ltree) : Yojson.Basic.t =
  match tree with
  | LogicalTree.Atom a ->
      let node_base = [ ("connective", `String "atom") ] in
      let label = ("label", `String a.label) in
      let pol = ("polarisation", `Bool a.pol) in
      `Assoc (label :: pol :: node_base)
  | LogicalTree.Tensor succ ->
      let node_base = [ ("connective", `String "tensor") ] in
      let successors = List.map succ ~f:serialize_ltree in
      `Assoc (("successors", `List successors) :: node_base)
  | LogicalTree.Par succ ->
      let node_base = [ ("connective", `String "par") ] in
      let successors = List.map succ ~f:serialize_ltree in
      `Assoc (("successors", `List successors) :: node_base)
  | LogicalTree.Prime (id_graph, succ) ->
      let connective = `String "prime" in
      let node_base = [ ("connective", connective) ] in

      let successors = List.map succ ~f:serialize_ltree in
      `Assoc
        (("successors", `List successors)
        :: ("graph", from_id_graph id_graph)
        :: node_base)

let parse_idg js_obj : Idgraph.id_graph =
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
  let step_type = js_obj |> member "type" |> to_string in
  let data = js_obj |> member "data" in
  match step_type with
  | "sw" ->
      let par = List.map ~f:to_int (data |> member "par" |> to_list) in
      let outside = List.map ~f:to_int (data |> member "outside" |> to_list) in
      let inside = List.map ~f:to_int (data |> member "inside" |> to_list) in
      let prime = List.map ~f:to_int (data |> member "prime" |> to_list) in

      Fingerprint.Switch_Par { par; outside; inside; prime }
  | "ai" ->
      let par = List.map ~f:to_int (data |> member "par" |> to_list) in
      let atom1 = List.map ~f:to_int (data |> member "atom1" |> to_list) in
      let atom2 = List.map ~f:to_int (data |> member "atom2" |> to_list) in
      Fingerprint.AI_down { par; atom1; atom2 }
  | "pp" ->
      let par = List.map ~f:to_int (data |> member "par" |> to_list) in
      let prime1 = List.map ~f:to_int (data |> member "prime1" |> to_list) in
      let prime2 = List.map ~f:to_int (data |> member "prime2" |> to_list) in
      Fingerprint.Prime_down { par; prime1; prime2 }
  | "simplify" -> Fingerprint.Simplify
  | _ -> failwith "Tried to serialize malformed proof"

let parse_fingerprint js_obj : Fingerprint.proof =
  let initial = js_obj |> member "initial" |> parse_tree in
  let steps = List.map ~f:to_step (js_obj |> member "steps" |> to_list) in
  { initial; steps }

let serialize_rule (rule : Fingerprint.rule_id) =
  let rule_type =
    match rule with
    | Fingerprint.Switch_Par _ -> "sw"
    | Fingerprint.AI_down _ -> "ai"
    | Fingerprint.Prime_down _ -> "pp"
    | Fingerprint.Simplify -> "simplify"
  in
  let data =
    match rule with
    | Fingerprint.Switch_Par { par; outside; inside; prime } ->
        let par = `List (List.map par ~f:(fun x -> `Int x)) in
        let outside = `List (List.map outside ~f:(fun x -> `Int x)) in
        let inside = `List (List.map inside ~f:(fun x -> `Int x)) in
        let prime = `List (List.map prime ~f:(fun x -> `Int x)) in
        `Assoc
          [
            ("par", par);
            ("outside", outside);
            ("inside", inside);
            ("prime", prime);
          ]
    | Fingerprint.AI_down { par; atom1; atom2 } ->
        let par = `List (List.map par ~f:(fun x -> `Int x)) in
        let atom1 = `List (List.map atom1 ~f:(fun x -> `Int x)) in
        let atom2 = `List (List.map atom2 ~f:(fun x -> `Int x)) in
        `Assoc [ ("par", par); ("atom1", atom1); ("atom2", atom2) ]
    | Fingerprint.Prime_down { par; prime1; prime2 } ->
        let par = `List (List.map par ~f:(fun x -> `Int x)) in
        let prime1 = `List (List.map prime1 ~f:(fun x -> `Int x)) in
        let prime2 = `List (List.map prime2 ~f:(fun x -> `Int x)) in
        `Assoc [ ("par", par); ("prime1", prime1); ("prime2", prime2) ]
    | Fingerprint.Simplify -> `Assoc []
  in
  `Assoc [ ("type", `String rule_type); ("data", data) ]

let serialize_fingerprint (proof : Fingerprint.proof) =
  let initial = serialize_ltree proof.initial in
  let steps = List.map proof.steps ~f:serialize_rule in
  `Assoc [ ("initial", initial); ("steps", `List steps) ]

let read_file_as_fingerprints filepath =
  let s = Stdio.In_channel.read_all filepath in
  let js_obj = Yojson.Basic.from_string s in
  List.map ~f:parse_fingerprint (to_list js_obj)

let clean_file_path filepath =
  Caml.Filename.concat
    (Caml.Filename.dirname filepath)
    (Caml.Filename.basename filepath)

let write_tree tree filepath =
  Yojson.Basic.to_file (clean_file_path filepath) (serialize_ltree tree)

(*Id_graphs are autoreindexed to be 1-indexed*)
let write_id_graph id_graph filepath =
  Yojson.Basic.to_file (clean_file_path filepath) (serialize_id_graph id_graph)
