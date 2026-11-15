#!/usr/bin/env bash
# Stage 8: One-off migrations (install/migrations/), run once the stages above have converged the machine

info "=== Stage 8: Migrations ==="

# A failed migration stays pending and does not stop the install: stage 9 reports it and
# install.sh exits 3, so a caller can tell the run was not clean.
if migrations_run; then
    success "=== Stage 8: Complete ==="
else
    warn "=== Stage 8: A migration is still pending ==="
fi
