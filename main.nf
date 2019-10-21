#!/usr/bin/env nextflow
/*
========================================================================================
                         PhilPalmer/vcf-annotator
========================================================================================
 PhilPalmer/vcf-annotator Nextflow pipeline to annotate VCF files
 #### Homepage / Documentation
 https://github.com/PhilPalmer/vcf-annotator
----------------------------------------------------------------------------------------
*/

Channel
  .fromPath(params.vcf)
  .ifEmpty { exit 1, "VCF file not found: ${params.vcf}" }
  .map { file -> tuple(file.baseName, file) }
  .set { vcf }
Channel
  .fromPath(params.dbsnp)
  .ifEmpty { exit 1, "dbSNP file not found: ${params.dbsnp}" }
  .set { dbsnp }

/*--------------------------------------------------
  Annotate VCF
---------------------------------------------------*/

process annotate_vcf {
  tag "$name"
  publishDir params.outdir, mode: 'copy'

  input:
  set val(name), file(vcf) from vcf
  each file(dbsnp) from dbsnp

  output:
  file('*') into downloaded_files

  script:
  """
  gzip -df $dbsnp
  bgzip -c ${dbsnp.baseName} > $dbsnp
  tabix -p vcf $dbsnp

  vcf=$vcf

  # check if input is bgzipped or gzipped
  if [[ $vcf == *.gz ]]; then
    compression=\$(htsfile $vcf)
    if [[ \$compression == *"BGZF"* ]]; then
      mv $vcf ${name}.tmp.vcf.gz && vcf=${name}.tmp.vcf.gz
    elif [[ \$compression == *"gzip"* ]]; then
      gzip -cdf $vcf > tmp.vcf && vcf=tmp.vcf
    fi
  fi

  # bgzip uncompressed VCFs
  if [[ \$vcf == *.vcf ]]; then
    bgzip -c \$vcf > ${name}.tmp.vcf.gz
  fi

  tabix -p vcf ${name}.tmp.vcf.gz
  bcftools annotate -c CHROM,FROM,TO,ID -a ${dbsnp} -Oz -o ${name}.vcf.gz ${name}.tmp.vcf.gz
  """ 
}