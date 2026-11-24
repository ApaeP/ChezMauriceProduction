class RealisationsController < ApplicationController
  # Promoted frame visits merge the film metadata into the current document head.
  layout "application", only: :show

  def index
    @categories = Category.joins(:realisations).merge(Realisation.published).distinct.order(:name)
    @category = @categories.find(params[:categorie]) if params[:categorie].present?

    catalogue = @category ? @category.realisations : Realisation.all
    @realisations = catalogue.published.ordered.preload(:categories).with_attached_thumbnail
  end

  def show
    @realisation = Realisation.published.find(params[:id])
  end
end
