get "connexion-youtube", to: "youtube_connections#show", as: :youtube_connection
post "connexion-youtube", to: "youtube_connections#unlock"
delete "connexion-youtube", to: "youtube_connections#close"
post "connexion-youtube/autoriser", to: "youtube_connections#authorize", as: :authorize_youtube
get "connexion-youtube/retour", to: "youtube_connections#landing", as: :youtube_callback
post "connexion-youtube/retour", to: "youtube_connections#callback"

get "connexion-frame-io", to: "adobe_connections#show", as: :frame_io_connection
post "connexion-frame-io", to: "adobe_connections#unlock"
delete "connexion-frame-io", to: "adobe_connections#close"
post "connexion-frame-io/autoriser", to: "adobe_connections#authorize", as: :authorize_frame_io
get "connexion-frame-io/retour", to: "adobe_connections#landing", as: :frame_io_callback
post "connexion-frame-io/retour", to: "adobe_connections#callback"
post "connexion-frame-io/compte", to: "adobe_connections#select_account", as: :frame_io_account
