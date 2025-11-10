# NotiMesh - Distributed Notification System

A distributed, fault-tolerant notification system built with Phoenix, Erlang distribution, and Oban for background job processing.

## Features

- **Multi-node cluster communication** - Distribute notifications across multiple Erlang nodes
- **Fault-tolerant background workers** - Built on Oban for reliable job processing
- **Multiple delivery channels** - Email (Swoosh), SMS, and Slack support
- **Admin dashboard** - Real-time tracking of notification delivery
- **Retry with exponential backoff** - Automatic retry logic for failed notifications
- **Node tracking** - See which node processed each notification

## Tech Stack

- **Phoenix** - Web framework
- **Erlang Distribution** - Multi-node clustering
- **Oban** - Background job processing
- **Swoosh** - Email delivery
- **Req** - HTTP client for SMS/Slack APIs
- **PostgreSQL** - Database for notification tracking
- **Phoenix LiveView** - Real-time admin dashboard

## Setup

### Prerequisites

- Elixir 1.15+
- PostgreSQL
- Erlang/OTP 26+

### Installation

1. Install dependencies:
```bash
cd notimesh
mix deps.get
```

2. Create and migrate the database:
```bash
mix ecto.create
mix ecto.migrate
```

3. Install Oban migrations:
```bash
mix ecto.gen.migration add_oban_jobs_table
# Then copy the migration from Oban's documentation or run:
mix oban.install
```

4. Start the Phoenix server:
```bash
mix phx.server
```

Visit `http://localhost:4000/admin` to access the dashboard.

## Multi-Node Setup

To run multiple nodes:

### Node 1:
```bash
NODE_NAME=notimesh@127.0.0.1 COOKIE=notimesh_cookie iex --sname notimesh@127.0.0.1 -S mix phx.server
```

### Node 2:
```bash
NODE_NAME=notimesh2@127.0.0.1 COOKIE=notimesh_cookie iex --sname notimesh2@127.0.0.1 -S mix phx.server
```

Connect nodes:
```elixir
Node.connect(:"notimesh2@127.0.0.1")
Node.list()
```

## Configuration

### Email (Swoosh)

Configure in `config/dev.exs`:
```elixir
config :notimesh, Notimesh.Mailer,
  adapter: Swoosh.Adapters.SMTP,
  relay: "smtp.example.com",
  username: "user",
  password: "pass"
```

### SMS

Set environment variables:
```bash
export SMS_API_URL="https://api.sms-provider.com/send"
export SMS_API_KEY="your-api-key"
```

### Slack

Set webhook URL or include in notification metadata:
```elixir
Notimesh.Notifications.Delivery.enqueue(%{
  type: :slack,
  recipient: "#general",
  body: "Hello from NotiMesh!",
  metadata: %{
    "webhook_url" => "https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
  }
})
```

## Usage

### Enqueue a Notification

```elixir
alias Notimesh.Notifications.Delivery

# Email
Delivery.enqueue(%{
  type: :email,
  recipient: "user@example.com",
  subject: "Welcome!",
  body: "Welcome to NotiMesh"
})

# SMS
Delivery.enqueue(%{
  type: :sms,
  recipient: "+1234567890",
  body: "Your verification code is 123456"
})

# Slack
Delivery.enqueue(%{
  type: :slack,
  recipient: "#general",
  body: "New notification!",
  metadata: %{"webhook_url" => "..."}
})
```

### Query Notifications

```elixir
alias Notimesh.Notifications

# List all notifications
Notifications.list_notifications()

# Filter by status
Notifications.list_notifications([status: :pending])

# Get statistics
Notifications.get_statistics()
```

## Retry Logic

Notifications automatically retry with exponential backoff:
- 1st retry: 2 minutes
- 2nd retry: 4 minutes
- 3rd retry: 8 minutes

After max retries (default: 3), notifications are marked as failed.

## Admin Dashboard

Access the dashboard at `/admin` to:
- View real-time statistics
- See all notifications with status
- Filter by status and type
- Create new notifications
- Track which node processed each notification

## Architecture

- **Notifications Context** - Manages notification records
- **Delivery Module** - Enqueues notifications to Oban
- **Workers** - Process notifications asynchronously
- **Adapters** - Handle delivery to different channels
- **Admin LiveView** - Real-time dashboard

## License

MIT
