FROM curlimages/curl:7.80.0 AS builder

ARG FIRMWARE_VERSION=0.10.676

RUN mkdir /tmp/obs && \
    cd /tmp/obs && \
    curl --remote-name --location https://github.com/openbikesensor/OpenBikeSensorFirmware/releases/download/v${FIRMWARE_VERSION}/obs-v${FIRMWARE_VERSION}-initial-flash.zip && \
    curl --remote-name --location  https://github.com/openbikesensor/OpenBikeSensorFlash/releases/latest/download/flash.bin && \
	unzip obs-v${FIRMWARE_VERSION}-initial-flash.zip && \
	rm obs-v${FIRMWARE_VERSION}-initial-flash.zip

ADD ./public-html/ /tmp/obs/

RUN sed -i "s/FIRMWARE_VERSION/${FIRMWARE_VERSION}/g" /tmp/obs/index.html 
RUN sed -i "s/FIRMWARE_VERSION/${FIRMWARE_VERSION}/g" /tmp/obs/manifest.json 


FROM httpd:2.4

COPY --chown=www-data --from=builder /tmp/obs/ /usr/local/apache2/htdocs/
