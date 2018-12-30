# frozen_string_literal: true

class StreamController < ApplicationController
  include ActionController::Live

  before_action :require_login
  before_action :set_header

  def new
    song = Song.find_by(id: params[:song_id])
    return head :forbidden unless song

    stream = Stream.new(song)

    if stream.need_transcode?
      send_stream stream
    else
      send_file stream.file_path
    end
  end

  private

    # Let nginx can get value of media_path dynamically in the nginx config,
    # when use X-Accel-Redirect header to send file.
    #
    # Todo: add apache send_file header description.
    def set_header
      if Rails.configuration.action_dispatch.x_sendfile_header == 'X-Accel-Redirect'
        response.set_header('X-Media-Path', Setting.media_path)
      end
    end

    # Similar to send_file in rails, but let response_body to be a stream object.
    # The instance of Stream can respond to each() method. So the download can be streamed,
    # instead of read whole data into memory.
    def send_stream(stream)
      response.headers['Content-Type'] = 'audio/mpeg'

      stream.each do |data|
        response.stream.write data
      end
    ensure
      response.stream.close
    end
end