nsr - name service resolver
===========================

`nsr` is a stupendously simple commandline name service
resolver that feels/behaves sufficiently close to `host(1)`.

Contrary to `host` however, it does not bring its own resolver
path and instead uses the libc resolver. This means it uses
`nsswitch.conf(5)` and `hosts(5)` the same way as tools such as
`ping(8)` or `ping6(8)`.

Example
=======

* A typical `nsswitch.conf` will prefer `/etc/hosts` over results
  from DNS:

```
~% grep ^hosts /etc/nsswitch.conf
hosts: files dns
```

* Entries in your `/etc/hosts` might look like this:

```
~% grep foobar$ /etc/hosts
203.0.113.254       foobar.localdomain.example  foobar
2001:db8:0:1::254   foobar.localdomain.example  foobar
```

* `host(1)` goes directly to DNS, bypassing the system's resolver:

```
~% host foobar
Host foobar not found: 3(NXDOMAIN)
Exit 1
```

* since `nsr` uses the system resolver, the output is like this:

```
~% nsr foobar
foobar is an alias for foobar.localdomain.example
foobar.localdomain.example has IPv6 address 2001:db8:0:1::254
foobar.localdomain.example has IPv4 address 203.0.113.254
```

Installation
============

Just copy it somewhere in your `$PATH`. `$HOME/bin` might work for you.

Dependencies
============

`nsr` is written in Perl and requires version 5.14.0, in which
`getaddrinfo()` and `getnameinfo()` were added to core. If you have an
older version of Perl, get `Socket::GetAddrInfo` from CPAN.
