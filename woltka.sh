#####################
### INPUT OPTIONS ###
#####################

db=/data/databases/WoL/wol-20April2021
input=$1
output=$2

ext=.sam.gz

# output format (biom or tsv)
fmt=tsv

# taxonomy tree format (taxdump or lineage)
#taxtree=taxdump

# taxonomic ranks
#taxranks=phylum,class,order,family,genus,species
taxranks=species


##############
### WOLTKA ###
##############

[ "$fmt" == biom ] && altfmt= || altfmt="--to-tsv"
[ -z "$ext" ] && filext= || filext="--filext $ext"

echo "woltka START"
eval "$(micromamba shell hook --shell bash)" ; micromamba activate woltka

# Taxonomy
woltka classify \
  --input $input \
  --uniq \
  --lineage "${db}/taxonomy/lineages.txt" \
  --name-as-id \
  --rank $taxranks \
    $filext \
    $altfmt \
  --outmap ${output}/mapdir \
  --output ${output}/taxonomy/taxonomic_profile.tsv
echo "TAXONOMIC CLASSIFICATION DONE"



# Stratified functional profile
woltka classify \
  --input ${input} \
  --coords "${db}/proteins/coords.txt.xz" \
  --map "${db}/function/uniref/uniref.map.xz" \
  --map "${db}/function/kegg/ko.map.xz" \
  --rank ko \
  --stratify ${output}/mapdir/ \
    $filext \
    $altfmt \
  --output ${output}/functional/stratified_functional_profile.tsv
echo "STRATIFIED FUNCTIONAL CLASSIFICATION DONE"



# Unstratified functional profile
woltka classify \
  --input ${input} \
  --coords "${db}/proteins/coords.txt.xz" \
  --map "${db}/function/uniref/uniref.map.xz" \
  --map "${db}/function/kegg/ko.map.xz" \
  --rank ko \
    $filext \
    $altfmt \
  --output ${output}/functional/unstratified_functional_profile.tsv
echo "UNSTRATIFIED FUNCTIONAL CLASSIFICATION DONE"



conda deactivate
echo "woltka FINISHED"
