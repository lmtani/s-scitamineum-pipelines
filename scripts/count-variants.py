import pysam
import sys

vcf_file = sys.argv[1]  # Replace with your VCF file path

# Open VCF file
vcf = pysam.VariantFile(vcf_file)

# Initialize a dictionary to count variants by type per sample
variant_counts = {sample: {'SNP': 0, 'INDEL': 0, 'OTHER': 0} for sample in vcf.header.samples}

# Function to determine variant type
def variant_type(record):
    ref = record.ref
    alts = record.alts

    if len(alts) > 1:
        print("Multiple alts")
        print(record)
        return 'OTHER'

    alt = alts[0]
    if len(alt)  > len(ref) or len(alt) < len(ref):
        return 'INDEL'
    elif len(alt) == len(ref):
        return 'SNP'
    else:
        raise ValueError("Unexpected variant type")
   
for record in vcf:
    var_type = variant_type(record)  # Determine the variant type
    for sample in record.samples:  # Iterate over samples    
        if record.samples[sample]['GT'][0] is not None:
            variant_counts[sample][var_type] += 1

# Print the counts
for sample, counts in variant_counts.items():
    print(f"Sample: {sample}")
    for var_type, count in counts.items():
        print(f"  {var_type}: {count}")
