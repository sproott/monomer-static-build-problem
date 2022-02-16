FROM utdemir/ghc-musl:v23-ghc902 AS builder

# Install dependencies
RUN apk upgrade --no-cache && \
  apk add --no-cache \
  glew-dev \
  sdl2-dev

# Install ghcup
RUN echo "Downloading and installing ghcup" && \
  GHCUP_VERSION="0.1.17.4" && \
  wget -O /usr/bin/ghcup "https://downloads.haskell.org/~ghcup/${GHCUP_VERSION}/x86_64-linux-ghcup-${GHCUP_VERSION}" && \
  chmod +x /usr/bin/ghcup

# Install Stack
RUN echo "Installing Stack" && \ 
  ghcup install stack

# Add ghcup bin directory to PATH
ENV PATH="/root/.cabal/bin:/root/.ghcup/bin:$PATH"

# Set Stack to use global GHC
RUN stack config set system-ghc --global true

# -----------------------------------------------------------------------

FROM builder AS dependencies

WORKDIR /opt/build

COPY package.yaml stack.yaml stack.yaml.lock ./
RUN stack build --dependencies-only

# -----------------------------------------------------------------------

FROM builder as build

WORKDIR /opt/build

# Copy built dependencies
COPY --from=dependencies /root/.stack /root/.stack

# Copy sources
COPY . ./

# Build executable
RUN stack --local-bin-path /sbin install \
  --ghc-options=-fPIC
