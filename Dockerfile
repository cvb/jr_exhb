FROM elixir:1.4

ENV user=app
ENV workdir=/var/app
ENV MNESIA_DIR=/var/mnesia

RUN groupadd $user &&\
    useradd -M -d /var -g $user $user &&\
    mkdir $workdir &&\
    mkdir $MNESIA_DIR &&\
    chown -R $user:$user /var

VOLUME $MNESIA_DIR

RUN cd /tmp &&\
    wget https://github.com/Yelp/dumb-init/releases/download/v1.2.0/dumb-init_1.2.0_amd64.deb &&\
    dpkg -i dumb-init_*.deb &&\
    rm dumb-init_*.deb

ENTRYPOINT ["dumb-init"]

WORKDIR /var

USER $user
RUN mix local.hex --force &&\
    mix local.rebar --force

USER root
COPY . $workdir
RUN chown -R $user:$user /var

USER $user
WORKDIR $workdir
RUN mix deps.get &&\
    mix compile  &&\
    cd apps/gh_trends_cli/ &&\
    mix escript.build

EXPOSE 4001
CMD mix run --no-halt
