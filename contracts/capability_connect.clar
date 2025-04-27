;; CapabilityConnect Framework

;; ========== QUERY FUNCTIONS ==========


;; Retrieve position announcement details from registry
(define-read-only (query-position-details (announcement-id principal))
    (match (map-get? position-announcements announcement-id)
        position-data (ok position-data)
        NOT-FOUND-ERROR
    )
)

;; Retrieve organizational entity information from registry
(define-read-only (query-organization-record (identity-key principal))
    (match (map-get? organization-registry identity-key)
        profile-data (ok profile-data)
        NOT-FOUND-ERROR
    )
)

;; ========== STORAGE ARCHITECTURE ==========

;; Repository for available position announcements
(define-map position-announcements
    principal
    {
        title: (string-ascii 100),
        description: (string-ascii 500),
        author: principal,
        location: (string-ascii 100),
        requirements: (list 10 (string-ascii 50))
    }
)

;; Repository for individual contributor records
(define-map contributor-registry
    principal
    {
        identity: (string-ascii 100),
        capabilities: (list 10 (string-ascii 50)),
        location: (string-ascii 100),
        biography: (string-ascii 500)
    }
)

;; Repository for organizational entity records
(define-map organization-registry
    principal
    {
        entity-title: (string-ascii 100),
        industry: (string-ascii 50),
        location: (string-ascii 100)
    }
)


;; ========== RESPONSE CODES AND ERROR HANDLING ==========

;; Standard error response definitions for robust operation
(define-constant NOT-FOUND-ERROR (err u404))
(define-constant CONFLICT-ERROR (err u409))
(define-constant INVALID-CAPABILITIES-ERROR (err u400))
(define-constant INVALID-LOCATION-ERROR (err u401))
(define-constant INVALID-BIOGRAPHY-ERROR (err u402))
(define-constant INVALID-POSITION-ERROR (err u403))
(define-constant REGISTRY-ENTRY-MISSING (err u404))

;; ========== ORGANIZATION MANAGEMENT FUNCTIONS ==========

;; Establish new organizational presence in registry
(define-public (register-organization 
    (entity-title (string-ascii 100))
    (industry (string-ascii 50))
    (location (string-ascii 100)))
    (let
        (
            (registry-owner tx-sender)
            (existing-entry (map-get? organization-registry registry-owner))
        )
        ;; Verify no duplicate registration attempt
        (if (is-none existing-entry)
            (begin
                ;; Validate all mandatory organization fields
                (if (or (is-eq entity-title "")
                        (is-eq industry "")
                        (is-eq location ""))
                    (err INVALID-LOCATION-ERROR)
                    (begin
                        ;; Document the organization in registry
                        (map-set organization-registry registry-owner
                            {
                                entity-title: entity-title,
                                industry: industry,
                                location: location
                            }
                        )
                        (ok "Organization successfully registered in network.")
                    )
                )
            )
            (err CONFLICT-ERROR)
        )
    )
)

;; Modify existing organizational profile information
(define-public (amend-organization-details 
    (entity-title (string-ascii 100))
    (industry (string-ascii 50))
    (location (string-ascii 100)))
    (let
        (
            (registry-owner tx-sender)
            (existing-entry (map-get? organization-registry registry-owner))
        )
        ;; Confirm organization record exists before modification
        (if (is-some existing-entry)
            (begin
                ;; Validate all mandatory organization fields
                (if (or (is-eq entity-title "")
                        (is-eq industry "")
                        (is-eq location ""))
                    (err INVALID-LOCATION-ERROR)
                    (begin
                        ;; Update organization record with new information
                        (map-set organization-registry registry-owner
                            {
                                entity-title: entity-title,
                                industry: industry,
                                location: location
                            }
                        )
                        (ok "Organization details successfully updated.")
                    )
                )
            )
            (err REGISTRY-ENTRY-MISSING)
        )
    )
)

;; Completely remove organizational presence from registry
(define-public (deregister-organization)
    (let
        (
            (registry-owner tx-sender)
            (existing-entry (map-get? organization-registry registry-owner))
        )
        ;; Confirm organization record exists before removal
        (if (is-some existing-entry)
            (begin
                ;; Purge organization record from system
                (map-delete organization-registry registry-owner)
                (ok "Organization successfully removed from registry.")
            )
            (err REGISTRY-ENTRY-MISSING)
        )
    )
)

;; ========== POSITION ANNOUNCEMENT FUNCTIONS ==========

;; Publish new open position announcement
(define-public (announce-position 
    (title (string-ascii 100))
    (description (string-ascii 500))
    (location (string-ascii 100))
    (requirements (list 10 (string-ascii 50))))
    (let
        (
            (registry-owner tx-sender)
            (existing-announcement (map-get? position-announcements registry-owner))
        )
        ;; Prevent duplicate position announcements
        (if (is-none existing-announcement)
            (begin
                ;; Enforce complete position announcement requirements
                (if (or (is-eq title "")
                        (is-eq description "")
                        (is-eq location "")
                        (is-eq (len requirements) u0))
                    (err INVALID-POSITION-ERROR)
                    (begin
                        ;; Record position announcement in registry
                        (map-set position-announcements registry-owner
                            {
                                title: title,
                                description: description,
                                author: registry-owner,
                                location: location,
                                requirements: requirements
                            }
                        )
                        (ok "Position announcement successfully published.")
                    )
                )
            )
            (err CONFLICT-ERROR)
        )
    )
)

;; Update content of existing position announcement
(define-public (revise-position-announcement 
    (title (string-ascii 100))
    (description (string-ascii 500))
    (location (string-ascii 100))
    (requirements (list 10 (string-ascii 50))))
    (let
        (
            (registry-owner tx-sender)
            (existing-announcement (map-get? position-announcements registry-owner))
        )
        ;; Verify announcement exists before modification
        (if (is-some existing-announcement)
            (begin
                ;; Validate all required announcement fields
                (if (or (is-eq title "")
                        (is-eq description "")
                        (is-eq location "")
                        (is-eq (len requirements) u0))
                    (err INVALID-POSITION-ERROR)
                    (begin
                        ;; Update position announcement with revised information
                        (map-set position-announcements registry-owner
                            {
                                title: title,
                                description: description,
                                author: registry-owner,
                                location: location,
                                requirements: requirements
                            }
                        )
                        (ok "Position announcement successfully updated.")
                    )
                )
            )
            (err REGISTRY-ENTRY-MISSING)
        )
    )
)

;; Remove position announcement from public registry
(define-public (withdraw-position-announcement)
    (let
        (
            (registry-owner tx-sender)
            (existing-announcement (map-get? position-announcements registry-owner))
        )
        ;; Confirm announcement exists before removal
        (if (is-some existing-announcement)
            (begin
                ;; Remove position announcement from system
                (map-delete position-announcements registry-owner)
                (ok "Position announcement successfully withdrawn.")
            )
            (err REGISTRY-ENTRY-MISSING)
        )
    )
)

;; ========== CONTRIBUTOR MANAGEMENT FUNCTIONS ==========

;; Establish new individual contributor profile
(define-public (register-contributor 
    (identity (string-ascii 100))
    (capabilities (list 10 (string-ascii 50)))
    (location (string-ascii 100))
    (biography (string-ascii 500)))
    (let
        (
            (registry-owner tx-sender)
            (existing-entry (map-get? contributor-registry registry-owner))
        )
        ;; Prevent duplicate contributor registration
        (if (is-none existing-entry)
            (begin
                ;; Validate all mandatory contributor fields
                (if (or (is-eq identity "")
                        (is-eq location "")
                        (is-eq (len capabilities) u0)
                        (is-eq biography ""))
                    (err INVALID-BIOGRAPHY-ERROR)
                    (begin
                        ;; Document contributor in registry
                        (map-set contributor-registry registry-owner
                            {
                                identity: identity,
                                capabilities: capabilities,
                                location: location,
                                biography: biography
                            }
                        )
                        (ok "Contributor profile successfully established.")
                    )
                )
            )
            (err CONFLICT-ERROR)
        )
    )
)

;; Update existing contributor profile information
(define-public (amend-contributor-profile 
    (identity (string-ascii 100))
    (capabilities (list 10 (string-ascii 50)))
    (location (string-ascii 100))
    (biography (string-ascii 500)))
    (let
        (
            (registry-owner tx-sender)
            (existing-entry (map-get? contributor-registry registry-owner))
        )
        ;; Confirm contributor record exists before modification
        (if (is-some existing-entry)
            (begin
                ;; Validate all mandatory contributor fields
                (if (or (is-eq identity "")
                        (is-eq location "")
                        (is-eq (len capabilities) u0)
                        (is-eq biography ""))
                    (err INVALID-BIOGRAPHY-ERROR)
                    (begin
                        ;; Update contributor record with new information
                        (map-set contributor-registry registry-owner
                            {
                                identity: identity,
                                capabilities: capabilities,
                                location: location,
                                biography: biography
                            }
                        )
                        (ok "Contributor profile successfully updated.")
                    )
                )
            )
            (err REGISTRY-ENTRY-MISSING)
        )
    )
)

;; Remove contributor presence completely from registry
(define-public (deregister-contributor)
    (let
        (
            (registry-owner tx-sender)
            (existing-entry (map-get? contributor-registry registry-owner))
        )
        ;; Confirm contributor record exists before removal
        (if (is-some existing-entry)
            (begin
                ;; Purge contributor record from system
                (map-delete contributor-registry registry-owner)
                (ok "Contributor profile successfully removed from registry.")
            )
            (err REGISTRY-ENTRY-MISSING)
        )
    )
)

