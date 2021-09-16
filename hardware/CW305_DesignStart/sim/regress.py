#!/usr/bin/env python3

import argparse
import subprocess
import random
import re
import time

parser = argparse.ArgumentParser()
group = parser.add_mutually_exclusive_group()
group.add_argument("--runs", type=int, help="Number of iterations.", default=1)
group.add_argument("--test", help="Testcase to run")
parser.add_argument("--seed", type=int, help="Seed to use when running a single test with --test.")
parser.add_argument("--tests", help="Run all tests whose name contains TESTS", default='')
parser.add_argument("--list", help="List available tests.", action='store_true')
parser.add_argument("--dump", help="Enable waveform dumping.", action='store_true')
parser.add_argument("--CW305", help="Run CW305 tests only.", action='store_true')
args = parser.parse_args()

# Define testcases:
tests = []
tests.append(dict(name  = 'fewrules',
             frequency = 5,
             description = 'Few rules, lots of events, capture rules.',
             CAPTURE_RAW = 0,
             RULES = 2,
             TRACE_CLOCK_SEL = [0, 1],
             EVENTS = 30))

tests.append(dict(name  = 'manyrules',
             frequency = 5,
             description = 'Many rules, lots of events, capture rules.',
             CAPTURE_RAW = 0,
             RULES = 8,
             EVENTS = 30))

tests.append(dict(name  = 'swtrigger_raw',
             frequency = 3,
             description = 'Lots of events, capture raw traces, triggered by sofware.',
             CAPTURE_RAW = 1,
             TRACE_CLOCK_SEL = [0, 1],
             PATTERN_TRIG = 0,
             RULES = 1,
             EVENTS = 30))

tests.append(dict(name  = 'patterntrigger_raw',
             frequency = 3,
             description = 'Lots of events, capture raw trace, triggered by pattern.',
             CAPTURE_RAW = 1,
             PATTERN_TRIG = 1,
             TRACE_CLOCK_SEL = [0, 1],
             RULES = 4,
             EVENTS = 30))

tests.append(dict(name  = 'long_timestamps_raw',
             frequency = 1,
             description = 'Small max timestamp, capture raw traces, triggered by sofware.',
             MAX_TIMESTAMP = 1024,
             CAPTURE_RAW = 1,
             PATTERN_TRIG = 0,
             TRACE_CLOCK_SEL = [0, 1],
             RULES = 1,
             EVENTS = 30))

tests.append(dict(name  = 'lots_long_timestamps_raw',
             frequency = 1,
             description = 'Very small max timestamp so that they occur successively, capture raw traces, triggered by sofware.',
             MAX_TIMESTAMP = 600,
             CAPTURE_RAW = 1,
             PATTERN_TRIG = 0,
             TRACE_CLOCK_SEL = [0, 1],
             RULES = 1,
             EVENTS = 30))

tests.append(dict(name  = 'long_corner',
             frequency = 1,
             description = 'Corner case: event coincident with a long timestamp.',
             MAX_TIMESTAMP = 528,
             CAPTURE_RAW = 1,
             PATTERN_TRIG = 0,
             TRACE_CLOCK_SEL = [0, 1],
             RULES = 1,
             LONGCORNER = 1,
             EVENTS = 15))


tests.append(dict(name  = 'long_timestamps_rules',
             frequency = 1,
             description = 'Small max timestamp, capture rules, triggered by sofware.',
             MAX_TIMESTAMP = 1024,
             CAPTURE_RAW = 0,
             PATTERN_TRIG = 0,
             TRACE_CLOCK_SEL = [0, 1],
             RULES = 4,
             EVENTS = 30))



if not args.CW305:
    tests.append(dict(name  = 'swo_raw_swtrig',
                 frequency = 3,
                 description = 'SWO, raw mode',
                 SWO_MODE = 1,
                 CAPTURE_RAW = 1,
                 PATTERN_TRIG = 0,
                 RULES = 4,
                 #TIMEOUT = 10000, # TODO-temp
                 USB_CLOCK_SEL = 1, # TODO-temp
                 TRACE_CLOCK_SEL = 0, # TODO-temp
                 EVENTS = 30))

    tests.append(dict(name  = 'swo_rules_swtrig',
                 frequency = 3,
                 description = 'SWO, rules mode',
                 SWO_MODE = 1,
                 CAPTURE_RAW = 0,
                 PATTERN_TRIG = 0,
                 RULES = 8,
                 #TIMEOUT = 10000, # TODO-temp
                 USB_CLOCK_SEL = 1, # TODO-temp
                 TRACE_CLOCK_SEL = 0, # TODO-temp
                 EVENTS = 30))

    tests.append(dict(name  = 'capture_now',
                 frequency = 2,
                 description = '...',
                 CAPTURE_RAW = 1,
                 PATTERN_TRIG = 0,
                 CAPTURE_NOW = 1,
                 TRACE_CLOCK_SEL = [0, 1],
                 RULES = 1,
                 EVENTS = 30))

    tests.append(dict(name  = 'swo_raw_fastread',
                 frequency = 2,
                 description = 'SWO, raw mode, fast FIFO read (timestamps disabled)',
                 TIMESTAMPS_DISABLED = 1,
                 SWO_MODE = 1,
                 CAPTURE_RAW = 1,
                 PATTERN_TRIG = 0,
                 RULES = 4,
                 #TIMEOUT = 10000, # TODO-temp
                 USB_CLOCK_SEL = 1, # TODO-temp
                 TRACE_CLOCK_SEL = 0, # TODO-temp
                 EVENTS = 30))

    tests.append(dict(name  = 'raw_fastread',
                 frequency = 2,
                 description = 'Raw mode, fast FIFO read (timestamps disabled)',
                 TIMESTAMPS_DISABLED = 1,
                 SWO_MODE = 0,
                 CAPTURE_RAW = 1,
                 PATTERN_TRIG = 0,
                 TRACE_CLOCK_SEL = [0, 1],
                 RULES = 4,
                 EVENTS = 30))



def print_tests():
    print("Available tests:")
    for test in tests:
       print("%s: %s" % (test['name'], test['description']))
    quit()

if (args.list):
    print_tests()
    quit()

# if running a single testcase:
if (args.test):
   found = False
   for test in tests:
      if test['name'] == args.test:
         found = True
         tests = [test]
         break
   if not found:
      print("Error: test %s undefined." % args.test)
      print_tests()


pass_regex = re.compile(r'^Simulation passed \((\d+) warnings')
fail_regex = re.compile(r'^SIMULATION FAILED \((\d+) errors')
seed_regex = re.compile(r'^Running with pSEED=(\d+)$')
test_regex = re.compile(args.tests)

passed = 0
failed = 0

# Check once that compile passes:
outfile = open('regress.out', 'w')
makeargs = ['make', 'compile']
result = subprocess.run(makeargs, stdout=outfile, stderr=outfile)
if result.returncode:
   print ("Compilation failed (return code: %d), check regress.out." % result.returncode)
   quit()

# Run tests:
start_time = int(time.time())
for test in tests:
   if args.tests:
      if test_regex.search(test['name']) == None:
          continue
   for i in range(args.runs):

      # set the random seed first, so that both Python and Verilog randomizations are reproducible:
      if (args.seed):
         seed = args.seed
      else:
         seed = random.randint(0, 2**31-1)
      random.seed(seed)

      run_test = True
      # build make command:
      makeargs = ['make', 'all', 'VERBOSE=0']
      makeargs.append("SEED=%d" % seed)
      if args.dump:
         makeargs.append('DUMP=1')
      for key in test.keys():
         if key == 'name':
            logfile = "results/%s%d.log" % (test[key], i) 
            makeargs.append("LOGFILE=%s" % logfile)
         elif key == 'description':
            pass
         elif key == 'frequency':
            if test[key] == 0:
               run_test = False
            elif i % test[key]:
               run_test = False
         else:
            if type(test[key]) == list:
               value = random.randint(test[key][0], test[key][1])
            else:
               value = test[key]
            makeargs.append("%s=%s" % (key, value))


      # run:
      if run_test:
         print("Running %s... " % logfile, end='', flush=True)
         subprocess.run(makeargs, stdout=outfile, stderr=outfile)

         # check pass/fail:
         log = open(logfile, 'r')
         for line in log:
            pass_matches = pass_regex.search(line)
            fail_matches = fail_regex.search(line)
            if pass_matches:
               passed += 1
               print("pass (%0d warnings)" % (int(pass_matches.group(1))))
               break
            elif fail_matches:
               failed += 1
               print("FAILED! %d errors, seed = %d" % (int(fail_matches.group(1)), seed))
               break


# Summarize results:
print('\n*** RESULTS SUMMARY ***')
print('%d tests passing, %d tests failing.' % (passed, failed))
print('Elapsed time: %d seconds' % (int(time.time() - start_time)))



