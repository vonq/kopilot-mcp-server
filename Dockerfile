# --- Builder stage ---
FROM golang:1.22.0-alpine AS builder

RUN apk add --no-cache make git

ENV GOTOOLCHAIN=local

WORKDIR /app

COPY . .

RUN go mod download -x

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
