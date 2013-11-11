# This configures the PkgNG Package manager on FreeBSD systems, and adds
# support for managing packages with Puppet.  This will eventually be in
# mainline FreeBSD, but for now, we are leaving the installation up to the
# adminstrator, since there is no going back.
# To install PkgNG, one can simply run the following:
# make -C /usr/ports/ports-mgmg/pkg install clean

class pkgng (
  $packagesite  = $pkgng::params::packagesite,
  $srv_mirrors  = $pkgng::params::srv_mirrors,
  $pkg_dbdir    = $pkgng::params::pkg_dbdir,
  $pkg_cachedir = $pkgng::params::pkg_cachedir,
  $portsdir     = $pkgng::params::portsdir,
) inherits pkgng::params {

  if $pkgng_supported {
    file { "/usr/local/etc/pkg.conf":
      content  => "PACKAGESITE: ${packagesite}\n",
      notify   => Exec['pkg update'],
    }

    file { "/etc/make.conf":
      ensure => present,
    }

    file_line { "WITH_PKGNG":
      path    => '/etc/make.conf',
      line    => "WITH_PKGNG=yes\n",
      require => File['/etc/make.conf'],
    }

    file { "/usr/local/etc/pkg":
      ensure => directory,
      owner  => root,
      group  => 0,
      mode   => 0755,
    }

    file { "/usr/local/etc/pkg/repos":
      ensure => directory,
      owner  => root,
      group  => 0,
      mode   => 0755,
    }

    # read the repo on config changes
    exec { "pkg update":
      path        => '/usr/local/sbin',
      refreshonly => true,
      command     => "pkg -q update -f",
    }

    # This exec should really on ever be run once, and only upon converting to
    # pkgng.  If you are building up a new system where the only software that
    # has been installed form ports is the pkgng itself, then the pkg database
    # is already up to date, and this is not required.  As you will see,
    # refreshonly, but nothing notifies this.  I am uncertain at this time how
    # to proceed, other than manually.
    exec { "convert pkg database to pkgng":
      path        => '/usr/local/sbin',
      refreshonly => true,
      command     => "pkg2ng",
    }
  } else {
    notice("PkgNG is not supported on this release of ${operatingsystem}.")
  }
}
