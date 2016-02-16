require 'rubygems'
require 'bundler'
Bundler.require(:default)
require 'benchmark'

$stdout.sync = true
$stderr.sync = true

task :default => 'test'
task :test do
  exit_code = 0

  time = Benchmark.measure do
    xctool = File.join(Dir.pwd, 'xctool', 'xctool.sh')
    xctool = "#{xctool} -derivedDataPath '#{File.join(Dir.pwd, 'build')}' -scheme SampleApp -sdk iphonesimulator -workspace SampleApp.xcworkspace"

    # Destroy and create devices for given name, type and os version
    devices = [
      SimCtl.reset_device('SampleApp iPhone 9.2', SimCtl.devicetype(name: 'iPhone 5'),    SimCtl.runtime(name: 'iOS 9.2')),
      SimCtl.reset_device('SampleApp iPad 9.2',   SimCtl.devicetype(name: 'iPad Retina'), SimCtl.runtime(name: 'iOS 9.2')),
    ]
    devices.each { |device| device.launch! }

    # Build tests once
    sh "#{xctool} build-tests"

    threads = []

    # Run tests on each device in a separate thread
    devices.each do |device|
      threads << Thread.new do
        system "#{xctool} run-tests -destination 'id=#{device.udid}'"
        Thread.current[:result] = $?
      end
    end

    # Wait for all threads to finish
    threads.each do |thread|
      thread.join
      exit_code |= thread[:result].to_i
    end
  end

  puts "Total time: #{time.real}s"

  exit exit_code
end
