FROM curlimages/curl:8.00.1 AS builder
ARG FIRMWARE_VERSION=0.18.849

RUN mkdir /tmp/obs
WORKDIR /tmp/obs
RUN curl --remote-name --location https://github.com/openbikesensor/OpenBikeSensorFirmware/releases/download/v${FIRMWARE_VERSION}/obs-v${FIRMWARE_VERSION}-initial-flash.zip && \
    curl --remote-name --location  https://github.com/openbikesensor/OpenBikeSensorFlash/releases/latest/download/flash.bin && \
	unzip obs-v${FIRMWARE_VERSION}-initial-flash.zip && \
	rm obs-v${FIRMWARE_VERSION}-initial-flash.zip

COPY --chown=100 ./public-html/ ./
RUN sed -i "s/FIRMWARE_VERSION/${FIRMWARE_VERSION}/g" /tmp/obs/index.html && \
    sed -i "s/FIRMWARE_VERSION/${FIRMWARE_VERSION}/g" /tmp/obs/manifest.json && \
    mv /tmp/obs/manifest.json /tmp/obs/manifest-${FIRMWARE_VERSION}.json

RUN for file in *.bin; \
    do \
        if [ -f "$file" ]; \
        then \
            sha256=`sha256sum -b ${file} | cut -c1-32`; \
            mv ${file} ${sha256}-${file}; \
            sed -i "s/${file}/${sha256}-${file}/g" manifest-*.json; \
        fi \
    done

RUN chmod -R a=rX .

FROM node:18-bullseye AS nodebuilder
ARG ESP_WEB_TOOLS_VERSION=9.2.1

WORKDIR /tmp/esp-web-tool
RUN DEBIAN_FRONTEND=noninteractive \
      apt update -qq && \
    DEBIAN_FRONTEND=noninteractive \
      apt install -y -qq jq && \
    npm install -g npm@9.6.2
RUN curl --remote-name --location https://github.com/esphome/esp-web-tools/archive/refs/tags/${ESP_WEB_TOOLS_VERSION}.zip && \
    unzip *.zip && \
    rm *.zip && \
    mv */* . && \
# make unsupported browser hint more visible
    sed -i "/'unsupported'/ s|\(<slot.*unsupported.*slot>\)|<div style='font-size:xx-large;color:red;font-weight:bold;'>\1</div>|" src/install-button.ts && \
    npm ci  && \
    script/build && \
    npm exec -- prettier --check src && \
    chmod -R a=rX /tmp/esp-web-tool/dist


FROM httpd:2.4-alpine

COPY --chown=nobody:nogroup --from=builder /tmp/obs/ /usr/local/apache2/htdocs/
COPY --chown=nobody:nogroup --from=nodebuilder /tmp/esp-web-tool/dist/web/ /usr/local/apache2/htdocs/esp-web-tools

