open Logic

exception READERROR of string

(*2 values in each file, expected and start*)
let path = "./fingerprints.json"
let proofs = Parseproofs.read_file_as_fingerprints path
let proofs_arr = Array.of_list proofs
let len = Array.length proofs_arr
let () = assert (len = 9)
let%test "test_ai1" = None = Fingerprint.verify proofs_arr.(0)
let%test "test_ai2" = None <> Fingerprint.verify proofs_arr.(1)
let%test "test_ai3" = None = Fingerprint.verify proofs_arr.(2)
let%test "test_ai4" = None = Fingerprint.verify proofs_arr.(3)
let%test "test_ai5" = None <> Fingerprint.verify proofs_arr.(4)
let%test "test_ai6" = None <> Fingerprint.verify proofs_arr.(5)
let%test "test_pp_one_step" = None = Fingerprint.verify proofs_arr.(6)
let%test "test_pp_verif" = None = Fingerprint.verify proofs_arr.(7)
let%test "test_sw" = None = Fingerprint.verify proofs_arr.(8)
