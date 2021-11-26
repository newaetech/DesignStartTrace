#!/usr/bin/env python3

import argparse
import subprocess
import random
import re
import time
from tqdm import tqdm

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
                 USB_CLOCK_SEL = [0, 1],
                 TRACE_CLOCK_SEL = 0,
                 SWO_DIV = [1, 13],
                 USB_CLOCK_PERIOD = [6, 14, 2],
                 EVENTS = 30))

    tests.append(dict(name  = 'swo_rules_swtrig',
                 frequency = 3,
                 description = 'SWO, rules mode',
                 SWO_MODE = 1,
                 CAPTURE_RAW = 0,
                 PATTERN_TRIG = 0,
                 RULES = 8,
                 USB_CLOCK_SEL = [0, 1],
                 TRACE_CLOCK_SEL = 0,
                 SWO_DIV = [1, 13],
                 USB_CLOCK_PERIOD = [6, 14, 2],
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
                 USB_CLOCK_SEL = [0, 1],
                 TRACE_CLOCK_SEL = 0,
                 SWO_DIV = [1, 13],
                 USB_CLOCK_PERIOD = [6, 14, 2],
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

def check_pass_fail(logfile):
    log = open(logfile, 'r')
    passed = None
    warnings = 0
    errors = 0
    for line in log:
       pass_matches = pass_regex.search(line)
       fail_matches = fail_regex.search(line)
       if pass_matches:
          passed = 1
          warnings = int(pass_matches.group(1))
          break
       elif fail_matches:
          passed = 0
          errors = int(fail_matches.group(1))
          break
    log.close()
    if passed is None:
        print("*** parsing error on %s ***" % logfile)
    return passed, warnings, errors


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

# Check once that compile passes:
outfile = open('regress.out', 'w')
makeargs = ['make', 'compile', 'TARGET_CLOCK_TRACE_PERIOD=10', 'TARGET_CLOCK_SWO_PERIOD=10', 'TRIGGER_CLOCK_PERIOD=10']
result = subprocess.run(makeargs, stdout=outfile, stderr=outfile)
if result.returncode:
   print ("Compilation failed (return code: %d), check regress.out." % result.returncode)
   quit()

# Run tests:
start_time = int(time.time())
processes = []

print("Dispatching jobs... ", end='')
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

      # some required defaults for all testcases, used in calculation later:
      TARGET_CLOCK_TRACE_PERIOD = 168
      SWO_DIV = 1
      USB_CLOCK_SEL = 0

      for key in test.keys():
         if key == 'name':
            logfile = "results/%s%d.log" % (test[key], i) 
            rundir = "run_%s%d" % (test[key], i) 
            exefile = "run.vvp"
            makeargs.append("LOGFILE=%s" % logfile)
            makeargs.append("EXEFILE=%s" % exefile)
            makeargs.append("RUNDIR=%s" % rundir)
         elif key == 'description':
            pass
         elif key == 'frequency':
            if test[key] == 0:
               run_test = False
            elif i % test[key]:
               run_test = False
         else:
            if type(test[key]) == list:
                if len(test[key]) == 2:
                   value = random.randint(test[key][0], test[key][1])
                elif len(test[key]) == 3:
                   value = random.randrange(test[key][0], test[key][1], test[key][2])
                else:
                   raise ValueError
            else:
               value = test[key]

            # if these aren't specified by the testcase they will retain their previously defined default value
            if key == 'SWO_DIV':
               SWO_DIV = value
            elif key == 'USB_CLOCK_SEL':
               USB_CLOCK_SEL = value

            makeargs.append("%s=%s" % (key, value))

      # Target clock arguments computed here because they're needed by both the
      # Verilog testbench and gen_trace_data.py.
      # In parallel trace mode, each tick of the target clock carries 4 trace bits; 
      # In SWO mode, each tick carries 1 / (pSWO_DIV + 1) bits; 1.5 factor is extra margin for start/stop bits:
      TARGET_CLOCK_SWO_PERIOD = int(TARGET_CLOCK_TRACE_PERIOD / (1.5*4))
      TRIGGER_CLOCK_PERIOD = int(TARGET_CLOCK_TRACE_PERIOD / (1.5*4*(SWO_DIV+1)))
      if TRIGGER_CLOCK_PERIOD % 2:
          TRIGGER_CLOCK_PERIOD -= 1
      if TRIGGER_CLOCK_PERIOD < 2:
          raise ValueError("Required trigger clock is too fast; reduce SWO_DIV.")
      makeargs.append("TARGET_CLOCK_SWO_PERIOD=%s" % TARGET_CLOCK_SWO_PERIOD)
      makeargs.append("TARGET_CLOCK_TRACE_PERIOD=%s" % TARGET_CLOCK_TRACE_PERIOD)
      makeargs.append("TRIGGER_CLOCK_PERIOD=%s" % TRIGGER_CLOCK_PERIOD)
      makeargs.append("SWO_DIV=%s" % SWO_DIV)
      makeargs.append("USB_CLOCK_SEL=%s" % USB_CLOCK_SEL)

      # run:
      if run_test:
         p = subprocess.Popen(makeargs, stdout=outfile, stderr=outfile)
         processes.append((p,logfile,seed))

num_processes = len(processes)
print("done. %d tests running." % num_processes)

warns = []
fails = []

pbar       = tqdm(total=len(processes), desc='Tests finished')
pbarpassed = tqdm(total=len(processes), desc='Tests passing ')

oldfinished = 0
finished = 0
oldpass_count = 0
fail_count = 0
pass_count = 0
while len(processes):
    for p,l,s in processes:
        if not p.poll() is None:
            finished += 1
            passed, warnings, errors = check_pass_fail(l)
            pass_count += passed
            if warnings:
                warns.append("%s: %0d warnings" % (l, warnings))
            if errors:
                fail_count += 1
                fails.append("%s: %d errors (seed=%d)" % (l, errors, s))
            processes.remove((p,l,s))

    pbar.update(finished - oldfinished)
    pbarpassed.update(pass_count - oldpass_count)
    oldfinished = finished
    oldpass_count = pass_count
    time.sleep(1)
pbar.close()
pbarpassed.close()

# just to be sure:
#exit_codes = [p.wait() for p,l,s in processes]

# sanity check:
assert num_processes == pass_count + fail_count


# Summarize results:
print('\n*** RESULTS SUMMARY ***')
print('%d tests passing, %d tests failing.' % (pass_count, fail_count))
print('Elapsed time: %d seconds' % (int(time.time() - start_time)))
if warns:
    for w in warns:
        print(w)
if fails:
    for f in fails:
        print(f)

