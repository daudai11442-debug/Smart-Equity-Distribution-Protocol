(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-already-exists (err u103))
(define-constant err-invalid-input (err u104))
(define-constant err-distribution-complete (err u105))
(define-constant err-insufficient-balance (err u106))
(define-constant err-not-stakeholder (err u107))
(define-constant err-vesting-locked (err u108))

(define-data-var total-equity uint u1000000)
(define-data-var distributed-equity uint u0)
(define-data-var next-pool-id uint u1)
(define-data-var next-distribution-id uint u1)

(define-map equity-pools uint {
  name: (string-ascii 50),
  total-amount: uint,
  distributed-amount: uint,
  creator: principal,
  is-active: bool,
  created-at: uint,
  vesting-period: uint,
  cliff-period: uint
})

(define-map stakeholders principal {
  total-equity: uint,
  vested-equity: uint,
  claimed-equity: uint,
  last-claim: uint,
  vesting-start: uint,
  is-active: bool
})

(define-map distributions uint {
  pool-id: uint,
  recipient: principal,
  amount: uint,
  vesting-schedule: uint,
  cliff-period: uint,
  start-block: uint,
  claimed-amount: uint,
  is-completed: bool
})

(define-map pool-members {pool-id: uint, member: principal} {
  allocated-amount: uint,
  claimed-amount: uint,
  join-date: uint,
  is-active: bool
})

(define-map equity-transfers uint {
  from: principal,
  to: principal,
  amount: uint,
  timestamp: uint,
  transfer-type: (string-ascii 20)
})

(define-data-var next-transfer-id uint u1)

(define-read-only (get-equity-pool (pool-id uint))
  (map-get? equity-pools pool-id))

(define-read-only (get-stakeholder (user principal))
  (map-get? stakeholders user))

(define-read-only (get-distribution (dist-id uint))
  (map-get? distributions dist-id))

(define-read-only (get-pool-member (pool-id uint) (member principal))
  (map-get? pool-members {pool-id: pool-id, member: member}))

(define-read-only (get-transfer (transfer-id uint))
  (map-get? equity-transfers transfer-id))

(define-read-only (get-total-equity)
  (var-get total-equity))

(define-read-only (get-distributed-equity)
  (var-get distributed-equity))

(define-read-only (get-available-equity)
  (- (var-get total-equity) (var-get distributed-equity)))

(define-read-only (get-vested-amount (user principal))
  (let ((stakeholder (map-get? stakeholders user)))
    (match stakeholder
      holder (calculate-vested-amount 
              (get vesting-start holder)
              (get total-equity holder)
              stacks-block-height)
      u0)))

(define-read-only (calculate-vested-amount (start-block uint) (total-amount uint) (current-block uint))
  (let ((blocks-passed (- current-block start-block)))
    (if (<= blocks-passed u0)
      u0
      (let ((vested (/ (* total-amount blocks-passed) u52560)))
        (if (> vested total-amount) total-amount vested)))))

(define-public (create-equity-pool (name (string-ascii 50)) (amount uint) (vesting-period uint) (cliff-period uint))
  (let ((pool-id (var-get next-pool-id))
        (current-block stacks-block-height))
    (asserts! (> amount u0) err-invalid-input)
    (asserts! (<= amount (get-available-equity)) err-insufficient-balance)
    (asserts! (> vesting-period u0) err-invalid-input)
    
    (map-set equity-pools pool-id {
      name: name,
      total-amount: amount,
      distributed-amount: u0,
      creator: tx-sender,
      is-active: true,
      created-at: current-block,
      vesting-period: vesting-period,
      cliff-period: cliff-period
    })
    
    (var-set distributed-equity (+ (var-get distributed-equity) amount))
    (var-set next-pool-id (+ pool-id u1))
    (ok pool-id)))

(define-public (add-stakeholder (user principal) (equity-amount uint) (vesting-start-block uint))
  (let ((current-block stacks-block-height))
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (> equity-amount u0) err-invalid-input)
    (asserts! (is-none (map-get? stakeholders user)) err-already-exists)
    
    (map-set stakeholders user {
      total-equity: equity-amount,
      vested-equity: u0,
      claimed-equity: u0,
      last-claim: current-block,
      vesting-start: vesting-start-block,
      is-active: true
    })
    
    (ok true)))

(define-public (distribute-to-stakeholder (pool-id uint) (recipient principal) (amount uint))
  (let ((pool (unwrap! (map-get? equity-pools pool-id) err-not-found))
        (dist-id (var-get next-distribution-id))
        (current-block stacks-block-height))
    
    (asserts! (is-eq tx-sender (get creator pool)) err-unauthorized)
    (asserts! (get is-active pool) err-distribution-complete)
    (asserts! (> amount u0) err-invalid-input)
    (asserts! (<= (+ (get distributed-amount pool) amount) (get total-amount pool)) err-insufficient-balance)
    
    (map-set distributions dist-id {
      pool-id: pool-id,
      recipient: recipient,
      amount: amount,
      vesting-schedule: (get vesting-period pool),
      cliff-period: (get cliff-period pool),
      start-block: current-block,
      claimed-amount: u0,
      is-completed: false
    })
    
    (map-set equity-pools pool-id (merge pool {
      distributed-amount: (+ (get distributed-amount pool) amount)
    }))
    
    (match (map-get? stakeholders recipient)
      existing-holder (map-set stakeholders recipient (merge existing-holder {
        total-equity: (+ (get total-equity existing-holder) amount),
        vesting-start: current-block
      }))
      (map-set stakeholders recipient {
        total-equity: amount,
        vested-equity: u0,
        claimed-equity: u0,
        last-claim: current-block,
        vesting-start: current-block,
        is-active: true
      }))
    
    (var-set next-distribution-id (+ dist-id u1))
    (ok dist-id)))

(define-public (claim-vested-equity)
  (let ((stakeholder (unwrap! (map-get? stakeholders tx-sender) err-not-stakeholder))
        (current-block stacks-block-height)
        (vested-amount (get-vested-amount tx-sender))
        (claimable-amount (- vested-amount (get claimed-equity stakeholder))))
    
    (asserts! (get is-active stakeholder) err-unauthorized)
    (asserts! (> claimable-amount u0) err-vesting-locked)
    
    (map-set stakeholders tx-sender (merge stakeholder {
      claimed-equity: (+ (get claimed-equity stakeholder) claimable-amount),
      last-claim: current-block
    }))
    
    (record-transfer tx-sender tx-sender claimable-amount "claim")
    (ok claimable-amount)))

(define-public (transfer-equity (to principal) (amount uint))
  (let ((sender-stakeholder (unwrap! (map-get? stakeholders tx-sender) err-not-stakeholder))
        (available-equity (- (get claimed-equity sender-stakeholder) u0))
        (current-block stacks-block-height))
    
    (asserts! (>= available-equity amount) err-insufficient-balance)
    (asserts! (> amount u0) err-invalid-input)
    
    (map-set stakeholders tx-sender (merge sender-stakeholder {
      claimed-equity: (- (get claimed-equity sender-stakeholder) amount)
    }))
    
    (match (map-get? stakeholders to)
      existing-holder (map-set stakeholders to (merge existing-holder {
        claimed-equity: (+ (get claimed-equity existing-holder) amount)
      }))
      (map-set stakeholders to {
        total-equity: amount,
        vested-equity: amount,
        claimed-equity: amount,
        last-claim: current-block,
        vesting-start: current-block,
        is-active: true
      }))
    
    (record-transfer tx-sender to amount "transfer")
    (ok true)))

(define-public (join-pool (pool-id uint))
  (let ((pool (unwrap! (map-get? equity-pools pool-id) err-not-found))
        (current-block stacks-block-height))
    
    (asserts! (get is-active pool) err-distribution-complete)
    (asserts! (is-none (map-get? pool-members {pool-id: pool-id, member: tx-sender})) err-already-exists)
    
    (map-set pool-members {pool-id: pool-id, member: tx-sender} {
      allocated-amount: u0,
      claimed-amount: u0,
      join-date: current-block,
      is-active: true
    })
    
    (ok true)))

(define-public (allocate-to-member (pool-id uint) (member principal) (amount uint))
  (let ((pool (unwrap! (map-get? equity-pools pool-id) err-not-found))
        (member-info (unwrap! (map-get? pool-members {pool-id: pool-id, member: member}) err-not-found)))
    
    (asserts! (is-eq tx-sender (get creator pool)) err-unauthorized)
    (asserts! (get is-active pool) err-distribution-complete)
    (asserts! (get is-active member-info) err-unauthorized)
    (asserts! (> amount u0) err-invalid-input)
    
    (map-set pool-members {pool-id: pool-id, member: member} (merge member-info {
      allocated-amount: (+ (get allocated-amount member-info) amount)
    }))
    
    (ok true)))

(define-public (deactivate-pool (pool-id uint))
  (let ((pool (unwrap! (map-get? equity-pools pool-id) err-not-found)))
    (asserts! (is-eq tx-sender (get creator pool)) err-unauthorized)
    
    (map-set equity-pools pool-id (merge pool {
      is-active: false
    }))
    
    (ok true)))

(define-public (update-total-equity (new-total uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (>= new-total (var-get distributed-equity)) err-invalid-input)
    
    (var-set total-equity new-total)
    (ok true)))

(define-private (record-transfer (from principal) (to principal) (amount uint) (transfer-type (string-ascii 20)))
  (let ((transfer-id (var-get next-transfer-id)))
    (map-set equity-transfers transfer-id {
      from: from,
      to: to,
      amount: amount,
      timestamp: stacks-block-height,
      transfer-type: transfer-type
    })
    
    (var-set next-transfer-id (+ transfer-id u1))
    transfer-id))

(define-public (get-pool-stats (pool-id uint))
  (let ((pool (unwrap! (map-get? equity-pools pool-id) err-not-found)))
    (ok {
      remaining-amount: (- (get total-amount pool) (get distributed-amount pool)),
      distribution-percentage: (/ (* (get distributed-amount pool) u100) (get total-amount pool))
    })))
