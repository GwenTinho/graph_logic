open Logic

exception READERROR of string

(*2 values in each file, expected and start*)
let path = "./ai_test.json"
let tree = Parseproofs.read_file_as_tree path

let%test "ai_path_test_1" =
  let p1 = [ 0; 1 ] in
  let p2 = [ 0; 0 ] in
  let pPar = [ 0 ] in
  let res_opt = PathRules.atomic_identity_down_paths tree p1 p2 pPar in
  if Option.is_none res_opt then false
  else Equality.is_empty (Option.get res_opt)
