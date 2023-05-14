open Base
open Graph

let share_module graph vi vj =
  let si = find_or_empty graph.edges vi |> Fn.flip Set.remove vj in
  let sj = find_or_empty graph.edges vj |> Fn.flip Set.remove vi in
  NSet.equal si sj

let keep_links g (h : nodes) v : nodes =
  let new_h = Set.remove h v in
  match Map.find (graph_difference g new_h).edges v with
  | None -> Set.empty (module Node)
  | Some vset -> vset

let is_module g (h : nodes) =
  let connected =
    match Set.choose h with
    | None -> Set.empty (module Node)
    | Some v -> keep_links g h v
  in
  Set.for_all h ~f:(fun v ->
      let v_connected = keep_links g h v in
      Set.equal connected v_connected)
