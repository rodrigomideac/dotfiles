.PHONY: test test-debian test-verbose clean debug-debian shell

# Main test target (run all tests)
test: test-debian
	@echo "✓ All bootstrap tests passed!"

# Test on Debian 12 (quiet - only shows errors)
test-debian:
	@echo "Building Debian 12 container..."
	@docker build -f Dockerfile.debian -t dotfiles-bootstrap-test:debian .. 2>&1 | grep -E "^(ERROR|error:|failed|FAILED)" || true
	@echo "Running tests..."
	@docker run --rm dotfiles-bootstrap-test:debian
	@echo "✓ Debian 12 test passed"

# Test with verbose build output (for debugging)
test-verbose:
	docker build -f Dockerfile.debian -t dotfiles-bootstrap-test:debian ..
	docker run --rm dotfiles-bootstrap-test:debian

# Clean up Docker images
clean:
	@docker rmi -f dotfiles-bootstrap-test:debian 2>/dev/null || true
	@echo "Cleaned up test images"

# Debug target: Run container interactively
debug-debian:
	@docker build -f Dockerfile.debian -t dotfiles-bootstrap-test:debian .. 2>&1 | grep -E "^(ERROR|error:|failed|FAILED)" || true
	docker run --rm -it dotfiles-bootstrap-test:debian /bin/bash

# Shell into completed container (after all tests pass)
shell:
	@docker run --rm -it --entrypoint /bin/zsh dotfiles-bootstrap-test:debian
