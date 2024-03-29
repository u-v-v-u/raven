FROM node:18-buster-slim as base

WORKDIR /usr/src/app

RUN apt-get update && \
  apt-get upgrade -y --no-install-recommends && \
  apt-get install -y --no-install-recommends build-essential dumb-init python3 && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

COPY --chown=node:node yarn.lock .
COPY --chown=node:node package.json .
COPY --chown=node:node .yarnrc.yml .
COPY --chown=node:node .yarn/ .yarn/

ENTRYPOINT [ "dumb-init", "--" ]

FROM base as builder 

COPY --chown=node:node src/ src/
COPY --chown=node:node prisma/ prisma/
COPY --chown=node:node scripts/ scripts/

ENV NODE_ENV="development"

RUN yarn install --immutable
RUN yarn prisma generate
RUN yarn build

RUN rm -r scripts/

FROM base AS runner

ENV NODE_ENV="production"

COPY --chown=node:node --from=builder /usr/src/app/build build
COPY --chown=node:node prisma/ prisma/
COPY --chown=node:node scripts/ scripts/

RUN yarn install --immutable
RUN yarn prisma generate

RUN chown node:node /usr/src/app/

USER node

CMD ["yarn", "start"]
