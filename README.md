# Issued

Issued is a Rails 8 app for a Hack Club-style flow where users can design apparel with code, track effort through Hackatime, RSVP for an event/launch, and submit orders.

The app includes:

- Hack Club OAuth sign-in
- RSVP flow with open/closed state toggles
- User dashboard with design and order pipeline visibility
- Design editor flow with optional Hackatime project linking
- Admin area for user/product/order management plus RSVP CSV import

## Table of Contents

- [What Is Issued](#what-is-issued)
- [Current Feature Set](#current-feature-set)
- [Tech Stack](#tech-stack)
- [Architecture Overview](#architecture-overview)
- [Data Model Snapshot](#data-model-snapshot)
- [Local Setup](#local-setup)
- [Environment Variables](#environment-variables)
- [Authentication (Hack Club OAuth)](#authentication-hack-club-oauth)
- [Developer Workflow](#developer-workflow)
- [Testing, Linting, and Security](#testing-linting-and-security)
- [Admin Operations](#admin-operations)
- [Deployment](#deployment)
- [Project Structure](#project-structure)
- [Known Gaps / Notes](#known-gaps--notes)

## What Is Issued

YS: Make Designs with code either using hackatime or the integrated svg editor
WS: Get custom clothes made with your designs

From an admin perspective:

- Manage users and roles.
- Manage products.
- View/manage orders (some order admin actions are currently stubs).
- Import RSVP records via CSV.

## Current Feature Set

### Public Pages

- Home page (`/`)
- About page (`/about`)
- FAQ page (`/faq`)
- RSVP page (`/rsvp`)
- RSVP count page (`/rsvps`)
- Dynamic RSVP OG image (`/rsvps/og-image.svg`)

### Auth

- OAuth login entry (`/login`)
- OmniAuth callback (`/auth/:provider/callback`)
- Auth failure handler (`/auth/failure`)
- Logout (`/logout`)

### User Area

- Dashboard (`/dashboard`)
- Designs CRUD-ish flow (`/designs`, plus editor routes)
- Orders pages (`/orders`, `/orders/new`, etc.)

### Admin Area

- Admin dashboard (`/admin`)
- Admin users/products/orders resources
- Admin RSVP listing/import/delete

## Tech Stack

- Ruby: `3.4.9`
- Rails: `8.1.2.1`
- Database: SQLite (`storage/*.sqlite3`)
- Assets: Propshaft + Importmap (no Node bundler required for app runtime)
- Frontend behavior: Turbo + Stimulus
- Auth: OmniAuth + custom Hack Club strategy
- Background/cache/cable: Solid Queue, Solid Cache, Solid Cable
- Deployment support: Docker + Kamal
- Quality/security tooling: RuboCop, Brakeman, bundler-audit, importmap audit

## Architecture Overview

At a high level:

- Controllers handle web flows for home/dashboard/designs/orders/rsvp/admin.
- `SessionsController` + custom OmniAuth strategy manage Hack Club OAuth.
- `HackatimeService` wraps Hackatime API calls for trust/project stats.
- Models connect the design-order-user lifecycle.
- Active Storage stores uploaded assets (SVG previews, product/design images).

Key integration services:

- Hack Club OAuth provider (`lib/omniauth/strategies/hackclub.rb`)
- Hackatime API integration (`app/services/hackatime_service.rb`)

## Data Model Snapshot

Main entities:

- `User`
	- OAuth identity (`slack_id`, name, tokens)
	- Role enum (`user`, `admin`, `superadmin`)
	- Trust + verification + YSWS eligibility fields
- `Design`
	- Belongs to a user
	- Optional Hackatime project metadata
	- Active Storage attachments (`svg`, `image`)
- `DesignEditSession`
	- Tracks edit intervals and duration
- `Product`
	- Catalog item (with optional image)
- `Order`
	- Connects `User`, `Design`, and `Product`
	- Status pipeline (`pending`, `processing`, `production`, `completed`, `cancelled`)
- `Rsvp`
	- Simple association to `User`

See `db/schema.rb` for source-of-truth schema details.

## Local Setup

### Prerequisites

- Ruby `3.4.9` (matches `.ruby-version`)
- Bundler
- SQLite3

Optional but useful:

- Docker (for containerized runs)
- `gh` CLI (if you use optional CI signoff flow)

### 1) Clone and install

```bash
git clone https://github.com/Acidicts/Issued.git
cd Issued
bundle install
```

### 2) Configure environment

```bash
cp .env.example .env
```

Set at least OAuth variables (see [Environment Variables](#environment-variables)).

### 3) Prepare database

```bash
bin/rails db:prepare
```

### 4) Start app

```bash
bin/dev
```

Then open `http://localhost:3000`.

### One-command bootstrap

If you prefer, use:

```bash
bin/setup
```

`bin/setup` installs dependencies, prepares DB, clears logs/tmp, and starts the dev server unless `--skip-server` is passed.

## Environment Variables

Environment is typically loaded via `dotenv-rails` in development/test.

### Required for login

- `HACKCLUB_CLIENT_ID`
- `HACKCLUB_CLIENT_SECRET`

Without these, `/login` redirects back with an OAuth-not-configured alert.

### Strongly recommended

- `HACKCLUB_REDIRECT_URI`
	- Explicit callback URL for OAuth provider config.
- `APP_URL`
	- Used to build absolute URLs/OG metadata in helpers/admin views.

### Hackatime integration

- `HACKATIME_API_KEY`
- `HACKATIME_START_DATE` (default is 30 days ago)
- `HACKATIME_CACHE_TTL_SECONDS` (default `300`)
- `HACKATIME_BYPASS_CACHE` (presence disables cache)

### OAuth token fallback (optional)

- `HACKCLUB_ACCESS_TOKEN`
- `HACKCLUB_REFRESH_TOKEN`

These are fallback sources if user/session tokens are unavailable.

### RSVP/event state toggles

- `RUNNING`
- `ENDED`
- `RSVP_OPEN`

Used to drive RSVP and home-page CTA behavior.

### Optional helper integrations

- `EXCHANGE_RATE_API_KEY`
	- Enables GBP->USD conversion utility used in product-related helpers.

### Runtime/platform vars

- `PORT` (Puma default is `3000`)
- `PIDFILE` (optional)
- `SOLID_QUEUE_IN_PUMA` (enables Solid Queue plugin inside Puma)
- `RAILS_MASTER_KEY` (required for encrypted credentials in environments that need it)

## Authentication (Hack Club OAuth)

OAuth flow details:

1. User visits `/login`.
2. App redirects to `/auth/hackclub`.
3. Callback hits `/auth/hackclub/callback`.
4. Session is established (`session[:user_id]`, token fields).
5. User record is created/updated from OAuth profile.

Implementation files:

- Initializer: `config/initializers/omniauth.rb`
- Strategy: `lib/omniauth/strategies/hackclub.rb`
- Controller: `app/controllers/sessions_controller.rb`

## Developer Workflow

### Common commands

```bash
# Start local server
bin/dev

# Rails console
bin/rails console

# Prepare DB
bin/rails db:prepare

# Reset DB (destructive)
bin/setup --reset --skip-server
```

### Notes

- `bin/dev` currently execs `bin/rails server` directly.
- This app uses Importmap, so there is no JS bundler build step required for standard development.

## Testing, Linting, and Security

### Run everything (CI parity-ish)

```bash
bin/ci
```

`bin/ci` performs setup, style checks, security scans, tests, and seed replant in test.

### Individual commands

```bash
# Tests
bin/rails test
bin/rails test:system

# Style
bin/rubocop

# Security
bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error
bin/bundler-audit
bin/importmap audit
```

### GitHub Actions

Workflow at `.github/workflows/ci.yml` runs:

- Ruby security scans
- JS dependency audit (importmap)
- RuboCop
- Rails tests
- Optional system tests when present

## Admin Operations

Admin access requires `current_user.admin?` (admin or superadmin role).

### RSVP CSV import

- Endpoint/UI: Admin RSVP page
- Expected CSV headers:
	- `slack_id` (required)
	- `name` (optional)

The importer creates or updates users by `slack_id`, then creates RSVP records if missing.

### Role updates

- Role changes in admin user update are restricted to `superadmin` users.

## Deployment

### Docker

This repository ships a production-ready multi-stage `Dockerfile`.

```bash
docker build -t issued .
docker run --rm -p 3000:3000 --env-file .env issued
```

Container details:

- Entrypoint: `bin/docker-entrypoint` (prepares DB on startup)
- Health endpoint: `/up`
- Default server: Puma with `config/puma.rb`

### Kamal

`config/deploy.yml` is present for Kamal deploys.

Before using it:

1. Replace placeholder hosts/registry values.
2. Configure secrets (especially `RAILS_MASTER_KEY`) in `.kamal/secrets`.
3. Validate persistent volume strategy (`issued_storage:/rails/storage`) for SQLite and Active Storage data.

## Project Structure

```text
app/
	controllers/      # user, auth, RSVP, admin flows
	models/           # User, Design, Order, Product, Rsvp, DesignEditSession
	services/         # Hackatime integration
	views/            # ERB templates
config/
	routes.rb         # route map
	initializers/     # OmniAuth and framework setup
db/
	schema.rb         # current schema state
lib/
	omniauth/strategies/hackclub.rb
bin/
	setup, dev, ci, rails, rubocop, brakeman, bundler-audit
```

## Known Gaps / Notes

- `Admin::OrdersController` methods are currently stubs and should be completed before relying on full admin order operations.
- `Design` enforces global uniqueness for `hackatime_project`; if project sharing across users is desired, that constraint may need redesign.
- `.env.example` includes some placeholders and may contain redundant entries; keep local `.env` aligned with actual variables used in code.

## Contributing

1. Create a branch.
2. Make changes with tests.
3. Run `bin/ci` locally.
4. Open a PR.

If you are introducing new env vars, migrations, or operational scripts, update this README in the same PR.
