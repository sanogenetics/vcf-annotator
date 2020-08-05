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
  .map { file -> tuple(file.simpleName, file) }
  .set { vcf }
Channel
  .fromPath(params.dbsnp)
  .ifEmpty { exit 1, "dbSNP file not found: ${params.dbsnp}" }
  .set { dbsnp }
Channel
  .fromPath(params.dbsnp_index)
  .ifEmpty { exit 1, "dbSNP index file not found: ${params.dbsnp_index}" }
  .set { dbsnp_index }

/*--------------------------------------------------
  Annotate VCF
---------------------------------------------------*/

process annotate_vcf {
  tag "$name"
  publishDir params.outdir, mode: 'copy'

  input:
  set val(name), file(vcf) from vcf
  each file(dbsnp) from dbsnp
  each file(dbsnp_index) from dbsnp_index

  output:
  file("${name}.annotated.vcf.*") into annotated_vcf

  script:
  """
  vcf=$vcf

  # uncompress bgzipped or gzipped input
  if [[ $vcf == *.gz ]]; then
    compression=\$(htsfile $vcf)
    if [[ \$compression == *"BGZF"* ]]; then
      bgzip -cdf $vcf > tmp.vcf && vcf=tmp.vcf
    elif [[ \$compression == *"gzip"* ]]; then
      gzip -cdf $vcf > tmp.vcf && vcf=tmp.vcf
    fi
  else 
    cp $vcf tmp.vcf
  fi

  awk '{gsub(/^chr/,""); print}' tmp.vcf > tmp.fm.vcf
  
  # vcf_remapper.py --input_file \$vcf --output_file ${name}
  # mv output/${name}.vcf ${name}.tmp.vcf
  bgzip tmp.fm.vcf 
  tabix -p vcf tmp.fm.vcf.gz

  bcftools annotate -c CHROM,FROM,TO,ID -a ${dbsnp} -Oz -o ${name}.vcf.gz tmp.fm.vcf.gz
  bgzip -dfc ${name}.vcf.gz 
  cp ${name}.vcf.gz ${name}.annotated.vcf.gz
  tabix -p vcf ${name}.annotated.vcf.gz
  """ 
}
