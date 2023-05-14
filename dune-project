(lang dune 2.9)
(name quartic_MD)

(generate_opam_files true)

(package
  (name quartic_MD)
  (synopsis "Modular decomposition of undirected graphs")
  (depends
    (js_of_ocaml (>= 4.0))
    (js_of_ocaml-ppx (>=  4.0))
    (yojson (>= 1.7))
    (base (>= 4.13))
    (ppx_inline_test (>= 4.13))
    (ppx_jane (>= 4.13))))