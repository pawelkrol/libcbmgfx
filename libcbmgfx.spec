Name:           libcbmgfx
Version:        1.1.0
Release:        1
Summary:        A simple thread-safe Commodore 64 graphics library

License:        MIT
URL:            https://github.com/pawelkrol/libcbmgfx
Source0:        https://github.com/pawelkrol/%{name}/archive/refs/tags/%{name}-%{version}.tar.gz

BuildRequires:  libpng libpng-devel
Requires:       libpng

%description
A simple thread-safe Commodore 64 graphics library with a built-in
support for the most common CBM file format specifications, entirely
written in x86-64 Assembly language. It supports reading, rendering,
converting, and writing picture data from/to miscellaneous CBM image
data formats.

%package        devel
Summary:        Development files for %{name}
Requires:       %{name}%{?_isa} = %{version}-%{release}

%description    devel
The %{name}-devel package contains libraries and header files for
developing applications that use %{name}.

%global debug_package %{nil}
%prep
%autosetup

%build
%make_build

%install
%make_install DESTDIR=%{buildroot}
find %{buildroot} -name '*.la' -exec rm -f {} ';'

%{?ldconfig_scriptlets}

%files
%{_libdir}/%{name}.so.%{version}
%ghost %{_libdir}/%{name}.so

%files devel
%{_includedir}/*

%post
ln -nfrs %{_libdir}/%{name}.so.%{version} %{_libdir}/%{name}.so

%changelog
* Sun Sep 19 2025 Pawel Krol <djgruby@gmail.com> - 1.1.0-1
- Add support for reading images in a FLI Designer file format.
- Add support for converting FLI images to PNG files.
- Add support for reading images in a Fun Painter file format.
- Add support for reading images in a Gunpaint file format.
- Add support for converting IFLI images to PNG files.

* Tue Sep 02 2025 Pawel Krol <djgruby@gmail.com> - 1.0.0-1
- Initial release with a built-in support for various hires and
multicolour file formats as well as PNG files.
