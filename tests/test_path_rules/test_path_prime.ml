open Logic

let ( let* ) o f = match o with None -> None | Some x -> f x
let path = "./prime_test.json"
let tree = Parseproofs.read_file_as_tree path

(* weak first test since we dont have a quick way of checking equality yet*)
let%test "prime_path_test_1" =
  let pPar = [ 0 ] in
  let p1 = [ 0; 0 ] in
  let p2 = [ 0; 1 ] in
  PathRules.prime_down_paths tree pPar p1 p2 <> None
