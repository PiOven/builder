import netifaces
import os
import socket
import struct


def decimal_to_ip(decimal):
    return socket.inet_ntoa(struct.pack('!L', decimal))


def get_default_gateway_linux():
    """Read the default gateway directly from /proc."""
    with open("/proc/net/route") as fh:
        for line in fh:
            fields = line.strip().split()
            if fields[1] != "00000000" or not int(fields[3], 16) & 2:
                continue

            return socket.inet_ntoa(struct.pack("<L", int(fields[2], 16)))


def get_ip_address(start_ip, end_ip):
    start_ip_decimal = ip_to_decimal(start_ip)
    end_ip_decimal = ip_to_decimal(end_ip)
    target_ip = None

    # Try each of these
    for current_ip_decimal in range(start_ip_decimal, end_ip_decimal + 1):
        current_ip = decimal_to_ip(current_ip_decimal)

        try:
            # The IP is in use
            socket.gethostbyaddr(current_ip)
            continue
        except socket.herror:
            # The IP address is free
            target_ip = current_ip
            break

    if target_ip is None:
        raise Exception('Unable to find a free IP address between ' + start_ip + ' and ' + end_ip)

    return target_ip


def ip_to_decimal(ip):
    packed_ip = socket.inet_aton(ip)
    return struct.unpack("!L", packed_ip)[0]


ifaces = [
    'eth0',
    'wlan0',
    'wlan1',
    'wlp2s0'
]

values = []

target_ip_address = None
start_ip = os.environ.get('PI_IP_ADDRESS_RANGE_START')
end_ip = os.environ.get('PI_IP_ADDRESS_RANGE_END')

if start_ip is not None and end_ip is not None:
    target_ip_address = get_ip_address(start_ip, end_ip)

for iface in ifaces:
    try:
        gateway = get_default_gateway_linux()
        addrs = netifaces.ifaddresses(iface)[netifaces.AF_INET]

        if target_ip_address is not None:
            # We've got an IP address range set
            addrs[0]['addr'] = target_ip_address

        values.append({
            "iface": iface,
            "values": [
                addrs[0],
                gateway
            ]
        })
    except Exception as err:
        """
        Do nothing
        """

if len(values) == 0:
    raise Exception('No interfaces available')

"""
Do the output
"""
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

    for value in values:
        iface = value['iface']
        values = value['values']

        if iface.startswith('wlan'):
            the_file.write('allow-hotplug ' + iface + '\n')

        if values:
            the_file.write('iface ' + iface + ' inet static\n')
            the_file.write('    address ' + values[0]['addr'] + '\n')
            the_file.write('    netmask ' + values[0]['netmask'] + '\n')
            the_file.write('    gateway ' + values[1] + '\n')
            the_file.write('    gateway dns-nameservers 8.8.8.8 8.8.4.4\n') # Use Google for DNS
        else:
            the_file.write('iface ' + iface + ' inet manual\n')

        if iface.startswith('wlan'):
            the_file.write('    wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf\n')

        the_file.write('\n')

with open(os.environ.get('TARGET_IP'), 'w') as the_file:
    the_file.write(target_ip_address)
