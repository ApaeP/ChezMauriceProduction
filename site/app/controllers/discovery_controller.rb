class DiscoveryController < ApplicationController
  def sitemap
    @film_ids = Realisation.published.order(:id).pluck(:id)
  end

  def robots
    render plain: "User-agent: *\nDisallow: /up\nSitemap: #{sitemap_url}\n"
  end
end
