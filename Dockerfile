FROM archlinux/archlinux:base-devel
MAINTAINER Vufa <countstarlight@gmail.com>

ENV UGID='2000' UGNAME='build'

RUN pacman -Syy
RUN pacman -Syu --noconfirm

# Add sudoers
RUN echo "build ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/$UGNAME

RUN chmod 'u=r,g=r,o=' /etc/sudoers.d/$UGNAME

# Update, install packages, safely remove .pacnew without touching /proc /sys /dev /run
RUN pacman-key --init && \
    pacman-key --populate archlinux && \
    pacman -Syu --noconfirm --needed \
    base-devel \
    git \
    reflector \
    rsync && \
    # Safely remove .pacnew files while pruning pseudo-filesystems and suppressing harmless errors
    find / \( -path /proc -o -path /sys -o -path /dev -o -path /run \) -prune -o -name '*.pacnew' -print0 2>/dev/null | \
    xargs -0 -r bash -c 'for f; do mv -- "$f" "${f%.pacnew}"; done' sh

# Setup build user/group
RUN \
    groupadd --gid "$UGID" "$UGNAME" && \
    useradd --create-home --uid "$UGID" --gid "$UGID" --shell /usr/bin/false "${UGNAME}"

USER $UGNAME

RUN \
    sudo reflector --verbose -l 10 \
        --sort rate --save /etc/pacman.d/mirrorlist

ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/bin/core_perl

# install yay
RUN \
    cd /home/$UGNAME && \
    curl -O -s https://aur.archlinux.org/cgit/aur.git/snapshot/yay-bin.tar.gz && \
    tar xf yay-bin.tar.gz && \
    cd yay-bin && makepkg -is --skippgpcheck --noconfirm && cd .. && \
    rm -rf yay-bin && rm yay-bin.tar.gz

# Enable multilib repo
RUN sudo sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf

# install ldrfy dep
RUN yay -S \
            unzip \
            zip \
            make \
            meson \
            appstream-glib \
            python-requests \
            python-pillow \
            python-pyqt6 \
            qt6-svg \
            libadwaita \
            gobject-introspection \
            python-gobject \
            python --noconfirm --needed --useask --gpgflags "--keyserver hkp://pool.sks-keyservers.net"


COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
