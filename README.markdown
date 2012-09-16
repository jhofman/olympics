code to scrape and analyze olympics data from sports-reference.com. run messymatters.sh to scrape data and generate plots for [the messymatters blog post](http://messymatters.com/olympic-records).

*   pull_sports.sh:
	downloads html medal summaries for all sports and events
	containing links to gold, silver, and bronze medalists for
	each year. e.g.:

	     ./pull_sports.sh

	fetches

	     http://www.sports-reference.com/olympics/sports/ATH/mens-100-metres.html

*   parse_sport.py:
	extracts gold, silver, and bronze medalists for all events in
	the specified sport. e.g.,

		./parse_sports.py ATH

	produces `ath_medalists.tsv` containing

		2012    mens-100-metres JAM     Usain Bolt      usain-bolt-1    http://www.sports-reference.com/olympics/athletes/bo/usain-bolt-1.html
		2012    mens-100-metres JAM     Yohan Blake     yohan-blake-1   http://www.sports-reference.com/olympics/athletes/bl/yohan-blake-1.html
		2012    mens-100-metres USA     Justin Gatlin   justin-gatlin-1 http://www.sports-reference.com/olympics/athletes/ga/justin-gatlin-1.html

*   pull_medalists.sh:
	downloads html for medalist's pages, which contain their
	performance details (time/score/etc). e.g.,

		./pull_medalists.sh ath_medalists.tsv

	fetches

		http://www.sports-reference.com/olympics/athletes/bo/usain-bolt-1.html
		http://www.sports-reference.com/olympics/athletes/bl/yohan-blake-1.html
		http://www.sports-reference.com/olympics/athletes/ga/justin-gatlin-1.html

*   parse_medalists.py:

	extracts performance details for all medalists, across all
	sports. e.g.,

		./parse_medalists.py

	produces `records.tsv` containing

		2012	usain-bolt-1	25	Final	mens-100-metres-final	1	None	9.63	
		2012	yohan-blake-1	22	Final	mens-100-metres-final	2	None	9.75	
		2012	justin-gatlin-1	30	Final	mens-100-metres-final	3	None	9.79	