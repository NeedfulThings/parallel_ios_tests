require 'rubygems'
require 'bundler'
Bundler.require(:default)
require 'benchmark'

$stdout.sync = true
$stderr.sync = true

task :default => 'test'
task :test do
  time = Benchmark.measure do
    xctool = File.join(Dir.pwd, 'xctool', 'xctool.sh')
    xctool = "#{xctool} -derivedDataPath '#{File.join(Dir.pwd, 'build')}' -scheme SampleApp -sdk iphonesimulator -workspace SampleApp.xcworkspace"

    # Build tests once
    sh "#{xctool} build-tests"

    # Destroy and create devices for given name, type and os version
    devices = [
      SimCtl.reset_device('SampleApp iPhone 9.2', SimCtl.devicetype(name: 'iPhone 5'),    SimCtl.runtime(name: 'iOS 9.2')),
      SimCtl.reset_device('SampleApp iPad 9.2',   SimCtl.devicetype(name: 'iPad Retina'), SimCtl.runtime(name: 'iOS 9.2')),
    ]

    # Run tests on each device
    devices.each do |device|
      sh "#{xctool} run-tests -destination 'id=#{device.udid}'"
    end
  end
  puts "Total time: #{time.real}s"
end
