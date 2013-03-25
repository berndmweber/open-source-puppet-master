Puppet
======

This is the puppet module. It installs both a Puppet client/agent and a Puppet master depending
on the configuration. It also allows the configuration of a system via boot strap
script.

Travis Build Status
-------------------
[![Build Status](https://travis-ci.org/bernd-copperfroghosting/open-source-puppet-master.png?branch=master)](https://travis-ci.org/bernd-copperfroghosting/open-source-puppet-master)

License
-------
GPL v2

Contact
-------
Bernd Weber bernd@copperfroghosting.com

Support
-------

Please log tickets and issues at our [Projects site](https://github.com/bernd-copperfroghosting/open-source-puppet-master/issues)

Versions
--------

Versions tested:
* ruby - 1.8.7 (2012-02-08 patchlevel 358) [universal-darwin11.0]
* gem - 1.8.24
<p />
* ruby - 1.8.7 (2011-06-30 patchlevel 352) [x86_64-linux]
* gem - 1.8.15
<p />
* rake - 10.0.3
* rake - 0.8.7
<p />
* diff-lcs - 1.2.1
* hiera - 1.1.2
* json - 1.7.7
* json_pure - 1.7.7
* meataclass - 0.0.1
* mocha - 0.13.3
* rdoc - 4.0.0
* rspec - 2.13.0
* rspec-core - 2.13.1
* rspec-expectations - 2.13.0
* rspec-mocks - 2.13.0
<p />
* rspec-puppet - 0.1.6
* rspec-puppet-augeas - 0.2.3
* puppetlabs_spec_helper - 0.4.1
<p />

Known bugs
----------

Mac OS X:

Currently in order to get rspec-puppet-augeas working correctly under Mac OSX the ruby-augeas gem needs to be first patched then installed.
* ruby-augeas patch can be found here: https://github.com/uib/ruby-augeas/commit/497b2f628e3573ac7bf8d90c6a1bf08305f1d1e5
 
In order to be able to install the gem you will also need *augeas* installed. This can be done by installing [homebrew](http://mxcl.github.com/homebrew/).
After installing homebrew use it to install augeas, then rebuild the gem and install it.

```
$> ruby -e "$(curl -fsSL https://raw.github.com/mxcl/homebrew/go)"
$> brew doctor
$> brew install augeas
$> sudo gem install --local pkg/ruby-augeas-0.5.1.gem
```