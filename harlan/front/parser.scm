(library
  (harlan front parser)
  (export parse-harlan)
  (import
    (rnrs)
    (only (chezscheme) format printf)
    (util verify-grammar)
    (elegant-weapons helpers)
    (elegant-weapons match))

;; parse-harlan takes a syntax tree that a user might actually want
;; to write and converts it into something that's more easily
;; analyzed by the type inferencer and the rest of the compiler.
;; This subsumes the functionality of the previous
;; simplify-literals mini-pass.

;; unnests lets, checks that all variables are in scope, and
;; renames variables to unique identifiers

(define-match parse-harlan
  ((module ,[parse-decl -> decl*] ...)
   `(module . ,decl*)))

(define-match parse-decl
  ((extern ,name . ,[parse-type -> t])
   (guard (symbol? name))
   `(extern ,name . ,t))
  ((fn ,name ,args ,[(parse-stmt '()) -> stmt*] ...)
   `(fn ,name ,args . ,stmt*)))

(define-match parse-type
  (int 'int)
  (u64 'u64)
  (void 'void)
  (str 'str)
  (float 'float)
  ((vector ,[t] ,n)
   (guard (integer? n))
   `(vector ,t ,n))
  (((,[t*] ...) -> ,[t])
   `(,t* -> ,t)))

(define-match (parse-stmt env)
  ((assert ,[(parse-expr env) -> e])
   `(assert ,e))
  ((print ,[(parse-expr env) -> e])
   `(print ,e))
  ((return ,[(parse-expr env) -> e])
   `(return ,e))
  ((if ,[(parse-expr env) -> test]
       ,[(parse-stmt env) -> conseq])
   `(if ,test ,conseq))
  ((if ,[(parse-expr env) -> test]
       ,[(parse-stmt env) -> conseq]
       ,[(parse-stmt env) -> alt])
   `(if ,test ,conseq ,alt))
  ((for (,x ,start ,end) . ,stmt*)
   (guard (symbol? x))
   (let* ((x^ (gensym x))
          (env (cons `(,x . ,x^) env)))
     (let ((start ((parse-expr env) start))
           (end ((parse-expr env) end))
           (stmt* (map (parse-stmt env) stmt*)))
       `(for (,x^ ,start ,end) . ,stmt*))))
  ((while ,[(parse-expr env) -> test]
          ,[(parse-stmt env) -> stmt*] ...)
   `(while ,test . ,stmt*))
  ((set! ,[(parse-expr env) -> x]
     ,[(parse-expr env) -> e])
   `(set! ,x ,e))
  ((vector-set!
     ,[(parse-expr env) -> v]
     ,[(parse-expr env) -> i]
     ,[(parse-expr env) -> e])
   `(vector-set! ,v ,i ,e))
  ((let ((,x* ,[(parse-expr env) -> e*]) ...) . ,body)
   (let* ((x*^ (map gensym x*))
          (env (append (map cons x* x*^) env))
          (body (map (parse-stmt env) body)))
     `(let ((,x*^ ,e*) ...) . ,body)))
  (,[(parse-expr env) -> e] `(do ,e)))

(define-match (parse-expr env)
  (,f (guard (float? f)) `(float ,f))
  (,n (guard (integer? n)) `(num ,n))
  (,x (guard (symbol? x))
    (let ((x^ (assq x env)))
      (unless x^ (error 'parse-expr (format "Free variable ~s" x)))
      `(var ,(cdr x^))))
  (,str (guard (string? str)) `(str ,str))
  ((var ,x)
   (guard (symbol? x))
   (let ((x^ (assq x env)))
     (unless x^ (error 'parse-expr (format "Free variable ~s" x)))
     `(var ,(cdr x^))))
  ((vector ,[e*] ...)
   `(vector . ,e*))
  ((make-vector ,[e])
   `(make-vector ,e))
  ((if ,[test] ,[conseq] ,[alt])
   `(if ,test ,conseq ,alt))
  ((iota ,[e])
   `(iota ,e))
  ((vector-ref ,[v] ,[i])
   `(vector-ref ,v ,i))
  ((length ,[e])
   `(length ,e))
  ((int->float ,[e]) `(int->float ,e))
  ((let ((,x* ,[(parse-expr env) -> e*]) ...) ,stmt* ... ,expr)
   (let* ((x*^ (map gensym x*))
          (env (append (map cons x* x*^) env))
          (stmt* (map (parse-stmt env) stmt*))
          (expr ((parse-expr env) expr)))
     `(let ((,x*^ ,e*) ...) ,@stmt* ,expr)))
  ((kernel ((,x* ,[e*]) ...) ,stmt* ... ,e)
   (let* ((x*^ (map gensym x*))
          (env (append (map cons x* x*^) env)))
     `(kernel ((,x*^ ,e*) ...)
        ,@(map (parse-stmt env) stmt*)
        ,((parse-expr env) e))))
  ((reduce ,op ,[e])
   (guard (reduceop? op))
   `(reduce ,op ,e))
  ((,op ,[lhs] ,[rhs])
   (guard (or (binop? op) (relop? op)))
   `(,op ,lhs ,rhs))
  ((,rator ,[rand*] ...)
   (guard (symbol? rator))
   `(call ,rator . ,rand*)))

;; end library
)
