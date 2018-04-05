""" Sets up the interfaces for the Pi """
import os
import socket
import struct
import netifaces  # pylint: disable=import-error


def decimal_to_ip(decimal):
    """ Converts a decimal into an IP address """
    return socket.inet_ntoa(struct.pack('!L', decimal))


def get_default_gateway_linux():
    """ Read the default gateway directly from /proc. """
    with open("/proc/net/route") as file_handler:
        for line in file_handler:
            fields = line.strip().split()
            if fields[1] != "00000000" or not int(fields[3], 16) & 2:
                continue

            return socket.inet_ntoa(struct.pack("<L", int(fields[2], 16)))


def get_ip_address(start_ip, end_ip):
    """ Gets an unused IP address in the range """
    start_ip_decimal = ip_to_decimal(start_ip)
    end_ip_decimal = ip_to_decimal(end_ip)
    target_ip = None

    # Try each of these
    for current_ip_decimal in range(start_ip_decimal, end_ip_decimal + 1):
        current_ip = decimal_to_ip(current_ip_decimal)

        result = os.system('ping -c 1 ' + current_ip)

        if result == 0:
            # IP in use
            continue
        else:
            # The IP address is free
            target_ip = current_ip
            break

    if target_ip is None:
        raise Exception('Unable to find a free IP address between ' + start_ip + ' and ' + end_ip)

    return target_ip


def ip_to_decimal(ip_address):
    """ Converts an IP into decimal """
    packed_ip = socket.inet_aton(ip_address)
    return struct.unpack("!L", packed_ip)[0]


IFACES = [
    'eth0',
    'wlan0',
    'wlan1',
    'wlp2s0'
]

VALUES = []

TARGET_IP_ADDRESS = None
CONFIG_START_IP = os.environ.get('PI_IP_ADDRESS_RANGE_START')
CONFIG_END_IP = os.environ.get('PI_IP_ADDRESS_RANGE_END')
DNS_ADDRESS = os.environ.get('PI_DNS_ADDRESS')

if CONFIG_START_IP is not None and CONFIG_END_IP is not None:
    TARGET_IP_ADDRESS = get_ip_address(CONFIG_START_IP, CONFIG_END_IP)

for iface in IFACES:
    try:
        gateway = get_default_gateway_linux()
        addrs = netifaces.ifaddresses(iface)[netifaces.AF_INET]

        if TARGET_IP_ADDRESS is not None:
            # We've got an IP address range set
            addrs[0]['addr'] = TARGET_IP_ADDRESS

        VALUES.append({
            "iface": iface,
            "values": [
                addrs[0],
                gateway
            ]
        })
    except Exception as err:  # pylint: disable=broad-except
        # Do nothing
        print(err)

if len(VALUES) == 0:   # pylint: disable=len-as-condition
    raise Exception('No interfaces available')

# Do the output
with open(os.environ.get('NETWORK_CONFIG'), 'w') as the_file:
    the_file.write('# interfaces(5) file used by ifup(8) and ifdown(8)\n')
    the_file.write('\n')
    the_file.write('# Please note that this file is written to be used with dhcpcd\n')
    the_file.write('# For static IP, consult /etc/dhcpcd.conf and "man dhcpcd.conf"\n')
    the_file.write('\n')
    the_file.write('# Include files from /etc/network/interfaces.d:\n')
    the_file.write('source-directory /etc/network/interfaces.d\n')
    the_file.write('\n')
    the_file.write('auto lo\n')
    the_file.write('iface lo inet loopback\n')
    the_file.write('\n')

    for value in VALUES:
        iface = value['iface']
        VALUES = value['values']

        if iface.startswith('wlan'):
            the_file.write('allow-hotplug ' + iface + '\n')

        if VALUES:
            the_file.write('iface ' + iface + ' inet static\n')
            the_file.write('    wireless-power off\n')
            the_file.write('    address ' + VALUES[0]['addr'] + '\n')
            the_file.write('    netmask ' + VALUES[0]['netmask'] + '\n')
            the_file.write('    gateway ' + VALUES[1] + '\n')
            the_file.write('    gateway dns-nameservers ' + DNS_ADDRESS + '\n')
        else:
            the_file.write('iface ' + iface + ' inet manual\n')

        if iface.startswith('wlan'):
            the_file.write('    wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf\n')

        the_file.write('\n')

with open(os.environ.get('TARGET_IP'), 'w') as the_file:
    the_file.write(TARGET_IP_ADDRESS)
