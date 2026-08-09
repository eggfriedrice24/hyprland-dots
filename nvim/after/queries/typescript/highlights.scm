;; extends

; Property declarations as @property so treesitter matches the LSP
; semantic-token split (declarations rose, access blue) instantly,
; before ts_ls tokens arrive.
(pair
  key: (property_identifier) @property)

(property_signature
  name: (property_identifier) @property)

(public_field_definition
  name: (property_identifier) @property)
