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
# More stuffs:
# 14) midipix-ntcon
# 15) midipix-ntctty
# 16) perk

require 'optparse'
require 'pathname'
require 'fileutils'
require 'bcrypt'

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
      "#{host}-xz",
    ]
  end

  packages
end

def log(msg)
  puts msg
  File.open(BuildDir + 'build.log', 'a') do |f|
    f.puts `date`.chomp + ": " + msg
  end
end

def dependency_satisfied?(dep)
  `pacman -T '#{dep}'`
  $?.success?
end

def show_status(hosts)
  packages = packages_in_order(hosts)
  puts "Dependency status:"
  packages.each do |package|
    satisfied = dependency_satisfied?(package)
    puts "%-40s %s" % [package, satisfied ? "satisfied" : "not satisfied"]
  end
end

def purge(hosts)
  raise 'not implemented'
end

def select_build_params(hosts, name)
  params = {}
  params[:env] = {}

  hosts.each do |host|
    prefix = "#{host}-"
    name.sub!(prefix, 'midipix-')
  end

  if md = name.match(/-stage(\d+)$/)
    params[:env]['PKG_STAGE'] = md[1]
    name.sub!(md[0], '')
  end

  dir = SrcDir + name
  if !dir.directory?
    raise "PKGBUILD directory not present: #{dir}"
  end

  params[:dir] = dir

  params
end

def find_package_file(dir)
  # Kind of hacky, but we just find the newest .pkg.xz file in the
  # directory.  So this would not support building of packages in
  # parallel.
  package_file = Dir.glob(dir + '*.pkg.tar.xz').max_by { |a| File.ctime(a) }
  raise "package file not found" if !package_file
  package_file
end

def install_package(package_file, noconfirm)
  cmd = "sudo pacman -U #{package_file}"
  if noconfirm
    # we can't use --noconfirm because it automatically answers no to the
    # question about removing conflicting packages.
    cmd = "yes | #{cmd}"
  end
  puts "Installing package with command: #{cmd}"
  success = system(cmd)
  if !success
    raise "installation failed"
  end
end

def build_package(build_params)
  dir = build_params[:dir]
  env = build_params[:env].dup

  env['PKGDEST'] = (BuildDir + 'pkg').to_s
  env['SRCPKGDEST'] = (BuildDir + 'srcpkg').to_s
  env['LOGDEST'] = (BuildDir + 'log').to_s
  env['BUILDDIR'] = (BuildDir + 'build').to_s
  env['SRCDEST'] = (BuildDir + 'build' + 'downloads').to_s

  success = system(env, 'makepkg -f', chdir: dir.to_s)
  if !success
    raise "makepkg failed"
  end

  find_package_file(BuildDir + 'pkg')
end

def build_and_install_dependency(hosts, package, options = {})
  log "Time to build #{package}"

  build_params = select_build_params(hosts, package)
  package_file = build_package(build_params)
  install_package(package_file, options[:noconfirm])

  satisfied = dependency_satisfied?(package)
  if !satisfied
    raise "Error: Dependency #{package} not satisfied by building " \
      " and installing with params #{build_params.inspect}."
  end
end

def prepare_directories
  FileUtils.mkdir_p BuildDir + 'pkg'
  FileUtils.mkdir_p BuildDir + 'build' + 'downloads'
end

def prepare_sudo
  cmd = "sudo pacman -Q"
  puts "Acquiring/checking sudo permissions by running '#{cmd}'"
  `#{cmd}`
  if !$?.success?
    $stderr.puts "Acquiring/checking sudo permissions failed."
    exit 2
  end
end

def prepare_midipix_internal
  hash = "$2a$10$ts1/X9R5vbbRr19MPK0xUOKeZht3o6SwbPePCT7J.LrY0d53haN/C"
  if BCrypt::Password.new(hash) != ENV['midipix_internal']
    $stderr.puts "Error: $midipix_internal is wrong."
    $stderr.puts "You need to set the environment variable $midipix_internal such that"
    $stderr.puts "  http://git.midipix.org/cgit.cgi/$midipix_internal/psxscl"
    $stderr.puts "is a valid repository for the internal version of psxscl."
    $stderr.puts "See http://midipix.org/ for info about the internal repos."
    exit 3
  end
end

def prepare_for_build(options)
  puts "Preparing to build packages"
  puts "PKGBUILD script directory: #{SrcDir}"
  puts "Build directory: #{BuildDir}"

  prepare_directories
  prepare_sudo if options[:noconfirm]
  prepare_midipix_internal
end

def megabuild(hosts, options)
  log "Starting megabuild"
  prepare_for_build(options)
  packages = packages_in_order(hosts)
  packages.each do |package|
    satisfied = dependency_satisfied?(package)
    if satisfied
      log "Already satisfied: #{package}"
    else
      build_and_install_dependency(hosts, package, options)
    end
  end
  log "Done"
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
    opts.on("--build", "Build packages") do |v|
      options[:build] = v
    end
    opts.on("--noconfirm", "Bypass pacman prompts when installing packages.") do |v|
      options[:noconfirm] = v
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
    did_something = true
  end

  if options[:purge]
    purge(hosts)
    did_something = true
  end

  options[:build] = true if !did_something

  if options[:build]
    megabuild(hosts, options)
  end
end

SrcDir = Pathname(__FILE__).parent
BuildDir = Pathname(Dir.pwd)

run
