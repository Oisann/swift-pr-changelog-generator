FROM swift:4.1
LABEL maintainer="Jonas Myhr Refseth <jonas@huconglobal.com>"
LABEL Description="Docker Container that generates a CHANGELOG file in a git repository."
WORKDIR /app/repo
WORKDIR /app
COPY ./generate.swift .

ENV REPO=/app/repo
ENV BRANCH=origin/development
ENV BRANCH_MASTER=origin/master

CMD [ "swift", "generate.swift" ]