
;; Decentralized Governance Voting Contract (VoteDA)
;; Designed for transparent and immutable proposal management, the contract enables communities to create, vote on, and manage proposals with comprehensive safeguard

;; constants
;; Define error codes for precise error handling
(define-constant ERR-EMPTY-PROPOSAL (err u1))
(define-constant ERR-PROPOSAL-NOT-FOUND (err u2))
(define-constant ERR-PROPOSAL-INACTIVE (err u3))
(define-constant ERR-ALREADY-VOTED (err u4))
(define-constant ERR-PROPOSAL-RETRIEVAL-FAILED (err u5))
(define-constant ERR-UNAUTHORIZED-CLOSURE (err u6))

;; data maps and vars
;; Store proposal details with comprehensive tracking
(define-map proposals 
    { proposal-id: uint }
    {
        title: (string-utf8 100),        ;; Proposal title
        description: (string-utf8 500),  ;; Detailed description
        proposed-by: principal,          ;; Original proposer
        votes-for: uint,                 ;; Positive votes
        votes-against: uint,             ;; Negative votes
        is-active: bool,                 ;; Current proposal status
        created-at: uint                 ;; Timestamp of proposal 
    }
)    

;; Track individual voter participation
(define-map voter-status 
    { proposal-id: uint, voter: principal }
    { has-voted: bool }
)

;; Manage proposal ID generation
(define-data-var next-proposal-id uint u0)

;; private functions
;;

;; public functions
;; Internal utility for proposal validation
(define-private (is-valid-proposal (proposal-id uint))
    (is-some (map-get? proposals { proposal-id: proposal-id }))
)

;; public functions
;; Create a new governance proposal
(define-public (create-proposal 
    (title (string-utf8 100)) 
    (description (string-utf8 500))
)
    (let 
        (
            ;; Generate unique proposal ID
            (proposal-id (var-get next-proposal-id))
        )
        ;; Validate proposal title is not empty
        (asserts! (> (len title) u0) ERR-EMPTY-PROPOSAL)
        
        ;; Store proposal with comprehensive details
        (map-set proposals 
            { proposal-id: proposal-id }
            {
                title: title,
                description: description,
                proposed-by: tx-sender,
                votes-for: u0,
                votes-against: u0,
                is-active: true,
                created-at: block-height
            }
        )
        
        ;; Increment proposal ID for next proposal
        (var-set next-proposal-id (+ proposal-id u1))
        
        (ok proposal-id)
    )
)