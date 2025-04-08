;; Supplier Verification Contract
;; This contract validates legitimate product manufacturers

(define-data-var admin principal tx-sender)

;; Map to store verified suppliers
(define-map verified-suppliers principal bool)

;; Error codes
(define-constant ERR-NOT-AUTHORIZED u100)
(define-constant ERR-ALREADY-VERIFIED u101)
(define-constant ERR-NOT-FOUND u102)

;; Check if caller is admin
(define-private (is-admin)
  (is-eq tx-sender (var-get admin)))

;; Add a new verified supplier
(define-public (add-supplier (supplier-address principal))
  (begin
    (asserts! (is-admin) (err ERR-NOT-AUTHORIZED))
    (asserts! (not (default-to false (map-get? verified-suppliers supplier-address)))
              (err ERR-ALREADY-VERIFIED))
    (ok (map-set verified-suppliers supplier-address true))))

;; Remove a supplier from verified list
(define-public (remove-supplier (supplier-address principal))
  (begin
    (asserts! (is-admin) (err ERR-NOT-AUTHORIZED))
    (asserts! (default-to false (map-get? verified-suppliers supplier-address))
              (err ERR-NOT-FOUND))
    (ok (map-set verified-suppliers supplier-address false))))

;; Check if a supplier is verified
(define-read-only (is-verified-supplier (supplier-address principal))
  (default-to false (map-get? verified-suppliers supplier-address)))

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-admin) (err ERR-NOT-AUTHORIZED))
    (ok (var-set admin new-admin))))
