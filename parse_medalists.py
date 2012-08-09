#!/usr/bin/env python

import sys
from glob import glob
import codecs
from lxml import etree
from tableparser import tableparser

def htmlbase(url):
    return url.split('/')[-1].replace('.html','')

def main():
    if len(sys.argv) != 2:
        print "usage: %s <SPORTCODE>" % sys.argv[0]
        sys.exit(1)

    sport_code = sys.argv[1]

    events = glob('www.sports-reference.com/olympics/sports/%s/*.html' % sport_code.upper())

    medalists = codecs.open('%s_medalists.tsv' % sport_code.lower(),'w', encoding='utf-8')
    for event in events:
        if event.endswith('index.html'):
            continue

        event_name = htmlbase(event) #event.split('/')[-1].replace('.html','')
        
        html = open(event,'r')
        tree = etree.parse(html, etree.HTMLParser())
        html.close()

        table = tree.xpath('//table[@id="medals"]')[0]

        tp = tableparser(table)
        headers = list(tp.header())
        for i in xrange(len(headers)):
            tp.col_map[i] = tp.hypertext_map(img_rx=r'images/flags/([A-Z]+).png$')

        for row in tp.rows():
            year, gold, silver, bronze = row

            medalists.write("%s\t%s\tGold\t%s\t%s\t%s\t%s\n" % (year, event_name, gold.img, gold, htmlbase(gold.href), gold.href) )
            medalists.write("%s\t%s\tSilver\t%s\t%s\t%s\t%s\n" % (year, event_name, silver.img, silver, htmlbase(silver.href), silver.href) )
            medalists.write("%s\t%s\tBronze\t%s\t%s\t%s\t%s\n" % (year, event_name, bronze.img, bronze, htmlbase(bronze.href), bronze.href) )

    medalists.close()
    return 0


if __name__=='__main__':
    main()
