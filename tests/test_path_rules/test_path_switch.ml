open Logic

let ( let* ) o f = match o with None -> None | Some x -> f x
let path = "./switch_test.json"
let tree = Parseproofs.read_file_as_tree path

(* weak first test since we dont have a quick way of checking equality yet*)
let%test "switch_path_test_1" =
  let pPar = [ 0 ] in
  let pOut = [ 0; 0 ] in
  let pPrime = [ 0; 2 ] in
  let pPrimeIn = [ 0; 2; 0 ] in
  let res = Rules.switch_par tree pPar pOut pPrime pPrimeIn in
  match res with None -> false | Some _ -> true
