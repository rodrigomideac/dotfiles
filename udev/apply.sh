#!/bin/bash

set -xe

echo "Applying rules..."
sudo cp -r ./*.rules /etc/udev/rules.d/

sudo chown root:root /etc/udev/rules.d/*.rules
sudo chmod 644 /etc/udev/rules.d/*.rules
sudo udevadm control --reload-rules
sudo udevadm trigger
