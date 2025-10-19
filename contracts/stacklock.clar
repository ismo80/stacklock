
;; Error codes
(define-constant ERR_INVALID_AMOUNT u400)
(define-constant ERR_INVALID_UNLOCK_BLOCK u401)
(define-constant ERR_NOT_RECIPIENT u402)
(define-constant ERR_ALREADY_CLAIMED u403)
(define-constant ERR_NOT_UNLOCKED u404)
(define-constant ERR_NOT_FOUND u405)
(define-constant ERR_NOT_SENDER u406)
(define-constant ERR_NOT_CANCELABLE u407)
(define-constant ERR_TOO_LATE_TO_CANCEL u408)

(define-data-var deposit-count uint u0)

(define-map deposits
  uint
  {
    sender: principal,
    recipient: principal,
    amount: uint,
    unlock-block: uint,
    cancelable: bool,
    claimed: bool
  }
)

;; -------- Deposit STX with time lock --------
(define-public (lock-funds (recipient principal) (unlock-block uint) (cancelable bool) (amount uint))
  (let (
    (deposit-id (var-get deposit-count))
    (current-block stacks-block-height)
  )
    (begin
      (asserts! (> amount u0) (err ERR_INVALID_AMOUNT))
      (asserts! (> unlock-block current-block) (err ERR_INVALID_UNLOCK_BLOCK))

      ;; Transfer STX from sender to contract
      (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))

      ;; Save deposit
      (map-set deposits deposit-id {
        sender: tx-sender,
        recipient: recipient,
        amount: amount,
        unlock-block: unlock-block,
        cancelable: cancelable,
        claimed: false
      })

      (var-set deposit-count (+ deposit-id u1))
      (ok deposit-id)
    )
  )
)

;; -------- Withdraw funds after unlock --------
(define-public (withdraw (deposit-id uint))
  (let (
    (data (map-get? deposits deposit-id))
  )
    (match data
      deposit
      (begin
        (asserts! (is-eq tx-sender (get recipient deposit)) (err ERR_NOT_RECIPIENT))
        (asserts! (is-eq (get claimed deposit) false) (err ERR_ALREADY_CLAIMED))
        (asserts! (>= stacks-block-height (get unlock-block deposit)) (err ERR_NOT_UNLOCKED))

        ;; Transfer STX from contract to recipient
        (try! (as-contract (stx-transfer? (get amount deposit) tx-sender (get recipient deposit))))

        ;; Mark as claimed
        (map-set deposits deposit-id (merge deposit {claimed: true}))
        (ok "Withdrawn successfully")
      )
      (err ERR_NOT_FOUND)
    )
  )
)

;; -------- Cancel deposit if allowed --------
(define-public (cancel (deposit-id uint))
  (let (
    (data (map-get? deposits deposit-id))
  )
    (match data
      deposit
      (begin
        (asserts! (is-eq tx-sender (get sender deposit)) (err ERR_NOT_SENDER))
        (asserts! (get cancelable deposit) (err ERR_NOT_CANCELABLE))
        (asserts! (is-eq (get claimed deposit) false) (err ERR_ALREADY_CLAIMED))
        (asserts! (< stacks-block-height (get unlock-block deposit)) (err ERR_TOO_LATE_TO_CANCEL))

        ;; Refund STX from contract to sender
        (try! (as-contract (stx-transfer? (get amount deposit) tx-sender (get sender deposit))))

        ;; Mark as claimed to prevent reuse
        (map-set deposits deposit-id (merge deposit {claimed: true}))
        (ok "Deposit canceled and refunded")
      )
      (err ERR_NOT_FOUND)
    )
  )
)

;; -------- View a deposit --------
(define-read-only (get-deposit (deposit-id uint))
  (let ((data (map-get? deposits deposit-id)))
    (match data
      deposit (ok deposit)
      (err ERR_NOT_FOUND)
    )
  )
)
