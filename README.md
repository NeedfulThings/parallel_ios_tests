# Running iOS tests in multiple simulators in parallel

## tl;dr

* `git clone git@github.com:plu/parallel_ios_tests`
* `cd parallel_ios_tests && bundle && rake`
* [How?](#run-on-multiple-devices-in-parallel)

## Intro

Apple did some great job in the last versions of Xcode in regard of sandboxing Simulator instances.
Finally we can execute our tests on different devices (iPhone Simulator, iPad Simulator) at the
same time. It might not be obvious how to do that, it also is not possible by just using
`xcodebuild`. Instead we need to use [xctool's](https://github.com/facebook/xctool) feature of
separating the `build-tests` phase from the `run-tests` phase. Due to some internal implementation
details of `xctool` it's mandatory to path the `-derivedDataPath` option to both phases. Right
now it's also required to use the current `master` of `xctool`.

## Start simple

The example app includes two test cases that are using [KIF](https://github.com/kif-framework/KIF) for testing the UI.

A simple [rake](https://github.com/ruby/rake) task could look like this:

```ruby
task :test do
  time = Benchmark.measure do
    xctool = File.join(Dir.pwd, 'xctool', 'xctool.sh')
    xctool = "#{xctool} -derivedDataPath '#{File.join(Dir.pwd, 'build')}' -scheme SampleApp -sdk iphonesimulator -workspace SampleApp.xcworkspace"
    sh "#{xctool} build-tests"
    sh "#{xctool} run-tests"
  end
  puts "Total time: #{time.real}s"
end
```

Executing it looks like this:

```console
...
=== RUN-TESTS ===

  [Info] Collecting info for testables... (892 ms)
  run-test SampleAppTests.xctest (iphonesimulator9.2, iPhone 5, application-test)
    [Info] Prepared 'iPhone 5' simulator to run tests. (227 ms)
    [Info] Installed 'com.plunien.SampleApp'. (3651 ms)
    [Info] Launched 'com.plunien.SampleApp' on 'iPhone 5'. (12089 ms)
    ✓ -[SampleAppTests testDetailView] (42256 ms)
    ✓ -[SampleAppTests testRows] (20343 ms)
    2 passed, 0 failed, 0 errored, 2 total (62600 ms)


** RUN-TESTS SUCCEEDED: 2 passed, 0 failed, 0 errored, 2 total ** (80394 ms)

Total time: 85.675036s
```

## Run on multiple devices

Using the [simctl](https://github.com/plu/simctl) gem it's easy to run them on multiple devices (sequentially, so far):

```objc
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
```

The total runtime however got much worse, which is expected, because the tests are first executed on an iPhone Simulator followed by another execution on an iPad Simulator:

```console
Total time: 188.726965s
```

## Run on multiple devices in parallel

The `simctl` gem has one essential feature that makes running the tests in parallel possible: It can launch multiple simulator instances at the same time. Later `xctool` will pick up the right one during the `run-tests` phase when the simulator UDID is passed:

```objc
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
        test_log = File.join(Dir.pwd, 'build', "#{device.name}.log")
        junit_xml = File.join(Dir.pwd, 'build', "#{device.name}.junit.xml")
        system "#{xctool} run-tests -destination 'id=#{device.udid}' -reporter plain:'#{test_log}' -reporter junit:'#{junit_xml}'"
        Thread.current[:result] = $?
        device.kill!
        device.shutdown!
        device.delete!
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
```

This reduced the total executing time again:

```console
Total time: 92.138191s
```

In theory adding more devices does not change the executing time, because they are run in parallel.

## Integrating into Jenkins

On Jenkins you might be interested in saving some artifacts. In this example the test runs on the different devices produce a separate test log and JUnit test report:

```console
build/SampleApp iPad 9.2.junit.xml
```

```xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<testsuites name="AllTestUnits" tests="2" failures="0" errors="0" time="71.974116">
    <testsuite tests="2" failures="0" errors="0" time="71.974116" timestamp="2016-02-16T07:30:16GMT+04:00" name="Toplevel Test Suite">
        <testcase classname="SampleAppTests" name="testDetailView" time="56.856110"></testcase>
        <testcase classname="SampleAppTests" name="testRows" time="15.117341"></testcase>
    </testsuite>
</testsuites>
```

```console
build/SampleApp iPad 9.2.log
```

```console
[Info] Loading settings for scheme 'SampleApp' ... (1467 ms)

=== RUN-TESTS ===

  [Info] Collecting info for testables... (1795 ms)
  run-test SampleAppTests.xctest (iphonesimulator9.2, iPhone 5, application-test)
    [Info] Prepared 'SampleApp iPad 9.2' simulator to run tests. (9 ms)
    [Info] Installed 'com.plunien.SampleApp'. (1311 ms)
    [Info] Launched 'com.plunien.SampleApp' on 'SampleApp iPad 9.2'. (7402 ms)
    ~ -[SampleAppTests testDetailView] (56856 ms)
    ~ -[SampleAppTests testRows] (15117 ms)
    2 passed, 0 failed, 0 errored, 2 total (71974 ms)


** RUN-TESTS SUCCEEDED: 2 passed, 0 failed, 0 errored, 2 total ** (84246 ms)
```

```console
build/SampleApp iPhone 9.2.junit.xml
```

```xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<testsuites name="AllTestUnits" tests="2" failures="0" errors="0" time="63.119860">
    <testsuite tests="2" failures="0" errors="0" time="63.119860" timestamp="2016-02-16T07:30:07GMT+04:00" name="Toplevel Test Suite">
        <testcase classname="SampleAppTests" name="testDetailView" time="42.859884"></testcase>
        <testcase classname="SampleAppTests" name="testRows" time="20.259358"></testcase>
    </testsuite>
</testsuites>
```

```console
build/SampleApp iPhone 9.2.log
```

```console
[Info] Loading settings for scheme 'SampleApp' ... (1458 ms)

=== RUN-TESTS ===

  [Info] Collecting info for testables... (1795 ms)
  run-test SampleAppTests.xctest (iphonesimulator9.2, iPhone 5, application-test)
    [Info] Prepared 'SampleApp iPhone 9.2' simulator to run tests. (9 ms)
    [Info] Installed 'com.plunien.SampleApp'. (1312 ms)
    [Info] Launched 'com.plunien.SampleApp' on 'SampleApp iPhone 9.2'. (7356 ms)
    ~ -[SampleAppTests testDetailView] (42859 ms)
    ~ -[SampleAppTests testRows] (20259 ms)
    2 passed, 0 failed, 0 errored, 2 total (63119 ms)


** RUN-TESTS SUCCEEDED: 2 passed, 0 failed, 0 errored, 2 total ** (75426 ms)
```
