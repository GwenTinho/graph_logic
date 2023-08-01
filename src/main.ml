open InterfaceHelpers
open Js_of_ocaml

let _ =
  Js.export_all
    (object%js
       method decompose = decompose ()
       method recompose = recompose ()
       method ai pathPar path1 path2 = ai_down pathPar path1 path2
       method prime pathPar path1 path2 = prime_down pathPar path1 path2

       method switchPar pathPar pathOut pathPrime pathInPrime =
         switch_par pathPar pathOut pathPrime pathInPrime

       method isPrime graph =
         let directed = Js.Unsafe.js_expr "directed" |> Js.to_bool in
         isPrimeIdGraph ~directed graph

       method isPrimeGS graph =
         let directed = Js.Unsafe.js_expr "directed" |> Js.to_bool in
         isPrimeIdGraphGS ~directed graph

       method simplify = simplify ()
       method autoAI = auto_ai ()
       method autoPrime = auto_prime ()
       method autoSwitch = auto_switch ()
       method verify proof = verify proof
       method getTreeJson = getTreeJson ()
    end)
