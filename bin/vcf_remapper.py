#! /usr/bin/env python

"""
Validate input VCF files & remap them to GRCh37.
depends on:
> python 3
> argparse==1.4.0
> snps==0.4.0
> io
"""

import argparse
from snps import SNPs
import io

parser = argparse.ArgumentParser(description='Remap VCF files to GRCh37')
parser.add_argument('-i', '--input_file', help='Input VCF file')
parser.add_argument('-o', '--output_file', help='Output VCF file basename')
args = vars(parser.parse_args())
input_file = args['input_file']
output_file = args['output_file']
output_file_name = f"{output_file}.vcf"

# read & validate input file
snps = SNPs(input_file)

# remap SNPs if reference genome is not GRCh37
if snps.build_detected and snps.build != 37:
    snps.remap_snps(37)

# save to file
saved_snps = snps.save_snps(output_file_name, sep="\t", header=False, vcf=True)