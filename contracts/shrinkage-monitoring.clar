;; Shrinkage Monitoring Contract
;; This contract identifies inventory discrepancies

(define-data-var admin principal tx-sender)

;; Shrinkage report data structure
(define-map shrinkage-reports
  {
    report-id: uint
  }
  {
    product-id: (string-ascii 32),
    location-id: (string-ascii 32),
    expected-quantity: uint,
    actual-quantity: uint,
    timestamp: uint,
    resolved: bool
  })

;; Counter for report IDs
(define-data-var report-counter uint u0)

;; Error codes
(define-constant ERR-NOT-AUTHORIZED u100)
(define-constant ERR-REPORT-NOT-FOUND u101)

;; Check if caller is admin
(define-private (is-admin)
  (is-eq tx-sender (var-get admin)))

;; Create a new shrinkage report
(define-public (report-shrinkage
                (product-id (string-ascii 32))
                (location-id (string-ascii 32))
                (expected-quantity uint)
                (actual-quantity uint))
  (let ((report-id (var-get report-counter)))
    (asserts! (is-admin) (err ERR-NOT-AUTHORIZED))

    ;; Increment report counter
    (var-set report-counter (+ report-id u1))

    ;; Create new report
    (ok (map-set shrinkage-reports
                { report-id: report-id }
                {
                  product-id: product-id,
                  location-id: location-id,
                  expected-quantity: expected-quantity,
                  actual-quantity: actual-quantity,
                  timestamp: block-height,
                  resolved: false
                }))))

;; Mark a shrinkage report as resolved
(define-public (resolve-shrinkage-report (report-id uint))
  (let ((report (map-get? shrinkage-reports { report-id: report-id })))
    (asserts! (is-admin) (err ERR-NOT-AUTHORIZED))
    (asserts! (is-some report) (err ERR-REPORT-NOT-FOUND))

    (ok (map-set shrinkage-reports
                { report-id: report-id }
                (merge (unwrap-panic report) { resolved: true })))))

;; Get shrinkage report details
(define-read-only (get-shrinkage-report (report-id uint))
  (map-get? shrinkage-reports { report-id: report-id }))

;; Calculate shrinkage percentage
(define-read-only (calculate-shrinkage-percentage (report-id uint))
  (let ((report (map-get? shrinkage-reports { report-id: report-id })))
    (if (is-some report)
        (let ((report-data (unwrap-panic report)))
          (if (> (get expected-quantity report-data) u0)
              (/ (* (- (get expected-quantity report-data)
                        (get actual-quantity report-data))
                     u100)
                 (get expected-quantity report-data))
              u0))
        u0)))

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-admin) (err ERR-NOT-AUTHORIZED))
    (ok (var-set admin new-admin))))
