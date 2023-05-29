open Logic

let path = "./ai_test.json"
let trees = Parseproofs.read_file_as_trees path
let tree_arr = Array.of_list trees

let%test "ai_path_test_1" =
  let p1 = [ 0; 1 ] in
  let p2 = [ 0; 0 ] in
  let pPar = [ 0 ] in
  let res_opt = Rules.atomic_identity_down tree_arr.(0) pPar p1 p2 in
  if Option.is_none res_opt then false
  else Equality.is_empty (Option.get res_opt)

let%test "ai_path_test_2" =
  let p1 = [ 0; 1 ] in
  let p2 = [ 0; 0 ] in
  let pPar = [ 0 ] in
  let res_opt = Rules.atomic_identity_down tree_arr.(0) pPar p2 p1 in
  if Option.is_none res_opt then false
  else Equality.is_empty (Option.get res_opt)

let%test "ai_path_test_3" =
  let p1 = [ 0; 2; 1 ] in
  let p2 = [ 0; 2; 0 ] in
  let pPar = [ 0; 2 ] in
  let res_opt = Rules.atomic_identity_down tree_arr.(1) pPar p1 p2 in
  let p1 = [ 0; 1 ] in
  let p2 = [ 0; 0 ] in
  let pPar = [ 0 ] in
  let res_opt =
    match res_opt with
    | None -> None
    | Some res -> Rules.atomic_identity_down res pPar p1 p2
  in
  if Option.is_none res_opt then false
  else Equality.is_empty (Option.get res_opt)
