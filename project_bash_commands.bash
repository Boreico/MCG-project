# Running CheckM on MAGs (reference Bacteria)

mkdir checkm_output
conda activate checkm
bunzip2 mags/* && checkm taxonomy_wf domain Bacteria mags checkm_output -t 4

# Running PhyloPhlAn on MAGs

mkdir phylophlan_output
conda activate ppa
phylophlan_metagenomic -i mags -o phylophlan_output/ppa_m --nproc 4 -n 1 -d CMG2324 --database_folder ~/ppa_db --verbose

# Running CheckM on MAGs (reference Spirochaetales)

mkdir checkm_output_spirochaetales
checkm taxonomy_wf order Spirochaetales mags checkm_output_spirochaetales -t 4


# Plotting disriptive plot for each MAG

cat mags/*.fna > combined_mags.fna
check tetra combined_mags.fna join_tetra.tsv
checkm dist_plot --dpi 300 checkm_output_spirochaetales mags displot join_tetra.tsv 30

# Running Prokka

conda activate prokka
for f in mags/*; do
mag=$(basename $f .fna)
mkdir -p prokka_output/${mag}
prokka mags/${mag}.fna \
--outdir prokka_output/${mag} \
--prefix ${mag} \
--force \
--compliant
done

# Running Roary
conda activate roary
roary prokka_output/*/*.gff \
-f roary_output \
-i 95 \
-cd 90 \
-p
cd roary_output
curl https://raw.githubusercontent.com/sanger-pathogens/Roary/master/bin/create_pan_genome_plots.R \
-o create_pan_genome_plots.R
chmod +x create_pan_genome_plots.R
conda deactivate && conda activate roary_plots
Rscript create_pan_genome_plots.R
curl https://raw.githubusercontent.com/sanger-pathogens/Roary/master/contrib/roary_plots/roary_plots.py \
-o roary_plots.py
python roary_plots.py -h
python roary_plots.py accessory_binary_genes.fa.newick gene_presence_absence.csv

# Running FastTree

roary prokka_output/*/*.gff \
-f roary_output_w_aln \
-cd 90 \
-p 4 \
-e -n

FastTreeMP -pseudo -spr 4 -mlacc 2 -slownni -fastest -no2nd -mlnni 4 -gtr -nt -out roary_output_w_aln/core_gene_phylogeny.nwk roary_output_w_aln/core_gene_alignment.aln
