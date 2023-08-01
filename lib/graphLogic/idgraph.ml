open Base
open Poly
open BitMatrix

type id_graph = { nodes : int list; edges : (int * int) list }

let idg_of_tidg (tig : Quartic.Tree.id_graph) =
  { nodes = tig.nodes; edges = tig.edges }

let tidg_of_idg (tig : id_graph) : Quartic.Tree.id_graph =
  { nodes = tig.nodes; edges = tig.edges }

let isEdge (a, b) idg =
  let { nodes = _; edges } = idg in
  (*use the or statement because we are working with undirected edges*)
  List.exists edges ~f:(fun (c, d) -> (a = c && b = d) || (a = d && b = c))

let length idg =
  let { nodes; edges = _ } = idg in
  List.length nodes

let length_edges idg =
  (*we are not working with a set so this is a lot less reliable ISSUE TODO*)
  let { nodes = _; edges } = idg in
  List.length edges

(*We are passing the dimension since we need to keep the scope outside this function*)
(*NOTE the Slap library creates matricies that are 1 indexed, this means that we want to avoid indexing at all costs*)
let adj_mat idg =
  let dim = length idg in
  let { nodes; edges = _ } = idg in
  let nodes = List.to_array nodes in
  let m = create dim dim (fun i j -> isEdge (nodes.(i), nodes.(j)) idg) in
  m

let degrees idg =
  let m = adj_mat idg in
  Array.fold m
    ~init:(Array.init (length idg) ~f:(fun _ -> 0))
    ~f:(fun acc row ->
      Array.mapi row ~f:(fun i x -> if x then acc.(i) + 1 else acc.(i)))

let genInitialPerm idg1 idg2 dim1 dim2 =
  let degArr1 = degrees idg1 in
  let degArr2 = degrees idg2 in
  create dim1 dim2 (fun i j -> degArr2.(j) >= degArr1.(i))

let permToAssoc idg1 idg2 (perm : bit_matrix) =
  let nodes1 = Array.of_list idg1.nodes in
  let nodes2 = Array.of_list idg2.nodes in
  let perm_assoc = to_assoc_list perm in
  let nodemapping =
    List.map perm_assoc ~f:(fun (i, j) -> (nodes1.(i), nodes2.(j)))
  in
  Map.of_alist_exn (module Int) nodemapping

let setImmut a i v =
  let cpy = Array.copy a in
  let () = cpy.(i) <- v in
  cpy

let isIso perm matA matB = matA <= mul perm (transpose (mul perm matB))

(*TODO implement prune*)
let refine perm = copy perm

(*PSEUDOCODE
  https://adriann.github.io/Ullman%20subgraph%20isomorphism.html
*)

let rec recurse matA matB lastR lastC usedVert perm currentRow currentColumn =
  if currentRow = lastR && isIso perm matA matB then Some perm
  else
    let perm = copy perm in
    let perm = refine perm in
    let rec loop index =
      if index = lastC then None
      else if usedVert.(index) then loop (index + 1)
      else
        (*We are now in the for loop*)
        (*Mark c as used*)
        let () = update_rowi perm currentRow (fun j _ -> j = index) in
        let usedVert = setImmut usedVert index true in
        let new_mat =
          recurse matA matB lastR lastC usedVert perm (currentRow + 1) index
        in
        match new_mat with Some _ -> new_mat | None -> loop (index + 1)
    in
    loop currentColumn

(*Finds some isomorphism between matA and matB returns a Some iso on success*)
(*matA, matB are adjacency matricies*)
let ullmann_find perm matA matB =
  if is_empty matA then Some perm
  else if is_empty matB then None
  else
    let lastRow = Array.length matA in
    let lastCol = Array.length matB in
    recurse matA matB lastRow lastCol (Array.create ~len:lastCol false) perm 0 0

let find_sub_iso idg1 idg2 =
  (*haskell style syntax for composing into a monad*)
  let ( <&> ) m f = Option.( >>= ) m (fun x -> Option.return (f x)) in
  let l1 = length idg1 in
  let l2 = length idg2 in
  if (*We want empty graphs to be trivial subgraphs*)
     l1 > l2 then None
  else
    let m0 = genInitialPerm idg1 idg2 l1 l2 in
    let adj1 = adj_mat idg1 in
    let adj2 = adj_mat idg2 in
    ullmann_find m0 adj1 adj2 <&> permToAssoc idg1 idg2

let is_sub_iso idg1 idg2 =
  match find_sub_iso idg1 idg2 with Some _ -> true | None -> false

let is_iso idg1 idg2 =
  match (find_sub_iso idg1 idg2, find_sub_iso idg2 idg1) with
  | Some _, Some _ -> true
  | _ -> false

let find_iso idg1 idg2 =
  match (find_sub_iso idg1 idg2, find_sub_iso idg2 idg1) with
  | Some m1, Some _ -> Some m1
  | _ -> None

(*fills out all possible edges of the graph TODO, not very optimal but hey*)
let completetion_graph g =
  let ( >>= ) = List.( >>= ) in
  let { nodes; edges = _ } = g in
  let edges =
    nodes >>= fun x ->
    List.filter_map nodes ~f:(fun y -> if x = y then None else Some (x, y))
  in
  { nodes; edges }

let edge_diff idg1 idg2 =
  let { nodes = _; edges = e1 } = idg1 in
  let { nodes = _; edges = e2 } = idg2 in
  List.filter e1 ~f:(fun x ->
      not
        (List.mem e2 x ~equal:(fun (a, b) (c, d) ->
             (a = c && b = d) || (a = d && b = c))))

let id_graph_complement g =
  let compl = completetion_graph g in
  let edges = edge_diff compl g in
  { g with edges }

(*is_dual checks whether two graphs are in a dual relationship up to isomorphism*)
let is_dual g1 g2 = is_iso (id_graph_complement g2) g1

(*TODO write tests for this*)

let is_prime idg =
  let { nodes; edges } = idg in
  let node_list =
    List.map nodes ~f:(fun id ->
        let atom =
          Quartic.Graph.Atom { Quartic.Graph.label = ""; pol = true }
        in
        { Quartic.Graph.connective = atom; id })
  in
  let edge_list =
    List.map edges ~f:(fun (s, t) ->
        let source = List.find_exn node_list ~f:(fun v -> v.id = s) in
        let target = List.find_exn node_list ~f:(fun v -> v.id = t) in
        (source, target))
  in
  let graph, _ = Quartic.Graph.to_graph node_list edge_list in
  Quartic.Condense.isPrime graph

let successors node idg =
  let { nodes = _; edges } = idg in
  List.map ~f:(fun (_, v) -> v) (List.filter ~f:(fun (u, _) -> node = u) edges)

let dfs start idg =
  let rec rdfs visited node =
    if not (List.mem visited node ~equal:( = )) then
      let s = successors node idg in
      List.fold_left ~f:rdfs ~init:(node :: visited) s
    else visited
  in
  rdfs [] start

let restrict idg nodes =
  let { nodes = _; edges = e } = idg in
  let edges =
    List.filter
      ~f:(fun (u, v) ->
        List.mem nodes u ~equal:( = ) && List.mem nodes v ~equal:( = ))
      e
  in
  { nodes; edges }

let restrict_complement idg nodes =
  let { nodes = n; edges = e } = idg in
  let edges =
    List.filter
      ~f:(fun (u, v) ->
        not (List.mem nodes u ~equal:( = ) && List.mem nodes v ~equal:( = )))
      e
  in
  let nodes = List.filter ~f:(fun x -> not (List.mem nodes x ~equal:( = ))) n in
  { nodes; edges }

let connected_components idg =
  let rec aux components graph =
    match graph.nodes with
    | [] -> components
    | h :: _ ->
        let component = dfs h graph in
        let component_graph = restrict graph component in
        let component_complement = restrict_complement graph component in
        aux (component_graph :: components) component_complement
  in
  aux [] idg
