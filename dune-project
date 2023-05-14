(lang dune 2.9)

(name GSProofSearch)

(generate_opam_files true)

(package
 (name GSProofSearch)
 (synopsis "Implementation of proof search on graphs")
 (depends
  (yojson
   (>= 1.7))
  (base
   (>= 4.13))
  (ppx_inline_test
   (>= 4.13))
  (ppx_jane
   (>= 4.13))
  (ppx_assert
   (>= 0.15.0))
  (slap
   (>= 4.1.1))))
