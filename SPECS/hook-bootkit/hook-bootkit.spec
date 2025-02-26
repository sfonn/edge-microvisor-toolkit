%global hookgitpath github.com/tinkerbell/hook

Summary:        In-memory Operating System Installation Environment for Executing Tinkerbell Workflows
Name:           hook-bootkit
Version:        0.10.0
Release:        1%{?dist}
Distribution:   Tiber Microvisor
Vendor:         Intel Corporation
License:        Apache-2.0
URL:            https://tinkerbell.org
Source0:        https://%{hookgitpath}/archive/v%{version}/hook-%{version}.tar.gz#/%{name}-%{version}.tar.gz
Source1:        hook-bootkit.service
Source2:        hook-bootkit.sudoers

BuildRequires:  golang >= 1.22.6
BuildRequires:  systemd-rpm-macros
Requires(pre):  %{_bindir}/systemd-sysusers

%description
The hook-bootkit will parse the /proc/cmdline in order to retrieve the specific configuration for tink-worker to be started for the current/correct machine.
It will ask the engine to run the tink-worker:latest container.
tink-worker:latest will in turn begin to execute the workflow/actions associated with that machine.

%global debug_package %{nil}

%prep
%setup -q -n hook-%{version}

%build
cd images/hook-bootkit
CGO_ENABLED=0 go build -buildmode=pie -mod=vendor -trimpath -ldflags '-s -w -extldflags "-static"' -o ../../bootkit .

%install
# command
install -D -p -m 0755 -t %{buildroot}%{_bindir} ./bootkit

# systemd units
mkdir -p %{buildroot}%{_unitdir}
cp %{SOURCE1} %{buildroot}%{_unitdir}

mkdir -p %{buildroot}%{_sysconfdir}/sudoers.d
cp %{SOURCE2} %{buildroot}%{_sysconfdir}/sudoers.d/hook-bootkit

%post
%systemd_post hook-bootkit.service

%files
%{_bindir}/bootkit
%{_unitdir}/hook-bootkit.service
%config %{_sysconfdir}/sudoers.d/hook-bootkit

%changelog
* Wed Feb 25 2025 Andy <andy.peng@intel.com> - 0.10.0-1
- Initial package
