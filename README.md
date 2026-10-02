# Issued
<code>A draft ysws for hackclub</code>

A full stack `Ruby On Rails` application running on ruby 3.4.9 with rails 8.1.12

### Features Include
- Hackclub OAuth
- Design management
- Order system which takes your designs and allows you to put them on the clothes
- Printful API compatability for live stock, importing clothes by id and getting variant of it
- Ship flow (user submit -> reviewer -> admin -> payout)
- Reviewer Panel for reviewing ships
- Admin Panel for viewing general stats and managing roles, etc
- Hackatime compatability for time tracking for devlogs and ships
- Postgres DB with Redis Caching
- S3 storage compatability 

### Dependencies
- Rails
- Propshaft
- Puma 8.0.2
- Importmap
- Turbo
- Stimulus
- Jbuilder
- OmniAuth
- CSV
- Redcarpet 
- Ruby-Vips
- ImageProcessing
- AWS SDK S3 — S3-compatible storage/Cloudflare R2
- PostgreSQL adapter
- Redis
- Solid Queue
- Whenever
- Bootsnap
- Kamal
- Thruster
- TZInfo

### How to run
~ Needs [Docker](https://www.docker.com/) for easy run
1. Run `docker pull ghcr.io/acidicts/issued:latest`
	If github needs authentication do:
	```
	echo "$GITHUB_TOKEN" | docker login ghcr.io -u Acidicts --password-stdin
	docker pull ghcr.io/acidicts/issued:latest
	```
2. Download [.env.example](/.env.example)
3. Rename `.env.example` to `.env`
4. Create a docker compose file eg:
	docker-compose.yml:
	```
	services:
	  web:
	    image: ghcr.io/acidicts/issued:latest
	    env_file:
	      - .env
	    environment:
	      RAILS_ENV: production
	      RACK_ENV: production
	      DB_HOST: db
	      DB_PORT: 5432
	      DB_USERNAME: postgres
	      DB_PASSWORD: postgres
	      REDIS_URL: redis://redis:6379/0
	      PORT: 3000
	    ports:
	      - "3000:3000"
	    depends_on:
	      db:
	        condition: service_healthy
	      redis:
	        condition: service_started
	    restart: unless-stopped
	
	  db:
	    image: postgres:17
	    environment:
	      POSTGRES_USER: postgres
	      POSTGRES_PASSWORD: postgres
	      POSTGRES_DB: issued_production
	    volumes:
	      - postgres_data:/var/lib/postgresql/data
	    healthcheck:
	      test: ["CMD-SHELL", "pg_isready -U postgres -d issued_production"]
	      interval: 5s
	      timeout: 5s
	      retries: 10
	
	  redis:
	    image: redis:7-alpine
	    volumes:
	      - redis_data:/data
	
	volumes:
	  postgres_data:
	  redis_data:
	```
4. Start the application with `docker compose up -d`

Alternatively if you already have a postgres and redis instance you can do:
```
docker run --rm \
  --name issued \
  --env-file .env \
  -e DB_HOST=your-postgres-host \
  -e DB_PORT=5432 \
  -e DB_USERNAME=postgres \
  -e DB_PASSWORD=your-password \
  -e REDIS_URL=redis://your-redis-host:6379/0 \
  -p 3000:3000 \
  ghcr.io/acidicts/issued:latest
```
