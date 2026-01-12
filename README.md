# Agent Kill Switch

A real-time dashboard for monitoring and terminating mock AI agents built with Phoenix and Elixir. I wanted to gain some familiarity with Elixir and Svelte.

## Overview

This application simulates multiple AI agents that periodically emit thoughts and actions. A web dashboard allows operators to monitor agent behavior in real-time and instantly kill misbehaving agents.

## Features

- **Mock AI Agents**: GenServer-based agents that simulate AI behavior with periodic heartbeats
- **Real-time Monitoring**: Phoenix Channels provide live updates of agent status and logs
- **Kill Switch**: HTTP API and real-time UI for terminating agents
- **Process Supervision**: DynamicSupervisor manages agent lifecycles
- **Registry-based Discovery**: Efficient agent lookup using Elixir Registry

## Architecture

### Backend (Elixir/Phoenix)

- **AgentKillSwitch.Agents.MockAgent**: GenServer simulating AI agent behavior
- **AgentKillSwitch.Agents.Supervisor**: DynamicSupervisor managing agent processes
- **AgentKillSwitchWeb.AgentChannel**: Phoenix Channel for real-time updates
- **AgentKillSwitchWeb.AgentController**: HTTP API for agent spawn/kill operations

### Frontend (Svelte - TODO)

- Real-time dashboard showing agent status
- Agent logs and kill buttons
- WebSocket connection to Phoenix Channels

## Getting Started

### Prerequisites

- Elixir 1.14+
- Phoenix 1.7+

### Installation

```bash
# Install dependencies
mix deps.get

# Run tests
mix test

# Start the server
mix phx.server
```

The application will start 3 mock agents automatically and be available at `http://localhost:4000`.

### API Endpoints

- `POST /api/agents` - Spawn a new agent
- `POST /api/agents/:id/kill` - Kill an agent by ID

### WebSocket Channel

- Topic: `agents:lobby`
- Messages: `agent_update`, `agent_terminated`

## Configuration

Agent behavior can be configured in `AgentKillSwitch.Agents.Supervisor`:

- `tick_interval_ms`: Agent heartbeat interval (default: 1000ms)
- `max_log_entries`: Maximum log entries per agent (default: 20)
- `auto_respawn`: Whether agents respawn after being killed (default: false)

## Testing

Run the test suite:

```bash
mix test
```

Tests cover:

- Agent lifecycle management
- Supervisor operations
- State transitions and log management

## Architecture Notes

- Agents run continuously regardless of client connections
- Process termination is immediate but allows current broadcasts to complete
- Registry provides O(1) agent lookup by ID
- PubSub enables efficient broadcasting of agent updates
