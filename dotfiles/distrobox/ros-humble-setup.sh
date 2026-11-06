#!/usr/bin/env bash
# Install ROS 2 Humble + Gazebo Harmonic inside the ros-humble distrobox.
# Mirrors the Z690 desktop (Ubuntu 22.04). Idempotent: safe to re-run.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

if [[ $EUID -ne 0 ]]; then
  exec sudo -E bash "$0" "$@"
fi

apt-get update
apt-get install -y curl gnupg lsb-release locales software-properties-common
locale-gen en_US.UTF-8
add-apt-repository -y universe

codename=$(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")

# ROS 2 apt source (same ros2-apt-source package as on Z690)
if ! dpkg -s ros2-apt-source >/dev/null 2>&1; then
  version=$(curl -fsSL https://api.github.com/repos/ros-infrastructure/ros-apt-source/releases/latest |
    grep -F '"tag_name"' | awk -F'"' '{print $4}')
  curl -fsSL -o /tmp/ros2-apt-source.deb \
    "https://github.com/ros-infrastructure/ros-apt-source/releases/download/${version}/ros2-apt-source_${version}.${codename}_all.deb"
  apt-get install -y /tmp/ros2-apt-source.deb
  rm -f /tmp/ros2-apt-source.deb
fi

# Gazebo Harmonic (OSRF repo, as on Z690)
keyring=/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg
if [[ ! -f $keyring ]]; then
  curl -fsSL https://packages.osrfoundation.org/gazebo.gpg -o "$keyring"
fi
echo "deb [arch=$(dpkg --print-architecture) signed-by=$keyring] http://packages.osrfoundation.org/gazebo/ubuntu-stable ${codename} main" \
  >/etc/apt/sources.list.d/gazebo-stable.list

apt-get update
apt-get upgrade -y
apt-get install -y \
  ros-humble-desktop-full \
  ros-dev-tools \
  ros-humble-ros-gz \
  ros-humble-diagnostic-aggregator \
  ros-humble-rclpy-message-converter \
  ros-humble-rqt-robot-monitor \
  gz-harmonic \
  python3-argcomplete

[[ -f /etc/ros/rosdep/sources.list.d/20-default.list ]] || rosdep init

echo "ROS 2 Humble setup complete. Run 'rosdep update' as your user."
