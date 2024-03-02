FROM curlimages/curl:8.6.0 AS builder

# see https://github.com/openbikesensor/OpenBikeSensorFirmware/releases
ARG FIRMWARE_VERSION=0.19.877

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
        if [ -f "${file}" ]; \
        then \
            sha256=`sha256sum -b ${file} | cut -c1-32`; \
            mv ${file} ${sha256}-${file}; \
            sed -i "s/${file}/${sha256}-${file}/g" manifest-*.json; \
        fi \
    done

RUN chmod -R a=rX .

# based on infos here https://github.com/espressif/esptool-js/blob/main/.github/workflows/ci.yml#L16
FROM node:20-bullseye AS nodebuilder

# see at https://github.com/esphome/esp-web-tools/releases
ARG ESP_WEB_TOOLS_VERSION=9.4.2

RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get update -qq && \
    apt-get install -y -qq jq && \
    npm install -g npm@10.5.0
WORKDIR /tmp/esp-web-tool
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

LABEL version="${FIRMWARE_VERSION}" \
      description="OpenBikeSensor Firmware with ESP Web Tools" \
      maintainer="andreas.mandel@gmail.com"

COPY --chown=nobody:nogroup --from=builder /tmp/obs/ /usr/local/apache2/htdocs/
COPY --chown=nobody:nogroup --from=nodebuilder /tmp/esp-web-tool/dist/web/ /usr/local/apache2/htdocs/esp-web-tools

