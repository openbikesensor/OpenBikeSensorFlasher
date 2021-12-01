# OpenBileSensorFlasher

This container exposes a static web page that allows direct 
flashing of the OpenBikeSensor Firmware to an ESP via the 
Chrome browser.

To run the container call

    docker build -t openbikesensor/openbikesensorflasher .
	docker run --rm -p 80:80 openbikesensorflasher
	
then open your browser at http://localhost/.

## Details 

TODO


## Shoulders

- https://esphome.github.io/esp-web-tools/
- Sample https://github.com/Aircoookie/WLED-WebFlasher
- TODO: Leverage https://www.improv-wifi.com/

