# hymax

A minimal Hyrax/Valkyrie app for scalability testing.

## Development

Hymax is set up for development running the Rails application locally
and ancillary services (solr, postgres, redis, fits) via
[Docker](https://docker.io/), following the pattern set by the
[default Hyrax-based app](https://github.com/samvera/hyrax/blob/main/documentation/developing-your-hyrax-based-app.md#creating-a-hyrax-based-app).

Unlike the default app, however, it uses plain `docker compose` rather
than [Lando](https://lando.dev/).

### Getting started

In the `hymax` root directory:

1. bring up the ancillary services stack:
   ```none
   docker compose up --detach
   ```
2. initialize the development database:
   ```none
   rails db:create db:migrate db:seed
   ```
3. initialize the test database:
   ```none
   RAILS_ENV=test rails db:create db:migrate db:seed
   ```
4. start the server:
   ```none
   rails s
   ```
5. log in
   - click the "Login" link in the upper right corner
     - the default admin username and password should be pre-filled
     - click "Log in"