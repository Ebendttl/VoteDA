
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

;; Cast a vote on an existing proposal
(define-public (vote 
    (proposal-id uint) 
    (vote-direction bool)
)
    (let 
        (
            ;; Retrieve proposal details safely
            (proposal (unwrap! 
                (map-get? proposals { proposal-id: proposal-id }) 
                ERR-PROPOSAL-NOT-FOUND
            ))
            
            ;; Check proposal active status
            (is-active (get is-active proposal))
        )
        ;; Validate proposal is still active
        (asserts! is-active ERR-PROPOSAL-INACTIVE)
        
        ;; Prevent duplicate voting
        (asserts! 
            (is-none (map-get? voter-status 
                { proposal-id: proposal-id, voter: tx-sender }
            )) 
            ERR-ALREADY-VOTED
        )
        
        ;; Record voter participation
        (map-set voter-status 
            { proposal-id: proposal-id, voter: tx-sender }
            { has-voted: true }
        )
        
        ;; Update vote counts based on voter's choice
        (if vote-direction
            ;; Increment 'votes-for'
            (map-set proposals 
                { proposal-id: proposal-id }
                (merge proposal { 
                    votes-for: (+ (get votes-for proposal) u1) 
                })
            )
            ;; Increment 'votes-against'
            (map-set proposals 
                { proposal-id: proposal-id }
                (merge proposal { 
                    votes-against: (+ (get votes-against proposal) u1) 
                })
            )
        )
        
        (ok true)
    )
)

;; Retrieve proposal details
(define-read-only (get-proposal (proposal-id uint))
    (map-get? proposals { proposal-id: proposal-id })
)

;; Close an existing proposal
(define-public (close-proposal (proposal-id uint))
    (let 
        (
            ;; Safely retrieve proposal details
            (proposal (unwrap! 
                (map-get? proposals { proposal-id: proposal-id }) 
                ERR-PROPOSAL-RETRIEVAL-FAILED
            ))
        )
        ;; Restrict closure to original proposer
        (asserts! (is-eq tx-sender (get proposed-by proposal)) ERR-UNAUTHORIZED-CLOSURE)
        
        ;; Mark proposal as inactive
        (map-set proposals 
            { proposal-id: proposal-id }
            (merge proposal { is-active: false })
        )
        
        (ok true)
    )
)