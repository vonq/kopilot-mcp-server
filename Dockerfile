# --- Builder stage ---
FROM golang:1.21-alpine AS builder

# Install make and any required tools
RUN apk add --no-cache make git

# Set the working directory
WORKDIR /app

# Cache dependencies first
COPY go.mod go.sum ./
RUN go mod download

# Copy the full source code
COPY . .

# Run make (assumes this builds into bin/openapi-mcp)
RUN make

# --- Final stage (minimal image) ---
FROM alpine:latest

# Install CA certs (needed for HTTPS, e.g., downloading files or making API calls)
RUN apk add --no-cache ca-certificates

# Set the working directory
WORKDIR /app

# Copy the binary and any runtime dependencies (like kopilot.yaml)
COPY --from=builder /app/bin/openapi-mcp ./bin/openapi-mcp
COPY --from=builder /app/examples/kopilot.yaml ./examples/kopilot.yaml

# Ensure the binary is executable
RUN chmod +x ./bin/openapi-mcp

# Expose the app port
EXPOSE 8080

# Run the application
CMD ["./bin/openapi-mcp", "--http=:8080", "--api-key=test", "examples/kopilot.yaml"]
