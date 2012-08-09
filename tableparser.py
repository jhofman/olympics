#!/usr/bin/env python

from lxml import etree
import re

class hypertext:
    def __init__(self, text='', href='', img=''):
        self.text = text
        self.href = href
        self.img = img

    def __repr__(self):
        return self.text


# simple class to parse tables
#   pass table as lxml element
#   and xpaths for rows and columns
#   optionally pass column map (zero-indexed)
class tableparser:
    def __init__(self, table=None, row_path='./tbody/tr', col_path='./td', header_path='./thead/tr/th', col_map={}):
        self.table = table
        self.row_path = row_path
        self.col_path = col_path
        self.header_path = header_path
        self.col_map = col_map

    # generator which returns parsed headers
    def header(self):
        for col in self.table.xpath(self.header_path):
            yield str(col.text)

    # generator which returns parsed row data
    def rows(self):
        for row in self.table.xpath(self.row_path):
            yield [data for data in self.cols(row)]


    # generator which returns parsed column data
    # default is to return column text if col_map[i] is specified,
    # however, data from the (i+1)-th column is mapped through the
    # corresponding function
    def cols(self, row):
        for i, data in enumerate(row.xpath(self.col_path)):
            if i in self.col_map:
                yield self.col_map[i](data)
                #for mapped_data in self.col_map[i](data):
                #    yield mapped_data
            else:
                yield data.text


    # column map that returns text, href, and img for column with
    # hypertext. optionally specify regex for which part of href to
    # return
    def hypertext_map(self, href_rx=r'(.*)', img_rx=r'(.*)'):
        href_rx = re.compile(href_rx)
        img_rx = re.compile(img_rx)
        def f(data):
            try:
                a = data.xpath('.//a')[0]
                match = href_rx.search(a.get('href'))

                text = a.xpath('./text()')[0]
                href = match.group(1)
            except IndexError:
                text = data.text
                if not text:
                    text = ''
                href = ''

            try:
                img = data.xpath('.//img')[0]
                match = img_rx.search(img.get('src'))
                
                img = match.group(1)
            except IndexError:
                img = ''

            return hypertext(text=text,
                             href=href,
                             img=img)

        return f

