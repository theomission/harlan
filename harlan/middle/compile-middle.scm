(library
  (harlan middle compile-middle)
  (export compile-harlan-middle)
  (import
    (rnrs)
    (harlan compile-opts)
    (harlan verification-passes)
    (harlan middle lifting)
    (harlan middle remove-complex-kernel-args)
    (harlan middle remove-lambdas)
    (harlan middle remove-recursion)
    (harlan middle desugar-match)
    (harlan middle make-kernel-dimensions-explicit)
    (harlan middle make-work-size-explicit)
    (harlan middle optimize-fuse-kernels)
    (harlan middle remove-danger)
    (harlan middle insert-transactions)
    (harlan middle remove-transactions)
    (harlan middle remove-nested-kernels)
    (harlan middle returnify-kernels)
    (harlan middle make-vector-refs-explicit)
    (harlan middle lift-complex)
    (harlan middle annotate-free-vars)
    (harlan middle lower-vectors)
    (harlan middle insert-let-regions)
    (harlan middle specialize-string-equality)
    (harlan middle uglify-vectors)
    (harlan middle remove-let-regions)
    (harlan middle flatten-lets)
    (harlan middle hoist-kernels)
    (harlan middle fix-kernel-local-regions)
    (harlan middle generate-kernel-calls)
    (harlan middle compile-module)
    (harlan middle convert-types)
    (only (harlan middle languages M0-3)
          parse-M0
          unparse-M3)
    (only (harlan middle languages M5) parse-M5)
    (only (harlan middle languages M7)
          parse-M7 unparse-M7
          parse-M7.0 unparse-M7.0 parse-M7.0.0 parse-M7.0.2
          unparse-M7.0.0 unparse-M7.0.1 unparse-M7.0.3)
    (only (harlan middle languages M8) parse-M8)
    (only (harlan middle languages M9) unparse-M9.3))
    

;; The "middle end" of a compiler. No one ever knows what's supposed
;; to go here.
(define compile-harlan-middle
  (passes
   (nanopasses
    (remove-lambdas : M0 -> M3))
   (desugar-match
    verify-desugar-match)
   (nanopasses
    (make-kernel-dimensions-explicit : M5 -> M6)
    (make-work-size-explicit : M6 -> M7))
   (optimize-lift-lets
    verify-optimize-lift-lets
    1)
   (optimize-fuse-kernels
    verify-optimize-fuse-kernels
    1)
   (nanopasses
    (remove-danger : M7 -> M7.0.0))
   (remove-nested-kernels
    verify-remove-nested-kernels)
   (nanopasses
    (insert-transactions : M7.0.0 -> M7.0.1))
   (returnify-kernels
    verify-returnify-kernels)
   (lift-complex
    verify-lift-complex)
   (optimize-lift-allocation
    verify-optimize-lift-allocation
    1)
   ;; This seems like a good place to remove the transactions
   ;;
   ;; - originally I wanted to put it right after returnify-kernels,
   ;; but we need to be sure we don't lift any allocations outside of
   ;; a transaction.
   (nanopasses
    (remove-transactions : M7.0.2 -> M7.0.3))
   (make-vector-refs-explicit
    verify-make-vector-refs-explicit)
   (annotate-free-vars
    verify-annotate-free-vars)
   (nanopasses
    (unless (allow-complex-kernel-args)
      (remove-complex-kernel-args : M7.0 -> M7.0)))
   (lower-vectors
    verify-lower-vectors)
   ;;(nanopasses
   ;; (uglify-vectors-new : M7.1 -> M7.2))
   (uglify-vectors
    verify-uglify-vectors)
   (remove-let-regions
    verify-remove-let-regions)
   ;; remove-unused-bindings should go here.
   (flatten-lets
    verify-flatten-lets)
   (hoist-kernels
    verify-hoist-kernels)
   (nanopasses
    (fix-kernel-local-regions : M8 -> M8)
    (generate-kernel-calls : M8 -> M9)
    (remove-recursion : M9 -> M9.3)
    (specialize-string-equality : M9.3 -> M9.3))
   (compile-module
    verify-compile-module)
   (convert-types
    verify-convert-types)))

)

