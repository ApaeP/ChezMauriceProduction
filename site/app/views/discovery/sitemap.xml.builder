xml.instruct!
xml.urlset(xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9") do
  [ root_url, realisations_url, contact_url, mentions_legales_url ].each do |url|
    xml.url { xml.loc(url) }
  end
  @film_ids.each do |id|
    xml.url { xml.loc(realisation_url(id)) }
  end
end
