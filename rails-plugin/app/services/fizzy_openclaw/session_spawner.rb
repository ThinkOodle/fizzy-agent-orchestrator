require "net/http"
require "json"

module FizzyOpenclaw
  class SessionSpawner
    HOOK_URL = "http://localhost:18789/hooks/fizzy".freeze

    def self.spawn(card, column_config)
      new(card, column_config).spawn
    end

    def initialize(card, column_config)
      @card = card
      @column_config = column_config
    end

    def spawn
      # Stop any existing active session first
      existing = CardSession.find_by(card_id: @card.id, status: [0, 1])
      existing&.update!(status: :stopped, completed_at: Time.current)

      session = CardSession.create!(
        card_id: @card.id,
        status: :pending,
        started_at: Time.current
      )

      response = post_to_openclaw
      if response && response.code.to_i == 200
        session.update!(status: :running)
        session
      else
        session.update!(status: :failed, completed_at: Time.current)
        Rails.logger.error "[FizzyOpenclaw] Spawn failed (HTTP #{response&.code}): #{response&.body}"
        nil
      end
    rescue => e
      Rails.logger.error "[FizzyOpenclaw] Spawn error: #{e.message}"
      nil
    end

    private

    def post_to_openclaw
      uri = URI(HOOK_URL)
      http = Net::HTTP.new(uri.host, uri.port)
      http.open_timeout = 5
      http.read_timeout = 10

      req = Net::HTTP::Post.new(uri.path)
      req["Authorization"] = "Bearer #{hook_token}"
      req["Content-Type"] = "application/json"
      req.body = payload.to_json

      http.request(req)
    end

    def payload
      board = @column_config.column.board
      board_config = FizzyOpenclaw::BoardConfig.find_by(board_id: board.id)

      {
        action: "column_changed",
        card: {
          id: @card.id,
          number: @card.number,
          title: @card.title
        },
        column: {
          id: @column_config.column.id,
          name: @column_config.column.name
        },
        board: {
          id: board.id,
          name: board.name
        },
        agent_context: {
          board_prompt: board_config&.system_prompt,
          column_prompt: @column_config.system_prompt,
          timeout_minutes: @column_config.timeout_minutes,
          allowed_tools: @column_config.allowed_tools
        }
      }
    end

    def hook_token
      Rails.application.credentials.openclaw_hook_token
    end
  end
end
