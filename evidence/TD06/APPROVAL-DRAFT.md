# DRAFT - not an approval. To be completed by an authorized reviewer other than the active deployer.
candidate=ghcr.io/pierreboudraa/dockerproject/delivery-api@sha256:f5d77bc62b3e52e3de4e309067bc1785ee577b76693f722e3f0d0850f4d3dc92
source_sha=e33fcfd2c1d220c2c9b2d0fa2f7ce62da1771576
run_url=https://github.com/PierreBoudraa/dockerproject/actions/runs/39036489432
previous=ghcr.io/pierreboudraa/dockerproject/delivery-api@sha256:abb19cde9713bb12ea75a712865c350b427ae49f1cec999c5bdfef6a714da901
reviewer=
decided_at_utc=
decision=
scan_disposition=
rollback_trigger=
reason=

# Facts for the reviewer (verified, not a decision)
# - run_attempt=3 on the same SHA (attempts 1-2 failed at GHCR push: permission_denied: read_package)
# - artifact SHA256SUMS OK; artifact release_sha == source_sha; imagetools digest == candidate
# - scan (Trivy v0.73.0, unfiltered, non-blocking): 0 CRITICAL, 48 HIGH, 99 MEDIUM, 70 LOW, 3 UNKNOWN
# - 4 HIGH have a fix (see fixable-high.txt): CVE-2026-103111 libpcre2-8-0, CVE-2026-84782 openssl/libssl3t64/openssl-provider-legacy
# - workflow scan is NOT filtered to fixed High/Critical and has no policy gate
# - GHCR package access (Manage Actions access, Write) was set in the browser, not versioned
# - pytest proven only by CI validate (Python 3.12); local run BLOCKED
