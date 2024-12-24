# Container as a Service (CAAS) Lab Materials

## Dependencies
The CAAS Materials a currently dependent on:
1. NAMESPACE value from F5 Distributed Cloud. The pattern for the namespace names are: adjective-animalname
2. Host file entries for adjective-animalname for:
        - "${NAMESPACE}.useast.lab-app.f5demos.com:34.48.159.144"
        - "${NAMESPACE}.uswest.lab-app.f5demos.com:35.236.21.11"
        - "${NAMESPACE}.europe.lab-app.f5demos.com:34.89.198.113"
3. Environment Variable set for NAMESPACE
  `export NAMESPACE=adjective-animalname`

## Usage
1. Export NAMESPACE Value
  `export NAMESPACE=adjective-animalname`
2. From the docker-grafana folder run

  Where sudo isn't being used, run:
  `docker compose up -d`
  Where sudo is being used, run:
  `sudo --preserve-env=NAMESPACE docker compose up -d

3. Generate system stats by running systemstats2mqtt.sh from the root of the repo.
  `./systemstats2mqtt.sh`

