FROM ubuntu:22.04

ARG USERNAME=constable
ARG GROUPNAME=watchmen
ARG DEBIAN_FRONTEND=noninteractive
ARG TZ=UTC
ARG UID=1001
ARG GID=1001
ARG COMPACTC_VERSION=0.9.2
ARG NODE_VERSION=18.19.1
ARG COMPACT_VERSION=0.9.2
ARG PROJECT_DIRECTORY=/app/midnight

# SET THE TIMEZONE
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# INSTALL THE OS DEPENDENCIES
RUN apt-get update && DEBIAN_FRONTEND=${DEBIAN_FRONTEND} apt-get install -y \
  wget \
  build-essential \
  python3 \
  unzip

# CREATE A SECURE USER AND GROUP
RUN groupadd -g ${GID} ${GROUPNAME} && \
  useradd -u ${UID} -g ${GROUPNAME} -G ${GROUPNAME} -ms /bin/bash ${USERNAME}

# RETRIEVE THE NODEJS TAR FILE (THIS WILL ALLOW US TO INSTALL NODEJS)
RUN wget https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz

# EXTRACT THE TAR FILE
RUN tar -xf node-v${NODE_VERSION}-linux-x64.tar.xz
RUN mv node-v${NODE_VERSION}-linux-x64 /usr/local/node

# REMOVE THE TAR FILE
RUN rm node-v${NODE_VERSION}-linux-x64.tar.xz

# ADD NODEJS TO THE PATH
ENV PATH="/usr/local/node/bin:${PATH}"

# ENABLE THE COREPACK
RUN corepack enable

# VERIFY YARN IS INSTALLED
RUN yarn --version

# INSTALL COMPACT
RUN mkdir -p /usr/local/bin/compact
RUN wget https://d3fazakqrumx6p.cloudfront.net/artifacts/compiler/compactc_${COMPACT_VERSION}/compactc-linux.zip
RUN unzip compactc-linux.zip -d /usr/local/bin/compact
RUN rm compactc-linux.zip

# SET ENVIRONMENT VARIABLES FOR COMPACT
ENV COMPACT_HOME="/usr/local/bin/compact"
ENV PATH="$COMPACT_HOME:$PATH"

# VERIFY COMPACT IS INSTALLED
RUN compactc --version

# SET THE WORKING DIRECTORY
WORKDIR ${PROJECT_DIRECTORY}

# COPY THE package.json FILE
COPY package.json ./
# COPY THE yarn.lock FILE
COPY yarn.lock ./

# COPY THE COMPACT PACKAGE.JSON FILE
COPY compact/package.json ./compact/package.json

# COPY THE FRONTEND PACKAGE.JSON FILE
COPY frontend/package.json ./frontend/package.json

# INSTALL THE DEPENDENCIES
RUN yarn install

# COPY THE REST OF THE FILES
COPY . .

# MAKE THE USER THE OWNER OF THE WORKING DIRECTORY
# RUN chown -R ${USERNAME}:${GROUPNAME} ${WORKING_DIRECTORY}/frontend

# SET THE USER
# USER ${USERNAME}

# SET THE WORKING DIRECTORY TO THE FRONTEND APP
WORKDIR ${PROJECT_DIRECTORY}/frontend

# EXPOSE THE PORT
EXPOSE 3333

# START THE APPLICATION
CMD ["yarn", "dev", "--port", "3333"]
