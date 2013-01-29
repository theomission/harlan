(library
  (harlan middle make-kernel-dimensions-explicit)
  (export make-kernel-dimensions-explicit)
  (import
   (rnrs)
   (harlan helpers)
   (except (elegant-weapons helpers) ident?)
   (cKanren mk))

  (define-match make-kernel-dimensions-explicit
    ((module ,[Decl -> decl*] ...)
     `(module ,decl* ...)))
    
  (define-match Decl
    ((fn ,name ,args ,t ,[Stmt -> stmt])
     `(fn ,name ,args ,t ,stmt))
    ((extern ,name ,args -> ,rtype)
     `(extern ,name ,args -> ,rtype)))

  (define-match Stmt
    ((let ((,x* ,t* ,[Expr -> e*]) ...) ,[body])
     `(let ((,x* ,t* ,e*) ...) ,body))
    ((let-region (,r ...) ,[body]) `(let-region (,r ...) ,body))
    ((set! ,[Expr -> lhs] ,[Expr -> rhs])
     `(set! ,lhs ,rhs))
    ((if ,[Expr -> test] ,[conseq] ,[altern])
     `(if ,test ,conseq ,altern))
    ((if ,[Expr -> test] ,[conseq])
     `(if ,test ,conseq))
    ((while ,[Expr -> test] ,[body])
     `(while ,test ,body))
    ((for (,x ,[Expr -> start]
              ,[Expr -> stop]
              ,[Expr -> step])
          ,[body])
     `(for (,x ,start ,stop ,step) ,body))
    ((begin ,[stmt*] ...)
     `(begin . ,stmt*))
    ((print ,[Expr -> e] ...)
     `(print . ,e))
    ((assert ,[Expr -> e])
     `(assert ,e))
    ((return) `(return))
    ((return ,[Expr -> e])
     `(return ,e))
    ((error ,x) `(error ,x))
    ((do ,[Expr -> e])
     `(do ,e)))

  (define-match Expr
    ((,t ,v) (guard (scalar-type? t)) `(,t ,v))
    ((var ,t ,x) `(var ,t ,x))
    ((int->float ,[e]) `(int->float ,e))
    ((make-vector ,t ,r ,[e])
     `(make-vector ,t ,r ,e))
    ((vector ,t ,r ,[e] ...)
     `(vector ,t ,r . ,e))
    ((vector-ref ,t ,[v] ,[i])
     `(vector-ref ,t ,v ,i))
    ((length ,[e])
     `(length ,e))
    ((call ,[f] ,[args] ...)
     `(call ,f . ,args))
    ((if ,[t] ,[c] ,[a]) `(if ,t ,c ,a))
    ((if ,[t] ,[c]) `(if ,t ,c))
    ((kernel ,kt ,r (((,x ,xt) (,[e] ,et)) ...) ,[body])
     `(kernel ,kt ,r 1 (((,x ,xt) (,e ,et) 0) ...) ,body))
    ((iota ,[e])
     `(kernel (vec int) ,(var 'region) 1 (,e) ()
              (call (c-expr ((int) -> int)
                            get_global_id)
                    (int 0))))
    ((iota-r ,r ,[e])
     `(kernel (vec ,r int) ,r 1 (,e) ()
              (call (c-expr ((int) -> int)
                            get_global_id)
                    (int 0))))
    ((let ((,x* ,t* ,[e*]) ...) ,[e])
     `(let ((,x* ,t* ,e*) ...) ,e))
    ((begin ,[Stmt -> s*] ... ,[e])
     `(begin ,s* ... ,e))
    ((,op ,[lhs] ,[rhs])
     (guard (or (relop? op) (binop? op)))
     `(,op ,lhs ,rhs)))

  ;; end library
  )
