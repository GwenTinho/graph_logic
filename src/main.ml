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
    end)
