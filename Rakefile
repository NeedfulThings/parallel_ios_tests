require 'rubygems'
require 'bundler'
Bundler.require(:default)

$stdout.sync = true
$stderr.sync = true

task :default => 'test'
task :test do
  xctool = File.join(ENV['PWD'], 'xctool', 'xctool.sh')
  xctool = "#{xctool} -derivedDataPath '#{File.join(ENV['PWD'], 'build')}' -scheme SampleApp -sdk iphonesimulator -workspace SampleApp.xcworkspace"
  sh "#{xctool} build-tests"
  sh "#{xctool} run-tests"
end
