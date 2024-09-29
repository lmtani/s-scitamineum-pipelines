import sys
import pandas as pd
import vcfpy
from collections import defaultdict
import matplotlib.pyplot as plt
from upsetplot import plot


# TODO: Make it be dynamic
samples = ['SSC39-MAT-1', 'SSC39-MAT-2', 'SSC04-MAT-1', 'SSC04-MAT-2']
combination_counts = defaultdict(int)

# Open the VCF file
vcf_reader = vcfpy.Reader.from_path(sys.argv[1])

# Process each record in the VCF
for record in vcf_reader:
    presence = []
    for sample in samples:
        call = record.call_for_sample[sample]
        gt = call.data.get('GT')

        if gt == '.' or gt == '0' or gt == './.' or gt is None:
            presence.append(False)
        else:
            presence.append(True)

    # Convert presence list to tuple to use as a key
    presence_tuple = tuple(presence)
    # Increment the count for this combination
    combination_counts[presence_tuple] += 1


renamed_samples = ['SSC39 MAT-1', 'SSC39 MAT-2', 'SSC04 MAT-1', 'SSC04 MAT-2']
# Now, create the index and counts
index = pd.MultiIndex.from_tuples(
    combination_counts.keys(),
    names=renamed_samples
)
counts = list(combination_counts.values())


# Create the UpSet plot
series = pd.Series(counts, index=index, name='value')
plot(series, show_counts=True)
plt.tight_layout()

plt.savefig("upset.png", dpi=300)
# plt.show()