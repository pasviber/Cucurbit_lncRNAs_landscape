#!/bin/bash

#SBATCH --job-name=PosNR3MH							# Job name.
#SBATCH --output=Positional_NR_3_MEME_High.log				# Standard output and error log.
#SBATCH --qos=medium								# Partition (queue)
#SBATCH --ntasks=100								# Run on one mode. 
#SBATCH --cpus-per-task=1							# Number of tasks = cpus.
#SBATCH --time=3-00:00:00							# Time limit days-hrs:min:sec.
#SBATCH --mem-per-cpu=2gb							# Job memory request.


####### MODULES
module load meme/5.5.1/serial

####### VARIABLES
WD="/storage/ncRNA/Projects/lncRNAs/Cucurbitaceae/Results"
F="/storage/ncRNA/Projects/lncRNAs/Cucurbitaceae/Scripts/Pascual/08-comparative_genomics/Motif_level/Positional_conserved/Functions_NR.sh"
Classes_list="intergenic antisense intronic sense ALL"
Confidence_levels_list="High"
#strictness_list="ORIGINAL RELAXED STRICT MORE-STRICT"
#nonmatch_list="no yes"
strictness_list="ORIGINAL"
nonmatch_list="no"
widths="6-15 6-50"
modes="oops"

####### NEW AND OTHER VARIABLES
WD1=$WD/08-comparative_genomics/Positional_level/Approach_2/nr/04-Families
WD2=$WD/08-comparative_genomics/Motif_level/nr/Positional_conserved

####### DIRECTORY
mkdir -p $WD/08-comparative_genomics
mkdir -p $WD/08-comparative_genomics/Motif_level
mkdir -p $WD/08-comparative_genomics/Motif_level/nr
mkdir -p $WD/08-comparative_genomics/Motif_level/nr/Positional_conserved
mkdir -p $WD/08-comparative_genomics/Motif_level/nr/Positional_conserved/03-MotifFinder
mkdir -p $WD/08-comparative_genomics/Motif_level/nr/Positional_conserved/03-MotifFinder/MEME


####### PIPELINE

### MOTIF FINDER (MEME)
## For each nonmatch level, strictness level, confidence level and class code, find the different motif and make an enrichment analysis.
cd $WD2/03-MotifFinder/MEME

echo -e "\n\nMOTIF FINDER (MEME): Find motivs...\n"

for strictness in $strictness_list; do
	mkdir -p $strictness
	echo -e $strictness"..."
	for nonmatch in $nonmatch_list; do
		mkdir -p $strictness/$nonmatch
		echo -e "\t"$nonmatch"..."
		for confidence in $Confidence_levels_list; do
			mkdir -p $strictness/$nonmatch/$confidence
			echo -e "\t\t"$confidence"..."
			for class in $Classes_list; do
				mkdir -p $strictness/$nonmatch/$confidence/$class
				echo -e "\t\t\t"$class"..."
				for mode in $modes; do
					mkdir -p $strictness/$nonmatch/$confidence/$class/$mode
					echo -e "\t\t\t\t"$mode"..."
					for width in $widths; do
						mkdir -p $strictness/$nonmatch/$confidence/$class/$mode/$width
						echo -e "\t\t\t\t\t"$width"..."
				
						DIR_A="$WD2/02-Preparation/$strictness/$nonmatch/$confidence/$class"
						DIR_B="$WD2/03-MotifFinder/MEME/$strictness/$nonmatch/$confidence/$class/$mode/$width"
						
						cd $DIR_B
						
						# OUTPUTS
						# First, clean the directory.
						if [ -d "$DIR_B/outputs" ]; then
							rm -r outputs
						fi
						mkdir outputs
						
						# REAL.
						# First, clean the directory.
						if [ -d "$DIR_B/real" ]; then
							rm -r real
						fi
						mkdir real
						
						# Second, execute meme by lncRNA family.
						echo -e "\t\t\t\t\t\tREAL"
						>$DIR_B/outputs/stdout_REAL.log
						srun -N1 -n1 -c$SLURM_CPUS_PER_TASK --quiet --exclusive $F task_MEME_2 $DIR_A/real $DIR_B/real $mode $width $DIR_B/outputs/stdout_REAL.log &
						
						# SIMULATIONS.
						# First, clean the directory.
						if [ -d "$DIR_B/simulations" ]; then
							rm -r simulations
						fi
						mkdir simulations
						
						# Second, execute meme by lncRNA family in each iteration.
						echo -e "\t\t\t\t\t\tSIMULATIONS"
						iterations=$(ls -1 $DIR_A/simulations/ | wc -l)
						for i in $(seq $iterations); do
							mkdir simulations/iter_$i
							>$DIR_B/outputs/stdout_SIMULATION_$i.log
							srun -N1 -n1 -c$SLURM_CPUS_PER_TASK --quiet --exclusive $F task_MEME_2 $DIR_A/simulations/iter_$i $DIR_B/simulations/iter_$i $mode $width $DIR_B/outputs/stdout_SIMULATION_$i.log &
						done
						
						cd $WD2/03-MotifFinder/MEME	
					done
					wait
				done
			done
		done
	done
done


