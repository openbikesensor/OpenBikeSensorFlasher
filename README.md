# OpenBikeSensorFlasher

This container exposes a static web page that allows direct 
flashing of the OpenBikeSensor Firmware to an ESP via the 
Chrome browser.

A running version is available at https://install.openbikesensor.org/.

You can also run the most recent container built on GitHub

    docker run --rm -p 80:80 ghcr.io/openbikesensor/openbikesensorflasher:main

open your browser at http://localhost/.

To build and run the container call

    docker build -t openbikesensor/openbikesensorflasher .
    docker run --rm -p 80:80 openbikesensor/openbikesensorflasher

then open your browser at http://localhost/.

## Details 

See linked documents for details.


## Shoulders

- https://esphome.github.io/esp-web-tools/
- Sample https://github.com/Aircoookie/WLED-WebFlasher
- https://www.improv-wifi.com/

