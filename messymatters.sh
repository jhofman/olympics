#!/bin/bash
#
# file: messymatters.sh
#
# description: code to scrape and analyze olympics data from sports-reference.com
#
# usage: ./messymatters.sh
#
# requirements:
#   wget
#   lxml module for python
#   ggplot2 and plyr packages for R
#
# author: jake hofman (gmail: jhofman)
#
 
# download html medal summaries for all sports and events
./pull_sports.sh

# extract gold, silver, and bronze medalists for all track (ATH) and swimming (SWI) events
[ -f ath_medalists.tsv ] || ./parse_sports.py ATH
[ -f swi_medalists.tsv ] || ./parse_sports.py SWI

# download html for medalist's pages, which contain their records
./pull_medalists.sh ath_medalists.tsv
./pull_medalists.sh swi_medalists.tsv

# extract records for all medalists we've pulled to records.tsv
./parse_medalists.py

# generate plots
[ -d figures ] || mkdir figures
Rscript messymatters.R

