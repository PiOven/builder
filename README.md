# Pi Builder

A script to automate building of a configured Raspberry Pi

# Config

Create a file at `./cache/settings.sh` with the following variables
define

- **PI_WIFI_SSID**: The SSID WiFi
- **PI_WIFI_PASS**: The password for the WiFi
- **PI_HOSTNAME**: The new network hostname (replacing `raspberry`)
- **PI_SSH_KEY**: The SSH key to use for connecting (replacing password)
- **PI_USERNAME**: The new username (replacing `pi`)
- **PI_OS**: The URL to the OS to download

## OS URLs

- [Raspbian](https://downloads.raspberrypi.org/raspbian/images)
- [Raspbian Lite](https://downloads.raspberrypi.org/raspbian/images)

# Run

Once you have got your settings, hit `sudo make build`. This will create
a new Pi image you can flash to a memory card (suggest
[Etcher](http://etcher.io))

# ToDo

- Generate a random hostname for each PI
- Get `make setup` to prompt for the setup
- Get working on operating systems (currently only tested on Fedora 26)
- Detect the mounted volume, other than `/dev/mapper/loop2*`
- Configure DDNS
