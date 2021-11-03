# babelfish-testbed

Messing around with BabelFish

## What is needed?

1. We need to build BabelFish from source currently. May as well do that in Docker for portablilty.
    - Follow the guide [here](https://babelfishpg.org/docs/installation/compiling-babelfish-from-source/) to set up the build environment.
    - We are going to need to build this in docker...

      ``` bash

        docker build -f ./postgres-builder.dockerfile -t babelfish-postgres .

      ```

    - Seems there is some light lying going on with the default instructions. Libicu66 doesn't exist in Debian. Libicu67 does though. Going to try install and link against that. Also Python... They use python 2.7 in their example to complile pl/python. You can do it with Python3. You need Python3-dev installed to provide the shared libs though. I'm pretty certain they have used instructions for AmazonLinux 2 and roughly converted them without testing. Maybe I should have tried to build in AL2.
    - Whatever ANTLR4 is, it takes almost as long to build as Postgres.
    - [ANTLR4](https://github.com/antlr/antlr4) It's a parser for translating structured text. It's probably the core of what makes Babelfish run by parsing the TDS wire protocol and translating it into something Postgres can understand.
    - My poor little i5 processor isn't happy with all the compilation.
