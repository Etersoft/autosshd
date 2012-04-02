# vim: set ft=spec : -*- rpm-spec -*-

Name: autosshd
Version: 0.0.1
Release: alt2

Summary: System administration - AutoSSH system level service
Group: System/Servers
License: GPL
Url: http://etersift.ru
Source: %name.tar

Packager: Dmitriy Kruglikov <dkr@altlinux.ru>

BuildArch: noarch

PreReq: pwgen shadow-utils openssh-common

Requires: autossh

%description
Run autossh as system service at startup

%define autossh_user      _autossh
%define autossh_group     _autossh
%define name 		  autosshd

%prep
%setup -n autosshd

%install
mkdir -p %buildroot%_initdir
mkdir -p %buildroot%_sysconfdir/sysconfig
mkdir -p %buildroot/var/run/%name
mkdir -p %buildroot/var/lib/autosshd/.ssh
mkdir -p %buildroot%_docdir/%name
install -D -m644 doc/README %buildroot%_docdir/%name/
install -D -m750 etc/rc.d/init.d/autosshd %buildroot%_initdir/autosshd
install -D -m644 etc/sysconfig/autosshd %buildroot%_sysconfdir/sysconfig/autosshd


%pre
# Add the "_autossh" user
%_sbindir/groupadd -r -f %autossh_group 2>/dev/null ||:
%_sbindir/useradd  -r -g %autossh_group -c 'Autossh daemon' \
	-s /dev/null -d /var/lib/autosshd %autossh_user 2>/dev/null ||:
%_sbindir/usermod -p `pwgen -s 24 1` %autossh_user
mkdir -p /var/lib/autosshd/.ssh
/usr/bin/ssh-keygen -t dsa -b 4096 -C "AutoSSH daemon" -N "" -q -f /var/lib/autosshd/.ssh/id_dsa
echo "StrictHostKeyChecking no" > /var/lib/autosshd/.ssh/config
cp /var/lib/autosshd/.ssh/id_dsa.pub /var/lib/autosshd/.ssh/authorized_keys
chown -R %autossh_user:%autossh_group /var/lib/autosshd/
chown %autossh_user:%autossh_group /var/run/autosshd/

%post
%post_service %name

%preun
%preun_service %name

%files
%_initdir/*
%config(noreplace) %_sysconfdir/sysconfig/autosshd
%dir /var/lib/autosshd
%dir /var/run/%name
%dir %_docdir/%name
%_docdir/%name/*
%attr(0644,root,root) %_docdir/%name/README

%changelog
* Tue Apr 03 2012 Dmitriy Kruglikov <dkr@altlinux.org> 0.0.1-alt2
- Ready for testing

* Mon Apr 02 2012 Dmitriy Kruglikov <dkr@altlinux.org> 0.0.1-alt1
- Initial draft
