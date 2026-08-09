;; extends

; The base go query maps field ACCESS to @property and keys/decls to
; @variable.member - inverted from the theme's TS pattern. These
; appended rules win and normalize: keys/declarations rose, access blue.
(keyed_element
  .
  (literal_element
    (identifier) @property))

(field_declaration
  name: (field_identifier) @property)

(selector_expression
  field: (field_identifier) @variable.member)
