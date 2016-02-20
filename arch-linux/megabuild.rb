#!/usr/bin/env ruby

# megabuild is a Ruby script that builds all the packages in this directory.
#
# Build tools:
# 1) lazy
#
# Toolchain:
# 2) midipix-binutils
# 3) midipix-gcc-stage1
# 4) midipix-psxstub
# 5) midipix-musl-stage1
# 6) midipix-gcc-stage2
# 7) midipix-musl
# 8) midipix-gcc
#
# Midipix runtime libraries:
# 9) midipix-psxtypes
# 10) midipix-dalist
# 11) midipix-pemagine
# 12) midipix-ntapi
# 13) midipix-psxscl
#
# Utilities:
# 14) midipix-ntcon
# 15) midipix-ntctty
# 16) perk

require 'optparse'

def packages_in_order(hosts)
  packages = [
    "lazy",
    "perk"
  ]

  hosts.each do |host|
    packages.concat [
      "#{host}-binutils",
      "#{host}-gcc-stage1",
      "#{host}-psxstub",
      "#{host}-musl-stage1",
      "#{host}-gcc-stage2",
      "#{host}-musl",
      "#{host}-gcc",
      "#{host}-psxtypes",
      "#{host}-dalist",
      "#{host}-pemagine",
      "#{host}-ntapi",
      "#{host}-psxscl",
      "#{host}-ntcon",
      "#{host}-ntctty",
    ]
  end

  packages
end

def dependency_satisfied?(dep)
  `pacman -T '#{dep}'`
  $?.success?
end

def show_status(hosts)
  packages = packages_in_order(hosts)
  puts "Package status:"
  packages.each do |package|
    installed = dependency_satisfied?(package)
    puts "%-40s %s" % [package, installed ? "installed" : "not installed"]
  end
end

def purge(hosts)
  packages = packages_in_order(hosts)
end

def parse_args
  options = {}
  option_parser = OptionParser.new do |opts|
    opts.banner = "Usage: megabuild.rb [options]"
    opts.on("-s", "--status", "Just show status") do |v|
      options[:status] = v
    end
    opts.on("--purge", "Uninstall/remove all packages") do |v|
      options[:purge] = v
    end
  end
  option_parser.parse!(ARGV)
  options
end

def run
  hosts = ['x86_64-nt64-midipix']
  options = parse_args

  if options[:status]
    show_status(hosts)
  end

  if options[:purge]
    purge(hosts)
  end
end

run
