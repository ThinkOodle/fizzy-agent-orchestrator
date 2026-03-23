module FizzyOpenclaw
  class AgentSessionsController < ApplicationController
    RELAY_URL = "http://localhost:18795".freeze

    def start
      @card = Card.find(params[:card_id])
      config = FizzyOpenclaw::ColumnConfig.find_by(column_id: @card.column_id)

      unless config
        return render json: { error: "No agent config for this column" }, status: :unprocessable_entity
      end

      session = SessionSpawner.spawn(@card, config)
      if session
        render json: { status: session.status, session_id: session.id }
      else
        render json: { error: "Failed to spawn agent" }, status: :unprocessable_entity
      end
    end

    def stop
      @card = Card.find(params[:card_id])
      session = CardSession.find_by(card_id: @card.id, status: [0, 1])

      if session
        session.update!(status: :stopped, completed_at: Time.current)
        render json: { status: "stopped" }
      else
        render json: { error: "No active session" }, status: :not_found
      end
    end

    # Proxy to relay server (avoids CORS issues from browser)
    def events
      card_number = params[:card_number]
      after_seq = params[:after_seq] || "0"

      uri = URI("#{RELAY_URL}/events?card_number=#{card_number}&after_seq=#{after_seq}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.open_timeout = 3
      http.read_timeout = 5

      req = Net::HTTP::Get.new(uri.request_uri)
      resp = http.request(req)

      render json: JSON.parse(resp.body)
    rescue => e
      render json: { events: [], has_more: false, error: e.message }
    end
  end
end
