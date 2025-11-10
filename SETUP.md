# NotiMesh Setup Guide

## Quick Start

1. **Install dependencies:**
   ```bash
   cd notimesh
   mix deps.get
   ```

2. **Set up database:**
   ```bash
   mix ecto.create
   mix ecto.migrate
   ```

3. **Install Oban tables:**
   ```bash
   mix oban.install
   mix ecto.migrate
   ```

4. **Start the server:**
   ```bash
   mix phx.server
   ```

5. **Access the dashboard:**
   Visit `http://localhost:4000/admin`

## Multi-Node Setup

### Terminal 1 (Node 1):
```bash
cd notimesh
NODE_NAME=notimesh@127.0.0.1 COOKIE=notimesh_cookie iex --sname notimesh@127.0.0.1 -S mix phx.server
```

### Terminal 2 (Node 2):
```bash
cd notimesh
NODE_NAME=notimesh2@127.0.0.1 COOKIE=notimesh_cookie iex --sname notimesh2@127.0.0.1 -S mix phx.server
```

### Connect nodes (in IEx):
```elixir
Node.connect(:"notimesh2@127.0.0.1")
Node.list()  # Should show both nodes
```

## Testing Notifications

### Via Dashboard
1. Go to `http://localhost:4000/admin`
2. Fill out the form on the right
3. Click "Send Notification"
4. Watch it appear in the list and process

### Via IEx
```elixir
alias Notimesh.Notifications.Delivery

# Email notification
Delivery.enqueue(%{
  type: :email,
  recipient: "test@example.com",
  subject: "Test Email",
  body: "This is a test notification"
})

# SMS notification
Delivery.enqueue(%{
  type: :sms,
  recipient: "+1234567890",
  body: "Test SMS message"
})

# Slack notification (requires webhook URL)
Delivery.enqueue(%{
  type: :slack,
  recipient: "#general",
  body: "Test Slack message",
  metadata: %{"webhook_url" => "https://hooks.slack.com/services/YOUR/WEBHOOK/URL"}
})
```

## Configuration

### Email (Production)
Update `config/prod.exs` or use environment variables:
```elixir
config :notimesh, Notimesh.Mailer,
  adapter: Swoosh.Adapters.SMTP,
  relay: System.get_env("SMTP_RELAY"),
  username: System.get_env("SMTP_USERNAME"),
  password: System.get_env("SMTP_PASSWORD"),
  ssl: true,
  tls: :always
```

### SMS Provider
Set environment variables:
```bash
export SMS_API_URL="https://api.twilio.com/2010-04-01/Accounts/YOUR_ACCOUNT/Messages.json"
export SMS_API_KEY="your-api-key"
```

### Slack
Either set globally:
```elixir
config :notimesh, :slack_webhook_url, "https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
```

Or include in notification metadata (per notification).

## Features Demonstrated

✅ **Multi-node clustering** - Erlang distribution across nodes  
✅ **Fault tolerance** - Oban workers with retry logic  
✅ **Background processing** - Asynchronous notification delivery  
✅ **Multiple channels** - Email, SMS, Slack adapters  
✅ **Real-time dashboard** - LiveView admin interface  
✅ **Retry with exponential backoff** - Automatic retry for failed notifications  
✅ **Node tracking** - See which node processed each notification  

## Project Structure

```
notimesh/
├── lib/
│   ├── notimesh/
│   │   ├── notifications/
│   │   │   ├── delivery/
│   │   │   │   ├── adapter.ex          # Behaviour for adapters
│   │   │   │   ├── email_adapter.ex    # Email delivery
│   │   │   │   ├── sms_adapter.ex      # SMS delivery
│   │   │   │   └── slack_adapter.ex   # Slack delivery
│   │   │   ├── notification.ex         # Ecto schema
│   │   │   └── delivery.ex             # Enqueue logic
│   │   ├── workers/
│   │   │   ├── notification_worker.ex  # Main worker
│   │   │   └── notification_retry_worker.ex  # Retry worker
│   │   ├── notifications.ex            # Context
│   │   ├── mailer.ex                   # Swoosh mailer
│   │   └── repo.ex                     # Ecto repo
│   └── notimesh_web/
│       └── live/
│           └── admin_live.ex           # Dashboard LiveView
└── priv/
    └── repo/
        └── migrations/                 # Database migrations
```

## Next Steps

1. Configure production email/SMS/Slack credentials
2. Set up monitoring and alerting
3. Add authentication to admin dashboard
4. Implement rate limiting
5. Add webhook endpoints for external integrations

