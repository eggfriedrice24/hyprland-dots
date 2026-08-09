;; extends

; Key-ish constructs as @property (rose) to match the theme's
; declarations-rose / access-blue pattern from TS.
; Keyword arguments: FastAPI(title=..., version=...)
(keyword_argument
  name: (identifier) @property)

; Class attribute declarations: status: str (pydantic, dataclasses)
(class_definition
  body: (block
    (expression_statement
      (assignment
        left: (identifier) @property))))
