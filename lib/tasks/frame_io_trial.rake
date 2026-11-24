namespace :frame_io do
  desc "Ouvrir la recette privée en excluant les fichiers déjà présents dans Publications"
  task ouvrir_recette: :environment do
    trial = FrameIoTrial.open!
    puts "Recette ouverte depuis le #{trial.created_at.iso8601}. Fichiers préexistants exclus : #{trial.existing_file_ids.size}."
  end
end
