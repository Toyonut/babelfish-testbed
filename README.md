# babelfish-testbed

Messing around with BabelFish

## What is needed?

1. We need to build BabelFish from source currently. May as well do that in Docker for portablilty.
    - Follow the guide [here](https://babelfishpg.org/docs/installation/compiling-babelfish-from-source/) to set up the build environment.
    - I'm going to build this in docker for portability.

      ``` bash

        docker build -f ./postgres-builder.dockerfile -t babelfish-postgres .

      ```

    - There are some oddities with the instructions. Libicu66 doesn't exist in Debian that I can find. Libicu67 does though, but only in Bullseye. Going to try install that. Also Python... They use python 2.7 in their example to complile pl/python. You can do it with Python3. You need Python3-dev installed to provide the shared libs though. Debian Buster has Libicu63 from memory, but with Buster and Bullseye you are getting too new to have a package for openjdk 8 and python2. Have tried to use python3 and corretto java 8 instead.
    - [ANTLR4](https://github.com/antlr/antlr4) I haven't come across this before. It's a parser for translating structured text. It's probably the core of what makes Babelfish run by parsing the TDS wire protocol and translating it into something Postgres can understand. It takes almost as long as postgres to build.
    - My poor little i5 processor isn't happy with all the compilation.
    - Had to look how the official Postgres docker image does startup. Instructions required at least running init_db to get the config files copied into a data directory and setting some useful settings like hba for docker.
    - Running the newly built container I can connect to the Postgres port with something like Azure Data Studio. It seems to work. I think from my understanding of the docs, there should be a second listener on port 1433. That currently isn't there if it should be. Connecting to port 5432 from SSMS gives an error in the container output `LOG:  invalid length of startup packet`. and a provider tcp error in SSMS. `Cannot connect to localhost,5432. A connection was successfully established with the server, but then an error occurred during the pre-login handshake.(provider: TCP Provider, error: 0 - An existing connection was forcibly closed by the remote host.) (Microsoft SQL Server, Error: 10054)`
    - Got further by noticing an error when trying to follow the [docs for single or multiple DB](https://babelfishpg.org/docs/installation/single-multiple/). It had a failure needing to have the babelfishpg_tds module added to the shared_preload_libraries. Once I added that to the shared preload libs, I now have a new listener starting up alongside the Postgres one. Still can't connect though, but I have a new error. `FATAL:  Configuration parameter "babelfishpg_tsql.database_name" is not defined. Set GUC value by specifying it in postgresql.conf or by ALTER SYSTEM`.
    - Trying to add babelfishpg_tsql.database_name via the ALTER_SYSTEM command didn't work. Adding it to postgres.conf did.
    - finally it seems to be working well enough to test.
    - Once the image is built, you can run it with:

    ``` bash

    # Use postgres DB
    docker run -it -p 1433:1433 -p 5432:5432 -e POSTGRES_PASSWORD=password babelfish-postgres

    # Specify your own DB to use
    docker run -it -p 1433:1433 -p 5432:5432 -e POSTGRES_PASSWORD=password -e POSTGRES_DB=test babelfish-postgres

    ```
