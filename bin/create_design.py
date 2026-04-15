import os
import argparse
import pandas as pd

def create_design(fastq_1, fastq_2, meta, output):
    # Read metadata
    meta_df = pd.read_csv(meta)
    
    # Create design DataFrame
    design_df = pd.DataFrame({
        'fastq_1': fastq_1,
        'fastq_2': fastq_2,
        'sample_id': meta_df['sample_id']
    })
    
    # Save to CSV
    design_df.to_csv(output, index=False)
    print(f"Design file created: {output}")