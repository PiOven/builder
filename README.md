# Pi Builder

A script to automate building of a configured Raspberry Pi

# Config

Create a file at `./cache/settings.sh` with the following variables defined:

- **PI_WIFI_SSID**: The SSID WiFi
- **PI_WIFI_PASS**: The password for the WiFi
- **PI_HOSTNAME**: The new network hostname prefix (replacing `raspberry`)
- **PI_SSH_KEY**: The filepath to the SSH public key to use for connecting (replacing password)
- **PI_USERNAME**: The new username (replacing `pi`)
- **PI_OS**: The URL to the OS to download

The Pi will be given a static IP (which will be the same as is first assigned
via DHCP) and the hostname will become the `$PI_HOSTNAME` followed by the IP
address (eg, hostname-192-168-10-10)

## OS URLs

- [Raspbian](https://downloads.raspberrypi.org/raspbian/images)
- [Raspbian Lite](https://downloads.raspberrypi.org/raspbian_lite/images)

# Run

Once you have got your settings, hit `sudo make build`. This will create
a new Pi image you can flash to a memory card (suggest
[Etcher](http://etcher.io))

# ToDo

- Generate a random hostname for each PI
- Get `make setup` to prompt for the setup
- Get working on operating systems (currently only tested on Fedora)
- Configure DDNS
