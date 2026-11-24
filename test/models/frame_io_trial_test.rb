require "test_helper"

class FrameIoTrialTest < ActiveSupport::TestCase
  test "l’ouverture est en lecture seule et ne réadmet jamais le catalogue d’origine" do
    client = Object.new
    client.define_singleton_method(:account_id) { "studio" }
    reads = []
    client.define_singleton_method(:project_file_ids) do |project|
      reads << project
      %w[ancien-a ancien-b]
    end

    factory = Class.new
    factory.define_singleton_method(:from_env) { client }
    stub_const(MediaApi, :FrameIo, factory) do
      first = FrameIoTrial.open!
      assert_equal %w[ancien-a ancien-b], first.existing_file_ids
      assert_equal first.id, FrameIoTrial.open!.id
    end
    assert_equal [ FrameIoPublication::PROJECT_ID ], reads
    assert_equal 0, Realisation.count
    assert_equal 0, FrameIoPublication.count
  end

  test "une erreur de pagination laisse la recette fermée" do
    client = Object.new
    client.define_singleton_method(:account_id) { "studio" }
    client.define_singleton_method(:project_file_ids) { |_| raise MediaApi::TransportError, "interrompu" }
    factory = Class.new
    factory.define_singleton_method(:from_env) { client }
    stub_const(MediaApi, :FrameIo, factory) do
      assert_no_difference("FrameIoTrial.count") { assert_raises(MediaApi::TransportError) { FrameIoTrial.open! } }
    end
  end
end
