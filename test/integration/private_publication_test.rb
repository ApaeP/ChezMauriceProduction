require "test_helper"

class PrivatePublicationTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  PROJECT = FrameIoPublication::PROJECT_ID
  CHANNEL = FrameIoPublication::CHANNEL_ID
  FILE_ID = "destination-1"
  FILE_URL = "https://api.frame.io/v4/accounts/studio/files/#{FILE_ID}"
  MEDIA = "https://assets.frame.io/original?signature=fake"
  SESSION = "https://www.googleapis.com/upload/youtube/v3/videos?upload_id=fake-session"
  VIDEO = "tEsT12_FAke"
  TRIAL = {
    "FRAME_IO_PRIVATE_TRIAL" => "1",
    "FRAME_IO_WEBHOOK_SECRET" => "fixture-secret", "FRAME_IO_AUTH_MODE" => "server_to_server",
    "ADOBE_CLIENT_ID" => "fixture", "ADOBE_CLIENT_SECRET" => "fixture", "ADOBE_SCOPES" => "fixture",
    "FRAME_IO_ACCOUNT_ID" => "studio", "YOUTUBE_CLIENT_ID" => "fixture", "YOUTUBE_CLIENT_SECRET" => "fixture",
    "FRAME_IO_TITLE_FIELD_ID" => nil, "FRAME_IO_DESCRIPTION_FIELD_ID" => nil
  }.freeze

  setup do
    @old = ENV.to_h.slice(*TRIAL.keys)
    TRIAL.each { |key, value| ENV[key] = value }
    @trial = FrameIoTrial.create!(account_id: "studio", project_id: PROJECT, existing_file_ids: %w[old-film-1 old-film-2])
    YoutubeConnection.create!(id: 1, channel_id: CHANNEL, channel_title: "Chaîne de test", refresh_token: "refresh")
    [ MediaApi::FrameIo::TOKEN_URL, Youtube::Client::TOKEN_URL ].each do |url|
      stub_request(:post, url).to_return_json(body: { token_type: "Bearer", access_token: "fixture", expires_in: 3600 })
    end
    stub_channel(CHANNEL)
    @file = { id: FILE_ID, type: "file", project_id: PROJECT, created_at: "2026-11-21T10:00:00Z",
      name: "Export de test.mov", media_type: "video/quicktime", file_size: 5, status: "ready" }
    stub_request(:get, FILE_URL).to_return { { body: { data: @file }.to_json } }
    stub_request(:get, "#{FILE_URL}?include=media_links.original").to_return do
      { body: { data: @file.merge(media_links: { original: { download_url: MEDIA } }) }.to_json }
    end
    @media = stub_request(:get, MEDIA).to_return(body: "abcde")
    @creation = stub_request(:post, Youtube::Client::CREATE_URL).with(body: {
      snippet: { title: @file[:name], description: "", categoryId: "1" }, status: { privacyStatus: "private" }
    }).to_return(status: 200, headers: { "Location" => SESSION })
    @probe = stub_request(:put, SESSION).with(headers: { "Content-Range" => "bytes */5", "Content-Length" => "0" })
    @result = { id: VIDEO, snippet: { channelId: CHANNEL }, status: { privacyStatus: "private" } }
  end

  teardown do
    TRIAL.each_key { |key| ENV[key] = @old[key] }
  end

  test "un dépôt interrompu reprend au dernier octet confirmé et reste privé malgré plusieurs signaux" do
    @probe.to_return(status: 308).then.to_return(status: 308, headers: { "Range" => "bytes=0-1" })
    first = stub_request(:put, SESSION).with(headers: { "Content-Range" => "bytes 0-4/5" }, body: "abcde").to_timeout
    remainder = stub_request(:put, SESSION).with(headers: { "Content-Range" => "bytes 2-4/5" }, body: "cde")
      .to_return_json(status: 201, body: @result)
    signal("file.ready")
    assert_difference("Realisation.count", 1) { work }
    transfer = FrameIoPublication.sole
    assert_equal "uploading", transfer.state
    assert_equal SESSION, transfer.session_url
    assert_not_includes transfer.read_attribute_before_type_cast("session_url"), "fake-session"
    assert_enqueued_jobs 1, only: FrameIoPublicationJob
    # The delayed retry alone completes the upload. Replayed deliveries can then drain.
    travel 2.minutes do
      work
      %w[file.upload.completed file.ready file.copied].each { |type| signal(type) }
      work
    end
    assert_requested @creation, times: 1
    assert_requested first, times: 1
    assert_requested remainder, times: 1
    assert_completed_and_hidden(transfer)
  end

  test "la copie prête seule aboutit, même datée comme son ancien original" do
    @file[:created_at] = "2020-05-01T00:00:00Z"
    @probe.to_return(status: 308)
    stub_request(:put, SESSION).with(body: "abcde").to_return_json(status: 201, body: @result)
    signal("file.copied")
    work
    signal("file.copied")
    work
    assert_requested @creation, times: 1
    assert_completed_and_hidden(FrameIoPublication.sole)
    assert_not_requested :get, "#{FILE_URL}/metadata"
  end

  test "un original en traitement attend puis peut aboutir sur la même fiche" do
    @file[:status] = "transcoding"
    signal("file.upload.completed")
    work
    draft = Realisation.sole
    assert_predicate draft, :persisted?
    assert_not draft.published?
    assert_not_requested @creation
    @file[:status] = "ready"
    @probe.to_return_json(body: @result)
    signal("file.ready")
    work
    assert_equal draft.id, FrameIoPublication.sole.realisation_id
    assert_requested @creation, times: 1
    assert_completed_and_hidden(FrameIoPublication.sole)
  end

  test "aucun ancien film, fichier source d’une copie, ou fichier d’un autre compte n’est transféré" do
    @file[:project_id] = "bibliotheque-source"
    signal("file.copied")
    work
    @file[:project_id] = PROJECT
    @trial.update!(existing_file_ids: [ FILE_ID ])
    signal("file.ready")
    work
    signal("file.copied", account: "autre-compte")
    work
    assert_equal 0, FrameIoPublication.count
    assert_equal 0, Realisation.count
    assert_not_requested @creation
    assert_not_requested @media
  end

  test "une chaîne inattendue échoue avant la création et conserve le brouillon" do
    stub_channel("autre-chaine")
    assert_raises(Youtube::Client::ChannelUnavailable) { FrameIoPublicationJob.perform_now("studio", PROJECT, FILE_ID, "file.copied") }
    assert_equal "pending", FrameIoPublication.sole.state
    assert_not Realisation.sole.published?
    assert_not_requested @creation
  end

  test "aucune répétition du POST après une réponse de création perdue ou un arrêt à cette étape" do
    lost = stub_request(:post, Youtube::Client::CREATE_URL).to_timeout
    signal("file.ready")
    work
    transfer = FrameIoPublication.sole
    assert_equal [ "review", "creation_incertaine" ], [ transfer.state, transfer.review_reason ]
    signal("file.copied")
    work
    transfer.update!(state: "creating_session", review_reason: nil)
    signal("file.upload.completed")
    work
    assert_requested @creation, times: 1
    assert_requested lost, times: 1
    assert_not_requested :put, SESSION
    assert_nil Realisation.sole.youtube_id
  end

  test "une session expirée reste à vérifier sans deuxième création" do
    @probe.to_return(status: 410)
    signal("file.ready")
    work
    signal("file.copied")
    work
    assert_equal "session_expiree", FrameIoPublication.sole.review_reason
    assert_requested @creation, times: 1
    assert_nil Realisation.sole.youtube_id
  end

  test "une réponse finale sans confirmation privée est isolée" do
    @probe.to_return_json(body: @result.merge(status: { privacyStatus: "unlisted" }))
    signal("file.copied")
    work
    assert_equal "reponse_youtube_inattendue", FrameIoPublication.sole.review_reason
    assert_nil Realisation.sole.youtube_id
    assert_not Realisation.sole.published?
  end

  test "un original différent de même taille ne reprend pas une session existante" do
    @probe.to_timeout
    signal("file.ready")
    work
    @media.to_return(body: "vwxyz")
    signal("file.copied")
    work
    assert_equal "original_modifie", FrameIoPublication.sole.review_reason
    assert_requested @creation, times: 1
    assert_requested @probe, times: 1
  end

  private
    def signal(type, account: "studio")
      body = { type: type, account: { id: account }, project: { id: PROJECT }, resource: { type: "file", id: FILE_ID } }.to_json
      epoch = Time.current.to_i.to_s
      mac = OpenSSL::HMAC.hexdigest("SHA256", TRIAL.fetch("FRAME_IO_WEBHOOK_SECRET"), "v0:#{epoch}:#{body}")
      post frame_io_webhook_path, params: body, headers: { "Content-Type" => "application/json",
        "X-Frameio-Request-Timestamp" => epoch, "X-Frameio-Signature" => "v0=#{mac}" }
      assert_response :accepted
    end

    def stub_channel(id)
      stub_request(:get, Youtube::Client::CHANNEL_URL).to_return_json(body: { items: [ { id: id, snippet: { title: "Chaîne" } } ] })
    end

    def work
      perform_enqueued_jobs(only: FrameIoPublicationJob, at: Time.current)
    end

    def assert_completed_and_hidden(transfer)
      assert_equal 1, Realisation.count
      assert_equal "completed", transfer.reload.state
      assert_nil transfer.session_url
      draft = transfer.realisation.reload
      assert_equal VIDEO, draft.youtube_id
      assert_not draft.published?
      get realisation_path(draft)
      assert_response :not_found
      get realisations_path
      assert_response :success
      assert_select "a[href=?]", realisation_path(draft), count: 0
      get sitemap_path
      assert_response :success
      assert_not_includes response.body, realisation_path(draft)
    end
end
