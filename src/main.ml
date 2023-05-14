open Quartic
open Base
open Js_of_ocaml
open Drawing
open Reading

let get_nodes_arr cy : Js.Unsafe.any_js_array  = 
  let colletion = Js.Unsafe.meth_call cy "nodes" [||] in
  Js.Unsafe.meth_call colletion "toArray" [||]

let get_edges_arr cy : Js.Unsafe.any_js_array =
  let collection = Js.Unsafe.meth_call cy "edges" [||] in
  Js.Unsafe.meth_call collection "toArray" [||]

let node_to_vertex (node : <data : Js.js_string Js.t -> Js.Unsafe.any Js.meth> Js.t) =
  let access_data (string : string) =
    node##data (Js.string string)
  in
  let id = Js.Unsafe.coerce (access_data "id") |> Js.parseInt in
  let label = Js.Unsafe.coerce (access_data "label") |> Js.to_string in
  let pol = Js.Unsafe.coerce (access_data "polarisation") |> Js.to_bool in
  let atom = {Graph.label=label; pol=pol} in
  {Graph.connective = Atom atom; id = id}

let to_edge (vertices : Graph.vertex list) (edge : <data : Js.js_string Js.t -> Js.Unsafe.any Js.meth> Js.t) =
  let access_data (string : string) = 
    edge##data (Js.string string)
  in
  let source_id = Js.Unsafe.coerce (access_data "source") |> Js.parseInt in
  let target_id = Js.Unsafe.coerce (access_data "target") |> Js.parseInt in
  let source = List.find_exn vertices ~f:(fun v -> v.id = source_id) in
  let target = List.find_exn vertices ~f:(fun v -> v.id = target_id) in
  (source, target)

let get_layout cy root =
  let name = if ((cy##nodes (Js.string ":child"))##toArray |> Js.to_array |> Array.length) > 0 then 
    "cose-bilkent"
    else
    "breadthfirst"
  in
  let options = object%js
    val name = name |> Js.string
    val animate = Js.bool false
    val roots = [|root|]
    val spacingFactor = 1.0
    val directed = true
  end
  in
  cy##layout options

let decompose () =
  let cy = Js.Unsafe.js_expr "cy1" in
  let nodes = (Js.Unsafe.coerce (get_nodes_arr cy)) |> Js.to_array in
  let vertices = Array.map nodes ~f:(node_to_vertex) |> Array.to_list in
  let edges_arr = (Js.Unsafe.coerce (get_edges_arr cy)) |> Js.to_array in
  let edge_list = Array.map edges_arr ~f:(to_edge vertices) |> Array.to_list in


  let directed = Js.Unsafe.js_expr "directed" |> Js.to_bool in
  let (graph, state) = Graph.to_graph ~directed:directed vertices edge_list in
  let condensed_graph = Condense.process graph state in
  let tree = Tree.tree_from_condensed ~directed:directed condensed_graph state in

  let cy2 = Js.Unsafe.js_expr "cy2" in
  let removed = cy2##elements##remove in
  let () = cy2##.changes##push ([|Js.Unsafe.inject (Js.string "remove"); removed|] |> Js.array) in
  match tree with
  | None -> ()
  | Some tree ->
    let () = Js.Unsafe.global##.tree := (Parsegraph.serialize_tree tree |> Yojson.Basic.pretty_to_string |> Js.string) in
    let root = draw_tree cy2 tree in
    let root_node = cy2##nodes (String.concat ["#";Js.to_string root] |> Js.string) in
    let () = (Js.Unsafe.coerce root_node)##addClass (Js.string "root") in
    let () = cy2##.changes##push ([|Js.Unsafe.inject (Js.string "replace"); cy2##elements|] |> Js.array) in
    let _ = (get_layout cy2 root)##run in
    ()

let recompose () =
  let cy = Js.Unsafe.js_expr "cy2" in
  let root_arr = cy##nodes (Js.string ".root") |> Js.to_array in 
  if Array.is_empty root_arr then () else
  let root = Array.get root_arr 0 in
  let tree = read_tree root in
  let directed = Js.Unsafe.js_expr "directed" |> Js.to_bool in
  let graph = Tree.tree_to_graph ~directed:directed tree in

  let cy1 = Js.Unsafe.js_expr "cy1" in
  let removed = cy1##elements##remove in
  let () = cy1##.changes##push ([|Js.Unsafe.inject (Js.string "remove"); removed|] |> Js.array) in
  let () = draw_graph ~directed:directed cy1 graph in
  let () = cy1##.changes##push ([|Js.Unsafe.inject (Js.string "replace"); cy1##elements|] |> Js.array) in
  Js.Unsafe.global##cleanLayout(cy1)

let isPrimeIdGraph ?directed idGraph =
  let jsnode_list = idGraph##nodes |> Js.to_array |> Array.to_list in
  let jsedge_list = idGraph##edges |> Js.to_array |> Array.to_list in
  let node_list = List.map jsnode_list ~f:(fun n ->
    let label = n##id |> Js.to_string in
    let id =  Util.remove_rep label in
    let atom = Graph.Atom {Graph.label = label; pol = true} in
    {Graph.connective = atom; id = id})
  in
  let edge_list = List.map jsedge_list ~f:(fun e ->
    let source_id = e##data (Js.string "source") |> Js.to_string |> Util.remove_rep in
    let target_id = e##data (Js.string "target") |> Js.to_string |> Util.remove_rep in
    let source = List.find_exn node_list ~f:(fun v -> v.id = source_id) in
    let target = List.find_exn node_list ~f:(fun v -> v.id = target_id) in
    (source, target))
  in
  let graph, _ = Graph.to_graph ?directed:directed node_list edge_list in
  Condense.isPrime graph

let getTreeJson () =
  Js.Unsafe.global##.tree

let _ = Js.export_all (object%js
  method decompose = decompose ()
  method getTreeJson = getTreeJson ()
  method recompose = recompose ()
  method isPrime graph =
    let directed = Js.Unsafe.js_expr "directed" |> Js.to_bool in
    isPrimeIdGraph ~directed:directed graph
  end)

