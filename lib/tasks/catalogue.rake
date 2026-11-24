namespace :catalogue do
  desc "Importer le catalogue historique local depuis MANIFEST=/chemin/catalogue.json"
  task import: :environment do
    count = LegacyCatalogue.new(ENV.fetch("MANIFEST")).import!
    puts "#{count} fiche(s) traitée(s)."
  end
end
