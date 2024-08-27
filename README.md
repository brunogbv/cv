# The Curriculum Vitae

[![Super-Linter](https://github.com/brunogbv/cv/actions/workflows/superlinter.yml/badge.svg)](https://github.com/marketplace/actions/super-linter)

Hosted at: [https://valerio.dev](https://valerio.dev)

You are a fantastic developer. Keep your CV on GitHub, exploiting Node.js GitHub Action. Host it on GitHub Pages. Have both HTML and PDF versions automatically generated and consistent.

<img src="https://raw.githubusercontent.com/dheereshagrwal/colored-icons/f926a9cacef437021842aa53029d1b73fb03de15/svg/nodejs.svg" alt="nodejs Logo" width="40" height="40" /> &nbsp; &nbsp;
<img src="https://raw.githubusercontent.com/dheereshagrwal/colored-icons/f926a9cacef437021842aa53029d1b73fb03de15/svg/npm.svg" alt="npm Logo" width="40" height="40" /> &nbsp; &nbsp;
<img src="https://raw.githubusercontent.com/dheereshagrwal/colored-icons/f926a9cacef437021842aa53029d1b73fb03de15/svg/html.svg" alt="html Logo" width="40" height="40" /> &nbsp; &nbsp;
<img src="https://raw.githubusercontent.com/dheereshagrwal/colored-icons/f926a9cacef437021842aa53029d1b73fb03de15/svg/css.svg" alt="css Logo" width="40" height="40" /> &nbsp; &nbsp;
<img src="https://raw.githubusercontent.com/dheereshagrwal/colored-icons/f926a9cacef437021842aa53029d1b73fb03de15/svg/js.svg" alt="js Logo" width="40" height="40" />

## What does this project do?

* Helps you to manage your CV as a web app (HTML + CSS + JS).
* Dockerized for easy building and deployment.
* Github Actions for CI/CD. (Currently only for CI, CD is manual for now)

## Dependencies

This project leverages Docker and Docker Compose for building and deploying the page. It's recommended to install Docker and Docker Compose to streamline the development process and avoid the need for local dependencies.

If you do insist on building locally, you will need the following dependencies:
* npm
* node

## Usage

This project uses a Makefile and Docker to streamline various development tasks. Below are the available commands and their descriptions:

### Dev and Build

- **page**: Build the page using local environment. Dependencies: npm, node
  ```sh
  make page
  ```
- **lint**: Lints the code using SuperLinter in dockerized environment.
  ```sh
  make lint
  ```

- **build**: Build the page using dockerized environment. Useful for deploying the page to a server when certificates are already created. Output will be stored in the container's /app/dist folder and mounted to shared volume cv_dist.
  ```sh
  make build
  ```

- **dev-build**: Build the page using dockerized environment and copy files to local dist folder. Useful for building the page without having to install dependencies on local machine. Same as **page**, but no dependency requirements on local machine.
  ```sh
  make dev-build
  ```

- **logs-app-builder**: Get the logs of the app-builder, useful for debugging build issues in the container.
  ```sh
  make logs-app-builder
  ```

- **logs-webserver**: Get the logs of the webserver, useful for debugging nginx issues.
  ```sh
  make logs-webserver
  ```

- **logs-certbot**: Get the logs of the certbot, useful for debugging issues when creating certificates.
  ```sh
  make logs-certbot
  ```

- **remove-app-builder**: Useful if you need to remove the app-builder container.
  ```sh
  make remove-app-builder
  ```

- **remove-certbot**: Useful if you need to remove the certbot container.
  ```sh
  make remove-certbot
  ```

### Deploy

- **certificates**: Create certificates using dockerized certbot. Certs are stored in ./certbot/conf/live/valerio.dev/ and mounted to shared volume cv_certs. Be careful with the rate limits of Let's Encrypt, as they may block you if you create too many certificates in a short period of time. Whenever testing, use **certificates-dry-run** instead.
  ```sh
  make certificates
  ```

- **certificates-dry-run**: Similar to **certificates** Simulates the creation of certificates using dockerized certbot. Useful for testing without hitting the rate limits of Let's Encrypt.
  ```sh
  make certificates-dry-run
  ```

- **webserver-ssl-config**: Updates the nginx configuration to use the newly created certificates. Enables SSL and redirects all HTTP traffic to HTTPS.
  ```sh
  make webserver-ssl-config
  ```

- **webserver-restart-nginx**: Restarts the nginx server to apply new configurations
  ```sh
  make webserver-restart-nginx
  ```

- **webserver-upgrade-to-https**: Upgrades the webserver to use HTTPS. It creates the certificates, updates the nginx configuration and restarts the server.
  ```sh
  make webserver-upgrade-to-https
  ```

- **down**: Downs the webserver.
  ```sh
  make down
  ```

- **webserver**: Starts the webserver
  ```sh
  webserver
  ```

- **webserver-local**: Adds localhost to nginx server_name. Useful for local development.
  ```sh
  webserver-local
  ```

- **all**: Full build and deploy, hosting the webserver locally. Useful for deploying the page to a server for the first time. Avoid running this command if you are just updating the page as it will recreate the certificates.
  ```sh
  webserver-local
  ```


## WIP


<!-- ## What does this project do?

* Helps you to manage your CV as a web app (HTML + CSS + JS).
* Automatically generates and publishes HTML and PDF version on every push to `main`.

Demo: [http://sneas.github.io/cv-template](http://sneas.github.io/cv-template).

Real world example: [http://sneas.github.io/cv](http://sneas.github.io/cv).


## Motivation

GitHub Pages is probably the best place developer could store their CV. Giving a potential employer a link to your CV stored on GitHub shows your intense desire for automation and stands you out.

The idea behind **The Curriculum Vitae Template** is to provide anyone with a quick solution for creating and managing CVs (both HTML and PDF versions) with the help of GitHub.

## Installation

1. Create a new repository out of this template by clicking [this link](https://github.com/sneas/cv-template/generate).
1. Clone the newly created repository.
1. Install project dependencies with `npm install`.
1. Run `npm run deploy` to initialize `gh-pages`. This is a one time action. Further deployments will be initiated by GitHub Actions on every push to `main`.

## Usage

1. Start local development server with `npm start`.
1. Update contents of `src` folder to fit your needs. This item is explained [below](#update-contents).
1. Commit and push your changes.
1. GitHub Actions will automatically build the latest version and deploy it to GitHub Pages.
1. Open `http://your-username.github.io/your-cv-repo`.

### Update contents

The project uses [HandlebarsJS](https://github.com/wycats/handlebars.js/) as a template engine.

The main HTML template is located in [src/templates/index.html](src/templates/index.html). Metadata for the template could be found in [src/metadata/metadata.js](src/metadata/metadata.js).

Don't forget to update [src/assets/favicon.ico](src/assets/favicon.ico). You can generate a new favicon out of your photo with [icoconvert.com](http://icoconvert.com/). -->
