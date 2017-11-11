from collections import defaultdict
import os.path

BUILD_DIR = "/Users/s3j/_code/_build/swig-debug"

results = defaultdict(list)
with open(os.path.join(BUILD_DIR,
        "Examples/test-suite/fortran/summary.txt")) as f:
    for line in f:
        (test, result) = line.strip().split('|')
        results[result].append(test)

for (k,v) in results.items():
    print("{:25s}: {:4d}".format(k, len(v)))

with open("failing-tests.mk", 'w') as f:
    for k in reversed(sorted(results)):
        if k == "passed":
            continue
        print('\n#',k, file=f)
        print("FAILING_CPP_TESTS += \\\n ", " \\\n  ".join(sorted(results[k])),
                file=f)
