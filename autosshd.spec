# vim: set ft=spec : -*- rpm-spec -*-

Name: autosshd
Version: 0.0.1
Release: alt1

Summary: System administration - AutSSH daemon
Group: System/Servers
License: GPL
Url: http://etersift.ru
Source: %name.tar

Packager: Dmitriy Kruglikov <dkr@altlinux.ru>

BuildArch: noarch

PreReq: pwgen shadow-utils openssh-common

%description
Run autossh as system service at startup

%define autossh_user      _autossh
%define autossh_group     _autossh

%prep
%setup -n autosshd

%install
mkdir -p %buildroot%_initdir
mkdir -p %buildroot%_sysconfdir/sysconfig
mkdir -p %buildroot/var/lib/autosshd/.ssh
install -m 644 etc/rc.d/init.d/autosshd %buildroot%_initdir/autosshd
install -m 644 etc/sysconfig/autosshd %buildroot%_sysconfdir/sysconfig/autosshd


%pre
# Add the "_autossh" user
%_sbindir/groupadd -r -f %autossh_group 2>/dev/null ||:
%_sbindir/useradd  -r -g %autossh_group -c 'Autossh daemon' \
	-s /dev/null -d /var/lib/autosshd %autossh_user 2>/dev/null ||:
%_sbindir/usermod -p `pwgen -s 24 1`

/usr/bin/ssh-keygen -t dsa -b 4096 -C "AutoSSH daemon" -N "" -q -f /var/lib/autosshd/.ssh/autosshd_dsa

%post
%post_service %name

%preun
%preun_service %name

%files
%_initdir/*
%config(noreplace) %_sysconfdir/sysconfig/autosshd
%dir /var/lib/autosshd/.ssh/

%changelog
* Mon Apr 02 2012 Dmitriy Kruglikov <dkr@altlinux.org> 0.0.1-alt1
- Initial draft
