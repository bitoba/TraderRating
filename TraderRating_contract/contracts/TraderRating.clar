
;; title: TraderRating
;; version: 1.0.0
;; summary: An address reputation system for trading behavior and performance scoring
;; description: This contract tracks trader performance, ratings, and reputation metrics
;; to provide a decentralized rating system for trading activities on Stacks.

;; traits
;;

;; token definitions
;;

;; constants
;;
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-UNAUTHORIZED (err u100))
(define-constant ERR-NOT-FOUND (err u101))
(define-constant ERR-INVALID-RATING (err u102))
(define-constant ERR-ALREADY-RATED (err u103))
(define-constant ERR-CANNOT-RATE-SELF (err u104))
(define-constant ERR-INSUFFICIENT-TRADES (err u105))

(define-constant MIN-RATING u1)
(define-constant MAX-RATING u100)
(define-constant MIN-TRADES-TO-RATE u5)

;; data vars
;;
(define-data-var total-traders uint u0)
(define-data-var total-ratings uint u0)

;; data maps
;;
;; Main trader profile data
(define-map trader-profiles
  { trader: principal }
  {
    total-trades: uint,
    successful-trades: uint,
    failed-trades: uint,
    total-volume: uint,
    average-rating: uint,
    rating-count: uint,
    reputation-score: uint,
    first-trade-block: uint,
    last-activity-block: uint,
    is-active: bool
  }
)

;; Individual ratings given by one trader to another
(define-map trader-ratings
  { rater: principal, rated: principal }
  {
    rating: uint,
    comment: (string-ascii 256),
    block-height: uint,
    trade-reference: (optional (string-ascii 64))
  }
)

;; Trade records for reputation calculation
(define-map trade-records
  { trader: principal, trade-id: (string-ascii 64) }
  {
    counterparty: principal,
    volume: uint,
    success: bool,
    block-height: uint,
    trade-type: (string-ascii 32)
  }
)

;; Aggregate rating statistics
(define-map rating-stats
  { trader: principal }
  {
    five-star-count: uint,
    four-star-count: uint,
    three-star-count: uint,
    two-star-count: uint,
    one-star-count: uint
  }
)

;; public functions
;;

;; Initialize or update trader profile
(define-public (register-trader)
  (let ((caller tx-sender))
    (match (map-get? trader-profiles { trader: caller })
      existing-profile (ok "Trader already registered")
      (begin
        (map-set trader-profiles
          { trader: caller }
          {
            total-trades: u0,
            successful-trades: u0,
            failed-trades: u0,
            total-volume: u0,
            average-rating: u0,
            rating-count: u0,
            reputation-score: u0,
            first-trade-block: block-height,
            last-activity-block: block-height,
            is-active: true
          }
        )
        (map-set rating-stats
          { trader: caller }
          {
            five-star-count: u0,
            four-star-count: u0,
            three-star-count: u0,
            two-star-count: u0,
            one-star-count: u0
          }
        )
        (var-set total-traders (+ (var-get total-traders) u1))
        (ok "Trader registered successfully")
      )
    )
  )
)

;; Record a trade for reputation tracking
(define-public (record-trade (counterparty principal) (trade-id (string-ascii 64)) (volume uint) (success bool) (trade-type (string-ascii 32)))
  (let (
    (caller tx-sender)
    (current-profile (unwrap! (map-get? trader-profiles { trader: caller }) ERR-NOT-FOUND))
  )
    ;; Update trade record
    (map-set trade-records
      { trader: caller, trade-id: trade-id }
      {
        counterparty: counterparty,
        volume: volume,
        success: success,
        block-height: block-height,
        trade-type: trade-type
      }
    )

    ;; Update trader profile
    (map-set trader-profiles
      { trader: caller }
      {
        total-trades: (+ (get total-trades current-profile) u1),
        successful-trades: (if success
          (+ (get successful-trades current-profile) u1)
          (get successful-trades current-profile)
        ),
        failed-trades: (if (not success)
          (+ (get failed-trades current-profile) u1)
          (get failed-trades current-profile)
        ),
        total-volume: (+ (get total-volume current-profile) volume),
        average-rating: (get average-rating current-profile),
        rating-count: (get rating-count current-profile),
        reputation-score: (calculate-reputation-score
          (+ (get total-trades current-profile) u1)
          (if success (+ (get successful-trades current-profile) u1) (get successful-trades current-profile))
          (+ (get total-volume current-profile) volume)
          (get average-rating current-profile)
        ),
        first-trade-block: (get first-trade-block current-profile),
        last-activity-block: block-height,
        is-active: true
      }
    )
    (ok "Trade recorded successfully")
  )
)

;; Rate a trader
(define-public (rate-trader (rated-trader principal) (rating uint) (comment (string-ascii 256)) (trade-reference (optional (string-ascii 64))))
  (let (
    (caller tx-sender)
    (rated-profile (unwrap! (map-get? trader-profiles { trader: rated-trader }) ERR-NOT-FOUND))
    (caller-profile (unwrap! (map-get? trader-profiles { trader: caller }) ERR-NOT-FOUND))
  )
    ;; Validation checks
    (asserts! (not (is-eq caller rated-trader)) ERR-CANNOT-RATE-SELF)
    (asserts! (and (>= rating MIN-RATING) (<= rating MAX-RATING)) ERR-INVALID-RATING)
    (asserts! (>= (get total-trades caller-profile) MIN-TRADES-TO-RATE) ERR-INSUFFICIENT-TRADES)
    (asserts! (is-none (map-get? trader-ratings { rater: caller, rated: rated-trader })) ERR-ALREADY-RATED)

    ;; Record the rating
    (map-set trader-ratings
      { rater: caller, rated: rated-trader }
      {
        rating: rating,
        comment: comment,
        block-height: block-height,
        trade-reference: trade-reference
      }
    )

    ;; Update rating statistics
    (update-rating-stats rated-trader rating)

    ;; Update rated trader's profile
    (let (
      (new-rating-count (+ (get rating-count rated-profile) u1))
      (new-average (calculate-new-average
        (get average-rating rated-profile)
        (get rating-count rated-profile)
        rating
      ))
    )
      (map-set trader-profiles
        { trader: rated-trader }
        (merge rated-profile {
          average-rating: new-average,
          rating-count: new-rating-count,
          reputation-score: (calculate-reputation-score
            (get total-trades rated-profile)
            (get successful-trades rated-profile)
            (get total-volume rated-profile)
            new-average
          )
        })
      )
    )

    (var-set total-ratings (+ (var-get total-ratings) u1))
    (ok "Rating submitted successfully")
  )
)

;; Deactivate trader profile
(define-public (deactivate-profile)
  (let (
    (caller tx-sender)
    (current-profile (unwrap! (map-get? trader-profiles { trader: caller }) ERR-NOT-FOUND))
  )
    (map-set trader-profiles
      { trader: caller }
      (merge current-profile { is-active: false })
    )
    (ok "Profile deactivated")
  )
)

;; read only functions
;;

;; Get trader profile
(define-read-only (get-trader-profile (trader principal))
  (map-get? trader-profiles { trader: trader })
)

;; Get trader rating statistics
(define-read-only (get-rating-stats (trader principal))
  (map-get? rating-stats { trader: trader })
)

;; Get specific rating between two traders
(define-read-only (get-trader-rating (rater principal) (rated principal))
  (map-get? trader-ratings { rater: rater, rated: rated })
)

;; Get trade record
(define-read-only (get-trade-record (trader principal) (trade-id (string-ascii 64)))
  (map-get? trade-records { trader: trader, trade-id: trade-id })
)

;; Calculate success rate
(define-read-only (get-success-rate (trader principal))
  (match (map-get? trader-profiles { trader: trader })
    profile
    (if (> (get total-trades profile) u0)
      (some (/ (* (get successful-trades profile) u100) (get total-trades profile)))
      (some u0)
    )
    none
  )
)

;; Get contract statistics
(define-read-only (get-contract-stats)
  {
    total-traders: (var-get total-traders),
    total-ratings: (var-get total-ratings)
  }
)

;; Check if trader meets minimum requirements to rate others
(define-read-only (can-rate (trader principal))
  (match (map-get? trader-profiles { trader: trader })
    profile (>= (get total-trades profile) MIN-TRADES-TO-RATE)
    false
  )
)

;; private functions
;;

;; Calculate new average rating
(define-private (calculate-new-average (current-avg uint) (rating-count uint) (new-rating uint))
  (if (is-eq rating-count u0)
    new-rating
    (/ (+ (* current-avg rating-count) new-rating) (+ rating-count u1))
  )
)

;; Calculate reputation score based on multiple factors
(define-private (calculate-reputation-score (total-trades uint) (successful-trades uint) (total-volume uint) (avg-rating uint))
  (let (
    ;; Success rate component (0-40 points)
    (success-component (if (> total-trades u0)
      (/ (* successful-trades u40) total-trades)
      u0
    ))
    ;; Rating component (0-40 points)
    (rating-component (/ (* avg-rating u40) u100))
    ;; Volume component (0-10 points, capped)
    (volume-component (if (> total-volume u100000) u10 (/ total-volume u10000)))
    ;; Experience component (0-10 points, capped at 100 trades)
    (experience-component (if (> total-trades u100) u10 (/ total-trades u10)))
  )
    (+ success-component rating-component volume-component experience-component)
  )
)

;; Update rating statistics for a trader
(define-private (update-rating-stats (trader principal) (rating uint))
  (let ((current-stats (default-to
    { five-star-count: u0, four-star-count: u0, three-star-count: u0, two-star-count: u0, one-star-count: u0 }
    (map-get? rating-stats { trader: trader })
  )))
    (map-set rating-stats { trader: trader }
      (if (>= rating u81)
        (merge current-stats { five-star-count: (+ (get five-star-count current-stats) u1) })
        (if (>= rating u61)
          (merge current-stats { four-star-count: (+ (get four-star-count current-stats) u1) })
          (if (>= rating u41)
            (merge current-stats { three-star-count: (+ (get three-star-count current-stats) u1) })
            (if (>= rating u21)
              (merge current-stats { two-star-count: (+ (get two-star-count current-stats) u1) })
              (merge current-stats { one-star-count: (+ (get one-star-count current-stats) u1) })
            )
          )
        )
      )
    )
  )
)
