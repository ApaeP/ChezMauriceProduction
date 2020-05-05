# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
puts "Creating a user"
User.create!(email: 'bite@test.com', password: 'azerty')
puts "User created"

videos_from_vimeo = [["https://vimeo.com/396446791", "Veolia", '"Les héros de l’eau" Ep 1 - Veolia', "Corporate"],
 ["https://vimeo.com/380593500", "UrbanEra", "Manifeste pour le renouvellement Urbain - Urbanera", "Corporate"],
 ["https://vimeo.com/391924943", "Capital8", "Film de présentation pour Capital 8", "Corporate"],
 ["https://vimeo.com/392024943", "UrbanEra teaser", "Teaser - Manifeste pour le renouvellement urbain - Urbanera", "Corporate"],
 ["https://vimeo.com/375635015", "Kärcher", "Témoignage de Florian Marguerie de chez Kärcher pour l’agence Kiss The Bride", "Corporate"],
 ["https://vimeo.com/270397040", "Maisons-lafitte", "Centre d’entrainement hippique de Maisons-Laffitte 2018", "Corporate"],
 ["https://vimeo.com/298146063", "JPH", "Jean-Paul Hévin chocolatier", "Corporate"],
 ["https://vimeo.com/372093798", "MACSF", "Interview pour la MACSF de Camille Reynier, Sage-Femme", "Corporate"],
 ["https://vimeo.com/345659457", "cegiditw", "Interview d’Antoine Wattinne, Directeur des Affaires Publique chez Cegid", "Corporate"],
 ["https://vimeo.com/352236611", "cegid", "Film institutionnel - Cegid comptabilité", "Corporate"],
 ["https://vimeo.com/348110998", "spotlight", "Interview “Spotlight” chez Kiss the Bride avec Sandrine Fonteneau et Cyrille Peixoto", "Corporate"],
 ["https://vimeo.com/343609838", "spotlight2", "Interview “Spotligtht” pour Kiss the Bride avec Sandrine Fonteneau et Cyrille Peixoto", "Corporate"],
 ["https://vimeo.com/329979289", "vocalyz", "Vocalyz, porte-partitions pour musiciens et choristes, de Viquel", "Corporate"],
 ["https://vimeo.com/312724698", "7minutes", "7 minutes avec Marlène Schiappa, Christophe Castaner & Mounir Mahjoubi", "Corporate"],
 ["https://vimeo.com/327255494", "dylan robert", "Shooting Dylan Robert", "Corporate"],
 ["https://vimeo.com/329980083", "quentin2", "“Quentin vous éclaire” Ep 2", "Corporate"],
 ["https://vimeo.com/312724295", "cegiditw2", "Interview de Christophe Maillet pour Cegid", "Corporate"],
 ["https://vimeo.com/298146279", "JPH2", "Jean-Paul Hévin Pâtisserie", "Publicité"],
 ["https://vimeo.com/298145392", "necker enfants", "Fonds pour les soins palliatifs à l’Hôpital Necker-Enfants malades", "Publicité"],
 ["https://vimeo.com/281796649", "rodolpheco", "Rodolphe & Co à Paris", "Publicité"],
 ["https://vimeo.com/281287005", "kds rh", "KDS - film de présentation RH", "Publicité"],
 ["https://vimeo.com/275996956", "70ans clamart", "Soirée des 70 ans des Docks de Clamart", "Publicité"],
 ["https://vimeo.com/275996522", "toitauxsables", "Présentation d’une maisons aux Sables-d’Olonne pour Un toit aux Sables", "Publicité"],
 ["https://vimeo.com/275076872", "kisstb", "Interview de Pierre-François Canault pour Kiss the bride", "Publicité"],
 ["https://vimeo.com/275073590", "airbus", "Film de présentation pour GDI Simulation (Airbus)", "Publicité"],
 ["https://vimeo.com/270397486", "ucollec", "Collection printemps/été 2018 pour U Collection", "Publicité"],
 ["https://vimeo.com/255531549", "maisonslaffitte", "Centre d’entrainement de Maisons-Laffitte 2017", "Publicité"],
 ["https://vimeo.com/225829270", "CFE_CGC", "La télé CFE-CGC pour la CFE-CGC", "Publicité"],
 ["https://vimeo.com/225829162", "mineral", "Tutoriel Mineral whitener pour Rodolphe & Co", "Publicité"],
 ["https://vimeo.com/225828643", "desarçonnes", "Exposition Totalement désarçonnés pour Maisons-Laffitte", "Publicité"],
 ["https://vimeo.com/225828540", "raison", "Cuisines Raison - Film de présentation", "Publicité"],
 ["https://vimeo.com/225828444", "openconseil", "Open Conseil - Film de présentation", "Publicité"],
 ["https://vimeo.com/225828383", "emma malig", "Exposition Emma Malig pour Maisons-Laffitte", "Publicité"],
 ["https://vimeo.com/225828198", "rodolphe", "Rodolphe & Co Vannes", "Publicité"],
 ["https://vimeo.com/225827294", "toptech", "Top tech challenge 2017 pour Fraikin", "Publicité"]]

puts "Create #{videos_from_vimeo.length} videos"

  videos_from_vimeo.first(12).each_with_index do |video, i|
    puts "\n creating video n°#{i+1}"
    Video.create!(name: video[1], title: video[2], url: video[0], number: i+1, category: video[3])
  end
