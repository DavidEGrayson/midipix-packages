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
require 'pathname'

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

def install_package(package_file)
  cmd = "sudo pacman -U #{package_file}"
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
  env['SRCDEST'] = (BuildDir + 'src').to_s
  env['SRCPKGDEST'] = (BuildDir + 'srcpkg').to_s
  env['LOGDEST'] = (BuildDir + 'log').to_s
  env['BUILDDIR'] = (BuildDir + 'build').to_s

  success = system(env, 'makepkg -f', chdir: dir.to_s)
  if !success
    raise "makepkg failed"
  end

  find_package_file(BuildDir + 'pkg')
end

def build_and_install_dependency(hosts, package)
  puts `date`.chomp + ": Time to build #{package}"

  build_params = select_build_params(hosts, package)
  package_file = build_package(build_params)
  install_package(package_file)
end

def megabuild(hosts)
  packages = packages_in_order(hosts)
  packages.each do |package|
    satisfied = dependency_satisfied?(package)
    if satisfied
      puts "Already satisfied: #{package}"
    else
      build_and_install_dependency(hosts, package)
    end
  end
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

  if options[:build]
    megabuild(hosts)
  end
end

SrcDir = Pathname(__FILE__).parent
BuildDir = Pathname(Dir.pwd)

run
