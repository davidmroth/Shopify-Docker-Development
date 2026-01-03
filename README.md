# Shopify Docker Development

This project provides a Dockerized environment for developing Shopify themes using the Shopify CLI, keeping your local machine clean of dependencies.

## Quick Start

1.  `cp docker-compose.override.yml.example docker-compose.override.yml`
2.  Add your Store ID to `docker-compose.override.yml`
3.  `docker compose run --rm shopify theme pull`
4.  `docker compose up`

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)

## Setup

1.  **Configure Environment**:
    Copy the example override file to create your local configuration:

    ```bash
    cp docker-compose.override.yml.example docker-compose.override.yml
    ```

2.  **Set Store ID**:
    Open `docker-compose.override.yml` and replace `<YOUR_STORE_ID>` with your actual Shopify store URL or ID.

## Usage

All commands are run via `docker compose` (or `docker-compose` v1).

### 1. Authenticate & Pull Theme

First, you need to login and pull your theme.

```bash
docker compose run --rm shopify theme pull
```

_Note: Since the container cannot open a browser, it will print an authentication URL to the terminal. Command-click (Mac) or Ctrl-click (Windows/Linux) the link to authenticate in your browser._

### 2. Start Development Server

Start the local development server. This will sync changes and reload the theme.

```bash
docker compose up
```

The server will run on `http://localhost:8080`.
_To use a different port (e.g., 8001):_

```bash
PORT=8001 docker compose up
```

### 3. Push Changes

To push your changes back to Shopify:

```bash
docker compose run --rm shopify theme push
```

### 4. Logout

To clear credentials:

```bash
docker compose run --rm shopify auth logout
```

## Useful Aliases

To save typing, you can add this alias to your shell profile (`.zshrc` or `.bashrc`):

```bash
alias dc='docker compose'
```

Then you can run: `dc up`, `dc run --rm shopify theme pull`, etc.
