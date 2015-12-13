FROM perl:latest

RUN apt-get update && \
    apt-get install -y \
    libidn11 libidn11-dev && \
    rm -r /var/lib/apt/lists/*

# TODO: Remove the CGI dep once Test::Memory::Cycle is fixed
RUN cpanm \
    CGI \
    YAML \
    AnyEvent::XMPP \
    Term::ReadPassword \
    Sys::Hostname \
    AnyEvent::Git::Wrapper \
    AnyEvent::HTTP \
    AnyEvent::HTTPD \
    AnyEvent::Open3::Simple \
    AnyEvent::WebSocket::Server \
    AnyEvent::WebSocket::Client \
    JSON::WebToken

COPY . /usr/src/cluebot

WORKDIR /usr/src/cluebot

RUN cpanm -v \
    ./Bot-ClueBot \
    ./Bot-ClueBot-Plugin-WebTokens \
    ./Bot-ClueBot-Plugin-WebSocket \
    ./Bot-ClueBot-Plugin-HTTPD \
    ./Bot-ClueBot-Plugin-Git \
    ./Bot-ClueBot-Plugin-Run

CMD [ "cluebot", "-F", "-v", "-f", "script/tiny_mojo" ]

