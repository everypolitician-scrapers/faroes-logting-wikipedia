#!/bin/env ruby
# encoding: utf-8

require 'nokogiri'
require 'open-uri'
require 'scraperwiki'
require 'pry'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

class String
  def tidy
    self.gsub(/[[:space:]]+/, ' ').strip
  end
end

def noko_for(url)
  Nokogiri::HTML(open(url).read)
end

def scrape_term(term)
  noko = noko_for(term[:source])
  table = noko.xpath(".//table[.//th[contains(.,'Flokkur')]][1]")
  raise "Can't find unique table of Members" unless table.count == 1
  table.xpath('.//tr[td]').each do |tr|
    tds = tr.css('td')
    wikiname = tds[0].css('a/@title').first.text.sub(' (síðan er ikki til)','')
    data = { 
      id: wikiname.downcase.tr(' ', '_'),
      name: tds[0].css('a').first.text.tidy,
      party: tds[1].text.tidy,
      party_wikipedia: tds[1].css('a/@title').first.text,
      constituency: tds[2].text,
      term: term[:id],
      identifier__wikipedia_fo: wikiname,
      source: term[:source],
    }
    ScraperWiki.save_sqlite([:id, :term], data)
  end
end

ScraperWiki.sqliteexecute('DROP TABLE data') rescue nil

term_data = [ 
  [ '1990', 'https://fo.wikipedia.org/wiki/L%C3%B8gtingslimir_%C3%AD_F%C3%B8royum_1990-94', ],
  [ '1994', 'https://fo.wikipedia.org/wiki/L%C3%B8gtingslimir_%C3%AD_F%C3%B8royum_1994-98', ],
  [ '1998', 'https://fo.wikipedia.org/wiki/L%C3%B8gtingslimir_%C3%AD_F%C3%B8royum_1998%E2%80%932002', ],
  [ '2002', 'https://fo.wikipedia.org/wiki/L%C3%B8gtingslimir_%C3%AD_F%C3%B8royum_2002-2004' ],
  [ '2004', 'https://fo.wikipedia.org/wiki/L%C3%B8gtingslimir_%C3%AD_F%C3%B8royum_2004-2008', ],
  [ '2008', 'https://fo.wikipedia.org/wiki/L%C3%B8gtingslimir_%C3%AD_F%C3%B8royum_2008%E2%80%932011', ],
  [ '2011', 'https://fo.wikipedia.org/wiki/L%C3%B8gtingslimir_%C3%AD_F%C3%B8royum_2011%E2%80%932015', ],
  [ '2015', 'https://fo.wikipedia.org/wiki/L%C3%B8gtingslimir_%C3%AD_F%C3%B8royum_2015%E2%80%932019', ],
]

term_data.each_with_index do |t, i|
  term = {
    id: t.first,
    source: t.last,
  }
  scrape_term(term)
end
